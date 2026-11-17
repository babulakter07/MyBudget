import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/domain/backup_models.dart';

const _ts = 1700000000; // unix seconds

Future<void> _sql(
  AppDatabase db,
  String sql, [
  List<Object?> args = const [],
]) => db.customStatement(sql, args);

Future<void> _seed(AppDatabase db) async {
  Future<void> prof(int id, String name, int active) => _sql(
    db,
    'INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (?,?,?,?,?,?)',
    [id, name, 'BDT', active, _ts, _ts],
  );
  await prof(1, 'Home', 1);
  await prof(2, 'Work', 0);

  Future<void> cat(int id, int pid, String name, int active) => _sql(
    db,
    'INSERT INTO categories (id,profile_id,name,description,color,is_active,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?)',
    [
      id,
      pid,
      name,
      id == 1 ? 'Daily food' : null,
      id == 1 ? 123 : null,
      active,
      _ts,
      _ts,
    ],
  );
  await cat(1, 1, 'Food', 1);
  await cat(2, 1, 'Rent', 0); // inactive
  await cat(3, 2, 'Food', 1); // same name, other profile

  await _sql(
    db,
    'INSERT INTO sub_categories (id,profile_id,category_id,name,is_active,created_at,updated_at) VALUES (1,1,1,?,1,?,?)',
    ['Groceries', _ts, _ts],
  );
  await _sql(
    db,
    'INSERT INTO cost_items (id,profile_id,sub_category_id,name,default_amount_minor,is_active,created_at,updated_at) VALUES (1,1,1,?,?,1,?,?)',
    ['Rice', 12050, _ts, _ts],
  );
  await _sql(
    db,
    'INSERT INTO monthly_budgets (id,profile_id,year,month,total_budget_minor,created_at,updated_at) VALUES (1,1,2024,5,10000000,?,?)',
    [_ts, _ts],
  );
  await _sql(
    db,
    'INSERT INTO category_budgets (id,profile_id,monthly_budget_id,category_id,amount_minor,created_at,updated_at) VALUES (1,1,1,1,4000000,?,?)',
    [_ts, _ts],
  );
  Future<void> acc(int id, int pid, String name, String type) => _sql(
    db,
    'INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (?,?,?,?,?,?,1,?,?)',
    [id, pid, name, type, 500000, '2024-01-01', _ts, _ts],
  );
  await acc(1, 1, 'Cash', 'cash');
  await acc(2, 1, 'Bank', 'bank');
  await acc(3, 2, 'Cash', 'cash');

  Future<void> txn(
    int id,
    String type, {
    required int amount,
    int account = 1,
    int? to,
    int? cat,
    int? sub,
    int? cost,
    String? key,
    bool deleted = false,
  }) => _sql(
    db,
    'INSERT INTO financial_transactions (id,profile_id,type,account_id,to_account_id,category_id,sub_category_id,cost_item_id,'
    'account_name_snapshot,amount_minor,txn_date,title,idempotency_key,is_deleted,deleted_at,created_at,updated_at) '
    'VALUES (?,1,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
    [
      id,
      type,
      account,
      to,
      cat,
      sub,
      cost,
      'Cash',
      amount,
      '2024-05-0$id',
      'Txn $id',
      key,
      deleted ? 1 : 0,
      deleted ? _ts : null,
      _ts,
      _ts,
    ],
  );
  await txn(1, 'expense', amount: 5000, cat: 1, sub: 1, cost: 1, key: 'k1');
  await txn(2, 'income', amount: 900000, key: 'k2');
  await txn(3, 'transfer', amount: 70000, to: 2);
  await txn(4, 'expense', amount: 123, cat: 1, deleted: true); // soft-deleted
  await _sql(
    db,
    "INSERT INTO transaction_audit_logs (id,profile_id,transaction_id,action,previous_json,new_json,created_at) VALUES (1,1,1,'create',NULL,'{\"a\":1}',?)",
    [_ts],
  );
  await _sql(
    db,
    "INSERT INTO transaction_audit_logs (id,profile_id,transaction_id,action,previous_json,new_json,created_at) VALUES (2,1,4,'delete','{\"a\":1}',NULL,?)",
    [_ts],
  );
  await _sql(
    db,
    "INSERT INTO application_settings (key,value) VALUES ('theme','dark')",
  );
}

Map<String, dynamic> _tables(String json) =>
    (jsonDecode(json) as Map<String, dynamic>)['tables']
        as Map<String, dynamic>;

