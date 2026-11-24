import 'package:shared_preferences/shared_preferences.dart';

/// The user's chosen sound for one notification channel.
///
/// [uri] null = the system default, '' = silent, otherwise a content URI
/// picked in the system ringtone dialog. [title] is the display name.
class NotificationSound {
  const NotificationSound({this.uri, this.title});

  static const systemDefault = NotificationSound();
  static const silent = NotificationSound(uri: '');

  final String? uri;
  final String? title;

  bool get isDefault => uri == null;
  bool get isSilent => uri == '';

  /// Suffix that makes the Android channel id unique per sound (a channel's
  /// sound cannot change after creation, so each sound gets its own channel).
  String get channelSuffix {
    if (isDefault) return '';
    if (isSilent) return '_silent';
    var hash = 0x811c9dc5;
    for (final unit in uri!.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '_${hash.toRadixString(16)}';
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSound && other.uri == uri && other.title == title;

  @override
  int get hashCode => Object.hash(uri, title);
}

class NotificationSounds {
  const NotificationSounds({
    this.reminders = NotificationSound.systemDefault,
    this.budget = NotificationSound.systemDefault,
  });

  static const _remindersUri = 'notif_sound_reminders_uri';
  static const _remindersTitle = 'notif_sound_reminders_title';
  static const _budgetUri = 'notif_sound_budget_uri';
  static const _budgetTitle = 'notif_sound_budget_title';

  final NotificationSound reminders;
  final NotificationSound budget;

  NotificationSounds copyWith({
    NotificationSound? reminders,
    NotificationSound? budget,
  }) => NotificationSounds(
    reminders: reminders ?? this.reminders,
    budget: budget ?? this.budget,
  );

  static NotificationSound _read(SharedPreferences p, String u, String t) =>
      NotificationSound(uri: p.getString(u), title: p.getString(t));

  static NotificationSounds load(SharedPreferences prefs) => NotificationSounds(
    reminders: _read(prefs, _remindersUri, _remindersTitle),
    budget: _read(prefs, _budgetUri, _budgetTitle),
  );

  static Future<void> _write(
    SharedPreferences p,
    String u,
    String t,
    NotificationSound s,
  ) async {
    if (s.uri == null) {
      await p.remove(u);
      await p.remove(t);
    } else {
      await p.setString(u, s.uri!);
      await p.setString(t, s.title ?? '');
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    await _write(prefs, _remindersUri, _remindersTitle, reminders);
    await _write(prefs, _budgetUri, _budgetTitle, budget);
  }
}
