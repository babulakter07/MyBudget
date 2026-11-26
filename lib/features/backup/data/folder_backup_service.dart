import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_crypto.dart';
import 'backup_folder_gateway.dart';
import 'backup_service.dart';

/// Device-specific settings live in SharedPreferences on purpose: a folder
/// permission and password must not travel inside a backup file.
const _kUri = 'folder_backup_uri';
const _kName = 'folder_backup_name';
const _kPhotos = 'folder_backup_include_photos';
const _kInstallId = 'folder_backup_install_id';
const _kDigest = 'folder_backup_digest';
const _kLastFile = 'folder_backup_last_file';
const _kLastAt = 'folder_backup_last_at_ms';
const _kError = 'folder_backup_error';

/// A database with no rows in any of these has nothing worth saving.
const _userDataTables = [
  'accounts',
  'financial_transactions',
  'debts',
  'loans',
  'credit_cards',
  'fixed_deposits',
  'dps_accounts',
  'savings_goals',
];

class FolderBackupConfig {
  const FolderBackupConfig({
    required this.folderUri,
    required this.folderName,
    required this.includePhotos,
    this.lastCopyAt,
    this.lastError,
  });
  final String folderUri;
  final String folderName;
  final bool includePhotos;

  /// Time of the newest copy written to the folder.
  final DateTime? lastCopyAt;

  /// Set when the most recent attempt failed; cleared by the next success.
  final String? lastError;
}

/// Saved folder settings, or null when the feature is off.
FolderBackupConfig? readFolderBackupConfig(SharedPreferences prefs) {
  final uri = prefs.getString(_kUri);
  if (uri == null) return null;
  final at = prefs.getInt(_kLastAt);
  return FolderBackupConfig(
    folderUri: uri,
    folderName: prefs.getString(_kName) ?? uri,
    includePhotos: prefs.getBool(_kPhotos) ?? true,
    lastCopyAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
    lastError: prefs.getString(_kError),
  );
}

enum FolderSyncResult { disabled, nothingToSave, unchanged, saved, failed }

// Top level so the isolate closure captures only sendable values.
Future<String> _encryptInIsolate(
  BackupCrypto crypto,
  String json,
  String password,
) => Isolate.run(() => crypto.encrypt(json, password));

