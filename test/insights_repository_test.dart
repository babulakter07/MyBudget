import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/insights/data/insights_repository.dart';
import 'package:my_budget/features/insights/domain/insights_models.dart';

import 'ledger_test_helpers.dart';

final _now = DateTime(2026, 3, 20);

void main() {
  late AppDatabase db;
  late InsightsRepository repo;
  late int acc;
  late int food;
  late int fun;
  late int rent;

  setUp(() async {
    db = AppDatabase.memory();
    repo = InsightsRepository(db);
    await addProfile(db, 'A');
    await addProfile(db, 'B');
    acc = await addAccount(db, 1, 'Cash');
    food = await addCategory(db, 1, 'Food');
    fun = await addCategory(db, 1, 'Fun');
    rent = await addCategory(db, 1, 'Rent');
  });
  tearDown(() => db.close());

  Future<void> exp(
    int cat,
    String name,
    int amt,
    String date, {
    int profile = 1,
    int? account,
    bool deleted = false,
    String? title,
  }) => addTxn(
    db,
    profileId: profile,
    type: 'expense',
    accountId: account ?? acc,
    amount: amt,
    date: date,
    categoryId: cat,
    category: name,
    title: title,
    deleted: deleted,
  );

  Future<Insights> run() => repo.compute(1, 2026, 3, now: _now);

  test('month vs previous month incl. new/absent categories', () async {
    await exp(food, 'Food', 11200, '2026-03-05');
    await exp(food, 'Food', 10000, '2026-02-05');
    await exp(fun, 'Fun', 2000, '2026-03-06');
    await exp(rent, 'Rent', 5000, '2026-02-01');
    final c = (await run()).comparison;
    expect(c.currentMinor, 13200);
    expect(c.previousMinor, 15000);
    expect(c.deltaMinor, -1800);
    expect(c.categories.map((x) => x.name), ['Rent', 'Fun', 'Food']);
    expect(c.categories.firstWhere((x) => x.name == 'Fun').percent, isNull);
  });

  test('empty month: no data, no crash', () async {
    final i = await run();
    expect(i.hasData, isFalse);
    expect(i.comparison.percent, isNull);
    expect(i.savings.rate, isNull);
    expect(i.weekdays, hasLength(7));
  });

  group('unusual', () {
    Future<void> history(int cat, String name, List<int> amts) async {
      for (var k = 0; k < amts.length; k++) {
        await exp(cat, name, amts[k], '2025-1${k % 3}-10');
      }
    }

    test('flags only above mean + 2sd', () async {
      await history(food, 'Food', [1000, 1100, 900, 1000, 1000, 1000]);
      await exp(food, 'Food', 1200, '2026-03-02', title: 'Feast');
      await exp(food, 'Food', 1100, '2026-03-03');
      final u = (await run()).unusual;
      expect(u, hasLength(1));
      expect(u.single.title, 'Feast');
      expect(u.single.usualMinor, 1000);
      expect(u.single.excessMinor, 200);
    });

    test('fewer than 5 samples skipped; deleted history ignored', () async {
      await history(fun, 'Fun', [1000, 1000, 1000, 1000]);
      await exp(fun, 'Fun', 1000, '2025-12-12', deleted: true);
      await exp(fun, 'Fun', 99999, '2026-03-02');
      expect((await run()).unusual, isEmpty);
    });

    test('limited to 5 and sorted by excess', () async {
      await history(food, 'Food', [1000, 1000, 1000, 1000, 1000, 1000]);
      for (var d = 1; d <= 7; d++) {
        await exp(food, 'Food', 1000 + d * 100, '2026-03-0$d');
      }
      final u = (await run()).unusual;
      expect(u, hasLength(5));
      expect(u.first.amountMinor, 1700);
      expect(u.last.amountMinor, 1300);
    });

    test('history older than 6 months does not count', () async {
      for (var k = 0; k < 6; k++) {
        await exp(food, 'Food', 1000, '2025-08-1$k');
      }
      await exp(food, 'Food', 9999, '2026-03-02');
      expect((await run()).unusual, isEmpty);
    });
  });

  group('forecast', () {
    setUp(() async {
      await exp(food, 'Food', 2000, '2026-03-02');
      await exp(food, 'Food', 14000, '2026-03-10');
    });

    test('only for the current month', () async {
      expect((await repo.compute(1, 2026, 2, now: _now)).forecast, isNull);
      expect((await run()).forecast, isNotNull);
    });

    test('math and status vs budget', () async {
      var f = (await run()).forecast!;
      expect(f.spentSoFarMinor, 16000);
      expect(f.dailyAverageMinor, 1000);
      expect(f.projectedMinor, 27000);
      expect(f.status, isNull);
      await addBudget(db, 1, 2026, 3, 20000);
      f = (await run()).forecast!;
      expect(f.status, ForecastStatus.overBudget);
      expect(f.overageMinor, 7000);
    });

    test('on track / at risk', () async {
      await addBudget(db, 1, 2026, 3, 40000);
      expect((await run()).forecast!.status, ForecastStatus.onTrack);
      await (db.update(db.monthlyBudgets))
          .write(const MonthlyBudgetsCompanion(totalBudgetMinor: Value(28000)));
      expect((await run()).forecast!.status, ForecastStatus.atRisk);
    });

    test('active recurring expense rules are included, others not', () async {
      Future<void> rule(
        int amt,
        String next, {
        bool active = true,
        String type = 'expense',
      }) => db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              profileId: 1,
              type: type,
              categoryId: Value(food),
              accountId: acc,
              amountMinor: amt,
              title: 'r',
              frequency: 'monthly',
              startDate: '2026-01-25',
              nextDueDate: next,
              isActive: Value(active),
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
      await rule(5000, '2026-03-25'); // counted
      await rule(7000, '2026-03-26', active: false); // inactive
      await rule(9000, '2026-04-25'); // already posted this month
      await rule(1000, '2026-03-25', type: 'income'); // not an expense
      final f = (await run()).forecast!;
      expect(f.recurringRemainingMinor, 5000);
      expect(f.projectedMinor, 32000);
    });
  });

  test('weekday buckets, last 90 days only, top items', () async {
    await exp(food, 'Food', 500, '2026-03-16', title: 'Rice'); // Monday
    await exp(food, 'Food', 300, '2026-03-16', title: 'Rice');
    await exp(food, 'Food', 100, '2026-03-17', title: 'Tea'); // Tuesday
    await exp(food, 'Food', 4000, '2025-11-01'); // > 90 days ago
    final i = await run();
    expect(i.weekdays[0].totalMinor, 800);
    expect(i.weekdays[1].totalMinor, 100);
    expect(i.weekdays.fold(0, (a, b) => a + b.totalMinor), 900);
    expect(i.topItems.first.name, 'Rice');
    expect(i.topItems.first.totalMinor, 800);
  });

  test('savings rate and zero income', () async {
    await exp(food, 'Food', 750, '2026-03-02');
    expect((await run()).savings.rate, isNull);
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: acc,
      amount: 1000,
      date: '2026-03-03',
    );
    expect((await run()).savings.rate, 0.25);
  });

  test('deleted rows are ignored everywhere', () async {
    await exp(food, 'Food', 9000, '2026-03-02', deleted: true);
    await exp(food, 'Food', 9000, '2026-02-02', deleted: true);
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: acc,
      amount: 9000,
      date: '2026-03-03',
      deleted: true,
    );
    final i = await run();
    expect(i.hasData, isFalse);
    expect(i.forecast!.spentSoFarMinor, 0);
    expect(i.savings.incomeMinor, 0);
    expect(i.topItems, isEmpty);
  });

  test('other profiles never leak in', () async {
    final acc2 = await addAccount(db, 2, 'Cash');
    final cat2 = await addCategory(db, 2, 'Food');
    await exp(cat2, 'Food', 9000, '2026-03-02', profile: 2, account: acc2);
    await exp(cat2, 'Food', 9000, '2026-02-02', profile: 2, account: acc2);
    await addBudget(db, 2, 2026, 3, 100);
    await exp(food, 'Food', 100, '2026-03-02');
    final i = await run();
    expect(i.comparison.currentMinor, 100);
    expect(i.comparison.previousMinor, 0);
    expect(i.forecast!.budgetMinor, 0);
    expect(i.topItems.single.totalMinor, 100);
    final other = await repo.compute(2, 2026, 3, now: _now);
    expect(other.comparison.currentMinor, 9000);
  });
}