Future<void> _wipe(AppDatabase db) async {
  for (final t in [
    'transaction_audit_logs',
    'financial_transactions',
    'category_budgets',
    'monthly_budgets',
    'accounts',
    'cost_items',
    'sub_categories',
    'categories',
    'financial_profiles',
    'application_settings',
  ]) {
    await _sql(db, 'DELETE FROM $t');
  }
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BackupService service;
  var tick = 0;

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('mybudget_backup_test_');
    tick = 0;
    service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
      clock: () => DateTime(2024, 6, 1, 12).add(Duration(seconds: tick++)),
    );
    await _seed(db);
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Map<String, dynamic> mutable(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  List<Map<String, dynamic>> rows(Map<String, dynamic> j, String t) =>
      ((j['tables'] as Map<String, dynamic>)[t] as List)
          .cast<Map<String, dynamic>>();

  group('export', () {
    test('is versioned, includes all rows and integer money', () async {
      final j = mutable(await service.exportJson());
      expect(j['format'], 'mybudget-backup');
      expect(j['version'], 1);
      expect(j['schemaVersion'], AppDatabase.currentSchemaVersion);
      expect(rows(j, 'financial_transactions'), hasLength(4));
      expect(
        rows(j, 'financial_transactions').any((r) => r['is_deleted'] == true),
        isTrue,
      );
      expect(rows(j, 'categories').any((r) => r['is_active'] == false), isTrue);
      expect(rows(j, 'cost_items').single['default_amount_minor'], 12050);
      expect(rows(j, 'financial_transactions')[1]['amount_minor'], isA<int>());
      expect(service.validate(jsonEncode(j)).isValid, isTrue);
    });

    test('excludes transient backup status settings', () async {
      await service.recordStatus(success: true, message: 'ok');
      await service.setFrequency(BackupFrequency.daily);
      final keys = rows(
        mutable(await service.exportJson()),
        'application_settings',
      ).map((r) => r['key']).toSet();
      expect(keys, containsAll(['theme', 'backup.frequency']));
      expect(
        keys.any((k) => (k as String).startsWith('backup.last_')),
        isFalse,
      );
    });
  });

  group('restore', () {
    test(
      'round trip after wipe equals original incl. soft-deleted/inactive',
      () async {
        final original = await service.exportJson();
        await _wipe(db);
        expect(
          rows(mutable(await service.exportJson()), 'financial_profiles'),
          isEmpty,
        );

        final result = await service.restore(original);
        expect(result.counts['financial_transactions'], 4);

        final after = await service.exportJson();
        expect(_tables(after), _tables(original));

        // ids preserved and AUTOINCREMENT continues after the highest id.
        await _sql(
          db,
          "INSERT INTO financial_profiles (name,currency_code,is_active,created_at,updated_at) VALUES ('New','BDT',1,?,?)",
          [_ts, _ts],
        );
        final r = await db
            .customSelect("SELECT id FROM financial_profiles WHERE name='New'")
            .getSingle();
        expect(r.data['id'], 3);
      },
    );

    test('creates a safety backup of the previous data first', () async {
      final before = await service.exportJson();
      await service.restore(before);
      final safety = (await service.listBackups())
          .where((b) => b.kind == BackupKind.safety)
          .toList();
      expect(safety, hasLength(1));
      expect(safety.single.name, startsWith('safety_'));
      expect(_tables(await service.readBackup(safety.single)), _tables(before));
    });

    test(
      'active profile that no longer exists is cleared via callback',
      () async {
        final j = mutable(await service.exportJson());
        // Drop profile 2 and everything that depends on it.
        var cleared = 0;
        await service.restore(
          jsonEncode(j),
          activeProfileId: 99,
          clearActiveProfile: () async => cleared++,
        );
        expect(cleared, 1);
        await service.restore(
          jsonEncode(j),
          activeProfileId: 1,
          clearActiveProfile: () async => cleared++,
        );
        expect(cleared, 1);
      },
    );

    test('failure mid-insert rolls back and keeps old data intact', () async {
      final before = await service.exportJson();
      final j = mutable(before);
      rows(j, 'financial_profiles').first['name'] = 'Renamed in backup';
      rows(j, 'financial_transactions')[0]['amount_minor'] = 777;
      expect(service.validate(jsonEncode(j)).isValid, isTrue);

      // Parents are inserted first, then this fires on the transactions.
      await _sql(
        db,
        'CREATE TRIGGER fail_mid BEFORE INSERT ON financial_transactions '
        "WHEN NEW.amount_minor = 777 BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );

      await expectLater(
        service.restore(jsonEncode(j)),
        throwsA(isA<AppException>()),
      );
      expect(_tables(await service.exportJson()), _tables(before));
    });
  });

  group('validation rejects bad files and changes nothing', () {
    late String base;
    late Map<String, dynamic> tablesBefore;

    setUp(() async {
      base = await service.exportJson();
      tablesBefore = _tables(base);
    });

    Future<void> expectRejected(String json, {String? expectText}) async {
      final v = service.validate(json);
      expect(v.isValid, isFalse);
      if (expectText != null) {
        expect(
          v.errors.join('\n').toLowerCase(),
          contains(expectText.toLowerCase()),
        );
      }
      await expectLater(
        service.restore(json),
        throwsA(isA<ValidationException>()),
      );
      expect(_tables(await service.exportJson()), tablesBefore);
      expect(
        (await service.listBackups()).where((b) => b.kind == BackupKind.safety),
        isEmpty,
        reason: 'no safety backup/restore attempt for an invalid file',
      );
    }

    Future<void> mutateAndReject(
      void Function(Map<String, dynamic> j) mutate,
      String expectText,
    ) async {
      final j = mutable(base);
      mutate(j);
      await expectRejected(jsonEncode(j), expectText: expectText);
    }

    test(
      'invalid JSON',
      () => expectRejected('{not json', expectText: 'valid json'),
    );
    test('not an object', () => expectRejected('[1,2]'));
    test(
      'wrong format',
      () => mutateAndReject((j) => j['format'] = 'other', 'not a mybudget'),
    );
    test(
      'newer version',
      () => mutateAndReject((j) => j['version'] = 2, 'newer version'),
    );
    test(
      'newer schema',
      () => mutateAndReject((j) => j['schemaVersion'] = 99, 'schema'),
    );
    test(
      'missing table',
      () => mutateAndReject(
        (j) => (j['tables'] as Map).remove('accounts'),
        'accounts',
      ),
    );
    test(
      'wrong field type',
      () => mutateAndReject(
        (j) => rows(j, 'accounts').first['name'] = 5,
        'invalid value',
      ),
    );
    test(
      'duplicate ids',
      () => mutateAndReject(
        (j) => rows(j, 'categories')[1]['id'] = 1,
        'duplicate id',
      ),
    );
    test(
      'dangling reference',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[0]['account_id'] = 99,
        'does not exist',
      ),
    );
    test(
      'cross-profile reference',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[0]['category_id'] = 3,
        'different profile',
      ),
    );
    test(
      'zero amount',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[0]['amount_minor'] = 0,
        'greater than zero',
      ),
    );
    test(
      'negative amount',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[1]['amount_minor'] = -5,
        'greater than zero',
      ),
    );
    test(
      'bad date',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[0]['txn_date'] = '2024-13-45',
        'txn_date',
      ),
    );
    test(
      'transfer to same account',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[2]['to_account_id'] = 1,
        'same account',
      ),
    );
    test(
      'transfer without destination',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[2]['to_account_id'] = null,
        'destination',
      ),
    );
    test(
      'income with destination',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[1]['to_account_id'] = 2,
        'only transfers',
      ),
    );
    test(
      'expense without category',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[0]['category_id'] = null,
        'needs a category',
      ),
    );
    test(
      'duplicate category names (case-insensitive)',
      () => mutateAndReject(
        (j) => rows(j, 'categories')[1]['name'] = 'FOOD',
        'duplicate name',
      ),
    );
    test(
      'duplicate account names',
      () => mutateAndReject(
        (j) => rows(j, 'accounts')[1]['name'] = 'cash',
        'duplicate name',
      ),
    );
    test(
      'duplicate budget month',
      () => mutateAndReject((j) {
        final b = Map<String, dynamic>.from(rows(j, 'monthly_budgets').first)
          ..['id'] = 2;
        rows(j, 'monthly_budgets').add(b);
      }, 'more than one budget'),
    );
    test(
      'duplicate idempotency key',
      () => mutateAndReject(
        (j) => rows(j, 'financial_transactions')[1]['idempotency_key'] = 'k1',
        'idempotency',
      ),
    );
    test(
      'audit log for missing transaction',
      () => mutateAndReject(
        (j) => rows(j, 'transaction_audit_logs')[0]['transaction_id'] = 55,
        'does not exist',
      ),
    );
    test(
      'bad account type',
      () => mutateAndReject(
        (j) => rows(j, 'accounts')[0]['type'] = 'crypto',
        'account type',
      ),
    );
  });

  group('backup files and retention', () {
    test('createBackupFile writes valid JSON in the backups dir', () async {
      final info = await service.createBackupFile(kind: BackupKind.manual);
      expect(info.kind, BackupKind.manual);
      expect(info.sizeBytes, greaterThan(100));
      expect(info.name, startsWith('manual_'));
      expect(service.validate(await service.readBackup(info)).isValid, isTrue);
      expect(await service.listBackups(), hasLength(1));
    });

    test('retention prunes oldest automatic backups only', () async {
      for (var i = 0; i < 6; i++) {
        await service.createBackupFile(kind: BackupKind.auto);
      }
      await service.createBackupFile(kind: BackupKind.manual);
      await service.createBackupFile(kind: BackupKind.manual);
      final newestAuto = (await service.listBackups())
          .where((b) => b.kind == BackupKind.auto)
          .map((b) => b.name)
          .take(3)
          .toList();

      await service.setRetention(3);
      final all = await service.listBackups();
      final autos = all.where((b) => b.kind == BackupKind.auto).toList();
      expect(autos.map((b) => b.name).toList(), newestAuto);
      expect(all.where((b) => b.kind == BackupKind.manual), hasLength(2));
    });

    test('default retention is 7 and runAutoBackup applies it', () async {
      expect((await service.loadSettings()).retention, 7);
      for (var i = 0; i < 9; i++) {
        expect(await service.runAutoBackup(), isTrue);
      }
      final autos = (await service.listBackups()).where(
        (b) => b.kind == BackupKind.auto,
      );
      expect(autos, hasLength(7));
      final s = await service.loadSettings();
      expect(s.lastSuccess, isTrue);
      expect(s.lastBackupAt, isNotNull);
    });

    test('retention outside 3..30 is rejected', () async {
      await expectLater(
        service.setRetention(2),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        service.setRetention(31),
        throwsA(isA<ValidationException>()),
      );
      await service.setRetention(30);
      expect((await service.loadSettings()).retention, 30);
    });

    test(
      'only newest safety backups are kept; safety cannot be deleted',
      () async {
        for (var i = 0; i < 7; i++) {
          await service.createBackupFile(kind: BackupKind.safety);
        }
        final safety = (await service.listBackups())
            .where((b) => b.kind == BackupKind.safety)
            .toList();
        expect(safety, hasLength(BackupService.safetyKeep));
        await expectLater(
          service.deleteBackup(safety.first),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('deleteBackup removes a manual file', () async {
      final info = await service.createBackupFile(kind: BackupKind.manual);
      await service.deleteBackup(info);
      expect(await service.listBackups(), isEmpty);
    });

    test('runAutoBackup records failure instead of throwing', () async {
      final blocked = File('${dir.path}/blocker')..writeAsStringSync('x');
      final bad = BackupService(db, backupsDirectory: Directory(blocked.path));
      expect(await bad.runAutoBackup(), isFalse);
      final s = await bad.loadSettings();
      expect(s.lastSuccess, isFalse);
      expect(s.lastMessage, isNotEmpty);
    });
  });

  group('settings', () {
    test('defaults then persistence across service instances', () async {
      final d = await service.loadSettings();
      expect(d.frequency, BackupFrequency.off);
      expect(d.retention, 7);
      expect(d.lastSuccess, isNull);

      await service.setFrequency(BackupFrequency.weekly);
      await service.setRetention(12);
      await service.recordStatus(success: false, message: 'disk full');

      final again = BackupService(
        db,
        backupsDirectory: service.backupsDirectory,
      );
      final s = await again.loadSettings();
      expect(s.frequency, BackupFrequency.weekly);
      expect(s.retention, 12);
      expect(s.lastSuccess, isFalse);
      expect(s.lastMessage, 'disk full');
      expect(s.lastBackupAt, isNotNull);
    });

    test(
      'restore keeps the transient last-status keys of this device',
      () async {
        await service.recordStatus(success: true, message: 'kept');
        final json = await service.exportJson();
        await service.restore(json);
        final s = await service.loadSettings();
        expect(s.lastMessage, 'kept');
        expect(s.lastSuccess, isTrue);
      },
    );
  });
}
