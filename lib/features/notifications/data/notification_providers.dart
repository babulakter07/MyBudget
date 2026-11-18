import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../preferences/data/app_l10n_resolver.dart';
import '../domain/notification_models.dart';
import '../domain/notification_settings.dart';
import 'budget_alert_service.dart';
import 'notification_gateway.dart';
import 'notification_scheduler.dart';

/// Override with [FakeNotificationGateway] in tests.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => LocalNotificationGateway(),
);

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    db: ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    gateway: ref.watch(notificationGatewayProvider),
    activeProfileId: () => ref.read(activeProfileIdProvider),
  );
});

final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  return BudgetAlertService(
    db: ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    gateway: ref.watch(notificationGatewayProvider),
  );
});

class NotificationSettingsState {
  const NotificationSettingsState({
    required this.settings,
    this.permissionDenied = false,
  });

  final NotificationSettings settings;

  /// True when the user tried to enable a toggle but the OS permission was
  /// refused.
  final bool permissionDenied;
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() => NotificationSettingsState(
    settings: NotificationSettings.load(ref.watch(sharedPreferencesProvider)),
  );

  Future<void> _apply(
    NotificationSettings next, {
    bool permissionDenied = false,
  }) async {
    await next.save(ref.read(sharedPreferencesProvider));
    state = NotificationSettingsState(
      settings: next,
      permissionDenied: permissionDenied,
    );
    await ref.read(notificationSchedulerProvider).resync();
  }

  /// Requests the OS permission only when turning something on. If denied,
  /// the toggle stays off and [permissionDenied] is set.
  Future<bool> _permitted() =>
      ref.read(notificationGatewayProvider).requestPermission();

  Future<void> setRemindersEnabled(bool on) async {
    final cur = state.settings;
    if (on && !await _permitted()) {
      state = NotificationSettingsState(settings: cur, permissionDenied: true);
      return;
    }
    await _apply(cur.copyWith(remindersEnabled: on));
  }

  Future<void> setBudgetAlertsEnabled(bool on) async {
    final cur = state.settings;
    if (on && !await _permitted()) {
      state = NotificationSettingsState(settings: cur, permissionDenied: true);
      return;
    }
    await _apply(cur.copyWith(budgetAlertsEnabled: on));
  }

  Future<void> setReminderHour(int hour) async {
    if (hour < 0 || hour > 23) return;
    await _apply(state.settings.copyWith(reminderHour: hour));
  }

  /// Sends an immediate test notification (asks permission first).
  Future<bool> sendTest() async {
    final gateway = ref.read(notificationGatewayProvider);
    if (!await gateway.requestPermission()) {
      state = NotificationSettingsState(
        settings: state.settings,
        permissionDenied: true,
      );
      return false;
    }
    final l10n = resolveAppLocalizations(ref.read(sharedPreferencesProvider));
    await gateway.show(
      id: stableNotificationId('test'),
      title: l10n.notificationsTestTitle,
      body: l10n.notificationsTestBody,
      kind: NotificationKind.test,
    );
    return true;
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
      NotificationSettingsNotifier.new,
    );
