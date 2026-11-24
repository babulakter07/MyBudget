import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/domain/backup_models.dart';

const _ts = 1700000000;

Future<void> _sql(AppDatabase db, String sql, [List<Object?> a = const []]) =>
    db.customStatement(sql, a);

Future<void> _seed(AppDatabase db) async {
  await _sql(
    db,
    "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (1,'Home','BDT',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO categories (id,profile_id,name,is_active,created_at,updated_at) VALUES (1,1,'Food',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (1,1,'Cash','cash',0,'2024-01-01',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (2,1,'Bank','bank',0,'2024-01-01',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO exchange_rates (id,profile_id,currency_code,rate_micro,is_active,created_at,updated_at) VALUES (1,1,'USD',122500000,1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO exchange_rates (id,profile_id,currency_code,rate_micro,is_active,created_at,updated_at) VALUES (2,1,'EUR',133333333,0,?,?)",
    [_ts, _ts],
  );
  const cols =
      'profile_id,type,account_id,to_account_id,category_id,account_name_snapshot,amount_minor,original_amount_minor,original_currency,rate_micro,txn_date,idempotency_key,is_deleted,created_at,updated_at';
  // 2000 USD cents * 122.5 = 245000 minor
  await _sql(
    db,
    "INSERT INTO financial_transactions (id,$cols) VALUES (1,1,'expense',1,NULL,1,'Cash',245000,2000,'USD',122500000,'2024-05-01','k1',0,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO financial_transactions (id,$cols) VALUES (2,1,'income',1,NULL,NULL,'Cash',?,3333,'EUR',133333333,'2024-05-02','k2',0,?,?)",
    [(3333 * 133333333 + 500000) ~/ 1000000, _ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO financial_transactions (id,$cols) VALUES (3,1,'expense',1,NULL,1,'Cash',500,NULL,NULL,NULL,'2024-05-03','k3',0,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO financial_transactions (id,$cols) VALUES (4,1,'transfer',1,2,NULL,'Cash',700,NULL,NULL,NULL,'2024-05-04','k4',0,?,?)",
    [_ts, _ts],
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
    dir = Directory.systemTemp.createTempSync('mybudget_backup_v5_');
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
  List txns(Map<String, dynamic> j) =>
      (j['tables'] as Map)['financial_transactions'] as List;
  List rates(Map<String, dynamic> j) =>
      (j['tables'] as Map)['exchange_rates'] as List;

  void expectInvalid(Map<String, dynamic> j, String text) {
    final r = service.validate(jsonEncode(j));
    expect(r.isValid, isFalse);
    expect(r.errors.join('\n'), contains(text));
  }

  group('multi-currency backup', () {
    test('versions', () {
      expect(backupFormatVersion, 5);
    });

    test('export carries rates and original_* columns', () async {
      final j = await export();
      expect(j['version'], 5);
      expect(j['schemaVersion'], 7);
      expect(rates(j), hasLength(2));
      expect(txns(j)[0]['original_currency'], 'USD');
      expect(txns(j)[2]['original_currency'], isNull);
      expect(service.validate(jsonEncode(j)).isValid, isTrue);
    });

    test('round trip restores identical data', () async {
      final text = await service.exportJson();
      const tx = 'SELECT * FROM financial_transactions ORDER BY id';
      const er = 'SELECT * FROM exchange_rates ORDER BY id';
      final beforeT = await _dump(db, tx);
      final beforeR = await _dump(db, er);
      await _sql(db, 'DELETE FROM financial_transactions');
      await _sql(db, 'DELETE FROM exchange_rates');
      await service.restore(text);
      expect(await _dump(db, tx), beforeT);
      expect(await _dump(db, er), beforeR);
    });

    test(
      'format v2 file (no rates, no original_*) restores with NULLs',
      () async {
        final j = await export();
        j['version'] = 2;
        j['schemaVersion'] = 4;
        (j['tables'] as Map).remove('exchange_rates');
        for (final r in txns(j)) {
          (r as Map)
            ..remove('original_amount_minor')
            ..remove('original_currency')
            ..remove('rate_micro');
        }
        final text = jsonEncode(j);
        expect(service.validate(text).isValid, isTrue);
        await service.restore(text);
        expect(await _dump(db, 'SELECT * FROM exchange_rates'), isEmpty);
        final t = await _dump(
          db,
          'SELECT original_amount_minor o, original_currency c, rate_micro r FROM financial_transactions',
        );
        expect(t, hasLength(4));
        for (final r in t) {
          expect(r['o'], isNull);
          expect(r['c'], isNull);
          expect(r['r'], isNull);
        }
      },
    );

    test('format v1 file restores', () async {
      final j = await export();
      j['version'] = 1;
      j['schemaVersion'] = 3;
      final t = j['tables'] as Map;
      for (final n in [
        'exchange_rates',
        'recurring_rules',
        'savings_goals',
        'debts',
        'debt_payments',
        'tags',
        'transaction_tags',
        'transaction_attachments',
      ]) {
        t.remove(n);
      }
      for (final r in txns(j)) {
        (r as Map)
          ..remove('original_amount_minor')
          ..remove('original_currency')
          ..remove('rate_micro');
      }
      for (final r in (t['cost_items'] as List)) {
        (r as Map).remove('is_favorite');
      }
      for (final r in (t['category_budgets'] as List)) {
        (r as Map).remove('rollover_enabled');
      }
      await service.restore(jsonEncode(j));
      expect(await _dump(db, 'SELECT * FROM exchange_rates'), isEmpty);
      expect(
        await _dump(db, 'SELECT * FROM financial_transactions'),
        hasLength(4),
      );
    });

    test('version 6 is rejected as newer', () async {
      final j = await export();
      j['version'] = 6;
      expectInvalid(j, 'newer version');
    });

    test('schema 8 is rejected', () async {
      final j = await export();
      j['schemaVersion'] = 8;
      expectInvalid(j, 'schema');
    });

    test('partial original fields rejected', () async {
      for (final k in [
        'original_amount_minor',
        'original_currency',
        'rate_micro',
      ]) {
        final j = await export();
        txns(j)[0][k] = null;
        expectInvalid(j, 'all be set or all be empty');
      }
      final j = await export();
      txns(j)[2]['rate_micro'] = 1000000;
      expectInvalid(j, 'all be set or all be empty');
    });

    test('transfer with original rejected', () async {
      final j = await export();
      txns(j)[3]
        ..['original_amount_minor'] = 700
        ..['original_currency'] = 'USD'
        ..['rate_micro'] = 1000000;
      expectInvalid(j, 'only expense and income');
    });

    test('wrong converted amount rejected', () async {
      final j = await export();
      txns(j)[0]['amount_minor'] = 245001;
      expectInvalid(j, 'does not match the converted');
    });

    test('rounding is half up', () async {
      final j = await export();
      txns(j)[0]
        ..['original_amount_minor'] = 1
        ..['rate_micro'] = 500000
        ..['amount_minor'] = 1;
      expect(service.validate(jsonEncode(j)).isValid, isTrue);
      txns(j)[0]['amount_minor'] = 0;
      expect(service.validate(jsonEncode(j)).isValid, isFalse);
    });

    test('base-currency original rejected', () async {
      final j = await export();
      txns(j)[0]['original_currency'] = 'BDT';
      expectInvalid(j, 'differ from the profile currency');
    });

    test('bad currency code rejected', () async {
      for (final bad in ['usd', 'US', 'USDX', 'U1D']) {
        final j = await export();
        txns(j)[0]['original_currency'] = bad;
        expectInvalid(j, '3 upper-case letters');
      }
    });

    test('non-positive original amount / rate rejected', () async {
      var j = await export();
      txns(j)[0]['original_amount_minor'] = 0;
      expectInvalid(j, 'original_amount_minor must be greater than zero');
      j = await export();
      txns(j)[0]['rate_micro'] = -5;
      expectInvalid(j, 'rate_micro must be greater than zero');
    });

    test('exchange_rates validation', () async {
      var j = await export();
      rates(j)[0]['currency_code'] = 'us';
      expectInvalid(j, 'exchange_rates id 1');

      j = await export();
      rates(j)[0]['rate_micro'] = 0;
      expectInvalid(j, 'rate must be greater than zero');

      j = await export();
      rates(j)[1]['currency_code'] = 'USD';
      expectInvalid(j, 'duplicate rate');

      j = await export();
      rates(j)[0]['profile_id'] = 99;
      expectInvalid(j, 'does not exist');

      j = await export();
      rates(j)[0]['is_active'] = 1;
      expectInvalid(j, 'is_active');
    });

    test('same code allowed in different profiles', () async {
      await _sql(
        db,
        "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (2,'Work','BDT',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO exchange_rates (id,profile_id,currency_code,rate_micro,is_active,created_at,updated_at) VALUES (3,2,'USD',120000000,1,?,?)",
        [_ts, _ts],
      );
      final j = await export();
      expect(service.validate(jsonEncode(j)).isValid, isTrue);
    });

    test('encrypted round trip keeps multi-currency data', () async {
      final enc = await service.encryptJson(
        await service.exportJson(),
        'secret1',
      );
      await _sql(db, 'DELETE FROM financial_transactions');
      await _sql(db, 'DELETE FROM exchange_rates');
      await service.restore(enc, password: 'secret1');
      final t = await _dump(
        db,
        'SELECT original_currency c FROM financial_transactions WHERE original_currency IS NOT NULL',
      );
      expect(t, hasLength(2));
      expect(await _dump(db, 'SELECT * FROM exchange_rates'), hasLength(2));
    });
  });
}
