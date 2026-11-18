/// Pure budget math (no Flutter/Drift). All amounts are minor units.
class BudgetSummary {
  const BudgetSummary({required this.budgetMinor, required this.expenseMinor});

  final int budgetMinor;
  final int expenseMinor;

  /// budget - expense; negative when overspent (no carry-over either way).
  int get remainingMinor => budgetMinor - expenseMinor;

  bool get isOverspent => remainingMinor < 0;

  /// expense / budget * 100; 0 when the budget is 0 (never divides by zero).
  double get utilizationPercent =>
      budgetMinor <= 0 ? 0 : expenseMinor * 100 / budgetMinor;
}

/// Per-category budget for one month.
///
/// Rollover semantics (optional per category, default OFF = RESET):
/// for a row with [rolloverEnabled] in month M,
/// `carriedOverMinor = max(0, effectiveAllowance(M-1) - spent(M-1))`, where
/// effectiveAllowance(M-1) = amount(M-1) + its own carry (recursive, 12-month
/// lookback). No row in M-1, or a row without rollover, breaks the chain
/// (carry 0). Overspend never carries as debt. The effective allowance
/// ([effectiveAllowanceMinor] = [allocationMinor] + [carriedOverMinor]) drives
/// remaining/percent/over-budget status. The monthly total and the
/// sum(category) <= total validation use [allocationMinor] only.
class CategoryBudgetSummary {
  const CategoryBudgetSummary({
    required this.categoryId,
    required this.categoryName,
    required this.allocationMinor,
    required this.spentMinor,
    this.categoryBudgetId = 0,
    this.rolloverEnabled = false,
    this.carriedOverMinor = 0,
  });

  final int categoryId;
  final String categoryName;
  final int allocationMinor;
  final int spentMinor;

  /// Row id of the category_budgets row (used to toggle rollover).
  final int categoryBudgetId;
  final bool rolloverEnabled;
  final int carriedOverMinor;

  int get effectiveAllowanceMinor => allocationMinor + carriedOverMinor;

  BudgetSummary get summary => BudgetSummary(
    budgetMinor: effectiveAllowanceMinor,
    expenseMinor: spentMinor,
  );
  int get remainingMinor => summary.remainingMinor;
}

/// Everything shown for one (profile, year, month).
class MonthBudget {
  const MonthBudget({
    required this.year,
    required this.month,
    required this.hasBudget,
    required this.summary,
    required this.categories,
  });

  final int year;
  final int month;

  /// false when no monthly budget row exists (new months start empty).
  final bool hasBudget;
  final BudgetSummary summary;
  final List<CategoryBudgetSummary> categories;

  int get allocatedMinor => categories.fold(0, (s, c) => s + c.allocationMinor);
}

class CategoryOption {
  const CategoryOption({required this.id, required this.name});
  final int id;
  final String name;
}
