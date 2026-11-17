import 'dart:io';

import 'package:workmanager/workmanager.dart';

import '../../../core/database/app_database.dart';
import '../domain/backup_models.dart';
import 'backup_service.dart';

const String backupTaskName = 'mybudget.auto_backup';
const String backupUniqueName = 'mybudget_auto_backup';

/// Background entry point (runs in its own isolate/engine). Opens its own
/// database connection, takes one automatic backup, prunes, records the
/// status and closes the database.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppDatabase? db;
    try {
      db = await openAppDatabase();
      final service = BackupService(
        db,
        backupsDirectory: await defaultBackupsDirectory(),
      );
      // runAutoBackup records failures itself. We still return true so the
      // platform does not retry in a tight loop; the next period tries again.
      await service.runAutoBackup();
      return true;
    } catch (_) {
      return true;
    } finally {
      await db?.close();
    }
  });
}

/// Schedules the periodic automatic backup through WorkManager (Android).
///
/// IMPORTANT: Android decides when periodic work actually runs. The interval
/// is a minimum, not a promise; Doze, battery saver and app-standby can delay
/// it by hours. The UI must never promise an exact time.
class BackupScheduler {
  BackupScheduler({bool? supported})
    : _supported = supported ?? Platform.isAndroid;

  final bool _supported;

  /// Call once from `main()` before `runApp` (after bindings are ready).
  Future<void> initialize() async {
    if (!_supported) return;
    await Workmanager().initialize(backupCallbackDispatcher);
  }

  Future<void> schedule(BackupFrequency frequency) async {
    if (!_supported) return;
    if (frequency == BackupFrequency.off) {
      await cancel();
      return;
    }
    await Workmanager().registerPeriodicTask(
      backupUniqueName,
      backupTaskName,
      frequency: frequency == BackupFrequency.daily
          ? const Duration(days: 1)
          : const Duration(days: 7),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresStorageNotLow: true,
      ),
    );
  }

  Future<void> cancel() async {
    if (!_supported) return;
    await Workmanager().cancelByUniqueName(backupUniqueName);
  }
}
