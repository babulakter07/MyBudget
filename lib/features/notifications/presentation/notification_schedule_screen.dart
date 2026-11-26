import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/notification_providers.dart';
import '../domain/notification_models.dart';

/// Lists every reminder that is going to fire (due day, days before, and the
/// one-time expiry reminder) with its exact date/time, and lets the user
/// switch an individual reminder off or on.
class NotificationScheduleScreen extends ConsumerWidget {
  const NotificationScheduleScreen({super.key});

  static IconData _icon(NotificationKind k) => switch (k) {
    NotificationKind.loan => Icons.account_balance_outlined,
    NotificationKind.card => Icons.credit_card,
    NotificationKind.fdr => Icons.lock_clock_outlined,
    NotificationKind.dps => Icons.savings,
    NotificationKind.debt => Icons.handshake_outlined,
    NotificationKind.recurring => Icons.repeat,
    _ => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dayFmt = DateFormat.yMMMEd(locale);
    final whenFmt = DateFormat.yMMMEd(locale).add_jm();
    final async = ref.watch(reminderScheduleProvider);
    final remindersOn = ref.watch(
      notificationSettingsProvider.select((s) => s.settings.remindersEnabled),
    );
    final notifier = ref.read(notificationSettingsProvider.notifier);

    String phaseLabel(NotificationPhase p) => switch (p) {
      NotificationPhase.upcoming => l.notificationsPhaseUpcoming,
      NotificationPhase.today => l.notificationsPhaseToday,
      NotificationPhase.expired => l.notificationsPhaseExpired,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsViewSchedule),
        actions: [
          IconButton(
            tooltip: l.notificationsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.notificationsScheduleEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final children = <Widget>[];
          if (!remindersOn) {
            children.add(
              Card(
                margin: const EdgeInsets.all(16),
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.notificationsScheduleOffBanner,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            );
          }
          String? lastDay;
          for (final n in items) {
            final day = dayFmt.format(n.when);
            if (day != lastDay) {
              lastDay = day;
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(day, style: theme.textTheme.titleSmall),
                ),
              );
            }
            final when = whenFmt.format(n.when);
            children.add(
              SwitchListTile(
                secondary: Icon(_icon(n.kind)),
                title: Text(n.title),
                isThreeLine: true,
                subtitle: Text(
                  '${n.body}\n${phaseLabel(n.phase)} - '
                  '${n.enabled ? l.notificationsFiresAt(when) : l.notificationsFiresAtOff(when)}',
                ),
                value: n.enabled,
                onChanged: (v) => notifier.setReminderKeyEnabled(n.key, v),
              ),
            );
          }
          return ListView(children: children);
        },
      ),
    );
  }
}
