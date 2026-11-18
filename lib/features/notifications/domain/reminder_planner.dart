import '../../../core/utils/date_keys.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/money.dart';
import 'notification_models.dart';

class RecurringReminderInput {
  const RecurringReminderInput({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.frequency,
    required this.intervalCount,
    required this.startDate,
    required this.endDate,
    required this.nextDueDate,
    required this.remindDaysBefore,
  });

  final int id;
  final String title;
  final int amountMinor;

  /// daily | weekly | monthly | yearly
  final String frequency;
  final int intervalCount;
  final String startDate;
  final String? endDate;
  final String nextDueDate;
  final int remindDaysBefore;
}

class DebtReminderInput {
  const DebtReminderInput({
    required this.id,
    required this.direction,
    required this.personName,
    required this.outstandingMinor,
    required this.dueDate,
  });

  final int id;

  /// lent | borrowed
  final String direction;
  final String personName;
  final int outstandingMinor;
  final String dueDate;
}

/// Pure planner: DB state + now => notifications to schedule.
class ReminderPlanner {
  const ReminderPlanner({
    this.horizonDays = 60,
    this.maxNotifications = 150,
    this.symbol = '৳',
  });

  final int horizonDays;
  final int maxNotifications;
  final String symbol;

  List<PlannedNotification> plan({
    required AppLocalizations l10n,
    required DateTime now,
    required List<RecurringReminderInput> rules,
    required List<DebtReminderInput> debts,
    int hour = 9,
  }) {
    final horizon = now.add(Duration(days: horizonDays));
    final out = <int, PlannedNotification>{};

    bool inWindow(DateTime t) => t.isAfter(now) && !t.isAfter(horizon);

    for (final r in rules) {
      if (r.remindDaysBefore < 0) continue;
      final occurrences = _occurrences(
        r,
        horizonEnd: horizon.add(Duration(days: r.remindDaysBefore + 1)),
      );
      for (final due in occurrences) {
        final fireDay = DateTime(
          due.year,
          due.month,
          due.day - r.remindDaysBefore,
        );
        final when = DateTime(fireDay.year, fireDay.month, fireDay.day, hour);
        if (!inWindow(when)) continue;
        final key = dateKey(due);
        final id = reminderNotificationId('recurring', r.id, key);
        final lead = r.remindDaysBefore;
        final amount = formatMinor(r.amountMinor, symbol: symbol);
        out[id] = PlannedNotification(
          id: id,
          when: when,
          title: l10n.notificationsUpcomingTitle(r.title),
          body: lead == 0
              ? l10n.notificationsDueToday(r.title, amount)
              : lead == 1
              ? l10n.notificationsDueTomorrow(r.title, amount)
              : l10n.notificationsDueInDays(r.title, amount, lead, key),
          kind: NotificationKind.recurring,
        );
      }
    }

    for (final d in debts) {
      if (d.outstandingMinor <= 0) continue;
      final due = _tryParse(d.dueDate);
      if (due == null) continue;
      final amount = formatMinor(d.outstandingMinor, symbol: symbol);
      for (final offset in const [1, 0]) {
        final day = DateTime(due.year, due.month, due.day - offset);
        final when = DateTime(day.year, day.month, day.day, hour);
        if (!inWindow(when)) continue;
        final id = reminderNotificationId('debt', d.id, '${d.dueDate}/$offset');
        final lent = d.direction == 'lent';
        out[id] = PlannedNotification(
          id: id,
          when: when,
          title: lent
              ? l10n.notificationsCollectTitle
              : l10n.notificationsDebtDueTitle,
          body: lent
              ? (offset == 0
                    ? l10n.notificationsOwesYouToday(d.personName, amount)
                    : l10n.notificationsOwesYouTomorrow(d.personName, amount))
              : (offset == 0
                    ? l10n.notificationsYouOweToday(d.personName, amount)
                    : l10n.notificationsYouOweTomorrow(d.personName, amount)),
          kind: NotificationKind.debt,
        );
      }
    }

    final list = out.values.toList()
      ..sort((a, b) {
        final c = a.when.compareTo(b.when);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return list.length > maxNotifications
        ? list.sublist(0, maxNotifications)
        : list;
  }

  static DateTime? _tryParse(String key) {
    try {
      return parseDateKey(key);
    } on FormatException {
      return null;
    }
  }

  /// Occurrence dates from nextDueDate on, up to [horizonEnd] / endDate.
  List<DateTime> _occurrences(
    RecurringReminderInput r, {
    required DateTime horizonEnd,
  }) {
    final first = _tryParse(r.nextDueDate);
    final start = _tryParse(r.startDate) ?? first;
    if (first == null || start == null) return const [];
    final end = r.endDate == null ? null : _tryParse(r.endDate!);
    final interval = r.intervalCount < 1 ? 1 : r.intervalCount;
    final result = <DateTime>[];
    for (var k = 0; k < 800; k++) {
      final DateTime d;
      switch (r.frequency) {
        case 'daily':
          d = DateTime(first.year, first.month, first.day + k * interval);
        case 'weekly':
          d = DateTime(first.year, first.month, first.day + 7 * k * interval);
        case 'monthly':
          d = _clamped(first.year, first.month + k * interval, start.day);
        case 'yearly':
          d = _clamped(first.year + k * interval, start.month, start.day);
        default:
          return result;
      }
      if (end != null && d.isAfter(end)) break;
      if (d.isAfter(horizonEnd)) break;
      result.add(d);
    }
    return result;
  }

  /// Day clamped to the month length; [month] may overflow past 12.
  static DateTime _clamped(int year, int month, int day) {
    final first = DateTime(year, month, 1);
    final dim = daysInMonth(first.year, first.month);
    return DateTime(first.year, first.month, day > dim ? dim : day);
  }
}
