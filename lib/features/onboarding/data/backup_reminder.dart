import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../backup/data/backup_providers.dart';
import '../../backup/domain/backup_models.dart';
import 'setup_progress.dart';

const backupReminderAfterDays = 30;
const backupReminderSnooze = Duration(days: 7);
const _snoozeKey = 'backup_reminder_snooze_until_ms';

/// Result of the reminder check. [daysSince] is null when no backup exists.
class BackupReminder {
  const BackupReminder({required this.daysSince});
  final int? daysSince;
}

/// Pure rule so it can be tested without a database or clock.
/// Returns null when no reminder should be shown.
BackupReminder? evaluateBackupReminder({
  required DateTime now,
  required bool hasData,
  required DateTime? newestBackup,
  required DateTime? snoozedUntil,
  int afterDays = backupReminderAfterDays,
}) {
  if (!hasData) return null; // do not nag before there is anything to lose
  if (snoozedUntil != null && snoozedUntil.isAfter(now)) return null;
  if (newestBackup == null) return const BackupReminder(daysSince: null);
  final days = now.difference(newestBackup).inDays;
  return days >= afterDays ? BackupReminder(daysSince: days) : null;
}

/// Whether the home screen should nudge the user to back up. Safety backups
/// (made automatically before a restore) do not count.
final backupReminderProvider = FutureProvider.autoDispose<BackupReminder?>((
  ref,
) async {
  final hasData =
      ref.watch(setupProgressProvider).value?.hasTransaction ?? false;
  final prefs = ref.watch(sharedPreferencesProvider);
  final snoozeMs = prefs.getInt(_snoozeKey);
  final List<BackupFileInfo> files = await ref.watch(backupListProvider.future);
  DateTime? newest;
  for (final f in files) {
    if (f.kind == BackupKind.safety) continue;
    if (newest == null || f.createdAt.isAfter(newest)) newest = f.createdAt;
  }
  return evaluateBackupReminder(
    now: DateTime.now(),
    hasData: hasData,
    newestBackup: newest,
    snoozedUntil: snoozeMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(snoozeMs),
  );
});

/// Hides the reminder for [backupReminderSnooze].
Future<void> snoozeBackupReminder(WidgetRef ref) async {
  final until = DateTime.now().add(backupReminderSnooze);
  await ref
      .read(sharedPreferencesProvider)
      .setInt(_snoozeKey, until.millisecondsSinceEpoch);
  ref.invalidate(backupReminderProvider);
}
