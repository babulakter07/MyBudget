/// Stable Android channel ids/names (defined here, used by the real gateway).
class NotificationChannels {
  const NotificationChannels._();

  static const reminders = 'mybudget_reminders';
  static const remindersName = 'Bill & debt reminders';
  static const remindersDescription =
      'Upcoming recurring bills and debt due dates';
  static const budget = 'mybudget_budget_alerts';
  static const budgetName = 'Budget alerts';
  static const budgetDescription = 'Warnings when spending nears the budget';
}

enum NotificationKind { recurring, debt, budget, test }

/// One notification to be scheduled (or shown now).
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.kind,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
  final NotificationKind kind;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.when == when &&
      other.title == title &&
      other.body == body &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(id, when, title, body, kind);

  @override
  String toString() => 'PlannedNotification($id, $when, $title)';
}

/// Stable positive 31-bit id from [key] (FNV-1a). Same key => same id, so
/// rescheduling is idempotent.
int stableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Id for a scheduled reminder: kind + entity + date.
int reminderNotificationId(String kind, int entityId, String dateKey) =>
    stableNotificationId('$kind|$entityId|$dateKey');
