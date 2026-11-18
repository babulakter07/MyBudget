import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/budget.dart';

class BudgetRepository {
  BudgetRepository(this._db);
  final AppDatabase _db;

  void _validMonth(int year, int month) {
    if (year < 1970 || year > 9999 || month < 1 || month > 12) {
      throw ValidationException('Invalid budget month.');
    }
  }

  Future<MonthlyBudgetRow?> _row(int profileId, int year, int month) =>
      (_db.select(_db.monthlyBudgets)..where(
            (b) =>
                b.profileId.equals(profileId) &
                b.year.equals(year) &
                b.month.equals(month),
          ))
          .getSingleOrNull();

  /// Total budget for the month, or null when none is set (RESET rule).
  Future<int?> getMonthlyTotal(int profileId, int year, int month) async =>
      (await _row(profileId, year, month))?.totalBudgetMinor;

  Future<int> _allocatedSum(
    int profileId,
    int monthlyBudgetId, {
    int? excludeCategoryId,
  }) async {
    final rows =
        await (_db.select(_db.categoryBudgets)..where(
              (c) =>
                  c.profileId.equals(profileId) &
                  c.monthlyBudgetId.equals(monthlyBudgetId),
            ))
            .get();
    return rows
        .where((r) => r.categoryId != excludeCategoryId)
        .fold<int>(0, (s, r) => s + r.amountMinor);
  }

