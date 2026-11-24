import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/notification_providers.dart';
import '../domain/notification_sound.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);
    final s = state.settings;
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final l10n = context.l10n;
    final sounds = ref.watch(notificationSoundsProvider);
    final soundNotifier = ref.read(notificationSoundsProvider.notifier);
    String soundText(NotificationSound s) => s.isDefault
        ? l10n.notificationsSoundDefault
        : s.isSilent
        ? l10n.notificationsSoundSilent
        : ((s.title ?? '').isEmpty ? l10n.notificationsSoundCustom : s.title!);
    final scheme = Theme.of(context).colorScheme;

    Future<void> pickHour() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: s.reminderHour, minute: 0),
      );
      if (picked != null) await notifier.setReminderHour(picked.hour);
    }

    String daysText(int days, {required bool before}) => days == 0
        ? l10n.notificationsOff
        : before
        ? l10n.notificationsDaysBefore(days)
        : l10n.notificationsDaysAfter(days);

    Future<void> pickDays(int current, Future<void> Function(int) apply) async {
      const options = [0, 1, 2, 3, 5, 7, 10, 14, 30];
      final picked = await showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l10n.notificationsPickDays),
          children: [
            RadioGroup<int>(
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              child: Column(
                children: [
                  for (final d in options)
                    RadioListTile<int>(
                      value: d,
                      title: Text(d == 0 ? l10n.notificationsOff : '$d'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (picked != null) await apply(picked);
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
          SwitchListTile(
            title: Text(l10n.notificationsTodayReminder),
            subtitle: Text(l10n.notificationsTodayReminderSubtitle),
            value: s.todayEnabled,
            onChanged: s.remindersEnabled ? notifier.setTodayEnabled : null,
          ),
          ListTile(
            title: Text(l10n.notificationsUpcomingReminder),
            subtitle: Text(daysText(s.upcomingDays, before: true)),
            trailing: const Icon(Icons.event_available_outlined),
            enabled: s.remindersEnabled,
            onTap: s.remindersEnabled
                ? () => pickDays(s.upcomingDays, notifier.setUpcomingDays)
                : null,
          ),
          ListTile(
            title: Text(l10n.notificationsExpireReminder),
            subtitle: Text(
              daysText(s.expireAfterDays, before: false) +
                  String.fromCharCode(10) +
                  l10n.notificationsExpireReminderSubtitle,
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.event_busy_outlined),
            enabled: s.remindersEnabled,
            onTap: s.remindersEnabled
                ? () => pickDays(s.expireAfterDays, notifier.setExpireAfterDays)
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l10n.notificationsReminderSound),
            subtitle: Text(soundText(sounds.reminders)),
            onTap: () => soundNotifier.choose(budget: false),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l10n.notificationsBudgetSound),
            subtitle: Text(soundText(sounds.budget)),
            onTap: () => soundNotifier.choose(budget: true),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(l10n.notificationsViewSchedule),
            subtitle: Text(l10n.notificationsViewScheduleSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications/schedule'),
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
