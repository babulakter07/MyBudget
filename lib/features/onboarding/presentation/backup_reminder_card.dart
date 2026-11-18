import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/backup_reminder.dart';

/// Home-screen nudge to back up. Shown only when the newest manual/automatic
/// backup is 30+ days old (or missing) and the user has data.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(backupReminderProvider).value;
    if (reminder == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final days = reminder.daysSince;
    return Card(
      key: const ValueKey('backup-reminder-card'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.backupReminderTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              days == null
                  ? l10n.backupReminderNone
                  : l10n.backupReminderOld(days),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                children: [
                  TextButton(
                    key: const ValueKey('backup-reminder-later'),
                    onPressed: () => snoozeBackupReminder(ref),
                    child: Text(l10n.backupReminderLater),
                  ),
                  FilledButton.tonal(
                    key: const ValueKey('backup-reminder-go'),
                    onPressed: () => context.push('/settings/backup'),
                    child: Text(l10n.backupReminderAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
