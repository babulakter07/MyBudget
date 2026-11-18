import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/notifications/data/budget_alert_service.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_scheduler.dart';
import 'package:my_budget/features/notifications/domain/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_test_helpers.dart';

final _ts = DateTime(2026);

Future<void> addRule(
  AppDatabase db,
  int profileId,
  int accountId, {
  int? remind = 1,
  String next = '2026-11-30',
  bool active = true,
}) => db
    .into(db.recurringRules)
    .insert(
      RecurringRulesCompanion.insert(
        profileId: profileId,
        type: 'income',
        accountId: accountId,
        amountMinor: 500000,
        title: 'Rent',
        frequency: 'monthly',
        startDate: '2026-01-30',
        nextDueDate: next,
        remindDaysBefore: Value(remind),
        isActive: Value(active),
        createdAt: _ts,
        updatedAt: _ts,
      ),
    );

Future<int> addDebt(
  AppDatabase db,
  int profileId, {
  int principal = 100000,
  String? due = '2026-11-25',
}) => db
    .into(db.debts)
    .insert(
      DebtsCompanion.insert(
        profileId: profileId,
        direction: 'borrowed',
        personName: 'Rahim',
        principalMinor: principal,
        startDate: '2026-10-01',
        dueDate: Value(due),
        createdAt: _ts,
        updatedAt: _ts,
      ),
    );

