import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';

const _ts = 1700000000;

Future<void> _sql(AppDatabase db, String sql) => db.customStatement(sql);

Future<List<Map<String, Object?>>> _rows(AppDatabase db, String q) async =>
    (await db.customSelect(q).get()).map((r) => r.data).toList();

/// A v6 database reduced to what the v7 step needs (a profile row).
AppDatabase _openV6() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
CREATE TABLE financial_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'BDT',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        raw.execute(
          "INSERT INTO financial_profiles VALUES (1,'Home','BDT',1,$_ts,$_ts)",
        );
        // The v7 step adds columns to the v6 loans table.
        raw.execute('''
CREATE TABLE loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  lender_name TEXT NOT NULL,
  principal_minor INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        raw.execute('PRAGMA user_version = 6');
      },
    ),
  );
}

const _deposit =
    "INSERT INTO fixed_deposits (id,profile_id,scheme_type,bank_name,beneficiary_name,is_active,created_at,updated_at) "
    "VALUES (1,1,'FDR','City Bank','Babul',1,$_ts,$_ts)";

String _term(
  int id,
  int no, {
  String outcome = 'active',
  String? settled,
  int? from,
  String number = '',
  String start = '2026-01-15',
}) {
  final closed = outcome != 'active';
  return 'INSERT INTO fixed_deposit_terms (id,profile_id,deposit_id,term_no,instrument_number,start_date,tenure_days,rate_bp,principal_minor,outcome,settled_date,interest_minor,tax_minor,bank_charge_minor,net_received_minor,renewed_from_term_id,created_at,updated_at) '
      "VALUES ($id,1,1,$no,'${number.isEmpty ? 'FDR-$id' : number}','$start',365,1000,100000000,'$outcome',${settled == null ? 'NULL' : "'$settled'"},${closed ? 10000000 : 'NULL'},${closed ? 1000000 : 'NULL'},${closed ? 0 : 'NULL'},${closed ? 109000000 : 'NULL'},${from ?? 'NULL'},$_ts,$_ts)";
}

void main() {
  group('migration v6 -> v7', () {
    test('creates the fixed deposit tables and keeps data', () async {
      final db = _openV6();
      addTearDown(db.close);
      expect(await _rows(db, 'SELECT name FROM financial_profiles'), [
        {'name': 'Home'},
      ]);
      final tables = (await _rows(
        db,
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((r) => r['name']).toSet();
      expect(tables, containsAll(['fixed_deposits', 'fixed_deposit_terms']));
      final indexes = (await _rows(
        db,
        "SELECT name FROM sqlite_master WHERE type='index'",
      )).map((r) => r['name']).toSet();
      expect(
        indexes,
        containsAll(['idx_fd_terms_deposit', 'uq_fd_terms_instrument']),
      );

      await _sql(db, _deposit);
      await _sql(db, _term(1, 1));
      expect(await _rows(db, 'SELECT COUNT(*) AS c FROM fixed_deposit_terms'), [
        {'c': 1},
      ]);
    });

    test('constraints are enforced', () async {
      final db = _openV6();
      addTearDown(db.close);
      await _sql(db, _deposit);
      await _sql(db, _term(1, 1));
      // duplicate (deposit, term_no)
      await expectLater(_sql(db, _term(2, 1)), throwsA(anything));
      // duplicate instrument number (case-insensitive)
      await expectLater(
        _sql(db, _term(5, 2, number: 'fdr-1')),
        throwsA(anything),
      );
      // unknown deposit
      await expectLater(
        _sql(db, _term(3, 2).replaceFirst('(3,1,1,', '(3,1,99,')),
        throwsA(anything),
      );
      // bad outcome
      await expectLater(
        _sql(db, _term(4, 3, outcome: 'paid', settled: '2027-01-15')),
        throwsA(anything),
      );
    });
  });

  group('backup', () {
    late AppDatabase db;
    late Directory dir;
    late BackupService service;

    setUp(() async {
      db = AppDatabase.memory();
      dir = Directory.systemTemp.createTempSync('mybudget_backup_v7_');
      service = BackupService(
        db,
        backupsDirectory: Directory('${dir.path}/backups'),
        crypto: const BackupCrypto(iterations: 1000),
      );
      await _sql(
        db,
        "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (1,'Home','BDT',1,$_ts,$_ts)",
      );
      await _sql(db, _deposit);
      await _sql(db, _term(1, 1, outcome: 'reissued', settled: '2027-01-15'));
      await _sql(db, _term(2, 2, from: 1, start: '2027-01-15'));
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

    test('export carries the deposit chain', () async {
      final j = await export();
      expect(j['schemaVersion'], 7);
      expect(table(j, 'fixed_deposits'), hasLength(1));
      expect(table(j, 'fixed_deposit_terms'), hasLength(2));
      expect(service.validate(jsonEncode(j)).isValid, isTrue);
    });

    test('round trip restores identical data', () async {
      final text = await service.exportJson();
      const queries = [
        'SELECT * FROM fixed_deposits ORDER BY id',
        'SELECT * FROM fixed_deposit_terms ORDER BY id',
      ];
      final before = [for (final q in queries) await _rows(db, q)];
      await _sql(db, 'DELETE FROM fixed_deposit_terms');
      await _sql(db, 'DELETE FROM fixed_deposits');
      await service.restore(text);
      final after = [for (final q in queries) await _rows(db, q)];
      expect(after, before);
    });

    test('older file without the v7 tables restores as empty', () async {
      final j = await export();
      j['version'] = 4;
      j['schemaVersion'] = 6;
      final t = j['tables'] as Map;
      t.remove('fixed_deposits');
      t.remove('fixed_deposit_terms');
      final text = jsonEncode(j);
      expect(service.validate(text).isValid, isTrue);
      await service.restore(text);
      expect(await _rows(db, 'SELECT * FROM fixed_deposits'), isEmpty);
    });

    group('validator rejects', () {
      test('term of a missing deposit', () async {
        final j = await export();
        (table(j, 'fixed_deposit_terms')[0] as Map)['deposit_id'] = 9;
        expectInvalid(j, 'does not exist');
      });

      test('bad term values', () async {
        final j = await export();
        final t = table(j, 'fixed_deposit_terms')[1] as Map;
        t['rate_bp'] = 20000;
        t['outcome'] = 'paid';
        expectInvalid(j, 'rate');
      });

      test('two running terms', () async {
        final j = await export();
        final t = table(j, 'fixed_deposit_terms')[0] as Map;
        t['outcome'] = 'active';
        t['settled_date'] = null;
        expectInvalid(j, 'more than one running instrument');
      });

      test('duplicate instrument number', () async {
        final j = await export();
        (table(j, 'fixed_deposit_terms')[1] as Map)['instrument_number'] =
            'fdr-1';
        expectInvalid(j, 'duplicate instrument number');
      });

      test('settled term without a date', () async {
        final j = await export();
        (table(j, 'fixed_deposit_terms')[0] as Map)['settled_date'] = null;
        expectInvalid(j, 'settled_date');
      });
    });
  });
}
