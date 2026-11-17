import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/reports/data/reports_repository.dart';

import 'reports_helpers.dart';

void main() {
  late AppDatabase db;
  late ReportsRepository repo;
  late int p, cat, sub, item, acc;

  setUp(() async {
    db = AppDatabase.memory();
    repo = ReportsRepository(db);
    p = await addProfile(db, 'Home');
    cat = await addCategory(db, p, 'Food');
    sub = await addSub(db, p, cat, 'Groceries');
    item = await addItem(db, p, sub, 'Rice');
    acc = await addAccount(db, p, 'Cash');
  });
  tearDown(() => db.close());

  Future<void> exp(String date, int amount, {int? c, int? s, int? i}) =>
      addExpense(
        db,
        p,
        account: acc,
        category: c ?? cat,
        sub: s ?? sub,
        item: i ?? item,
        amount: amount,
        date: date,
        subName: 'Groceries',
        itemName: 'Rice',
      );

  group('monthly', () {
    test('totals, budget, remaining, utilization, breakdowns', () async {
      await addIncome(db, p, account: acc, amount: 5000000, date: '2026-03-01');
      await exp('2026-03-02', 120000);
      await exp('2026-03-02', 30050);
      await exp('2026-03-31', 50000);
      await addBudget(db, p, 2026, 3, 400000);
      final r = await repo.monthly(p, 2026, 3);
      expect(r.incomeMinor, 5000000);
      expect(r.expenseMinor, 200050);
      expect(r.budgetMinor, 400000);
      expect(r.remainingMinor, 199950);
      expect(r.utilizationPermille, 500); // 50.0% (200050/400000 = 50.01%)
      expect(r.categories.single.name, 'Food');
      expect(r.categories.single.amountMinor, 200050);
      expect(r.subCategories.single.amountMinor, 200050);
      expect(r.items.single.name, 'Rice');
      expect(r.daily.length, 31);
      expect(r.daily[1].amountMinor, 150050);
      expect(r.daily[30].amountMinor, 50000);
      expect(r.daily[0].amountMinor, 0);
    });

    test('empty month', () async {
      final r = await repo.monthly(p, 2026, 5);
      expect(r.isEmpty, isTrue);
      expect(r.budgetMinor, isNull);
      expect(r.remainingMinor, isNull);
      expect(r.utilizationPermille, isNull);
      expect(r.categories, isEmpty);
      expect(r.daily.length, 31);
      expect(r.daily.every((d) => d.amountMinor == 0), isTrue);
    });

    test('zero budget is safe (no divide by zero)', () async {
      await addBudget(db, p, 2026, 3, 0);
      await exp('2026-03-05', 1000);
      final r = await repo.monthly(p, 2026, 3);
      expect(r.budgetMinor, 0);
      expect(r.utilizationPermille, isNull);
      expect(r.remainingMinor, -1000);
    });

    test('negative remaining when overspent', () async {
      await addBudget(db, p, 2026, 3, 10000);
      await exp('2026-03-05', 25000);
      final r = await repo.monthly(p, 2026, 3);
      expect(r.remainingMinor, -15000);
      expect(r.utilizationPermille, 2500);
    });

    for (final c in [
      (2026, 2, 28),
      (2028, 2, 29),
      (2026, 4, 30),
      (2026, 12, 31),
    ]) {
      test('daily series has ${c.$3} entries for ${c.$1}-${c.$2}', () async {
        final r = await repo.monthly(p, c.$1, c.$2);
        expect(r.daily.length, c.$3);
        expect(r.daily.first.date, endsWith('-01'));
        expect(r.daily.last.date, endsWith('-${c.$3}'));
      });
    }

    test('Dec 31 / Jan 1 boundary', () async {
      await exp('2026-12-31', 100);
      await exp('2027-01-01', 200);
      final dec = await repo.monthly(p, 2026, 12);
      final jan = await repo.monthly(p, 2027, 1);
      expect(dec.expenseMinor, 100);
      expect(jan.expenseMinor, 200);
      expect(dec.daily.last.amountMinor, 100);
      expect(jan.daily.first.amountMinor, 200);
    });

    test('deleted rows are excluded everywhere', () async {
      await exp('2026-03-05', 1000);
      await addExpense(
        db,
        p,
        account: acc,
        category: cat,
        amount: 9999,
        date: '2026-03-05',
        deleted: true,
      );
      await addIncome(
        db,
        p,
        account: acc,
        amount: 7777,
        date: '2026-03-05',
        deleted: true,
      );
      final r = await repo.monthly(p, 2026, 3);
      expect(r.expenseMinor, 1000);
      expect(r.incomeMinor, 0);
      expect(r.accounts.single.expenseMinor, 1000);
      final y = await repo.yearly(p, 2026);
      expect(y.expenseMinor, 1000);
      final g = await repo.range(p, '2026-03-01', '2026-03-31');
      expect(g.expenseMinor, 1000);
    });

    test('profiles are isolated', () async {
      final p2 = await addProfile(db, 'Other');
      final c2 = await addCategory(db, p2, 'Food');
      final a2 = await addAccount(db, p2, 'Cash');
      await addExpense(
        db,
        p2,
        account: a2,
        category: c2,
        amount: 5555,
        date: '2026-03-05',
      );
      await addBudget(db, p2, 2026, 3, 99999);
      await exp('2026-03-05', 1000);
      final r = await repo.monthly(p, 2026, 3);
      expect(r.expenseMinor, 1000);
      expect(r.budgetMinor, isNull);
      expect(r.accounts.length, 1);
      final r2 = await repo.monthly(p2, 2026, 3);
      expect(r2.expenseMinor, 5555);
      expect(r2.budgetMinor, 99999);
      expect(r2.profileName, 'Other');
    });

    test('grouped by ids but displays snapshot name; uncategorised', () async {
      await exp('2026-03-01', 100);
      // Same category id, renamed snapshot later.
      await addExpense(
        db,
        p,
        account: acc,
        category: cat,
        sub: sub,
        item: item,
        amount: 50,
        date: '2026-03-04',
        categoryName: 'Food (old)',
        subName: 'Groceries',
        itemName: 'Rice',
      );
      // Expense without sub-category / item.
      await addExpense(
        db,
        p,
        account: acc,
        category: cat,
        amount: 25,
        date: '2026-03-03',
      );
      final r = await repo.monthly(p, 2026, 3);
      expect(r.categories.length, 1);
      expect(r.categories.single.amountMinor, 175);
      expect(r.categories.single.name, 'Food (old)'); // latest snapshot
      expect(r.subCategories.length, 2);
      expect(r.subCategories.any((s) => s.name == noSubCategoryLabel), isTrue);
      expect(r.items.any((i) => i.name == noItemLabel), isTrue);
    });

    test('account movements with transfers and carry-in', () async {
      final bank = await addAccount(
        db,
        p,
        'Bank',
        opening: 100000,
        openingDate: '2026-01-01',
      );
      await addIncome(db, p, account: acc, amount: 50000, date: '2026-02-10');
      await addTransfer(
        db,
        p,
        from: acc,
        to: bank,
        amount: 20000,
        date: '2026-02-15',
      ); // before month: carry-in
      await addIncome(db, p, account: acc, amount: 10000, date: '2026-03-01');
      await exp('2026-03-02', 3000);
      await addTransfer(
        db,
        p,
        from: acc,
        to: bank,
        amount: 5000,
        date: '2026-03-03',
      );
      await addTransfer(
        db,
        p,
        from: bank,
        to: acc,
        amount: 1000,
        date: '2026-03-04',
      );
      final r = await repo.monthly(p, 2026, 3);
      final cash = r.accounts.firstWhere((a) => a.accountName == 'Cash');
      final b = r.accounts.firstWhere((a) => a.accountName == 'Bank');
      expect(cash.openingMinor, 30000); // 0 + 50000 - 20000
      expect(cash.incomeMinor, 10000);
      expect(cash.expenseMinor, 3000);
      expect(cash.transferOutMinor, 5000);
      expect(cash.transferInMinor, 1000);
      expect(cash.closingMinor, 30000 + 10000 - 3000 + 1000 - 5000);
      expect(b.openingMinor, 120000);
      expect(b.transferInMinor, 5000);
      expect(b.transferOutMinor, 1000);
      expect(b.closingMinor, 124000);
      // Transfers never count as income/expense.
      expect(r.incomeMinor, 10000);
      expect(r.expenseMinor, 3000);
    });

    test('account opened after the month is omitted', () async {
      await addAccount(db, p, 'Future', openingDate: '2030-01-01');
      final r = await repo.monthly(p, 2026, 3);
      expect(r.accounts.map((a) => a.accountName), ['Cash']);
    });

    test('validation', () async {
      expect(
        () => repo.monthly(p, 2026, 13),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.monthly(p, 2026, 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.monthly(999, 2026, 1),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('yearly', () {
    test('always 12 rows including empty months', () async {
      final empty = await repo.yearly(p, 2026);
      expect(empty.months.length, 12);
      expect(empty.months.map((m) => m.month), List.generate(12, (i) => i + 1));
      expect(empty.isEmpty, isTrue);
      expect(empty.highestSpendingMonth, isNull);
      expect(empty.lowestSpendingMonth, isNull);
      expect(empty.averageMonthlyExpenseMinor, 0);
      expect(empty.budgetMinor, isNull);

      await exp('2026-06-10', 100);
      final y = await repo.yearly(p, 2026);
      expect(y.months.length, 12);
      expect(y.months[5].expenseMinor, 100);
      expect(y.months[0].expenseMinor, 0);
    });

    test('totals, budgets, highest/lowest, average, category matrix', () async {
      await exp('2026-01-31', 30000);
      await exp('2026-02-01', 10000);
      await exp('2026-02-10', 5000);
      await exp('2026-12-31', 60000);
      await exp('2027-01-01', 77777); // other year
      await addIncome(db, p, account: acc, amount: 900000, date: '2026-05-05');
      await addBudget(db, p, 2026, 1, 50000);
      await addBudget(db, p, 2026, 2, 20000);
      await addBudget(db, p, 2027, 1, 12345); // other year
      final y = await repo.yearly(p, 2026);
      expect(y.expenseMinor, 105000);
      expect(y.incomeMinor, 900000);
      expect(y.budgetMinor, 70000);
      expect(y.remainingMinor, 70000 - 105000);
      expect(y.highestSpendingMonth!.month, 12);
      expect(y.lowestSpendingMonth!.month, 2); // 15000 < 30000 < 60000
      expect(y.averageMonthlyExpenseMinor, 8750);
      expect(y.months[0].budgetMinor, 50000);
      expect(y.months[2].budgetMinor, isNull);
      expect(y.categories.single.monthlyMinor.length, 12);
      expect(y.categories.single.monthlyMinor[0], 30000);
      expect(y.categories.single.monthlyMinor[1], 15000);
      expect(y.categories.single.monthlyMinor[11], 60000);
      expect(y.categories.single.totalMinor, 105000);
    });

    test('lowest ignores months without expense', () async {
      await exp('2026-03-03', 500);
      final y = await repo.yearly(p, 2026);
      expect(y.lowestSpendingMonth!.month, 3);
      expect(y.highestSpendingMonth!.month, 3);
    });

    test('profile isolation', () async {
      final p2 = await addProfile(db, 'Other');
      final c2 = await addCategory(db, p2, 'Food');
      final a2 = await addAccount(db, p2, 'Cash');
      await addExpense(
        db,
        p2,
        account: a2,
        category: c2,
        amount: 4242,
        date: '2026-04-04',
      );
      final y = await repo.yearly(p, 2026);
      expect(y.expenseMinor, 0);
    });
  });

  group('range', () {
    test('totals, breakdown, daily series, inclusive bounds', () async {
      await exp('2026-02-27', 100);
      await exp('2026-02-28', 200);
      await exp('2026-03-02', 300);
      await exp('2026-03-03', 999);
      await addIncome(db, p, account: acc, amount: 1000, date: '2026-03-01');
      final r = await repo.range(p, '2026-02-28', '2026-03-02');
      expect(r.expenseMinor, 500);
      expect(r.incomeMinor, 1000);
      expect(r.netMinor, 500);
      expect(r.daily.length, 3);
      expect(r.daily.map((d) => d.amountMinor), [200, 0, 300]);
      expect(r.categories.single.amountMinor, 500);
      expect(r.items.single.amountMinor, 500);
    });

    test('single day and leap day', () async {
      final r = await repo.range(p, '2028-02-29', '2028-02-29');
      expect(r.daily.length, 1);
      final r2 = await repo.range(p, '2028-02-28', '2028-03-01');
      expect(r2.daily.length, 3);
    });

    test('validation', () async {
      expect(
        () => repo.range(p, '2026-03-02', '2026-03-01'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.range(p, '2026-02-30', '2026-03-01'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.range(p, 'abc', '2026-03-01'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.range(p, '2026-3-1', '2026-03-01'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.range(999, '2026-03-01', '2026-03-02'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
