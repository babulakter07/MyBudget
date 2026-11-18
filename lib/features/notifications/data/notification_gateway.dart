import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_models.dart';

/// Thin seam over the notification plugin so logic is testable.
abstract class NotificationGateway {
  Future<void> init();

  /// Asks for POST_NOTIFICATIONS (Android 13+). Returns whether granted.
  Future<bool> requestPermission();

  /// Schedules (inexact, no exact-alarm permission). Same id replaces.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.recurring,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();

  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.budget,
  });
}

/// Real implementation backed by flutter_local_notifications.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  @override
  Future<void> init() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC-based tz.local; times may be offset on odd devices.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialised = true;
  }

  NotificationDetails _details(NotificationKind kind) {
    final budget = kind == NotificationKind.budget;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        budget ? NotificationChannels.budget : NotificationChannels.reminders,
        budget
            ? NotificationChannels.budgetName
            : NotificationChannels.remindersName,
        channelDescription: budget
            ? NotificationChannels.budgetDescription
            : NotificationChannels.remindersDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.recurring,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details(kind),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.budget,
  }) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(kind),
    );
  }
}

/// In-memory fake for tests.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.permissionGranted = true});

  bool permissionGranted;
  int initCalls = 0;
  int permissionRequests = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int cancelAllCalls = 0;

  /// Currently pending scheduled notifications by id.
  final Map<int, PlannedNotification> scheduled = {};

  /// Everything shown immediately, in order.
  final List<PlannedNotification> shown = [];

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.recurring,
  }) async {
    scheduleCalls++;
    scheduled[id] = PlannedNotification(
      id: id,
      when: when,
      title: title,
      body: body,
      kind: kind,
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.budget,
  }) async {
    shown.add(
      PlannedNotification(
        id: id,
        when: DateTime.now(),
        title: title,
        body: body,
        kind: kind,
      ),
    );
  }
}
