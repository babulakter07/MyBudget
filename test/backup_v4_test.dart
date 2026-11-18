import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/core/storage/app_paths.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_paths.dart';
import 'package:my_budget/features/backup/data/backup_schema.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/domain/backup_models.dart';

const _ts = 1700000000;

Future<void> _sql(
  AppDatabase db,
  String sql, [
  List<Object?> args = const [],
]) => db.customStatement(sql, args);

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
    "INSERT INTO sub_categories (id,profile_id,category_id,name,is_active,created_at,updated_at) VALUES (1,1,1,'Groceries',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO cost_items (id,profile_id,sub_category_id,name,is_favorite,is_active,created_at,updated_at) VALUES (1,1,1,'Rice',1,1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    'INSERT INTO monthly_budgets (id,profile_id,year,month,total_budget_minor,created_at,updated_at) VALUES (1,1,2024,5,1000000,?,?)',
    [_ts, _ts],
  );
  await _sql(
    db,
    'INSERT INTO category_budgets (id,profile_id,monthly_budget_id,category_id,amount_minor,rollover_enabled,created_at,updated_at) VALUES (1,1,1,1,400000,1,?,?)',
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (1,1,'Cash','cash',500000,'2024-01-01',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (2,1,'Bank','bank',0,'2024-01-01',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO financial_transactions (id,profile_id,type,account_id,category_id,account_name_snapshot,category_name_snapshot,amount_minor,txn_date,title,created_at,updated_at) VALUES (1,1,'expense',1,1,'Cash','Food',5000,'2024-05-01','Rice',?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO recurring_rules (id,profile_id,type,account_id,category_id,amount_minor,title,frequency,interval_count,start_date,next_due_date,remind_days_before,is_active,created_at,updated_at) VALUES (1,1,'expense',1,1,10000,'Rent','monthly',1,'2024-01-01','2024-06-01',2,1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO savings_goals (id,profile_id,name,account_id,target_minor,is_active,created_at,updated_at) VALUES (1,1,'Bike',2,900000,1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO debts (id,profile_id,direction,person_name,principal_minor,start_date,is_active,created_at,updated_at) VALUES (1,1,'lent','Rahim',20000,'2024-02-01',1,?,?)",
    [_ts, _ts],
  );
  await _sql(
    db,
    "INSERT INTO debt_payments (id,profile_id,debt_id,amount_minor,payment_date,is_deleted,created_at) VALUES (1,1,1,5000,'2024-03-01',0,?)",
    [_ts],
  );
  await _sql(
    db,
    "INSERT INTO tags (id,profile_id,name,is_active,created_at) VALUES (1,1,'Eid',1,?)",
    [_ts],
  );
  await _sql(
    db,
    'INSERT INTO transaction_tags (profile_id,transaction_id,tag_id) VALUES (1,1,1)',
  );
  await _sql(
    db,
    "INSERT INTO transaction_attachments (id,profile_id,transaction_id,relative_path,mime_type,size_bytes,is_deleted,created_at) VALUES (1,1,1,'2024/r1.jpg','image/jpeg',4,0,?)",
    [_ts],
  );
  await _sql(
    db,
    "INSERT INTO transaction_attachments (id,profile_id,transaction_id,relative_path,mime_type,size_bytes,is_deleted,created_at) VALUES (2,1,1,'gone.jpg','image/jpeg',4,0,?)",
    [_ts],
  );
}

Future<void> _wipe(AppDatabase db) async {
  for (final spec in backupTables.reversed) {
    await _sql(db, 'DELETE FROM "${spec.name}"');
  }
}

Map<String, dynamic> _tables(String json) =>
    (jsonDecode(json) as Map<String, dynamic>)['tables']
        as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late Directory dir;
  late Directory attach;
  late BackupService service;
  final photo = [1, 2, 3, 250];

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('mybudget_backup_v4_');
    attach = Directory('${dir.path}/attachments')..createSync();
    attachmentsDirectoryOverride = attach;
    service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
      crypto: const BackupCrypto(iterations: 1000),
    );
    await _seed(db);
    Directory('${attach.path}/2024').createSync();
    File('${attach.path}/2024/r1.jpg').writeAsBytesSync(photo);
  });

  tearDown(() async {
    attachmentsDirectoryOverride = null;
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('v4 data', () {
    test('export contains v4 tables and columns; validates', () async {
      final json = await service.exportJson();
      final t = _tables(json);
      for (final n in [
        'recurring_rules',
        'savings_goals',
        'debts',
        'debt_payments',
        'tags',
        'transaction_tags',
        'transaction_attachments',
      ]) {
        expect(t[n], isNotEmpty, reason: n);
      }
      expect((t['cost_items'] as List).single['is_favorite'], true);
      expect((t['category_budgets'] as List).single['rollover_enabled'], true);
      expect(service.validate(json).isValid, isTrue);
    });

    test('round trip with photos restores rows and files', () async {
      final export = await service.exportBackup(includePhotos: true);
      expect(export.photosEmbedded, 1);
      expect(export.photosMissing, 1);
      expect(export.photoBytes, 4);
      await _wipe(db);
      File('${attach.path}/2024/r1.jpg').deleteSync();

      final res = await service.restore(export.json);
      expect(res.photosRestored, 1);
      expect(res.photosFailed, 0);
      expect(File('${attach.path}/2024/r1.jpg').readAsBytesSync(), photo);
      expect(_tables(await service.exportJson()), _tables(export.json));
      final fav = await db
          .customSelect('SELECT is_favorite f FROM cost_items')
          .getSingle();
      expect(fav.data['f'], 1);
    });

    test('photos omitted when not requested', () async {
      final export = await service.exportBackup(includePhotos: false);
      expect(jsonDecode(export.json).containsKey('attachmentFiles'), isFalse);
      expect(export.photosEmbedded, 0);
    });

    test('estimatePhotos counts existing and missing', () async {
      final e = await service.estimatePhotos();
      expect(e.count, 1);
      expect(e.bytes, 4);
      expect(e.missing, 1);
    });

    test('old format (v1, schema 3, no v4 tables/columns) restores', () async {
      final j = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
      j['version'] = 1;
      j['schemaVersion'] = 3;
      final t = j['tables'] as Map<String, dynamic>;
      for (final n in [
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
      for (final r in (t['cost_items'] as List)) {
        (r as Map).remove('is_favorite');
      }
      for (final r in (t['category_budgets'] as List)) {
        (r as Map).remove('rollover_enabled');
      }
      final old = jsonEncode(j);
      expect(service.validate(old).isValid, isTrue);

      await service.restore(old);
      expect((await db.customSelect('SELECT * FROM debts').get()), isEmpty);
      final fav = await db
          .customSelect('SELECT is_favorite f FROM cost_items')
          .getSingle();
      expect(fav.data['f'], 0);
      final roll = await db
          .customSelect('SELECT rollover_enabled r FROM category_budgets')
          .getSingle();
      expect(roll.data['r'], 0);
      expect(
        await db.customSelect('SELECT * FROM financial_transactions').get(),
        hasLength(1),
      );
    });

    test('newer schema is rejected', () async {
      final j = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
      j['schemaVersion'] = 6;
      expect(service.validate(jsonEncode(j)).isValid, isFalse);
    });
  });

  group('path traversal and safety', () {
    test('isSafeRelativePath', () {
      expect(isSafeRelativePath('a/b.jpg'), isTrue);
      expect(isSafeRelativePath('a.jpg'), isTrue);
      for (final bad in [
        '',
        '../x.jpg',
        'a/../../x',
        '/etc/passwd',
        r'..\x',
        r'a\b.jpg',
        'C:/x.jpg',
        'a//b',
        './a',
        'a/./b',
      ]) {
        expect(isSafeRelativePath(bad), isFalse, reason: bad);
      }
    });

    Future<void> expectRejectedUntouched(Map<String, dynamic> j) async {
      final before = _tables(await service.exportJson());
      await expectLater(
        service.restore(jsonEncode(j)),
        throwsA(isA<ValidationException>()),
      );
      expect(_tables(await service.exportJson()), before);
      expect(File('${dir.path}/evil.jpg').existsSync(), isFalse);
      expect(
        (await service.listBackups()).where((b) => b.kind == BackupKind.safety),
        isEmpty,
      );
    }

    test('traversal in transaction_attachments.relative_path', () async {
      final j = jsonDecode(
        (await service.exportBackup(includePhotos: true)).json,
      ) as Map<String, dynamic>;
      ((j['tables'] as Map)['transaction_attachments']
              as List)[0]['relative_path'] =
          '../evil.jpg';
      await expectRejectedUntouched(j);
    });

    test('traversal in embedded attachmentFiles key', () async {
      final j = jsonDecode(
        (await service.exportBackup(includePhotos: true)).json,
      ) as Map<String, dynamic>;
      (j['attachmentFiles'] as Map)['../evil.jpg'] = base64Encode([9, 9]);
      await expectRejectedUntouched(j);
    });

    test('invalid base64 photo is rejected', () async {
      final j = jsonDecode(
        (await service.exportBackup(includePhotos: true)).json,
      ) as Map<String, dynamic>;
      (j['attachmentFiles'] as Map)['2024/r1.jpg'] = '***not base64***';
      await expectRejectedUntouched(j);
    });

    test('cross-profile tag link is rejected', () async {
      await _sql(
        db,
        "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (2,'Work','BDT',1,?,?)",
        [_ts, _ts],
      );
      await _sql(
        db,
        "INSERT INTO tags (id,profile_id,name,is_active,created_at) VALUES (2,2,'Other',1,?)",
        [_ts],
      );
      final j = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
      ((j['tables'] as Map)['transaction_tags'] as List)[0]['tag_id'] = 2;
      await expectRejectedUntouched(j);
    });

    test('failure mid-restore leaves DB and photo files untouched', () async {
      final export = await service.exportBackup(includePhotos: true);
      final j = jsonDecode(export.json) as Map<String, dynamic>;
      ((j['tables'] as Map)['debts'] as List)[0]['principal_minor'] = 777;
      ((j['attachmentFiles'] as Map))['2024/new.jpg'] = base64Encode([7]);
      final before = await service.exportJson();
      await _sql(
        db,
        'CREATE TRIGGER fail_mid BEFORE INSERT ON debts '
        "WHEN NEW.principal_minor = 777 BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(
        service.restore(jsonEncode(j)),
        throwsA(isA<AppException>()),
      );
      expect(_tables(await service.exportJson()), _tables(before));
      expect(File('${attach.path}/2024/new.jpg').existsSync(), isFalse);
    });
  });

  group('encryption', () {
    test('encrypted round trip (low iterations injected)', () async {
      final info = await service.createBackupFile(
        kind: BackupKind.manual,
        password: 'secret1',
      );
      final text = await service.readBackup(info);
      expect(BackupCrypto.isEncrypted(text), isTrue);
      final env = jsonDecode(text) as Map<String, dynamic>;
      expect(env['magic'], 'MYBUDGET-ENC');
      expect((env['kdf'] as Map)['iterations'], 1000);
      expect(text.contains('Rahim'), isFalse, reason: 'must not leak data');
      expect(service.validate(text).isValid, isFalse);

      final before = _tables(await service.exportJson());
      await _wipe(db);
      File('${attach.path}/2024/r1.jpg').deleteSync();
      final res = await service.restore(text, password: 'secret1');
      expect(res.photosRestored, 1);
      expect(_tables(await service.exportJson()), before);
    });

    test('encrypted file without password asks for one', () async {
      final text = await service.encryptJson(
        await service.exportJson(),
        'secret1',
      );
      await expectLater(
        service.restore(text),
        throwsA(isA<BackupPasswordRequired>()),
      );
    });

    test('wrong password: clear ValidationException, DB untouched', () async {
      final text = await service.encryptJson(
        await service.exportJson(),
        'secret1',
      );
      final before = _tables(await service.exportJson());
      await expectLater(
        service.restore(text, password: 'wrong-one'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Wrong password'),
          ),
        ),
      );
      expect(_tables(await service.exportJson()), before);
    });

    test('tampering with ciphertext or header is detected', () async {
      final text = await service.encryptJson(
        await service.exportJson(),
        'secret1',
      );
      final before = _tables(await service.exportJson());

      final env = jsonDecode(text) as Map<String, dynamic>;
      final ct = base64Decode(env['ciphertext'] as String);
      ct[ct.length ~/ 2] ^= 0x01;
      final t1 = Map<String, dynamic>.from(env)
        ..['ciphertext'] = base64Encode(ct);

      final t2 = Map<String, dynamic>.from(env)
        ..['kdf'] = {'name': 'PBKDF2-HMAC-SHA256', 'iterations': 1001};

      final t3 = Map<String, dynamic>.from(env)..['nonce'] = 'AAAA';
      final t4 = Map<String, dynamic>.from(env)..['salt'] = '%%%';
      final t5 = Map<String, dynamic>.from(env)
        ..['kdf'] = {'name': 'PBKDF2-HMAC-SHA256', 'iterations': 999999999};

      for (final t in [t1, t2, t3, t4, t5]) {
        await expectLater(
          service.restore(jsonEncode(t), password: 'secret1'),
          throwsA(isA<ValidationException>()),
        );
      }
      expect(_tables(await service.exportJson()), before);
    });

    test('password shorter than 6 is rejected on export', () async {
      await expectLater(
        service.createBackupFile(kind: BackupKind.manual, password: '12345'),
        throwsA(isA<ValidationException>()),
      );
      expect(await service.listBackups(), isEmpty);
    });

    test('auto backups stay plain', () async {
      final info = await service.createBackupFile(kind: BackupKind.auto);
      expect(BackupCrypto.isEncrypted(await service.readBackup(info)), isFalse);
    });

    test('default iteration count is at least 210000', () {
      expect(const BackupCrypto().iterations, greaterThanOrEqualTo(210000));
    });
  });
}