void main() {
  final now = DateTime(2026, 11, 18, 8);
  late AppDatabase db;
  late SharedPreferences prefs;
  late FakeNotificationGateway gateway;
  late NotificationScheduler scheduler;
  late int pid;
  late int acc;

  Future<void> enable({bool reminders = true, bool budget = true, int h = 9}) =>
      NotificationSettings(
        remindersEnabled: reminders,
        budgetAlertsEnabled: budget,
        reminderHour: h,
      ).save(prefs);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.memory();
    gateway = FakeNotificationGateway();
    pid = await addProfile(db);
    acc = await addAccount(db, pid, 'Cash');
    scheduler = NotificationScheduler(
      db: db,
      prefs: prefs,
      gateway: gateway,
      activeProfileId: () => pid,
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  group('scheduler', () {
    test('schedules rules and debts; idempotent on repeat', () async {
      await enable();
      await addRule(db, pid, acc);
      await addDebt(db, pid);
      await scheduler.resync();
      final first = Map.of(gateway.scheduled);
      // rule: Nov 29, Dec 30 (+ Jan 29 > 60d? no: Jan 17 limit) ; debt: 2
      expect(first.length, 4);
      expect(gateway.scheduleCalls, 4);
      expect(gateway.cancelCalls, 0);

      await scheduler.resync();
      expect(gateway.scheduled.keys.toSet(), first.keys.toSet());
      expect(gateway.cancelCalls, 4);
      expect(gateway.scheduleCalls, 8);
      expect(gateway.scheduled.length, 4);
    });

    test('partially paid debt still fires; fully paid does not', () async {
      await enable();
      final id = await addDebt(db, pid, principal: 100000);
      await db
          .into(db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              profileId: pid,
              debtId: id,
              amountMinor: 40000,
              paymentDate: '2026-11-10',
              createdAt: _ts,
            ),
          );
      await scheduler.resync();
      expect(gateway.scheduled.length, 2);
      expect(gateway.scheduled.values.first.body, contains('600.00'));

      await db
          .into(db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              profileId: pid,
              debtId: id,
              amountMinor: 60000,
              paymentDate: '2026-11-11',
              createdAt: _ts,
            ),
          );
      await scheduler.resync();
      expect(gateway.scheduled, isEmpty);
    });

    test(
      'ignores rules without reminder, inactive rules, other profile',
      () async {
        await enable();
        await addRule(db, pid, acc, remind: null);
        await addRule(db, pid, acc, active: false);
        final other = await addProfile(db, 'Other');
        final otherAcc = await addAccount(db, other, 'Cash');
        await addRule(db, other, otherAcc);
        await scheduler.resync();
        expect(gateway.scheduled, isEmpty);
      },
    );

    test('reminders off cancels everything and schedules nothing', () async {
      await enable();
      await addRule(db, pid, acc);
      await scheduler.resync();
      expect(gateway.scheduled, isNotEmpty);
      await enable(reminders: false);
      await scheduler.resync();
      expect(gateway.scheduled, isEmpty);
    });

    test('hour setting is honoured', () async {
      await enable(h: 18);
      await addDebt(db, pid);
      await scheduler.resync();
      expect(gateway.scheduled.values.every((n) => n.when.hour == 18), isTrue);
    });
  });

  group('budget alerts', () {
    late BudgetAlertService svc;
    late int cat;
    final nov = DateTime(2026, 11, 18);

    setUp(() async {
      svc = BudgetAlertService(db: db, prefs: prefs, gateway: gateway);
      cat = await addCategory(db, pid, 'Food');
      await addBudget(db, pid, 2026, 11, 100000);
    });

    Future<void> spend(int amount, {String date = '2026-11-10'}) => addTxn(
      db,
      profileId: pid,
      type: 'expense',
      accountId: acc,
      amount: amount,
      date: date,
      categoryId: cat,
      category: 'Food',
    );

    test('below 80% fires nothing', () async {
      await enable();
      await spend(79000);
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown, isEmpty);
    });

    test('80% fires once, 100% fires once more, never repeats', () async {
      await enable();
      await spend(80000);
      await svc.evaluate(pid, now: nov);
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown.length, 1);
      expect(gateway.shown.single.title, contains('warning'));

      await spend(30000);
      await svc.evaluate(pid, now: nov);
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown.length, 2);
      expect(gateway.shown.last.title, contains('Over budget'));
    });

    test(
      'jumping straight past 100% fires only the over-budget alert',
      () async {
        await enable();
        await spend(120000);
        await svc.evaluate(pid, now: nov);
        await svc.evaluate(pid, now: nov);
        expect(gateway.shown.length, 1);
        expect(gateway.shown.single.title, contains('Over budget'));
      },
    );

    test('category budgets alert independently', () async {
      await enable();
      final mb = await (db.select(db.monthlyBudgets)).getSingle();
      await db
          .into(db.categoryBudgets)
          .insert(
            CategoryBudgetsCompanion.insert(
              profileId: pid,
              monthlyBudgetId: mb.id,
              categoryId: cat,
              amountMinor: 10000,
              createdAt: _ts,
              updatedAt: _ts,
            ),
          );
      await spend(9000); // 90% of category, 9% of total
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown.length, 1);
      expect(gateway.shown.single.title, contains('Food'));
    });

    test('month rollover resets dedupe', () async {
      await enable();
      await addBudget(db, pid, 2026, 12, 100000);
      await spend(90000);
      await spend(90000, date: '2026-12-02');
      await svc.evaluate(pid, now: nov);
      await svc.evaluate(pid, now: DateTime(2026, 12, 5));
      expect(gateway.shown.length, 2);
    });

    test('deleted, income and transfer rows do not count', () async {
      await enable();
      await addTxn(
        db,
        profileId: pid,
        type: 'expense',
        accountId: acc,
        amount: 95000,
        date: '2026-11-03',
        categoryId: cat,
        category: 'Food',
        deleted: true,
      );
      await addTxn(
        db,
        profileId: pid,
        type: 'income',
        accountId: acc,
        amount: 95000,
        date: '2026-11-03',
      );
      final acc2 = await addAccount(db, pid, 'Bank');
      await addTxn(
        db,
        profileId: pid,
        type: 'transfer',
        accountId: acc,
        toAccountId: acc2,
        toAccountName: 'Bank',
        amount: 95000,
        date: '2026-11-03',
      );
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown, isEmpty);
    });

    test('toggle off => nothing, and nothing is marked as fired', () async {
      await enable(budget: false);
      await spend(150000);
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown, isEmpty);
      await enable();
      await svc.evaluate(pid, now: nov);
      expect(gateway.shown.length, 1);
    });

    test('no monthly budget => nothing', () async {
      await enable();
      await svc.evaluate(pid, now: DateTime(2027, 5, 1));
      expect(gateway.shown, isEmpty);
    });
  });
}
