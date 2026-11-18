// Pure-data models for spending insights. Money is integer minor units.

/// Per-category month-over-month change.
class CategoryDelta {
  const CategoryDelta({
    required this.categoryId,
    required this.name,
    required this.currentMinor,
    required this.previousMinor,
  });

  /// Null for expenses without a category.
  final int? categoryId;
  final String name;
  final int currentMinor;
  final int previousMinor;

  int get deltaMinor => currentMinor - previousMinor;
  bool get isNew => previousMinor == 0 && currentMinor > 0;
  bool get isAbsent => currentMinor == 0 && previousMinor > 0;

  /// Change relative to last month as a display ratio (0.18 = +18%); null
  /// when last month was 0 (no divide by zero).
  double? get percent => previousMinor == 0 ? null : deltaMinor / previousMinor;
}

class MonthComparison {
  const MonthComparison({
    required this.currentMinor,
    required this.previousMinor,
    required this.categories,
  });

  final int currentMinor;
  final int previousMinor;

  /// Sorted by absolute delta, largest first (zero deltas omitted).
  final List<CategoryDelta> categories;

  int get deltaMinor => currentMinor - previousMinor;
  double? get percent => previousMinor == 0 ? null : deltaMinor / previousMinor;

  /// Biggest increases first.
  List<CategoryDelta> get risers =>
      categories.where((c) => c.deltaMinor > 0).toList();

  /// Biggest decreases first.
  List<CategoryDelta> get fallers =>
      categories.where((c) => c.deltaMinor < 0).toList();
}

class UnusualTransaction {
  const UnusualTransaction({
    required this.transactionId,
    required this.date,
    required this.title,
    required this.categoryName,
    required this.amountMinor,
    required this.usualMinor,
  });

  final int transactionId;
  final String date;
  final String? title;
  final String categoryName;
  final int amountMinor;

  /// Category mean over the previous 6 months.
  final int usualMinor;

  int get excessMinor => amountMinor - usualMinor;
}

enum ForecastStatus { onTrack, atRisk, overBudget }

class Forecast {
  const Forecast({
    required this.spentSoFarMinor,
    required this.dailyAverageMinor,
    required this.runRateRemainingMinor,
    required this.recurringRemainingMinor,
    required this.projectedMinor,
    required this.budgetMinor,
    required this.status,
    required this.overageMinor,
    required this.daysElapsed,
    required this.daysRemaining,
  });

  final int spentSoFarMinor;
  final int dailyAverageMinor;
  final int runRateRemainingMinor;
  final int recurringRemainingMinor;
  final int projectedMinor;

  /// 0 when no budget is set.
  final int budgetMinor;

  /// Null when no budget is set for the month.
  final ForecastStatus? status;

  /// max(0, projected - budget); 0 without a budget.
  final int overageMinor;
  final int daysElapsed;
  final int daysRemaining;
}

class WeekdayBucket {
  const WeekdayBucket({required this.weekday, required this.totalMinor});

  /// 1 = Monday ... 7 = Sunday (DateTime.weekday).
  final int weekday;
  final int totalMinor;
}

class TopItem {
  const TopItem({required this.name, required this.totalMinor});
  final String name;
  final int totalMinor;
}

class SavingsRate {
  const SavingsRate({required this.incomeMinor, required this.expenseMinor});
  final int incomeMinor;
  final int expenseMinor;

  /// (income - expense) / income; null when income is 0. May be negative.
  double? get rate =>
      incomeMinor == 0 ? null : (incomeMinor - expenseMinor) / incomeMinor;
}

class Insights {
  const Insights({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.comparison,
    required this.unusual,
    required this.forecast,
    required this.weekdays,
    required this.topItems,
    required this.savings,
  });

  final int year;
  final int month;
  final bool isCurrentMonth;
  final MonthComparison comparison;
  final List<UnusualTransaction> unusual;

  /// Null unless [isCurrentMonth].
  final Forecast? forecast;

  /// Always 7 buckets, Monday..Sunday, last 90 days.
  final List<WeekdayBucket> weekdays;
  final List<TopItem> topItems;
  final SavingsRate savings;

  bool get hasData =>
      comparison.currentMinor > 0 ||
      comparison.previousMinor > 0 ||
      savings.incomeMinor > 0 ||
      weekdays.any((w) => w.totalMinor > 0);
}

/// A short human-readable insight line.
class InsightMessage {
  const InsightMessage(this.kind, this.text);

  /// forecast | total | category | unusual | savings | weekday
  final String kind;
  final String text;
}
