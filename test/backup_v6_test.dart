import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';

const _ts = 1700000000;

Future<void> _sql(AppDatabase db, String sql) => db.customStatement(sql);

Future<void> _seed(AppDatabase db) async {
  await _sql(
    db,
    "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (1,'Home','BDT',1,$_ts,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO loans (id,profile_id,lender_name,loan_type,reference_no,principal_minor,interest_rate_bp,interest_method,frequency,tenure_count,installment_minor,processing_fee_minor,start_date,first_due_date,is_active,created_at,updated_at) VALUES (1,1,'City Bank','home','LN-1',10000000,1200,'reducing','monthly',12,888488,50000,'2026-01-01','2026-02-01',1,$_ts,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO loan_payments (id,profile_id,loan_id,amount_minor,payment_date,note,is_deleted,created_at) VALUES (1,1,1,888488,'2026-02-01','first',0,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO loan_payments (id,profile_id,loan_id,amount_minor,payment_date,is_deleted,created_at) VALUES (2,1,1,100,'2026-02-02',1,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO credit_cards (id,profile_id,name,bank_name,last_four,credit_limit_minor,statement_day,due_days,apr_bp,min_payment_bp,min_payment_floor_minor,late_fee_bp,late_fee_floor_minor,interest_from_statement,is_active,created_at,updated_at) VALUES (1,1,'Visa Gold','EBL','4242',10000000,5,20,2400,500,50000,200,50000,1,1,$_ts,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO credit_card_bills (id,profile_id,card_id,bill_month,statement_date,due_date,amount_minor,min_payment_minor,is_active,created_at,updated_at) VALUES (1,1,1,'2026-03','2026-03-05','2026-03-25',100000,5000,1,$_ts,$_ts)",
  );
  await _sql(
    db,
    "INSERT INTO credit_card_payments (id,profile_id,bill_id,amount_minor,payment_date,is_deleted,created_at) VALUES (1,1,1,5000,'2026-03-20',0,$_ts)",
  );
}

Future<List<Map<String, Object?>>> _dump(AppDatabase db, String q) async =>
    (await db.customSelect(q).get()).map((r) => r.data).toList();

void main() {
  late AppDatabase db;
  late Directory dir;
  late BackupService service;

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('mybudget_backup_v6_');
    service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
      crypto: const BackupCrypto(iterations: 1000),
    );
    await _seed(db);
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> export() async =>
      jsonDecode(await service.exportJson()) as Map<String, dynamic>;

  List table(Map<String, dynamic> j, String name) =>
      (j['tables'] as Map)[name] as List;

  void expectInvalid(Map<String, dynamic> j, String text) {
    final r = service.validate(jsonEncode(j));
    expect(r.isValid, isFalse);
    expect(r.errors.join('\n'), contains(text));
  }

  test('export carries loan and credit card tables', () async {
    final j = await export();
    expect(j['schemaVersion'], 8);
    expect(table(j, 'loans'), hasLength(1));
    expect(table(j, 'loan_payments'), hasLength(2));
    expect(table(j, 'credit_cards'), hasLength(1));
    expect(table(j, 'credit_card_bills'), hasLength(1));
    expect(table(j, 'credit_card_payments'), hasLength(1));
    expect(service.validate(jsonEncode(j)).isValid, isTrue);
  });

  test('round trip restores identical data', () async {
    final text = await service.exportJson();
    const queries = [
      'SELECT * FROM loans ORDER BY id',
      'SELECT * FROM loan_payments ORDER BY id',
      'SELECT * FROM credit_cards ORDER BY id',
      'SELECT * FROM credit_card_bills ORDER BY id',
      'SELECT * FROM credit_card_payments ORDER BY id',
    ];
    final before = [for (final q in queries) await _dump(db, q)];
    await _sql(db, 'DELETE FROM credit_card_payments');
    await _sql(db, 'DELETE FROM credit_card_bills');
    await _sql(db, 'DELETE FROM credit_cards');
    await _sql(db, 'DELETE FROM loan_payments');
    await _sql(db, 'DELETE FROM loans');
    await service.restore(text);
    final after = [for (final q in queries) await _dump(db, q)];
    expect(after, before);
  });

  test('older file without the v6 tables restores as empty', () async {
    final j = await export();
    j['version'] = 3;
    j['schemaVersion'] = 5;
    final t = j['tables'] as Map;
    for (final n in [
      'loans',
      'loan_payments',
      'credit_cards',
      'credit_card_bills',
      'credit_card_payments',
    ]) {
      t.remove(n);
    }
    final text = jsonEncode(j);
    expect(service.validate(text).isValid, isTrue);
    await service.restore(text);
    expect(await _dump(db, 'SELECT * FROM loans'), isEmpty);
    expect(await _dump(db, 'SELECT * FROM credit_cards'), isEmpty);
  });

  group('validator rejects', () {
    test('cross-profile loan payment', () async {
      final j = await export();
      (j['tables'] as Map)['financial_profiles'] = [
        ...table(j, 'financial_profiles'),
        {
          'id': 2,
          'name': 'Work',
          'currency_code': 'BDT',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        },
      ];
      (table(j, 'loan_payments')[0] as Map)['profile_id'] = 2;
      expectInvalid(j, 'cross-profile');
    });

    test('bad loan values', () async {
      final j = await export();
      final l = table(j, 'loans')[0] as Map;
      l['interest_rate_bp'] = 20000;
      l['frequency'] = 'daily';
      l['tenure_count'] = 0;
      expectInvalid(j, 'interest rate');
    });

    test('loan payment of a missing loan', () async {
      final j = await export();
      (table(j, 'loan_payments')[0] as Map)['loan_id'] = 99;
      expectInvalid(j, 'does not exist');
    });

    test('bad card values', () async {
      final j = await export();
      final c = table(j, 'credit_cards')[0] as Map;
      c['statement_day'] = 31;
      c['last_four'] = '12';
      expectInvalid(j, 'statement day');
    });

    test('duplicate active bill month', () async {
      final j = await export();
      final bills = table(j, 'credit_card_bills');
      final dup = Map<String, dynamic>.from(bills[0] as Map)..['id'] = 2;
      bills.add(dup);
      expectInvalid(j, 'duplicate active bill');
    });

    test('minimum payment above the bill', () async {
      final j = await export();
      (table(j, 'credit_card_bills')[0] as Map)['min_payment_minor'] = 999999;
      expectInvalid(j, 'minimum payment');
    });

    test('card payment of a missing bill', () async {
      final j = await export();
      (table(j, 'credit_card_payments')[0] as Map)['bill_id'] = 42;
      expectInvalid(j, 'does not exist');
    });
  });
}
