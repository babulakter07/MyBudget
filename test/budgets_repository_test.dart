import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/budgets/data/budget_repository.dart';
import 'package:my_budget/features/budgets/domain/budget.dart';

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime.now();
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<int> _category(
  AppDatabase db,
  int profileId,
  String name, {
  bool active = true,
}) {
  final now = DateTime.now();
  return db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: profileId,
          name: name,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<int> _account(AppDatabase db, int profileId) {
  final now = DateTime.now();
  return db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Cash',
          openingDate: '2020-01-01',
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _expense(
  AppDatabase db, {
  required int profileId,
  required int accountId,
  required int categoryId,
  required int amount,
  required String date,
  bool deleted = false,
  String type = 'expense',
}) {
  final now = DateTime.now();
  return db
      .into(db.financialTransactions)
      .insert(
        FinancialTransactionsCompanion.insert(
          profileId: profileId,
          type: type,
          accountId: accountId,
          categoryId: Value(type == 'expense' ? categoryId : null),
          accountNameSnapshot: 'Cash',
          amountMinor: amount,
          txnDate: date,
          isDeleted: Value(deleted),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late BudgetRepository repo;
  late int p1, p2, acc, food, rent;

  setUp(() async {
    db = AppDatabase.memory();
    repo = BudgetRepository(db);
    p1 = await _profile(db, 'A');
    p2 = await _profile(db, 'B');
    acc = await _account(db, p1);
    food = await _category(db, p1, 'Food');
    rent = await _category(db, p1, 'Rent');
  });
  tearDown(() => db.close());

  Future<void> setTotal(int total, {int y = 2026, int m = 5, int? p}) =>
      repo.setMonthlyBudget(
        profileId: p ?? p1,
        year: y,
        month: m,
        totalMinor: total,
      );

  Future<void> alloc(int cat, int amt, {int y = 2026, int m = 5}) =>
      repo.setCategoryAllocation(
        profileId: p1,
        year: y,
        month: m,
        categoryId: cat,
        amountMinor: amt,
      );

  Future<void> spend(int amt, String date, {int? cat, bool deleted = false}) =>
      _expense(
        db,
        profileId: p1,
        accountId: acc,
        categoryId: cat ?? food,
        amount: amt,
        date: date,
        deleted: deleted,
      );

  group('BudgetSummary (pure)', () {
    test('remaining, utilization, overspend', () {
      const s = BudgetSummary(budgetMinor: 100000, expenseMinor: 25000);
      expect(s.remainingMinor, 75000);
      expect(s.utilizationPercent, 25);
      const o = BudgetSummary(budgetMinor: 100000, expenseMinor: 150000);
      expect(o.remainingMinor, -50000);
      expect(o.isOverspent, isTrue);
      expect(o.utilizationPercent, 150);
    });

    test('zero budget never divides by zero', () {
      const z = BudgetSummary(budgetMinor: 0, expenseMinor: 500);
      expect(z.utilizationPercent, 0);
      expect(z.remainingMinor, -500);
      const e = BudgetSummary(budgetMinor: 0, expenseMinor: 0);
      expect(e.utilizationPercent, 0);
    });
  });

  group('monthly budget', () {
    test('upsert keeps one row per month', () async {
      await setTotal(100000);
      await setTotal(200000);
      expect(await repo.getMonthlyTotal(p1, 2026, 5), 200000);
      expect(await db.select(db.monthlyBudgets).get(), hasLength(1));
      await setTotal(300000, m: 6);
      expect(await db.select(db.monthlyBudgets).get(), hasLength(2));
    });

    test('negative rejected, zero allowed, bad month rejected', () async {
      expect(setTotal(-1), throwsA(isA<ValidationException>()));
      expect(setTotal(10, m: 13), throwsA(isA<ValidationException>()));
      expect(setTotal(10, m: 0), throwsA(isA<ValidationException>()));
      await setTotal(0);
      final mb = await repo.loadMonth(p1, 2026, 5);
      expect(mb.hasBudget, isTrue);
      expect(mb.summary.budgetMinor, 0);
    });

    test('profile isolated and FK enforced', () async {
      await setTotal(100000);
      expect(await repo.getMonthlyTotal(p2, 2026, 5), isNull);
      await setTotal(5, p: p2);
      expect(await repo.getMonthlyTotal(p1, 2026, 5), 100000);
      expect(setTotal(1, p: 9999), throwsA(anything));
    });

    test('negative remaining when overspent', () async {
      await setTotal(10000);
      await spend(15000, '2026-05-10');
      final mb = await repo.loadMonth(p1, 2026, 5);
      expect(mb.summary.expenseMinor, 15000);
      expect(mb.summary.remainingMinor, -5000);
      expect(mb.summary.utilizationPercent, 150);
    });

    test(
      'expense counted only in month, soft-deleted/income excluded',
      () async {
        await setTotal(100000);
        await spend(1000, '2026-05-01');
        await spend(2000, '2026-05-31');
        await spend(4000, '2026-04-30');
        await spend(8000, '2026-06-01');
        await spend(16000, '2026-05-15', deleted: true);
        await _expense(
          db,
          profileId: p1,
          accountId: acc,
          categoryId: food,
          amount: 32000,
          date: '2026-05-15',
          type: 'income',
        );
        final mb = await repo.loadMonth(p1, 2026, 5);
        expect(mb.summary.expenseMinor, 3000);
      },
    );

    test('other profile expenses are not counted', () async {
      final acc2 = await _account(db, p2);
      final c2 = await _category(db, p2, 'X');
      await _expense(
        db,
        profileId: p2,
        accountId: acc2,
        categoryId: c2,
        amount: 999,
        date: '2026-05-10',
      );
      await setTotal(1000);
      expect((await repo.loadMonth(p1, 2026, 5)).summary.expenseMinor, 0);
    });

    test('leap-year February 2028 and year boundary', () async {
      await setTotal(100000, y: 2028, m: 2);
      await spend(100, '2028-02-29');
      await spend(200, '2028-03-01');
      await spend(400, '2028-02-01');
      expect((await repo.loadMonth(p1, 2028, 2)).summary.expenseMinor, 500);
      // non-leap February has no 29th
      await spend(800, '2027-02-28');
      expect((await repo.loadMonth(p1, 2027, 2)).summary.expenseMinor, 800);
      // Dec / Jan boundary
      await spend(1000, '2026-12-31');
      await spend(2000, '2027-01-01');
      expect((await repo.loadMonth(p1, 2026, 12)).summary.expenseMinor, 1000);
      expect((await repo.loadMonth(p1, 2027, 1)).summary.expenseMinor, 2000);
    });

    test(
      'RESET: next month starts with no budget and nothing carries over',
      () async {
        await setTotal(100000);
        await alloc(food, 40000);
        await spend(30000, '2026-05-10');
        final next = await repo.loadMonth(p1, 2026, 6);
        expect(next.hasBudget, isFalse);
        expect(next.summary.budgetMinor, 0);
        expect(next.summary.remainingMinor, 0);
        expect(next.categories, isEmpty);
        expect(await repo.getMonthlyTotal(p1, 2026, 6), isNull);
        // history preserved
        expect(
          (await repo.loadMonth(p1, 2026, 5)).summary.remainingMinor,
          70000,
        );
      },
    );

    test('copyFromMonth is explicit and only into an empty month', () async {
      await setTotal(100000);
      await alloc(food, 40000);
      await repo.copyFromMonth(
        profileId: p1,
        fromYear: 2026,
        fromMonth: 5,
        toYear: 2026,
        toMonth: 6,
      );
      final mb = await repo.loadMonth(p1, 2026, 6);
      expect(mb.summary.budgetMinor, 100000);
      expect(mb.categories.single.allocationMinor, 40000);
      expect(
        repo.copyFromMonth(
          profileId: p1,
          fromYear: 2026,
          fromMonth: 5,
          toYear: 2026,
          toMonth: 6,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('category allocations', () {
    test(
      'upsert, summary with per-category spend, not added to total',
      () async {
        await setTotal(100000);
        await alloc(food, 30000);
        await alloc(food, 40000);
        await alloc(rent, 50000);
        await spend(45000, '2026-05-05');
        await spend(1000, '2026-05-06', cat: rent);
        final mb = await repo.loadMonth(p1, 2026, 5);
        expect(mb.summary.budgetMinor, 100000);
        expect(mb.allocatedMinor, 90000);
        expect(mb.categories, hasLength(2));
        final f = mb.categories.firstWhere((c) => c.categoryId == food);
        expect(f.allocationMinor, 40000);
        expect(f.spentMinor, 45000);
        expect(f.remainingMinor, -5000);
        final r = mb.categories.firstWhere((c) => c.categoryId == rent);
        expect(r.remainingMinor, 49000);
        expect(mb.summary.expenseMinor, 46000);
      },
    );

    test('sum exceeding total rejected, exact total allowed', () async {
      await setTotal(100000);
      await alloc(food, 60000);
      expect(alloc(rent, 40001), throwsA(isA<ValidationException>()));
      await alloc(rent, 40000);
      expect(alloc(food, 60001), throwsA(isA<ValidationException>()));
    });

    test('lowering total below allocations rejected', () async {
      await setTotal(100000);
      await alloc(food, 60000);
      expect(setTotal(50000), throwsA(isA<ValidationException>()));
      await setTotal(60000);
    });

    test('requires monthly budget, non-negative amount', () async {
      expect(alloc(food, 1), throwsA(isA<ValidationException>()));
      await setTotal(1000);
      expect(alloc(food, -1), throwsA(isA<ValidationException>()));
      await alloc(food, 0);
    });

    test('cross-profile and unknown category rejected', () async {
      final other = await _category(db, p2, 'Other');
      await setTotal(1000);
      expect(alloc(other, 10), throwsA(isA<ProfileMismatchException>()));
      expect(alloc(99999, 10), throwsA(isA<NotFoundException>()));
    });

    test('inactive category: new rejected, existing editable', () async {
      final old = await _category(db, p1, 'Old', active: false);
      await setTotal(10000);
      expect(alloc(old, 10), throwsA(isA<ValidationException>()));
      await alloc(food, 100);
      await (db.update(db.categories)..where((c) => c.id.equals(food))).write(
        const CategoriesCompanion(isActive: Value(false)),
      );
      await alloc(food, 200);
      expect(
        (await repo.loadMonth(p1, 2026, 5)).categories.single.allocationMinor,
        200,
      );
      expect((await repo.activeCategories(p1)).map((c) => c.name), ['Rent']);
    });

    test('remove allocation', () async {
      await setTotal(1000);
      await alloc(food, 100);
      await repo.removeCategoryAllocation(
        profileId: p1,
        year: 2026,
        month: 5,
        categoryId: food,
      );
      expect((await repo.loadMonth(p1, 2026, 5)).categories, isEmpty);
      expect(
        repo.removeCategoryAllocation(
          profileId: p1,
          year: 2026,
          month: 5,
          categoryId: food,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        repo.removeCategoryAllocation(
          profileId: p2,
          year: 2026,
          month: 5,
          categoryId: food,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  test('watchMonth reacts to transactions', () async {
    await setTotal(10000);
    final exp = expectLater(
      repo.watchMonth(p1, 2026, 5).map((m) => m.summary.expenseMinor),
      emitsInOrder([0, 700]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await spend(700, '2026-05-02');
    await exp;
  });
}
