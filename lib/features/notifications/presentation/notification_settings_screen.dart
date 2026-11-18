import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);
    final s = state.settings;
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Future<void> pickHour() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: s.reminderHour, minute: 0),
      );
      if (picked != null) await notifier.setReminderHour(picked.hour);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ListView(
        children: [
          if (state.permissionDenied)
            Card(
              margin: const EdgeInsets.all(16),
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.notificationsPermissionDenied,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
          SwitchListTile(
            title: Text(l10n.notificationsReminders),
            subtitle: Text(l10n.notificationsRemindersSubtitle),
            value: s.remindersEnabled,
            onChanged: notifier.setRemindersEnabled,
          ),
          SwitchListTile(
            title: Text(l10n.notificationsBudgetAlerts),
            subtitle: Text(l10n.notificationsBudgetAlertsSubtitle),
            value: s.budgetAlertsEnabled,
            onChanged: notifier.setBudgetAlertsEnabled,
          ),
          ListTile(
            title: Text(l10n.notificationsReminderTime),
            subtitle: Text('${s.reminderHour.toString().padLeft(2, '0')}:00'),
            trailing: const Icon(Icons.access_time),
            enabled: s.remindersEnabled,
            onTap: s.remindersEnabled ? pickHour : null,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.notificationsSendTest),
              onPressed: () async {
                final ok = await notifier.sendTest();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? l10n.notificationsTestSent
                            : l10n.notificationsTestDenied,
                      ),
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}
