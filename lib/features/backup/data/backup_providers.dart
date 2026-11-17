import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../domain/backup_models.dart';
import 'backup_scheduler.dart';
import 'backup_service.dart';

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
