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

  /// null = use the global "days before" setting; negative = never remind.
  final int? remindDaysBefore;
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

/// One unpaid loan installment or credit-card bill to remind about.
class DueItemInput {
  const DueItemInput({
    required this.source,
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.dueDate,
  });

  /// 'loan' | 'card'
  final String source;

  /// Loan id / card-bill id (with [dueDate] this identifies the reminder).
  final int id;

  /// Already localized display name, e.g. "City Bank installment #3".
  final String name;
  final int amountMinor;
  final String dueDate;
}

/// A running fixed-deposit instrument whose maturity is to be reminded.
class MaturityReminderInput {
  const MaturityReminderInput({
    required this.id,
    required this.schemeType,
    required this.instrumentNumber,
    required this.bankName,
    required this.principalMinor,
    required this.maturityDate,
  });

  /// Instrument (term) id.
  final int id;

  /// Display text of the scheme, e.g. 'FDR'.
  final String schemeType;
  final String instrumentNumber;
  final String bankName;
  final int principalMinor;
  final String maturityDate;
}

/// Days before maturity at which a deposit reminder fires (0 = on the day).
const fdrReminderOffsets = [7, 1, 0];

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
    List<DueItemInput> dueItems = const [],
    List<MaturityReminderInput> maturities = const [],
    int hour = 9,
    bool todayEnabled = true,
    bool recurringToday = false,
    int upcomingDays = 1,
    int expireAfterDays = 0,
    Set<String> catchUpDone = const {},
  }) {
    final horizon = now.add(Duration(days: horizonDays));
    final out = <int, PlannedNotification>{};

    bool inWindow(DateTime t) => t.isAfter(now) && !t.isAfter(horizon);

    // A reminder whose time already passed TODAY (e.g. a "1 day before" rule
    // saved after the reminder hour) is shown right away, once, rather than
    // being silently dropped.
    DateTime? slot(DateTime t, String key) {
      if (inWindow(t)) return t;
      final sameDay =
          t.year == now.year && t.month == now.month && t.day == now.day;
      if (!t.isAfter(now) && sameDay && !catchUpDone.contains(key)) return now;
      return null;
    }

    for (final r in rules) {
      final leadDays = r.remindDaysBefore ?? upcomingDays;
      if (leadDays < 0) continue;
      final occurrences = _occurrences(
        r,
        horizonEnd: horizon.add(Duration(days: leadDays + 1)),
      );
      for (final due in occurrences) {
        final fireDay = DateTime(due.year, due.month, due.day - leadDays);
        final fireAt = DateTime(fireDay.year, fireDay.month, fireDay.day, hour);
        final key = dateKey(due);
        final upPhase = leadDays == 0
            ? NotificationPhase.today
            : NotificationPhase.upcoming;
        final pkey = reminderKey('recurring', r.id, key, upPhase);
        final when = slot(fireAt, pkey);
        if (when == null) continue;
        final id = reminderNotificationId('recurring', r.id, key);
        final lead = leadDays;
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
          key: pkey,
          phase: upPhase,
          dueDate: key,
          catchUp: when != fireAt,
        );
        if (lead > 0 && recurringToday && todayEnabled) {
          final todayAt = DateTime(due.year, due.month, due.day, hour);
          final tkey = reminderKey(
            'recurring',
            r.id,
            key,
            NotificationPhase.today,
          );
          final todayWhen = slot(todayAt, tkey);
          if (todayWhen != null) {
            final tid = reminderNotificationId('recurring', r.id, '$key/t');
            out[tid] = PlannedNotification(
              id: tid,
              when: todayWhen,
              title: l10n.notificationsUpcomingTitle(r.title),
              body: l10n.notificationsDueToday(r.title, amount),
              kind: NotificationKind.recurring,
              key: tkey,
              phase: NotificationPhase.today,
              dueDate: key,
              catchUp: todayWhen != todayAt,
            );
          }
        }
      }
    }

    for (final d in debts) {
      if (d.outstandingMinor <= 0) continue;
      final due = _tryParse(d.dueDate);
      if (due == null) continue;
      final amount = formatMinor(d.outstandingMinor, symbol: symbol);
      final lent = d.direction == 'lent';
      final name = lent
          ? l10n.notificationsDebtLentName(d.personName)
          : l10n.notificationsDebtBorrowedName(d.personName);
      for (final phase in NotificationPhase.values) {
        final int offset = switch (phase) {
          NotificationPhase.upcoming => upcomingDays,
          NotificationPhase.today => 0,
          NotificationPhase.expired => -expireAfterDays,
        };
        if (phase == NotificationPhase.upcoming && upcomingDays <= 0) continue;
        if (phase == NotificationPhase.today && !todayEnabled) continue;
        if (phase == NotificationPhase.expired && expireAfterDays <= 0) {
          continue;
        }
        final day = DateTime(due.year, due.month, due.day - offset);
        final at = DateTime(day.year, day.month, day.day, hour);
        final dkey = reminderKey('debt', d.id, d.dueDate, phase);
        final when = slot(at, dkey);
        if (when == null) continue;
        final id = reminderNotificationId('debt', d.id, '${d.dueDate}/$offset');
        final String title;
        final String body;
        if (phase == NotificationPhase.expired) {
          title = l10n.notificationsItemExpiredTitle(name);
          body = l10n.notificationsItemExpiredBody(name, amount, d.dueDate);
        } else if (phase == NotificationPhase.upcoming && offset != 1) {
          title = l10n.notificationsItemUpcomingTitle(name);
          body = l10n.notificationsItemUpcomingBody(
            name,
            amount,
            offset,
            d.dueDate,
          );
        } else {
          title = lent
              ? l10n.notificationsCollectTitle
              : l10n.notificationsDebtDueTitle;
          body = lent
              ? (offset == 0
                    ? l10n.notificationsOwesYouToday(d.personName, amount)
                    : l10n.notificationsOwesYouTomorrow(d.personName, amount))
              : (offset == 0
                    ? l10n.notificationsYouOweToday(d.personName, amount)
                    : l10n.notificationsYouOweTomorrow(d.personName, amount));
        }
        out[id] = PlannedNotification(
          id: id,
          when: when,
          title: title,
          body: body,
          kind: NotificationKind.debt,
          key: dkey,
          phase: phase,
          dueDate: d.dueDate,
          catchUp: when != at,
        );
      }
    }

    for (final item in dueItems) {
      if (item.amountMinor <= 0) continue;
      final due = _tryParse(item.dueDate);
      if (due == null) continue;
      final amount = formatMinor(item.amountMinor, symbol: symbol);
      for (final phase in NotificationPhase.values) {
        final int offset = switch (phase) {
          NotificationPhase.upcoming => upcomingDays,
          NotificationPhase.today => 0,
          NotificationPhase.expired => -expireAfterDays,
        };
        if (phase == NotificationPhase.upcoming && upcomingDays <= 0) continue;
        if (phase == NotificationPhase.today && !todayEnabled) continue;
        if (phase == NotificationPhase.expired && expireAfterDays <= 0) {
          continue;
        }
        final day = DateTime(due.year, due.month, due.day - offset);
        final at = DateTime(day.year, day.month, day.day, hour);
        final k = reminderKey(item.source, item.id, item.dueDate, phase);
        final when = slot(at, k);
        if (when == null) continue;
        final id = stableNotificationId(k);
        out[id] = PlannedNotification(
          id: id,
          when: when,
          title: switch (phase) {
            NotificationPhase.upcoming => l10n.notificationsItemUpcomingTitle(
              item.name,
            ),
            NotificationPhase.today => l10n.notificationsItemTodayTitle(
              item.name,
            ),
            NotificationPhase.expired => l10n.notificationsItemExpiredTitle(
              item.name,
            ),
          },
          body: switch (phase) {
            NotificationPhase.upcoming => l10n.notificationsItemUpcomingBody(
              item.name,
              amount,
              offset,
              item.dueDate,
            ),
            NotificationPhase.today => l10n.notificationsItemTodayBody(
              item.name,
              amount,
            ),
            NotificationPhase.expired => l10n.notificationsItemExpiredBody(
              item.name,
              amount,
              item.dueDate,
            ),
          },
          kind: item.source == 'loan'
              ? NotificationKind.loan
              : NotificationKind.card,
          key: k,
          phase: phase,
          dueDate: item.dueDate,
          catchUp: when != at,
        );
      }
    }

    for (final m in maturities) {
      if (m.principalMinor <= 0) continue;
      final due = _tryParse(m.maturityDate);
      if (due == null) continue;
      final amount = formatMinor(m.principalMinor, symbol: symbol);
      for (final offset in fdrReminderOffsets) {
        if (offset == 0 && !todayEnabled) continue;
        final phase = offset == 0
            ? NotificationPhase.today
            : NotificationPhase.upcoming;
        final day = DateTime(due.year, due.month, due.day - offset);
        final at = DateTime(day.year, day.month, day.day, hour);
        // 'fdr7' / 'fdr1' / 'fdr0': one key per reminder so each can be
        // switched off on its own.
        final k = reminderKey('fdr$offset', m.id, m.maturityDate, phase);
        final when = slot(at, k);
        if (when == null) continue;
        final id = stableNotificationId(k);
        out[id] = PlannedNotification(
          id: id,
          when: when,
          title: l10n.notificationsFdrTitle(m.schemeType),
          body: switch (offset) {
            0 => l10n.notificationsFdrBodyToday(
              m.schemeType,
              m.instrumentNumber,
              m.bankName,
              amount,
            ),
            1 => l10n.notificationsFdrBodyTomorrow(
              m.schemeType,
              m.instrumentNumber,
              m.bankName,
              amount,
            ),
            _ => l10n.notificationsFdrBodyUpcoming(
              m.schemeType,
              m.instrumentNumber,
              m.bankName,
              offset,
              m.maturityDate,
              amount,
            ),
          },
          kind: NotificationKind.fdr,
          key: k,
          phase: phase,
          dueDate: m.maturityDate,
          catchUp: when != at,
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
