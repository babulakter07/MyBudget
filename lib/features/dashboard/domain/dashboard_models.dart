/// Totals for one month.
class MonthOverview {
  const MonthOverview({
    required this.budgetMinor,
    required this.expenseMinor,
    required this.incomeMinor,
  });

  /// Monthly budget total (0 when none is set).
  final int budgetMinor;
  final int expenseMinor;
  final int incomeMinor;

  bool get hasBudget => budgetMinor > 0;

  /// Budget minus expense; negative when over budget. This is NOT the cash
  /// balance.
  int get remainingMinor => budgetMinor - expenseMinor;
}

/// Expense total for a named entity (cost item or category).
class RankedAmount {
  const RankedAmount({
    required this.id,
    required this.name,
    required this.amountMinor,
  });

  final int id;
  final String name;
  final int amountMinor;
}

class DayAmount {
  const DayAmount(this.date, this.amountMinor);

  /// 'yyyy-MM-dd'.
  final String date;
  final int amountMinor;
}

/// Income/expense per calendar month of one year; always 12 entries.
class YearlyTotals {
  const YearlyTotals({
    required this.year,
    required this.expenseByMonth,
    required this.incomeByMonth,
  }) : assert(expenseByMonth.length == 12 && incomeByMonth.length == 12);

  final int year;

  /// Index 0 = January.
  final List<int> expenseByMonth;
  final List<int> incomeByMonth;
}

class YearlySummary {
  const YearlySummary({
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.averageMonthlyExpenseMinor,
    required this.highestMonth,
    required this.lowestMonth,
  });

  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int averageMonthlyExpenseMinor;

  /// 1-12, or null when the year has no expenses.
  final int? highestMonth;

  /// 1-12 among months that HAVE expenses, or null when there are none.
  final int? lowestMonth;
}
