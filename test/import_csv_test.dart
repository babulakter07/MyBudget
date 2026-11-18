import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/import/data/csv_import_service.dart';
import 'package:my_budget/features/import/data/csv_parsing.dart';
import 'package:my_budget/features/import/domain/csv_import_models.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';

const _ts = 1700000000;

Future<void> _sql(AppDatabase db, String sql, [List<Object?> a = const []]) =>
    db.customStatement(sql, a);

void main() {
  group('parseCsv', () {
    test('quotes, embedded commas/quotes/newlines, CRLF', () {
      final t = parseCsv(
        'Date,Description,Amount\r\n'
        '01/05/2024,"Rice, 5kg",-500\r\n'
        '02/05/2024,"He said ""hi""\nsecond line",1200.50\r\n',
      );
      expect(t.headers, ['Date', 'Description', 'Amount']);
      expect(t.rows, hasLength(2));
      expect(t.rows[0][1], 'Rice, 5kg');
      expect(t.rows[1][1], 'He said "hi"\nsecond line');
      expect(t.delimiter, ',');
    });

    test('BOM is stripped and semicolon delimiter detected', () {
      final t = parseCsv('﻿Date;Amount;Note\n2024-05-01;"1,234.50";x\n');
      expect(t.headers.first, 'Date');
      expect(t.delimiter, ';');
      expect(t.rows.single, ['2024-05-01', '1,234.50', 'x']);
    });

    test('tab delimiter, no header, short rows padded, blanks skipped', () {
      final t = parseCsv('a\tb\tc\n\n1\t2\n', hasHeader: false);
      expect(t.delimiter, '\t');
      expect(t.headers, ['Column 1', 'Column 2', 'Column 3']);
      expect(t.rows, [
        ['a', 'b', 'c'],
        ['1', '2', ''],
      ]);
    });

    test('empty file is a ValidationException', () {
      expect(() => parseCsv('  \n'), throwsA(isA<ValidationException>()));
    });

    test('guessMapping from header names', () {
      final t = parseCsv('Txn Date,Narration,Amount,Category,Type\n');
      final m = guessMapping(t);
      expect(m.date, 0);
      expect(m.description, 1);
      expect(m.amount, 2);
      expect(m.category, 3);
      expect(m.type, 4);
    });

    test('guessDateFormat sniffs ISO and US layouts', () {
      var t = parseCsv('d,a\n2024-05-01,1\n');
      expect(guessDateFormat(t, 0), CsvDateFormat.yyyyMmDdDash);
      t = parseCsv('d,a\n05/25/2024,1\n');
      expect(guessDateFormat(t, 0), CsvDateFormat.mmDdYyyySlash);
      t = parseCsv('d,a\n25/05/2024,1\n');
      expect(guessDateFormat(t, 0), CsvDateFormat.ddMmYyyySlash);
    });
  });

  group('dates', () {
    test('supported formats', () {
      expect(
        parseCsvDate('25/12/2024', CsvDateFormat.ddMmYyyySlash),
        '2024-12-25',
      );
      expect(
        parseCsvDate('5/1/2024', CsvDateFormat.ddMmYyyySlash),
        '2024-01-05',
      );
      expect(
        parseCsvDate('2024-12-25', CsvDateFormat.yyyyMmDdDash),
        '2024-12-25',
      );
      expect(
        parseCsvDate('2024-12-25 10:30:00', CsvDateFormat.yyyyMmDdDash),
        '2024-12-25',
      );
      expect(
        parseCsvDate('25-12-2024', CsvDateFormat.ddMmYyyyDash),
        '2024-12-25',
      );
      expect(
        parseCsvDate('12/25/2024', CsvDateFormat.mmDdYyyySlash),
        '2024-12-25',
      );
    });

    test('same text means different dates per chosen format', () {
      expect(
        parseCsvDate('03/04/2024', CsvDateFormat.ddMmYyyySlash),
        '2024-04-03',
      );
      expect(
        parseCsvDate('03/04/2024', CsvDateFormat.mmDdYyyySlash),
        '2024-03-04',
      );
    });

    test('invalid dates are null', () {
      expect(parseCsvDate('31/02/2024', CsvDateFormat.ddMmYyyySlash), isNull);
      expect(parseCsvDate('13/25/2024', CsvDateFormat.mmDdYyyySlash), isNull);
      expect(parseCsvDate('2024/05/01', CsvDateFormat.yyyyMmDdDash), isNull);
      expect(parseCsvDate('', CsvDateFormat.ddMmYyyySlash), isNull);
      expect(parseCsvDate('abc', CsvDateFormat.ddMmYyyySlash), isNull);
    });
  });

  group('amounts', () {
    test('formats', () {
      expect(parseSignedAmount('1,234.50'), 123450);
      expect(parseSignedAmount('(500)'), -50000);
      expect(parseSignedAmount('৳500'), 50000);
      expect(parseSignedAmount('-৳500'), -50000);
      expect(parseSignedAmount('-500'), -50000);
      expect(parseSignedAmount('500-'), -50000);
      expect(parseSignedAmount('+75.5'), 7550);
      expect(parseSignedAmount('BDT 1,000'), 100000);
      expect(parseSignedAmount('Tk. 20'), 2000);
      expect(parseSignedAmount('−200'), -20000);
      expect(parseSignedAmount('0'), 0);
    });

    test('garbage is null', () {
      expect(parseSignedAmount(''), isNull);
      expect(parseSignedAmount('abc'), isNull);
      expect(parseSignedAmount('12.345'), isNull);
      expect(parseSignedAmount('1,23'), isNull);
    });

    test('type words', () {
      expect(parseTypeWord('Debit'), isTrue);
      expect(parseTypeWord(' CR '), isFalse);
      expect(parseTypeWord('transfer'), isNull);
    });
  });

  group('CsvImportService', () {
    late AppDatabase db;
    late TransactionRepository repo;
    late CsvImportService service;

    setUp(() async {
      db = AppDatabase.memory();
      repo = TransactionRepository(db);
      service = CsvImportService(db, repo);
      for (final id in [1, 2]) {
        await _sql(
          db,
          "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (?,?,'BDT',1,?,?)",
          [id, 'P$id', _ts, _ts],
        );
      }
      await _sql(
        db,
        "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (1,1,'Cash','cash',0,'2024-01-01',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (2,2,'Other','cash',0,'2024-01-01',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO categories (id,profile_id,name,is_active,created_at,updated_at) VALUES (1,1,'Food',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO categories (id,profile_id,name,is_active,created_at,updated_at) VALUES (2,1,'Transport',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO categories (id,profile_id,name,is_active,created_at,updated_at) VALUES (3,1,'Old',0,?,?)",
        [_ts, _ts],
      );
    });

    tearDown(() => db.close());

    ImportSettings settings({
      int account = 1,
      int? defCat = 1,
      ColumnMapping? mapping,
    }) => ImportSettings(
      accountId: account,
      defaultCategoryId: defCat,
      mapping:
          mapping ??
          const ColumnMapping(
            date: 0,
            description: 1,
            amount: 2,
            category: 3,
            dateFormat: CsvDateFormat.ddMmYyyySlash,
          ),
    );

    const csvText =
        'Date,Description,Amount,Category\n'
        '01/05/2024,Rice,-500,food\n'
        '02/05/2024,Bus,"-40.50",TRANSPORT\n'
        '03/05/2024,Salary,"50,000",Salary\n'
        '04/05/2024,Mystery,(10),Unknown cat\n';

    Future<int> count() async =>
        (await db
                    .customSelect(
                      'SELECT COUNT(*) c FROM financial_transactions',
                    )
                    .getSingle())
                .data['c']!
            as int;

    test('imports with sign handling, category matching and audit', () async {
      final t = parseCsv(csvText);
      final r = await service.import(
        profileId: 1,
        table: t,
        settings: settings(),
      );
      expect(r.imported, 4);
      expect(r.skippedDuplicates, 0);
      expect(r.invalid, 0);

      final rows = await db
          .customSelect(
            'SELECT type, amount_minor, category_id, category_name_snapshot, '
            'income_source, title, txn_date FROM financial_transactions ORDER BY id',
          )
          .get();
      expect(rows[0].data['type'], 'expense');
      expect(rows[0].data['amount_minor'], 50000);
      expect(rows[0].data['category_id'], 1); // "food" ~ Food
      expect(rows[1].data['category_id'], 2); // TRANSPORT ~ Transport
      expect(rows[1].data['amount_minor'], 4050);
      expect(rows[2].data['type'], 'income');
      expect(rows[2].data['amount_minor'], 5000000);
      expect(rows[2].data['income_source'], 'Salary');
      expect(rows[3].data['category_id'], 1); // unmatched -> default
      expect(rows[3].data['txn_date'], '2024-05-04');
      expect(
        (await db
                .customSelect('SELECT COUNT(*) c FROM transaction_audit_logs')
                .getSingle())
            .data['c'],
        4,
      );
      // never creates categories
      expect(
        (await db.customSelect('SELECT COUNT(*) c FROM categories').getSingle())
            .data['c'],
        3,
      );
    });

    test('re-importing the same file creates no duplicates', () async {
      final t = parseCsv(csvText);
      await service.import(profileId: 1, table: t, settings: settings());
      final again = await service.import(
        profileId: 1,
        table: parseCsv(csvText),
        settings: settings(),
      );
      expect(again.imported, 0);
      expect(again.skippedDuplicates, 4);
      expect(await count(), 4);
    });

    test('identical lines in one file are both imported, once', () async {
      const text =
          'Date,Description,Amount,Category\n'
          '01/05/2024,Tea,-20,Food\n'
          '01/05/2024,Tea,-20,Food\n';
      final r1 = await service.import(
        profileId: 1,
        table: parseCsv(text),
        settings: settings(),
      );
      expect(r1.imported, 2);
      final r2 = await service.import(
        profileId: 1,
        table: parseCsv(text),
        settings: settings(),
      );
      expect(r2.imported, 0);
      expect(r2.skippedDuplicates, 2);
      expect(await count(), 2);
      final keys = CsvImportService.rowKeys(parseCsv(text).rows, 1);
      expect(keys[0], matches(RegExp(r'^import:[0-9a-f]{64}:1$')));
      expect(keys[1].endsWith(':2'), isTrue);
    });

    test('a file with extra new rows only imports the new ones', () async {
      await service.import(
        profileId: 1,
        table: parseCsv(csvText),
        settings: settings(),
      );
      final r = await service.import(
        profileId: 1,
        table: parseCsv('${csvText}05/05/2024,New,-5,Food\n'),
        settings: settings(),
      );
      expect(r.imported, 1);
      expect(r.skippedDuplicates, 4);
      expect(await count(), 5);
    });

    test('invalid rows are reported and skipped', () async {
      const text =
          'Date,Description,Amount,Category\n'
          '31/02/2024,BadDate,-5,Food\n'
          '01/05/2024,BadAmt,abc,Food\n'
          '01/05/2024,Zero,0,Food\n'
          '01/12/2023,BeforeOpening,-5,Food\n'
          '01/05/2024,Good,-5,Food\n';
      final t = parseCsv(text);
      final plan = await service.plan(
        profileId: 1,
        table: t,
        settings: settings(),
      );
      expect(plan.invalidCount, 4);
      expect(plan.validCount, 1);
      expect(plan.rows[0].errors.single, contains('Invalid date'));
      expect(plan.rows[1].errors.single, contains('Invalid amount'));
      expect(plan.rows[2].errors.single, contains('greater than zero'));
      expect(plan.rows[3].errors.single, contains('opening date'));
      final r = await service.import(
        profileId: 1,
        table: t,
        settings: settings(),
      );
      expect(r.imported, 1);
      expect(r.invalid, 4);
      expect(await count(), 1);
    });

    test('expense without category and no default is invalid', () async {
      final plan = await service.plan(
        profileId: 1,
        table: parseCsv(csvText),
        settings: settings(defCat: null),
      );
      // Rice + Bus match; Salary is income; Mystery has an unknown category.
      expect(plan.invalidCount, 1);
      expect(plan.rows[3].errors.single, contains('Unknown cat'));
      expect(plan.validCount, 3);
    });

    test('inactive default category is refused', () async {
      await expectLater(
        service.plan(
          profileId: 1,
          table: parseCsv(csvText),
          settings: settings(defCat: 3),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('type column decides expense/income, amount sign ignored', () async {
      const text =
          'Date,Description,Amount,Type\n'
          '01/05/2024,A,100,Debit\n'
          '02/05/2024,B,-200,Credit\n'
          '03/05/2024,C,300,Transfer\n';
      final plan = await service.plan(
        profileId: 1,
        table: parseCsv(text),
        settings: settings(
          mapping: const ColumnMapping(
            date: 0,
            description: 1,
            amount: 2,
            type: 3,
          ),
        ),
      );
      expect(plan.rows[0].isExpense, isTrue);
      expect(plan.rows[1].isExpense, isFalse);
      expect(plan.rows[1].amountMinor, 20000);
      expect(plan.rows[2].status, ImportRowStatus.invalid);
    });

    test('all-or-nothing: a failing write rolls back every row', () async {
      await _sql(
        db,
        'CREATE TRIGGER boom BEFORE INSERT ON financial_transactions '
        "WHEN NEW.amount_minor = 777 BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      const text =
          'Date,Description,Amount,Category\n'
          '01/05/2024,One,-10,Food\n'
          '02/05/2024,Two,-20,Food\n'
          '03/05/2024,Three,-7.77,Food\n'
          '04/05/2024,Four,-40,Food\n';
      await expectLater(
        service.import(
          profileId: 1,
          table: parseCsv(text),
          settings: settings(),
        ),
        throwsA(isA<AppException>()),
      );
      expect(await count(), 0);
      expect(
        (await db
                .customSelect('SELECT COUNT(*) c FROM transaction_audit_logs')
                .getSingle())
            .data['c'],
        0,
      );
    });

    test('account of another profile is rejected', () async {
      await expectLater(
        service.plan(
          profileId: 1,
          table: parseCsv(csvText),
          settings: settings(account: 2),
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
    });

    test('incomplete mapping is rejected', () async {
      await expectLater(
        service.plan(
          profileId: 1,
          table: parseCsv(csvText),
          settings: settings(mapping: const ColumnMapping(date: 0)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'same file into another account is not treated as duplicate',
      () async {
        await _sql(
          db,
          "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (3,1,'Bank','bank',0,'2024-01-01',1,?,?)",
          [_ts, _ts],
        );
        await service.import(
          profileId: 1,
          table: parseCsv(csvText),
          settings: settings(),
        );
        final r = await service.import(
          profileId: 1,
          table: parseCsv(csvText),
          settings: settings(account: 3),
        );
        expect(r.imported, 4);
      },
    );
  });
}
