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

class CategoryBudgetSummary {
  const CategoryBudgetSummary({
    required this.categoryId,
    required this.categoryName,
    required this.allocationMinor,
    required this.spentMinor,
  });

  final int categoryId;
  final String categoryName;
  final int allocationMinor;
  final int spentMinor;

  BudgetSummary get summary =>
      BudgetSummary(budgetMinor: allocationMinor, expenseMinor: spentMinor);
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
