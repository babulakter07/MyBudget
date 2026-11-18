import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/app_paths.dart';
import '../domain/backup_models.dart';
import 'backup_crypto.dart';
import 'backup_paths.dart';
import 'backup_schema.dart';
import 'backup_validator.dart';

/// App-private directory that holds every local backup file.
Future<Directory> defaultBackupsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'backups'));
}

/// Export / validate / restore of the whole database plus local backup files,
/// retention and backup settings. Pure Dart over [AppDatabase] (no UI).
///
/// Retention policy (documented decision):
///  * `auto` backups: only the newest N (3..30, default 7) are kept; older
///    automatic backups are pruned after every automatic run and whenever
///    the retention setting changes.
///  * `manual` backups are never pruned automatically (the user made them
///    on purpose); they can be deleted by hand.
///  * `safety` backups (undo points taken before a restore) are never
///    deletable from the UI; only the newest [safetyKeep] are kept.
class BackupService {
  BackupService(
    this.db, {
    required this.backupsDirectory,
    DateTime Function()? clock,
    BackupValidator validator = const BackupValidator(),
    Future<Directory> Function()? attachmentsDir,
    this.crypto = const BackupCrypto(),
  }) : _clock = clock ?? DateTime.now,
       _attachmentsDir = attachmentsDir ?? attachmentsDirectory,
       // ignore: prefer_initializing_formals
       _validator = validator;

  static const int safetyKeep = 5;

  final AppDatabase db;
  final Directory backupsDirectory;
  final DateTime Function() _clock;
  final BackupValidator _validator;
  final Future<Directory> Function() _attachmentsDir;

  /// Encryption settings. Tests inject a low PBKDF2 iteration count.
  final BackupCrypto crypto;

  // ------------------------------------------------------------------ export

  /// Whole database as versioned JSON (no photos). Includes inactive and
  /// soft-deleted rows. Money stays integer minor units.
  Future<String> exportJson({bool includePhotos = false}) async =>
      (await exportBackup(includePhotos: includePhotos)).json;

  /// Export with statistics. With [includePhotos], every receipt photo
  /// referenced by `transaction_attachments` is embedded as base64 under
  /// `attachmentFiles` (key = relative path). Missing files are skipped and
  /// counted in [BackupExport.photosMissing]; they never fail the export.
  Future<BackupExport> exportBackup({bool includePhotos = false}) async {
    final tables = <String, Object?>{};
    // One read transaction => a consistent snapshot across tables.
    await db.transaction(() async {
      for (final spec in backupTables) {
        final result = await db
            .customSelect(
              'SELECT * FROM "${spec.name}" ORDER BY ${spec.orderBySql}',
            )
            .get();
        final out = <Map<String, Object?>>[];
        for (final row in result) {
          if (spec.name == 'application_settings' &&
              transientSettingKeys.contains(row.data['key'])) {
            continue;
          }
          out.add({
            for (final c in spec.columns) c.name: _toJson(c, row.data[c.name]),
          });
        }
        tables[spec.name] = out;
      }
    });

    final files = <String, String>{};
    var missing = 0;
    var bytes = 0;
    if (includePhotos) {
      final rels = <String>{
        for (final r in tables['transaction_attachments'] as List)
          (r as Map<String, Object?>)['relative_path'] as String,
      };
      if (rels.isNotEmpty) {
        final root = (await _attachmentsDir()).path;
        for (final rel in rels) {
          final path = resolveInside(root, rel);
          if (path == null) {
            missing++;
            continue;
          }
          final f = File(path);
          try {
            if (!await f.exists()) {
              missing++;
              continue;
            }
            final data = await f.readAsBytes();
            bytes += data.length;
            files[rel] = base64Encode(data);
          } on FileSystemException {
            missing++;
          }
        }
      }
    }
    return BackupExport(
      json: jsonEncode({
        'format': backupFormatName,
        'version': backupFormatVersion,
        'createdAt': _clock().toUtc().toIso8601String(),
        'schemaVersion': AppDatabase.currentSchemaVersion,
        'tables': tables,
        if (includePhotos && files.isNotEmpty) 'attachmentFiles': files,
      }),
      photosEmbedded: files.length,
      photosMissing: missing,
      photoBytes: bytes,
    );
  }

