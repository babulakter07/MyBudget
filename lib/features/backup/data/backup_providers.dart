import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/providers/core_providers.dart';
import '../domain/backup_models.dart';
import 'backup_folder_gateway.dart';
import 'backup_scheduler.dart';
import 'backup_service.dart';
import 'folder_backup_service.dart';

final backupSchedulerProvider = Provider<BackupScheduler>(
  (ref) => BackupScheduler(),
);

/// Resolves the app-private backups directory (async), so it is a future.
final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db, backupsDirectory: await defaultBackupsDirectory());
});

final backupListProvider = FutureProvider.autoDispose<List<BackupFileInfo>>((
  ref,
) async {
  final service = await ref.watch(backupServiceProvider.future);
  return service.listBackups();
});

final backupSettingsProvider = FutureProvider.autoDispose<BackupSettings>((
  ref,
) async {
  final service = await ref.watch(backupServiceProvider.future);
  return service.loadSettings();
});

/// One instance for the app, so its operations stay serialised.
final folderBackupServiceProvider = FutureProvider<FolderBackupService>((
  ref,
) async {
  return FolderBackupService(
    backups: await ref.watch(backupServiceProvider.future),
    gateway: ref.watch(backupFolderGatewayProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    tempDirectory: getTemporaryDirectory,
  );
});

/// Folder backup settings and status; null when it is off. Invalidate after a
/// folder operation.
final folderBackupConfigProvider = Provider.autoDispose<FolderBackupConfig?>(
  (ref) => readFolderBackupConfig(ref.watch(sharedPreferencesProvider)),
);