  /// Upsert the month's total. Zero is allowed. The total may not drop below
  /// the sum of existing category allocations.
  Future<void> setMonthlyBudget({
    required int profileId,
    required int year,
    required int month,
    required int totalMinor,
  }) async {
    _validMonth(year, month);
    if (totalMinor < 0) {
      throw ValidationException('Budget cannot be negative.');
    }
    await _db.transaction(() async {
      final now = DateTime.now();
      final existing = await _row(profileId, year, month);
      if (existing == null) {
        await _db
            .into(_db.monthlyBudgets)
            .insert(
              MonthlyBudgetsCompanion.insert(
                profileId: profileId,
                year: year,
                month: month,
                totalBudgetMinor: totalMinor,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return;
      }
      final allocated = await _allocatedSum(profileId, existing.id);
      if (allocated > totalMinor) {
        throw ValidationException(
          'Budget cannot be lower than the category allocations already set.',
        );
      }
      await (_db.update(_db.monthlyBudgets)..where(
            (b) => b.profileId.equals(profileId) & b.id.equals(existing.id),
          ))
          .write(
            MonthlyBudgetsCompanion(
              totalBudgetMinor: Value(totalMinor),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<void> setCategoryAllocation({
    required int profileId,
    required int year,
    required int month,
    required int categoryId,
    required int amountMinor,
  }) async {
    _validMonth(year, month);
    if (amountMinor < 0) {
      throw ValidationException('Allocation cannot be negative.');
    }
    await _db.transaction(() async {
      final budget = await _row(profileId, year, month);
      if (budget == null) {
        throw ValidationException('Set the monthly budget first.');
      }
      final cat = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (cat == null) throw NotFoundException('Category not found.');
      if (cat.profileId != profileId) {
        throw ProfileMismatchException(
          'Category belongs to a different profile.',
        );
      }
      final existing =
          await (_db.select(_db.categoryBudgets)..where(
                (c) =>
                    c.profileId.equals(profileId) &
                    c.monthlyBudgetId.equals(budget.id) &
                    c.categoryId.equals(categoryId),
              ))
              .getSingleOrNull();
      if (!cat.isActive && existing == null) {
        throw ValidationException('Category "${cat.name}" is inactive.');
      }
      final others = await _allocatedSum(
        profileId,
        budget.id,
        excludeCategoryId: categoryId,
      );
      if (others + amountMinor > budget.totalBudgetMinor) {
        throw ValidationException(
          'Category allocations cannot exceed the monthly budget.',
        );
      }
      final now = DateTime.now();
      if (existing == null) {
        await _db
            .into(_db.categoryBudgets)
            .insert(
              CategoryBudgetsCompanion.insert(
                profileId: profileId,
                monthlyBudgetId: budget.id,
                categoryId: categoryId,
                amountMinor: amountMinor,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(_db.categoryBudgets)..where(
              (c) => c.profileId.equals(profileId) & c.id.equals(existing.id),
            ))
            .write(
              CategoryBudgetsCompanion(
                amountMinor: Value(amountMinor),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  /// Removes an allocation (an allocation is not master/financial history).
  Future<void> removeCategoryAllocation({
    required int profileId,
    required int year,
    required int month,
    required int categoryId,
  }) async {
    final budget = await _row(profileId, year, month);
    if (budget == null) throw NotFoundException('No budget for this month.');
    final n =
        await (_db.delete(_db.categoryBudgets)..where(
              (c) =>
                  c.profileId.equals(profileId) &
                  c.monthlyBudgetId.equals(budget.id) &
                  c.categoryId.equals(categoryId),
            ))
            .go();
    if (n == 0) throw NotFoundException('Allocation not found.');
  }

  /// Explicit user action only: copies total + allocations into an EMPTY
  /// target month. Months never carry over automatically.
  Future<void> copyFromMonth({
    required int profileId,
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    _validMonth(toYear, toMonth);
    await _db.transaction(() async {
      final src = await _row(profileId, fromYear, fromMonth);
      if (src == null) throw NotFoundException('Source month has no budget.');
      if (await _row(profileId, toYear, toMonth) != null) {
        throw ValidationException('Target month already has a budget.');
      }
      await setMonthlyBudget(
        profileId: profileId,
        year: toYear,
        month: toMonth,
        totalMinor: src.totalBudgetMinor,
      );
      final allocs =
          await (_db.select(_db.categoryBudgets)..where(
                (c) =>
                    c.profileId.equals(profileId) &
                    c.monthlyBudgetId.equals(src.id),
              ))
              .get();
      for (final a in allocs) {
        final cat =
            await (_db.select(_db.categories)..where(
                  (c) =>
                      c.profileId.equals(profileId) & c.id.equals(a.categoryId),
                ))
                .getSingleOrNull();
        if (cat == null || !cat.isActive) continue;
        await setCategoryAllocation(
          profileId: profileId,
          year: toYear,
          month: toMonth,
          categoryId: a.categoryId,
          amountMinor: a.amountMinor,
        );
        // Keep the carry-over setting so a copied month continues the chain.
        if (a.rolloverEnabled) {
          final target = await _row(profileId, toYear, toMonth);
          await (_db.update(_db.categoryBudgets)..where(
                (c) =>
                    c.profileId.equals(profileId) &
                    c.monthlyBudgetId.equals(target!.id) &
                    c.categoryId.equals(a.categoryId),
              ))
              .write(
                const CategoryBudgetsCompanion(rolloverEnabled: Value(true)),
              );
        }
      }
    });
  }

  /// Active categories of the profile (for the allocation picker).
  Future<List<CategoryOption>> activeCategories(int profileId) async {
    final rows =
        await (_db.select(_db.categories)
              ..where(
                (c) => c.profileId.equals(profileId) & c.isActive.equals(true),
              )
              ..orderBy([(c) => OrderingTerm(expression: c.name.lower())]))
            .get();
    return [for (final r in rows) CategoryOption(id: r.id, name: r.name)];
  }

  Future<MonthBudget> loadMonth(int profileId, int year, int month) async {
    _validMonth(year, month);
    final start = monthStartKey(year, month);
    final end = monthEndKey(year, month);
    final budget = await _row(profileId, year, month);

    final spentRows = await _db
        .customSelect(
          'SELECT category_id AS cid, COALESCE(SUM(amount_minor), 0) AS s '
          'FROM financial_transactions '
          "WHERE profile_id = ? AND type = 'expense' AND is_deleted = 0 "
          'AND txn_date BETWEEN ? AND ? GROUP BY category_id',
          variables: [
            Variable.withInt(profileId),
            Variable.withString(start),
            Variable.withString(end),
          ],
        )
        .get();
    final spentBy = <int, int>{};
    var totalSpent = 0;
    for (final r in spentRows) {
      final s = r.read<int>('s');
      totalSpent += s;
      final cid = r.read<int?>('cid');
      if (cid != null) spentBy[cid] = s;
    }

    final cats = <CategoryBudgetSummary>[];
    if (budget != null) {
      final rows = await _db
          .customSelect(
            'SELECT cb.id AS id, cb.category_id AS cid, '
            'cb.amount_minor AS amt, cb.rollover_enabled AS ro, '
            'c.name AS name FROM category_budgets cb '
            'JOIN categories c ON c.profile_id = cb.profile_id '
            'AND c.id = cb.category_id '
            'WHERE cb.profile_id = ? AND cb.monthly_budget_id = ? '
            'ORDER BY lower(c.name)',
            variables: [
              Variable.withInt(profileId),
              Variable.withInt(budget.id),
            ],
          )
          .get();
      final anyRollover = rows.any((r) => r.read<int>('ro') != 0);
      final carry = anyRollover
          ? await _carryOvers(profileId, year, month)
          : const <int, int>{};
      for (final r in rows) {
        final cid = r.read<int>('cid');
        final ro = r.read<int>('ro') != 0;
        cats.add(
          CategoryBudgetSummary(
            categoryId: cid,
            categoryName: r.read<String>('name'),
            allocationMinor: r.read<int>('amt'),
            spentMinor: spentBy[cid] ?? 0,
            categoryBudgetId: r.read<int>('id'),
            rolloverEnabled: ro,
            carriedOverMinor: ro ? (carry[cid] ?? 0) : 0,
          ),
        );
      }
    }
    return MonthBudget(
      year: year,
      month: month,
      hasBudget: budget != null,
      summary: BudgetSummary(
        budgetMinor: budget?.totalBudgetMinor ?? 0,
        expenseMinor: totalSpent,
      ),
      categories: cats,
    );
  }

  static const _rolloverLookbackMonths = 12;

  /// Carry-over per category id into (year, month): two queries in total
  /// (budget rows + spending of the previous 12 months). Only categories whose
  /// M-1 row is rollover-enabled can carry; see [CategoryBudgetSummary].
  Future<Map<int, int>> _carryOvers(int profileId, int year, int month) async {
    final target = year * 12 + (month - 1);
    final first = target - _rolloverLookbackMonths;
    final from = monthStartKey(first ~/ 12, first % 12 + 1);
    final to = monthEndKey((target - 1) ~/ 12, (target - 1) % 12 + 1);

    final budgetRows = await _db
        .customSelect(
          'SELECT mb.year * 12 + mb.month - 1 AS idx, cb.category_id AS cid, '
          'cb.amount_minor AS amt, cb.rollover_enabled AS ro '
          'FROM category_budgets cb JOIN monthly_budgets mb '
          'ON mb.profile_id = cb.profile_id AND mb.id = cb.monthly_budget_id '
          'WHERE cb.profile_id = ? '
          'AND mb.year * 12 + mb.month - 1 BETWEEN ? AND ?',
          variables: [
            Variable.withInt(profileId),
            Variable.withInt(first),
            Variable.withInt(target - 1),
          ],
        )
        .get();
    final spentRows = await _db
        .customSelect(
          'SELECT category_id AS cid, '
          'CAST(substr(txn_date, 1, 4) AS INTEGER) * 12 + '
          'CAST(substr(txn_date, 6, 2) AS INTEGER) - 1 AS idx, '
          'COALESCE(SUM(amount_minor), 0) AS s FROM financial_transactions '
          "WHERE profile_id = ? AND type = 'expense' AND is_deleted = 0 "
          'AND category_id IS NOT NULL AND txn_date BETWEEN ? AND ? '
          'GROUP BY category_id, idx',
          variables: [
            Variable.withInt(profileId),
            Variable.withString(from),
            Variable.withString(to),
          ],
        )
        .get();
    // key = categoryId * 1000000 + monthIndex (monthIndex < 120000).
    int key(int cid, int idx) => cid * 1000000 + idx;
    final rowAt = <int, ({int amt, bool ro})>{};
    final cats = <int>{};
    for (final r in budgetRows) {
      final cid = r.read<int>('cid');
      cats.add(cid);
      rowAt[key(cid, r.read<int>('idx'))] = (
        amt: r.read<int>('amt'),
        ro: r.read<int>('ro') != 0,
      );
    }
    final spent = <int, int>{
      for (final r in spentRows)
        key(r.read<int>('cid'), r.read<int>('idx')): r.read<int>('s'),
    };
    final out = <int, int>{};
    for (final cid in cats) {
      int? prevEff; // effective allowance of previous month while chain holds
      var prevSpent = 0;
      for (var idx = first; idx < target; idx++) {
        final row = rowAt[key(cid, idx)];
        if (row == null || !row.ro) {
          prevEff = null;
        } else {
          final left = prevEff == null ? 0 : prevEff - prevSpent;
          prevEff = row.amt + (left > 0 ? left : 0);
        }
        prevSpent = spent[key(cid, idx)] ?? 0;
      }
      if (prevEff != null) {
        final c = prevEff - prevSpent;
        out[cid] = c > 0 ? c : 0;
      }
    }
    return out;
  }

  /// Turns "carry over unspent" on/off for one category budget row.
  Future<void> setRolloverEnabled({
    required int profileId,
    required int categoryBudgetId,
    required bool enabled,
  }) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.categoryBudgets,
      )..where((c) => c.id.equals(categoryBudgetId))).getSingleOrNull();
      if (row == null) throw NotFoundException('Category budget not found.');
      if (row.profileId != profileId) {
        throw ProfileMismatchException(
          'Category budget belongs to a different profile.',
        );
      }
      await (_db.update(_db.categoryBudgets)..where(
            (c) =>
                c.profileId.equals(profileId) & c.id.equals(categoryBudgetId),
          ))
          .write(
            CategoryBudgetsCompanion(
              rolloverEnabled: Value(enabled),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  /// Reactive month view: refreshes on any budget/transaction/category change.
  Stream<MonthBudget> watchMonth(int profileId, int year, int month) {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.financialTransactions,
            _db.monthlyBudgets,
            _db.categoryBudgets,
            _db.categories,
          },
        )
        .watch()
        .asyncMap((_) => loadMonth(profileId, year, month));
  }
}