/// Keeps password-encrypted copies of the data in a folder the user chose, so
/// they survive uninstalling the app.
///
/// * A copy is written only when the data changed since the last one.
/// * One file per day is kept, for the newest N days (the automatic backup
///   retention setting).
/// * Only files carrying this installation's id are ever deleted, so a
///   reinstalled app cannot prune the copies made before it.
class FolderBackupService {
  FolderBackupService({
    required this.backups,
    required this.gateway,
    required this.prefs,
    required this.tempDirectory,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final BackupService backups;
  final BackupFolderGateway gateway;
  final SharedPreferences prefs;
  final Future<Directory> Function() tempDirectory;
  final DateTime Function() _clock;
  final Random _random;

  Future<void> _queue = Future<void>.value();

  /// Runs [body] after every earlier operation, so two lifecycle events never
  /// write or prune at the same time.
  Future<T> _serial<T>(Future<T> Function() body) {
    final result = _queue.then((_) => body());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  FolderBackupConfig? get config => readFolderBackupConfig(prefs);

  /// Turns the feature on and writes the first copy.
  Future<FolderSyncResult> enable({
    required PickedFolder folder,
    required String password,
    required bool includePhotos,
  }) {
    BackupCrypto.checkPassword(password);
    return _serial(() async {
      final previous = prefs.getString(_kUri);
      await gateway.saveSecret(password);
      await prefs.setString(_kUri, folder.uri);
      await prefs.setString(_kName, folder.name);
      await prefs.setBool(_kPhotos, includePhotos);
      await _forgetLastCopy();
      if (previous != null && previous != folder.uri) {
        await _releaseQuietly(previous);
      }
      return _sync();
    });
  }

  /// Newer copies use [password]; older files keep their previous password.
  Future<FolderSyncResult> changePassword(String password) {
    BackupCrypto.checkPassword(password);
    return _serial(() async {
      if (config == null) return FolderSyncResult.disabled;
      await gateway.saveSecret(password);
      await prefs.remove(_kDigest);
      return _sync();
    });
  }

  /// Turns the feature off. Files already in the folder are left alone.
  Future<void> disable() => _serial(() async {
    final uri = prefs.getString(_kUri);
    await prefs.remove(_kUri);
    await prefs.remove(_kName);
    await prefs.remove(_kPhotos);
    await _forgetLastCopy();
    await gateway.clearSecret();
    if (uri != null) await _releaseQuietly(uri);
  });

  /// Writes a copy if one is needed ([force] always writes). Never throws; a
  /// failure is recorded in [FolderBackupConfig.lastError].
  Future<FolderSyncResult> sync({bool force = false}) =>
      _serial(() => _sync(force: force));

  Future<FolderSyncResult> _sync({bool force = false}) async {
    final current = config;
    if (current == null) return FolderSyncResult.disabled;
    try {
      final plain = await backups.exportBackup();
      final tables =
          (jsonDecode(plain.json) as Map<String, dynamic>)['tables']
              as Map<String, dynamic>;
      if (_userDataTables.every((t) => (tables[t] as List?)?.isEmpty ?? true)) {
        return FolderSyncResult.nothingToSave;
      }
      final digest = sha256
          .convert(
            utf8.encode('${current.includePhotos}|${jsonEncode(tables)}'),
          )
          .toString();
      final lastFile = prefs.getString(_kLastFile);
      if (!force &&
          digest == prefs.getString(_kDigest) &&
          (await gateway.listFiles(current.folderUri)).contains(lastFile)) {
        await prefs.remove(_kError);
        return FolderSyncResult.unchanged;
      }

      final password = await gateway.readSecret();
      if (password == null) {
        throw const FileSystemException(
          'The saved backup password is no longer available. '
          'Set the password again.',
        );
      }
      final json = current.includePhotos
          ? (await backups.exportBackup(includePhotos: true)).json
          : plain.json;
      final encrypted = await _encryptInIsolate(backups.crypto, json, password);

      final now = _clock();
      final name = await _fileName(now);
      final temp = File(p.join((await tempDirectory()).path, name));
      try {
        await temp.writeAsString(encrypted, flush: true);
        await gateway.writeFile(current.folderUri, name, temp.path);
      } finally {
        if (await temp.exists()) await temp.delete();
      }

      await prefs.setString(_kDigest, digest);
      await prefs.setString(_kLastFile, name);
      await prefs.setInt(_kLastAt, now.millisecondsSinceEpoch);
      await prefs.remove(_kError);
      await _prune(current.folderUri, name);
      return FolderSyncResult.saved;
    } catch (e) {
      await prefs.setString(_kError, '$e');
      return FolderSyncResult.failed;
    }
  }

  Future<String> _installId() async {
    var id = prefs.getString(_kInstallId);
    if (id == null) {
      id = List.generate(
        8,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join();
      await prefs.setString(_kInstallId, id);
    }
    return id;
  }

  Future<String> _fileName(DateTime t) async {
    String n(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return 'mybudget_${await _installId()}_'
        '${n(t.year, 4)}${n(t.month)}${n(t.day)}_'
        '${n(t.hour)}${n(t.minute)}${n(t.second)}${n(t.millisecond, 3)}.json';
  }

  /// Keeps [newest] plus the latest file of each of the newest N days.
  /// Best effort: the copy is already saved, so errors are ignored.
  Future<void> _prune(String folderUri, String newest) async {
    try {
      final keepDays = (await backups.loadSettings()).retention;
      final own = RegExp(
        '^mybudget_${await _installId()}_(\\d{8})_\\d{9}\\.json\$',
      );
      final files =
          (await gateway.listFiles(folderUri))
              .where((f) => own.hasMatch(f) && f != newest)
              .toList()
            ..sort((a, b) => b.compareTo(a));
      final days = <String>{own.firstMatch(newest)![1]!};
      for (final f in files) {
        final day = own.firstMatch(f)![1]!;
        if (!days.contains(day) && days.length < keepDays) {
          days.add(day);
          continue;
        }
        await gateway.deleteFile(folderUri, f);
      }
    } catch (_) {
      // Retried after the next copy.
    }
  }

  Future<void> _forgetLastCopy() async {
    await prefs.remove(_kDigest);
    await prefs.remove(_kLastFile);
    await prefs.remove(_kLastAt);
    await prefs.remove(_kError);
  }

  Future<void> _releaseQuietly(String uri) async {
    try {
      await gateway.releaseFolder(uri);
    } catch (_) {
      // The permission may already be gone.
    }
  }
}
