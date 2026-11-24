import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    this.remindersEnabled = false,
    this.budgetAlertsEnabled = false,
    this.reminderHour = defaultReminderHour,
    this.todayEnabled = true,
    this.upcomingDays = defaultUpcomingDays,
    this.expireAfterDays = defaultExpireAfterDays,
  });

  static const defaultReminderHour = 9;

  /// Days before the due date for the "upcoming" reminder (0 = off).
  static const defaultUpcomingDays = 1;

  /// Days after the due date for the single "expired" reminder (0 = off).
  static const defaultExpireAfterDays = 1;
  static const maxLeadDays = 30;
  static const todayKey = 'notif_today_enabled';
  static const upcomingKey = 'notif_upcoming_days';
  static const expireKey = 'notif_expire_after_days';
  static const disabledKeysKey = 'notif_disabled_keys';
  static const catchUpKey = 'notif_catchup_done';

  /// Keys of catch-up reminders already shown (never repeated).
  static Set<String> loadCatchUpDone(SharedPreferences prefs) =>
      (prefs.getStringList(catchUpKey) ?? const <String>[]).toSet();

  static Future<void> saveCatchUpDone(
    SharedPreferences prefs,
    Set<String> keys,
  ) => prefs.setStringList(catchUpKey, keys.toList()..sort());
  static const remindersKey = 'notif_reminders_enabled';
  static const budgetKey = 'notif_budget_alerts_enabled';
  static const hourKey = 'notif_reminder_hour';

  final bool remindersEnabled;
  final bool budgetAlertsEnabled;
  final int reminderHour;
  final bool todayEnabled;
  final int upcomingDays;
  final int expireAfterDays;

  NotificationSettings copyWith({
    bool? remindersEnabled,
    bool? budgetAlertsEnabled,
    int? reminderHour,
    bool? todayEnabled,
    int? upcomingDays,
    int? expireAfterDays,
  }) => NotificationSettings(
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    todayEnabled: todayEnabled ?? this.todayEnabled,
    upcomingDays: upcomingDays ?? this.upcomingDays,
    expireAfterDays: expireAfterDays ?? this.expireAfterDays,
  );

  static NotificationSettings load(SharedPreferences prefs) {
    final hour = prefs.getInt(hourKey) ?? defaultReminderHour;
    return NotificationSettings(
      remindersEnabled: prefs.getBool(remindersKey) ?? false,
      budgetAlertsEnabled: prefs.getBool(budgetKey) ?? false,
      reminderHour: hour < 0 || hour > 23 ? defaultReminderHour : hour,
      todayEnabled: prefs.getBool(todayKey) ?? true,
      upcomingDays: _lead(prefs.getInt(upcomingKey), defaultUpcomingDays),
      expireAfterDays: _lead(prefs.getInt(expireKey), defaultExpireAfterDays),
    );
  }

  static int _lead(int? v, int fallback) =>
      v == null || v < 0 || v > maxLeadDays ? fallback : v;

  /// Keys of single reminders the user switched off.
  static Set<String> loadDisabledKeys(SharedPreferences prefs) =>
      (prefs.getStringList(disabledKeysKey) ?? const <String>[]).toSet();

  static Future<void> saveDisabledKeys(
    SharedPreferences prefs,
    Set<String> keys,
  ) async {
    if (keys.isEmpty) {
      await prefs.remove(disabledKeysKey);
    } else {
      await prefs.setStringList(disabledKeysKey, keys.toList()..sort());
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(remindersKey, remindersEnabled);
    await prefs.setBool(budgetKey, budgetAlertsEnabled);
    await prefs.setInt(hourKey, reminderHour);
    await prefs.setBool(todayKey, todayEnabled);
    await prefs.setInt(upcomingKey, upcomingDays);
    await prefs.setInt(expireKey, expireAfterDays);
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.remindersEnabled == remindersEnabled &&
      other.budgetAlertsEnabled == budgetAlertsEnabled &&
      other.reminderHour == reminderHour &&
      other.todayEnabled == todayEnabled &&
      other.upcomingDays == upcomingDays &&
      other.expireAfterDays == expireAfterDays;

  @override
  int get hashCode => Object.hash(
    remindersEnabled,
    budgetAlertsEnabled,
    reminderHour,
    todayEnabled,
    upcomingDays,
    expireAfterDays,
  );
}
