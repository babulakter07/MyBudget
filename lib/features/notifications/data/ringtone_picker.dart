import 'package:flutter/services.dart';

import '../domain/notification_sound.dart';

/// Opens the phone's notification-sound picker. Returns null when cancelled.
abstract class RingtonePicker {
  Future<NotificationSound?> pick(NotificationSound current);
}

/// Native Android picker (see MainActivity.kt, channel `mybudget/ringtone`).
class PlatformRingtonePicker implements RingtonePicker {
  static const _channel = MethodChannel('mybudget/ringtone');

  @override
  Future<NotificationSound?> pick(NotificationSound current) async {
    final res = await _channel.invokeMapMethod<String, String>('pick', {
      'current': current.isDefault ? 'default' : current.uri,
    });
    if (res == null) return null;
    final uri = res['uri'] ?? '';
    if (uri == 'default') return NotificationSound.systemDefault;
    if (uri.isEmpty) return NotificationSound.silent;
    return NotificationSound(uri: uri, title: res['title']);
  }
}

class FakeRingtonePicker implements RingtonePicker {
  FakeRingtonePicker(this.result);
  NotificationSound? result;
  int calls = 0;

  @override
  Future<NotificationSound?> pick(NotificationSound current) async {
    calls++;
    return result;
  }
}
