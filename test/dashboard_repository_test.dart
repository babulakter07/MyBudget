import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/dashboard/data/dashboard_repository.dart';
import 'package:my_budget/features/dashboard/domain/dashboard_calculations.dart';

import 'ledger_test_helpers.dart';

void main() {
  late AppDatabase db;
  late DashboardRepository repo;
  late int p, acc;
  late int food, travel, sub;

  setUp(() async {
    db = AppDatabase.memory();
    repo = DashboardRepository(db);
    p = await addProfile(db);
    acc = await addAccount(db, p, 'Cash', opening: 100000);
    food = await addCategory(db, p, 'Food');
    travel = await addCategory(db, p, 'Travel');
    sub = await addSubCategory(db, p, food, 'Daily');
  });
  tearDown(() => db.close());

  Future<int> item(String name) => addCostItem(db, p, sub, name);

  Future<void> expense(
    int amount,
    String date, {
    int? cat,
    String catName = 'Food',
    int? itemId,
    String? itemName,
    int? profile,
    int? account,
    bool deleted = false,
  }) async {
    await addTxn(
      db,
      profileId: profile ?? p,
      type: 'expense',
      accountId: account ?? acc,
      amount: amount,
      date: date,
      categoryId: cat ?? food,
      category: catName,
      costItemId: itemId,
      costItem: itemName,
      deleted: deleted,
    );
  }

  Future<void> income(int amount, String date) => addTxn(
    db,
    profileId: p,
    type: 'income',
    accountId: acc,
    amount: amount,
    date: date,
  );

  test('empty month', () async {
    final o = await repo.watchMonthOverview(p, 2026, 3).first;
    expect(o.budgetMinor, 0);
    expect(o.expenseMinor, 0);
    expect(o.incomeMinor, 0);
    expect(o.hasBudget, isFalse);
    expect(await repo.watchTopCostItems(p, 2026, 3).first, isEmpty);
    expect(await repo.watchCategoryTotals(p, 2026, 3).first, isEmpty);
    expect(await repo.watchDailyExpenses(p, 2026, 3).first, isEmpty);
    expect(
      DashboardCalculations.highestDay(
        await repo.watchDailyExpenses(p, 2026, 3).first,
      ),
      isNull,
    );
  });

  test('overview with budget, negative remaining and deleted rows', () async {
    await addBudget(db, p, 2026, 3, 10000);
    await expense(7000, '2026-03-01');
    await expense(5000, '2026-03-31');
    await expense(9999, '2026-03-15', deleted: true);
    await expense(100, '2026-02-28');
    await expense(100, '2026-04-01');
    await income(25000, '2026-03-10');
    final o = await repo.watchMonthOverview(p, 2026, 3).first;
    expect(o.budgetMinor, 10000);
    expect(o.expenseMinor, 12000);
    expect(o.incomeMinor, 25000);
    expect(o.remainingMinor, -2000);
    expect(DashboardCalculations.utilizationPercent(10000, 12000), 120);
  });

  test('zero budget month keeps zero utilization', () async {
    await addBudget(db, p, 2026, 3, 0);
    await expense(500, '2026-03-02');
    final o = await repo.watchMonthOverview(p, 2026, 3).first;
    expect(o.budgetMinor, 0);
    expect(DashboardCalculations.utilizationPercent(o.budgetMinor, 500), 0);
    expect(o.remainingMinor, -500);
  });

  test('top five cost items and categories with ties and limit', () async {
    for (var i = 1; i <= 7; i++) {
      final id = await item('Item $i');
      await expense(
        i * 100,
        '2026-03-0$i',
        itemId: id,
        itemName: 'Item $i',
        cat: i.isEven ? travel : food,
        catName: i.isEven ? 'Travel' : 'Food',
      );
    }
    // Tie for 5th place: two items with 300 -> name order decides.
    final tieA = await item('Alpha');
    await expense(300, '2026-03-10', itemId: tieA, itemName: 'Alpha');
    // Expense without a cost item must not appear in top items.
    await expense(9000, '2026-03-11');
    final top = await repo.watchTopCostItems(p, 2026, 3).first;
    expect(top.map((e) => e.name), [
      'Item 7',
      'Item 6',
      'Item 5',
      'Item 4',
      'Alpha',
    ]);
    final cats = await repo.watchTopCategories(p, 2026, 3).first;
    // Food: 100+300+500+700+300+9000 = 10900; Travel: 200+400+600 = 1200
    expect(cats.map((e) => e.name), ['Food', 'Travel']);
    expect(cats.first.amountMinor, 10900);
    final all = await repo.watchCategoryTotals(p, 2026, 3).first;
    expect(all, hasLength(2));
    expect(all.fold(0, (s, e) => s + e.amountMinor), 12100);
  });

  test('highest spending day and average daily incl. leap February', () async {
    await expense(1000, '2028-02-03');
    await expense(1500, '2028-02-03');
    await expense(2000, '2028-02-29');
    await expense(100, '2028-03-01');
    final days = await repo.watchDailyExpenses(p, 2028, 2).first;
    expect(days.map((d) => d.date), ['2028-02-03', '2028-02-29']);
    final best = DashboardCalculations.highestDay(days)!;
    expect(best.date, '2028-02-03');
    expect(best.amountMinor, 2500);
    final o = await repo.watchMonthOverview(p, 2028, 2).first;
    expect(o.expenseMinor, 4500);
    expect(
      DashboardCalculations.averageDailyExpense(
        o.expenseMinor,
        2028,
        2,
        DateTime(2028, 7, 1),
      ),
      155, // 4500 / 29 = 155.17
    );
  });

  test('yearly totals always have 12 months incl. year boundary', () async {
    await expense(100, '2025-12-31');
    await expense(200, '2026-01-01');
    await expense(300, '2026-12-31');
    await expense(400, '2027-01-01');
    await income(5000, '2026-06-15');
    final t = await repo.watchYearlyTotals(p, 2026).first;
    expect(t.expenseByMonth, hasLength(12));
    expect(t.expenseByMonth[0], 200);
    expect(t.expenseByMonth[11], 300);
    expect(t.expenseByMonth.sublist(1, 11).every((v) => v == 0), isTrue);
    expect(t.incomeByMonth[5], 5000);
    final s = DashboardCalculations.yearlySummary(t);
    expect(s.totalExpenseMinor, 500);
    expect(s.highestMonth, 12);
    expect(s.lowestMonth, 1);
    expect(s.averageMonthlyExpenseMinor, 42); // 500/12 = 41.67
    final t25 = await repo.watchYearlyTotals(p, 2025).first;
    expect(t25.expenseByMonth[11], 100);
    final empty = await repo.watchYearlyTotals(p, 2030).first;
    expect(empty.expenseByMonth, everyElement(0));
    expect(empty.expenseByMonth, hasLength(12));
  });

  test(
    'cash balance is independent of budget and counts active only',
    () async {
      final bank = await addAccount(db, p, 'Bank', opening: 50000);
      final old = await addAccount(db, p, 'Old', opening: 7777, active: false);
      await addBudget(db, p, 2026, 3, 1);
      await income(20000, '2026-03-01');
      await expense(5000, '2026-03-02');
      // Between two active accounts: nets to zero.
      await addTxn(
        db,
        profileId: p,
        type: 'transfer',
        accountId: acc,
        toAccountId: bank,
        amount: 3000,
        date: '2026-03-03',
      );
      // To an inactive account: leaves the active total.
      await addTxn(
        db,
        profileId: p,
        type: 'transfer',
        accountId: bank,
        toAccountId: old,
        amount: 1000,
        date: '2026-03-04',
      );
      // Before the opening date: ignored.
      await addTxn(
        db,
        profileId: p,
        type: 'income',
        accountId: acc,
        amount: 123456,
        date: '2025-12-31',
      );
      await expense(900, '2026-03-05', deleted: true);
      final cash = await repo.watchCashBalance(p).first;
      expect(cash, 100000 + 50000 + 20000 - 5000 - 1000);
    },
  );

  test('cross-profile isolation and no accounts', () async {
    final p2 = await addProfile(db, 'Q');
    expect(await repo.watchCashBalance(p2).first, 0);
    final a2 = await addAccount(db, p2, 'Other', opening: 10);
    final c2 = await addCategory(db, p2, 'Z');
    await addTxn(
      db,
      profileId: p2,
      type: 'expense',
      accountId: a2,
      amount: 777,
      date: '2026-03-01',
      categoryId: c2,
      category: 'Z',
    );
    expect((await repo.watchMonthOverview(p, 2026, 3).first).expenseMinor, 0);
    expect(
      (await repo.watchMonthOverview(p2, 2026, 3).first).expenseMinor,
      777,
    );
    expect(await repo.watchCashBalance(p2).first, 10 - 777);
    expect(await repo.watchCategoryTotals(p, 2026, 3).first, isEmpty);
    final y = await repo.watchYearlyTotals(p, 2026).first;
    expect(y.expenseByMonth, everyElement(0));
  });
}
