import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_folder_gateway.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/data/folder_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements BackupFolderGateway {
  final folders = <String, Map<String, String>>{};
  final released = <String>[];
  String? secret;
  bool failWrites = false;

  Map<String, String> files(String uri) => folders.putIfAbsent(uri, () => {});

  @override
  Future<PickedFolder?> pickFolder() async => null;

  @override
  Future<List<String>> listFiles(String folderUri) async =>
      files(folderUri).keys.toList();

  @override
  Future<void> writeFile(String uri, String name, String sourcePath) async {
    if (failWrites) throw const FileSystemException('disk full');
    files(uri)[name] = await File(sourcePath).readAsString();
  }

  @override
  Future<void> deleteFile(String folderUri, String name) async =>
      files(folderUri).remove(name);

  @override
  Future<void> releaseFolder(String folderUri) async => released.add(folderUri);

  @override
  Future<void> saveSecret(String value) async => secret = value;

  @override
  Future<String?> readSecret() async => secret;

  @override
  Future<void> clearSecret() async => secret = null;
}

void main() {
  const folder = PickedFolder(uri: 'tree://a', name: 'Documents/MyBudget');
  const password = 'secret-123';

  late AppDatabase db;
  late Directory dir;
  late BackupService backups;
  late _FakeGateway gateway;
  late SharedPreferences prefs;
  late FolderBackupService service;
  var now = DateTime(2026, 11, 1, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('mybudget_folder_');
    backups = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
      attachmentsDir: () async => Directory('${dir.path}/attachments'),
      crypto: const BackupCrypto(iterations: 10),
    );
    gateway = _FakeGateway();
    now = DateTime(2026, 11, 1, 9);
    service = FolderBackupService(
      backups: backups,
      gateway: gateway,
      prefs: prefs,
      tempDirectory: () async => dir,
      clock: () => now,
      random: Random(1),
    );
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  var accounts = 0;
  Future<void> addAccount() async {
    final profile =
        (await db.select(db.financialProfiles).get()).firstOrNull?.id ??
        await db
            .into(db.financialProfiles)
            .insert(
              FinancialProfilesCompanion.insert(
                name: 'Home',
                createdAt: now,
                updatedAt: now,
              ),
            );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: profile,
            name: 'Cash ${accounts++}',
            type: const Value('cash'),
            createdAt: now,
            updatedAt: now,
            openingDate: '2026-11-01',
            openingBalanceMinor: const Value(100),
          ),
        );
  }

  Future<FolderSyncResult> enable() =>
      service.enable(folder: folder, password: password, includePhotos: false);

  Iterable<String> names() => gateway.files(folder.uri).keys;

  test('does nothing while the feature is off', () async {
    await addAccount();
    expect(await service.sync(), FolderSyncResult.disabled);
    expect(gateway.folders, isEmpty);
  });

  test('rejects a short password and stays off', () async {
    expect(
      () => service.enable(folder: folder, password: '1', includePhotos: false),
      throwsA(isA<ValidationException>()),
    );
    expect(service.config, isNull);
    expect(gateway.secret, isNull);
  });

  test('an empty app writes nothing into the folder', () async {
    gateway.files(folder.uri)['mybudget_ffffffff_20261001_090000000.json'] =
        'older install';
    expect(await enable(), FolderSyncResult.nothingToSave);
    expect(names(), ['mybudget_ffffffff_20261001_090000000.json']);
  });

  test('writes an encrypted copy that restores with the password', () async {
    await addAccount();
    expect(await enable(), FolderSyncResult.saved);

    final text = gateway.files(folder.uri).values.single;
    expect(BackupCrypto.isEncrypted(text), isTrue);
    expect(text, isNot(contains('Cash')));
    final plain = await backups.decryptIfNeeded(text, password: password);
    expect(backups.validate(plain).isValid, isTrue);
    expect(plain, contains('Cash'));
    expect(service.config!.lastCopyAt, now);
    expect(service.config!.lastError, isNull);
    // The temporary file is removed.
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('skips unchanged data but writes again after a change', () async {
    await addAccount();
    await enable();
    now = now.add(const Duration(hours: 1));
    expect(await service.sync(), FolderSyncResult.unchanged);

    // A recorded auto-backup run is not a data change.
    await backups.recordStatus(success: true, message: 'x');
    expect(await service.sync(), FolderSyncResult.unchanged);

    await addAccount();
    expect(await service.sync(), FolderSyncResult.saved);
  });

  test('rewrites the copy if it was removed from the folder', () async {
    await addAccount();
    await enable();
    gateway.files(folder.uri).clear();
    expect(await service.sync(), FolderSyncResult.saved);
    expect(names(), hasLength(1));
  });

  test('keeps one copy per day for the newest days only', () async {
    await backups.setRetention(3);
    await addAccount();
    await enable();
    for (var day = 2; day <= 6; day++) {
      for (var hour = 9; hour <= 10; hour++) {
        now = DateTime(2026, 11, day, hour);
        await addAccount();
        expect(await service.sync(), FolderSyncResult.saved);
      }
    }
    expect(
      names().map((n) => n.split('_').sublist(2).join('_')).toList()..sort(),
      [
        '20261104_100000000.json',
        '20261105_100000000.json',
        '20261106_100000000.json',
      ],
    );
  });

  test("never deletes another install's or the user's files", () async {
    await backups.setRetention(3);
    const others = [
      'mybudget_ffffffff_20200101_090000000.json',
      'holiday.jpg',
      'manual_20261101_090000_000.json',
    ];
    for (final name in others) {
      gateway.files(folder.uri)[name] = 'keep';
    }
    await addAccount();
    await enable();
    for (var day = 2; day <= 8; day++) {
      now = DateTime(2026, 11, day);
      await addAccount();
      await service.sync();
    }
    expect(names(), containsAll(others));
    expect(names(), hasLength(others.length + 3));
  });

  test('a failed write is reported, keeps old copies and retries', () async {
    await addAccount();
    await enable();
    final before = names().toList();
    final firstCopyAt = now;

    gateway.failWrites = true;
    now = now.add(const Duration(days: 1));
    await addAccount();
    expect(await service.sync(), FolderSyncResult.failed);
    expect(service.config!.lastError, contains('disk full'));
    expect(service.config!.lastCopyAt, firstCopyAt);
    expect(names(), before);
    expect(dir.listSync().whereType<File>(), isEmpty);

    gateway.failWrites = false;
    expect(await service.sync(), FolderSyncResult.saved);
    expect(service.config!.lastError, isNull);
  });

  test('a lost password is reported instead of writing plain data', () async {
    await addAccount();
    await enable();
    gateway.secret = null;
    expect(await service.sync(force: true), FolderSyncResult.failed);
    expect(service.config!.lastError, contains('password'));
    expect(names(), hasLength(1));
  });

  test('a new password applies to newer copies', () async {
    await addAccount();
    await enable();
    now = now.add(const Duration(days: 1));
    expect(await service.changePassword('other-456'), FolderSyncResult.saved);
    final newest = (names().toList()..sort()).last;
    await expectLater(
      backups.decryptIfNeeded(
        gateway.files(folder.uri)[newest]!,
        password: 'other-456',
      ),
      completion(contains('Cash')),
    );
  });

  test('turning off forgets the password and keeps the files', () async {
    await addAccount();
    await enable();
    await service.disable();
    expect(service.config, isNull);
    expect(gateway.secret, isNull);
    expect(gateway.released, [folder.uri]);
    expect(names(), hasLength(1));
  });

  test('simultaneous syncs write only one copy', () async {
    await addAccount();
    await enable();
    now = now.add(const Duration(days: 1));
    await addAccount();
    final results = await Future.wait([service.sync(), service.sync()]);
    expect(results, [FolderSyncResult.saved, FolderSyncResult.unchanged]);
    expect(names(), hasLength(2));
  });
}
