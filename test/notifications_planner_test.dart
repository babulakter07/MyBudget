import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/notifications/domain/notification_models.dart';
import 'package:my_budget/l10n/generated/app_localizations.dart';
import 'package:my_budget/features/notifications/domain/reminder_planner.dart';

RecurringReminderInput rule({
  int id = 1,
  String frequency = 'monthly',
  int interval = 1,
  String start = '2026-11-20',
  String? end,
  required String next,
  int remind = 1,
}) => RecurringReminderInput(
  id: id,
  title: 'Rent',
  amountMinor: 1200000,
  frequency: frequency,
  intervalCount: interval,
  startDate: start,
  endDate: end,
  nextDueDate: next,
  remindDaysBefore: remind,
);

DebtReminderInput debt({
  int id = 1,
  String direction = 'lent',
  int outstanding = 50000,
  String due = '2026-11-25',
}) => DebtReminderInput(
  id: id,
  direction: direction,
  personName: 'Karim',
  outstandingMinor: outstanding,
  dueDate: due,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bn = lookupAppLocalizations(const Locale('bn'));
  const planner = ReminderPlanner();
  final now = DateTime(2026, 11, 18, 8);

  test('monthly rule fires N days before at the chosen hour', () {
    final plan = planner.plan(
      l10n: en,
      now: now,
      rules: [rule(next: '2026-11-30', start: '2026-01-31', remind: 1)],
      debts: const [],
      hour: 7,
    );
    expect(plan.map((p) => p.when), [
      DateTime(2026, 11, 29, 7),
      DateTime(2026, 12, 30, 7), // Dec 31 due, 1 day before
    ]);
    expect(plan.first.body, contains('Rent'));
    expect(plan.first.body, contains('tomorrow'));
  });

  test('monthly anchor day 31 clamps to month end', () {
    final n = DateTime(2027, 1, 20, 8);
    final plan = planner.plan(
      l10n: en,
      now: n,
      rules: [rule(next: '2027-01-31', start: '2026-01-31', remind: 0)],
      debts: const [],
    );
    // Mar 31 is beyond the 60-day horizon.
    expect(plan.map((p) => p.when), [
      DateTime(2027, 1, 31, 9),
      DateTime(2027, 2, 28, 9),
    ]);
  });

  test('end date stops occurrences', () {
    final plan = planner.plan(
      l10n: en,
      now: now,
      rules: [rule(next: '2026-11-20', end: '2026-12-15', remind: 0)],
      debts: const [],
    );
    expect(plan.map((p) => p.when), [DateTime(2026, 11, 20, 9)]);
  });

  test('a fire time that passed today is shown now; earlier days skipped', () {
    final at = DateTime(2026, 11, 18, 10);
    final plan = planner.plan(
      l10n: en,
      now: at,
      rules: [rule(next: '2026-11-18', start: '2026-11-18', remind: 0)],
      debts: const [],
    );
    expect(plan.map((p) => p.when), [at, DateTime(2026, 12, 18, 9)]);
    expect(plan.first.catchUp, isTrue);
    expect(plan.last.catchUp, isFalse);

    // Already delivered once: never repeated.
    final again = planner.plan(
      l10n: en,
      now: at,
      rules: [rule(next: '2026-11-18', start: '2026-11-18', remind: 0)],
      debts: const [],
      catchUpDone: {plan.first.key},
    );
    expect(again.map((p) => p.when), [DateTime(2026, 12, 18, 9)]);
  });

  test('60-day horizon on a daily rule', () {
    final plan = planner.plan(
      l10n: en,
      now: now,
      rules: [rule(frequency: 'daily', next: '2026-11-18', remind: 0)],
      debts: const [],
    );
    expect(plan.length, 60);
    expect(plan.first.when, DateTime(2026, 11, 18, 9));
    expect(plan.last.when, DateTime(2027, 1, 16, 9));
  });

  test('weekly and yearly intervals', () {
    final weekly = planner.plan(
      l10n: en,
      now: now,
      rules: [
        rule(frequency: 'weekly', interval: 2, next: '2026-11-20', remind: 0),
      ],
      debts: const [],
    );
    expect(weekly.take(3).map((p) => p.when), [
      DateTime(2026, 11, 20, 9),
      DateTime(2026, 12, 4, 9),
      DateTime(2026, 12, 18, 9),
    ]);
    final yearly = planner.plan(
      l10n: en,
      now: now,
      rules: [
        rule(frequency: 'yearly', next: '2026-12-01', start: '2024-12-01'),
      ],
      debts: const [],
    );
    expect(yearly.single.when, DateTime(2026, 11, 30, 9));
  });

  test('debts: lent/borrowed text, due-1 and due day', () {
    final plan = planner.plan(
      l10n: en,
      now: now,
      rules: const [],
      debts: [
        debt(),
        debt(id: 2, direction: 'borrowed'),
      ],
    );
    expect(plan.length, 4);
    final lent = plan.where((p) => p.body.contains('owes you')).toList();
    final borrowed = plan.where((p) => p.body.startsWith('You owe')).toList();
    expect(lent.length, 2);
    expect(borrowed.length, 2);
    expect(lent.map((p) => p.when), [
      DateTime(2026, 11, 24, 9),
      DateTime(2026, 11, 25, 9),
    ]);
  });

  test('settled debt (outstanding 0) yields none', () {
    expect(
      planner.plan(
        l10n: en,
        now: now,
        rules: const [],
        debts: [debt(outstanding: 0)],
      ),
      isEmpty,
    );
  });

  test('ids are deterministic and distinct', () {
    final a = planner.plan(
      l10n: en,
      now: now,
      rules: const [],
      debts: [debt()],
    );
    final b = planner.plan(
      l10n: en,
      now: now,
      rules: const [],
      debts: [debt()],
    );
    expect(a, b);
    expect(a.map((p) => p.id).toSet().length, a.length);
    expect(
      reminderNotificationId('debt', 1, '2026-11-25'),
      reminderNotificationId('debt', 1, '2026-11-25'),
    );
    expect(
      reminderNotificationId('debt', 1, '2026-11-25'),
      isNot(reminderNotificationId('debt', 2, '2026-11-25')),
    );
    expect(reminderNotificationId('debt', 1, '2026-11-25'), greaterThan(-1));
  });

  test('text is localized (en and bn) while ids/times stay identical', () {
    final rules = [rule(next: '2026-11-30', start: '2026-01-31', remind: 1)];
    final debts = [debt(), debt(id: 2, direction: 'borrowed')];
    final a = planner.plan(l10n: en, now: now, rules: rules, debts: debts);
    final b = planner.plan(l10n: bn, now: now, rules: rules, debts: debts);
    expect(b.map((p) => p.id), a.map((p) => p.id));
    expect(b.map((p) => p.when), a.map((p) => p.when));
    expect(a.map((p) => p.title), contains('Upcoming: Rent'));
    final rent = b.firstWhere((p) => p.title == 'আসন্ন: Rent');
    expect(rent.body, contains('আগামীকাল'));
    expect(a.any((p) => p.title == 'Money to collect'), isTrue);
    expect(b.any((p) => p.title == 'আদায়যোগ্য টাকা'), isTrue);
    expect(b.any((p) => p.title == 'ঋণ পরিশোধের সময়'), isTrue);
  });
}