  /// Approximate size of the photos a backup would embed (for the export
  /// dialog). Reads only file metadata.
  Future<PhotoEstimate> estimatePhotos() async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT relative_path FROM transaction_attachments',
        )
        .get();
    if (rows.isEmpty) {
      return const PhotoEstimate(count: 0, bytes: 0, missing: 0);
    }
    final root = (await _attachmentsDir()).path;
    var count = 0, bytes = 0, missing = 0;
    for (final r in rows) {
      final path = resolveInside(root, r.data['relative_path'] as String);
      final f = path == null ? null : File(path);
      if (f != null && f.existsSync()) {
        count++;
        bytes += f.lengthSync();
      } else {
        missing++;
      }
    }
    return PhotoEstimate(count: count, bytes: bytes, missing: missing);
  }

  /// Encrypts backup JSON with [password] (>= 6 characters).
  Future<String> encryptJson(String json, String password) =>
      crypto.encrypt(json, password);

  /// Returns plain backup JSON: [text] unchanged when it is a plain backup,
  /// otherwise the decrypted content. Throws [BackupPasswordRequired] when
  /// the file is encrypted and no password was given, and a
  /// [ValidationException] on a wrong password or tampering.
  Future<String> decryptIfNeeded(String text, {String? password}) async {
    if (!BackupCrypto.isEncrypted(text)) return text;
    if (password == null || password.isEmpty) throw BackupPasswordRequired();
    return crypto.decrypt(text, password);
  }

  Object? _toJson(ColSpec c, Object? v) {
    if (v == null) return null;
    return switch (c.kind) {
      ColKind.bool_ => v != 0,
      ColKind.dateTime => DateTime.fromMillisecondsSinceEpoch(
        (v as int) * 1000,
        isUtc: true,
      ).toIso8601String(),
      _ => v,
    };
  }

  Object? _fromJson(ColSpec c, Object? v) {
    v ??= c.defaultValue;
    if (v == null) return null;
    return switch (c.kind) {
      ColKind.bool_ => (v as bool) ? 1 : 0,
      ColKind.dateTime =>
        DateTime.parse(v as String).millisecondsSinceEpoch ~/ 1000,
      _ => v,
    };
  }

  // ---------------------------------------------------------------- validate

  BackupValidationResult validate(String json) => _validator.validate(json);

  // ----------------------------------------------------------------- restore

  /// Validates, writes a safety backup, then replaces ALL data atomically.
  /// Any failure rolls the transaction back and leaves the old data intact.
  /// If [activeProfileId] no longer exists afterwards, [clearActiveProfile]
  /// is invoked (the router then sends the user to the profile screen).
  ///
  /// [json] may also be an encrypted envelope; then [password] is required
  /// (see [decryptIfNeeded]). Receipt photos embedded in the backup are
  /// written into the attachments directory only AFTER the database restore
  /// committed, so a failed restore never touches any file.
  Future<RestoreResult> restore(
    String json, {
    String? password,
    int? activeProfileId,
    Future<void> Function()? clearActiveProfile,
  }) async {
    json = await decryptIfNeeded(json, password: password);
    final validation = validate(json);
    if (!validation.isValid) {
      throw ValidationException(
        'Backup is not valid and was not restored: ${validation.errors.first}',
      );
    }
    final root = jsonDecode(json) as Map<String, dynamic>;
    final tables = root['tables'] as Map<String, dynamic>;
    final embedded = <String, List<int>>{
      for (final e
          in ((root['attachmentFiles'] as Map<String, dynamic>?) ?? const {})
              .entries)
        e.key: base64Decode(e.value as String),
    };

    final safety = await createBackupFile(kind: BackupKind.safety);

    try {
      await db.transaction(() async {
        for (final spec in backupTables.reversed) {
          if (spec.name == 'application_settings') {
            final keep = transientSettingKeys.map((k) => "'$k'").join(',');
            await db.customStatement(
              'DELETE FROM "application_settings" WHERE "key" NOT IN ($keep)',
            );
          } else {
            await db.customStatement('DELETE FROM "${spec.name}"');
          }
        }
        // Make AUTOINCREMENT counters follow the restored data.
        final seqNames = autoIncrementTables.map((t) => "'$t'").join(',');
        await db.customStatement(
          'DELETE FROM sqlite_sequence WHERE name IN ($seqNames)',
        );
        for (final spec in backupTables) {
          final cols = spec.columns.map((c) => '"${c.name}"').join(',');
          final marks = List.filled(spec.columns.length, '?').join(',');
          final sql = 'INSERT INTO "${spec.name}" ($cols) VALUES ($marks)';
          for (final raw in (tables[spec.name] as List?) ?? const []) {
            final row = raw as Map<String, dynamic>;
            if (spec.name == 'application_settings' &&
                transientSettingKeys.contains(row['key'])) {
              continue;
            }
            await db.customStatement(sql, [
              for (final c in spec.columns) _fromJson(c, row[c.name]),
            ]);
          }
        }
      });
    } catch (e) {
      throw AppException(
        'Restore failed and was rolled back; your existing data is '
        'unchanged. ($e)',
      );
    }

    // customStatement does not notify Drift streams; do it explicitly.
    db.markTablesUpdated(db.allTables);

    var cleared = false;
    if (activeProfileId != null) {
      final ids = {
        for (final r in tables['financial_profiles'] as List)
          (r as Map<String, dynamic>)['id'] as int,
      };
      if (!ids.contains(activeProfileId)) {
        await clearActiveProfile?.call();
        cleared = true;
      }
    }
    var restored = 0, failed = 0;
    if (embedded.isNotEmpty) {
      final dir = (await _attachmentsDir()).path;
      for (final e in embedded.entries) {
        final path = resolveInside(dir, e.key);
        if (path == null) {
          failed++; // defence in depth; validation already rejects these
          continue;
        }
        try {
          final target = File(path);
          await target.parent.create(recursive: true);
          final tmp = File('$path.restoring');
          await tmp.writeAsBytes(e.value, flush: true);
          await tmp.rename(path);
          restored++;
        } on FileSystemException {
          failed++;
        }
      }
    }
    return RestoreResult(
      counts: validation.counts,
      safetyBackupPath: safety.path,
      activeProfileCleared: cleared,
      photosRestored: restored,
      photosFailed: failed,
    );
  }

  // ------------------------------------------------------------ backup files

  static final RegExp _fileName = RegExp(
    r'^(manual|auto|safety)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})_(\d{3})(?:_\d+)?\.json$',
  );

  String _fileStamp(DateTime t) {
    String n(int v, int w) => v.toString().padLeft(w, '0');
    return '${n(t.year, 4)}${n(t.month, 2)}${n(t.day, 2)}_'
        '${n(t.hour, 2)}${n(t.minute, 2)}${n(t.second, 2)}_'
        '${n(t.millisecond, 3)}';
  }

  /// Writes a full backup into the app-private backups directory.
  ///
  /// Manual backups embed receipt photos by default; automatic and safety
  /// backups do not (they would bloat every run; safety restores never delete
  /// photo files). A [password] writes an encrypted envelope instead of plain
  /// JSON; automatic backups are always plain. [onExport] receives the photo
  /// statistics (e.g. skipped-file warning count).
  Future<BackupFileInfo> createBackupFile({
    required BackupKind kind,
    bool? includePhotos,
    String? password,
    void Function(BackupExport export)? onExport,
  }) async {
    if (password != null) BackupCrypto.checkPassword(password);
    final export = await exportBackup(
      includePhotos: includePhotos ?? kind == BackupKind.manual,
    );
    onExport?.call(export);
    final json = password == null
        ? export.json
        : await crypto.encrypt(export.json, password);
    await backupsDirectory.create(recursive: true);
    final stamp = _fileStamp(_clock());
    var name = '${kind.name}_$stamp.json';
    var n = 1;
    while (await File(p.join(backupsDirectory.path, name)).exists()) {
      name = '${kind.name}_${stamp}_${n++}.json';
    }
    final target = File(p.join(backupsDirectory.path, name));
    // Write to a temp file first so a crash never leaves a half-written
    // *.json that looks like a backup.
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(target.path);
    if (kind == BackupKind.safety) await _prune(BackupKind.safety, safetyKeep);
    return _info(target)!;
  }

  BackupFileInfo? _info(File f) {
    final name = p.basename(f.path);
    final m = _fileName.firstMatch(name);
    if (m == null) return null;
    int g(int i) => int.parse(m[i]!);
    return BackupFileInfo(
      path: f.path,
      name: name,
      kind: BackupKind.fromPrefix(m[1]!)!,
      createdAt: DateTime(g(2), g(3), g(4), g(5), g(6), g(7), g(8)),
      sizeBytes: f.lengthSync(),
    );
  }

  /// All backups, newest first.
  Future<List<BackupFileInfo>> listBackups() async {
    if (!await backupsDirectory.exists()) return const [];
    final out = <BackupFileInfo>[];
    await for (final e in backupsDirectory.list()) {
      if (e is! File) continue;
      final info = _info(e);
      if (info != null) out.add(info);
    }
    out.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.name.compareTo(a.name);
    });
    return out;
  }

  Future<String> readBackup(BackupFileInfo info) =>
      File(_ownedPath(info)).readAsString();

  /// Deletes a manual or automatic backup file (never a safety file).
  Future<void> deleteBackup(BackupFileInfo info) async {
    if (!info.deletable) {
      throw ValidationException(
        'Safety backups are managed automatically and cannot be deleted.',
      );
    }
    final f = File(_ownedPath(info));
    if (!await f.exists()) {
      throw NotFoundException('That backup file no longer exists.');
    }
    await f.delete();
  }

  String _ownedPath(BackupFileInfo info) {
    final name = p.basename(info.path);
    if (_fileName.firstMatch(name) == null) {
      throw ValidationException('Not a backup file managed by the app.');
    }
    return p.join(backupsDirectory.path, name);
  }

  Future<int> _prune(BackupKind kind, int keep) async {
    final files = (await listBackups()).where((b) => b.kind == kind).toList();
    var deleted = 0;
    for (final f in files.skip(keep)) {
      try {
        await File(f.path).delete();
        deleted++;
      } on FileSystemException {
        // Best effort; a locked file is retried on the next run.
      }
    }
    return deleted;
  }

  /// Prunes the oldest automatic backups beyond the retention setting.
  /// Manual and safety files are never touched here.
  Future<int> applyRetention() async {
    final s = await loadSettings();
    return _prune(BackupKind.auto, s.retention);
  }

  // ---------------------------------------------------------------- settings

  Future<Map<String, String>> _settingsMap() async {
    final rows = await db.select(db.applicationSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> _put(String key, String value) => db
      .into(db.applicationSettings)
      .insertOnConflictUpdate(
        ApplicationSettingsCompanion.insert(key: key, value: value),
      );

  Future<BackupSettings> loadSettings() async {
    final m = await _settingsMap();
    final r = int.tryParse(m[settingRetention] ?? '');
    final status = m[settingLastStatus];
    return BackupSettings(
      frequency: BackupFrequency.parse(m[settingFrequency]),
      retention:
          (r != null &&
              r >= BackupSettings.minRetention &&
              r <= BackupSettings.maxRetention)
          ? r
          : BackupSettings.defaultRetention,
      lastBackupAt: DateTime.tryParse(m[settingLastAt] ?? '')?.toLocal(),
      lastSuccess: status == null ? null : status == 'success',
      lastMessage: m[settingLastMessage],
    );
  }

  Future<void> setFrequency(BackupFrequency f) =>
      _put(settingFrequency, f.name);

  Future<void> setRetention(int n) async {
    if (n < BackupSettings.minRetention || n > BackupSettings.maxRetention) {
      throw ValidationException(
        'Keep between ${BackupSettings.minRetention} and '
        '${BackupSettings.maxRetention} automatic backups.',
      );
    }
    await _put(settingRetention, '$n');
    await applyRetention();
  }

  Future<void> recordStatus({
    required bool success,
    required String message,
  }) async {
    await db.transaction(() async {
      await _put(settingLastAt, _clock().toUtc().toIso8601String());
      await _put(settingLastStatus, success ? 'success' : 'failure');
      await _put(settingLastMessage, message);
    });
  }

  /// One automatic backup run: create file, prune, record status. Never
  /// throws; returns whether it succeeded.
  Future<bool> runAutoBackup() async {
    try {
      final info = await createBackupFile(kind: BackupKind.auto);
      await applyRetention();
      await recordStatus(success: true, message: 'Saved ${info.name}');
      return true;
    } catch (e) {
      try {
        await recordStatus(success: false, message: '$e');
      } catch (_) {
        // DB unavailable; nothing more we can do in the background.
      }
      return false;
    }
  }
}
