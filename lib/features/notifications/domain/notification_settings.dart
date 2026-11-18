import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    this.remindersEnabled = false,
    this.budgetAlertsEnabled = false,
    this.reminderHour = defaultReminderHour,
  });

  static const defaultReminderHour = 9;
  static const remindersKey = 'notif_reminders_enabled';
  static const budgetKey = 'notif_budget_alerts_enabled';
  static const hourKey = 'notif_reminder_hour';

  final bool remindersEnabled;
  final bool budgetAlertsEnabled;
  final int reminderHour;

  NotificationSettings copyWith({
    bool? remindersEnabled,
    bool? budgetAlertsEnabled,
    int? reminderHour,
  }) => NotificationSettings(
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
  );

  static NotificationSettings load(SharedPreferences prefs) {
    final hour = prefs.getInt(hourKey) ?? defaultReminderHour;
    return NotificationSettings(
      remindersEnabled: prefs.getBool(remindersKey) ?? false,
      budgetAlertsEnabled: prefs.getBool(budgetKey) ?? false,
      reminderHour: hour < 0 || hour > 23 ? defaultReminderHour : hour,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(remindersKey, remindersEnabled);
    await prefs.setBool(budgetKey, budgetAlertsEnabled);
    await prefs.setInt(hourKey, reminderHour);
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.remindersEnabled == remindersEnabled &&
      other.budgetAlertsEnabled == budgetAlertsEnabled &&
      other.reminderHour == reminderHour;

  @override
  int get hashCode =>
      Object.hash(remindersEnabled, budgetAlertsEnabled, reminderHour);
}
