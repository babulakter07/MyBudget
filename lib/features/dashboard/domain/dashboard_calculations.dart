import '../../../core/utils/date_keys.dart';
import 'dashboard_models.dart';

/// Pure dashboard calculations (no Flutter, no Drift).
class DashboardCalculations {
  DashboardCalculations._();

  /// Utilization percentage (expense / budget * 100). A zero (or missing)
  /// budget yields 0 so the UI never divides by zero.
  static double utilizationPercent(int budgetMinor, int expenseMinor) {
    if (budgetMinor <= 0) return 0;
    return expenseMinor * 100 / budgetMinor;
  }

  /// Progress-bar value clamped to 0..1.
  static double utilizationProgress(int budgetMinor, int expenseMinor) =>
      (utilizationPercent(budgetMinor, expenseMinor) / 100).clamp(0.0, 1.0);

  /// Days used as the divisor for the average daily expense: the whole month
  /// for past/future months, and the days elapsed so far (today's day-of-month,
  /// today included) for the current month.
  static int daysForAverage(int year, int month, DateTime today) {
    final total = daysInMonth(year, month);
    if (today.year == year && today.month == month) {
      return today.day.clamp(1, total);
    }
    return total;
  }

  /// Average daily expense in minor units, rounded half up.
  static int averageDailyExpense(
    int expenseMinor,
    int year,
    int month,
    DateTime today,
  ) {
    final days = daysForAverage(year, month, today);
    return (expenseMinor + days ~/ 2) ~/ days;
  }

  /// Top [limit] entries by amount desc; ties broken by name (case-insensitive)
  /// then id so the result is deterministic. Zero/negative amounts are dropped.
  static List<RankedAmount> topN(
    Iterable<RankedAmount> items, {
    int limit = 5,
  }) {
    final list = items.where((e) => e.amountMinor > 0).toList()
      ..sort((a, b) {
        final c = b.amountMinor.compareTo(a.amountMinor);
        if (c != 0) return c;
        final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return n != 0 ? n : a.id.compareTo(b.id);
      });
    return list.take(limit).toList();
  }

  /// Day with the highest spend (earliest date wins ties); null when empty.
  static DayAmount? highestDay(Iterable<DayAmount> days) {
    DayAmount? best;
    for (final d in days) {
      if (d.amountMinor <= 0) continue;
      if (best == null ||
          d.amountMinor > best.amountMinor ||
          (d.amountMinor == best.amountMinor &&
              d.date.compareTo(best.date) < 0)) {
        best = d;
      }
    }
    return best;
  }

  /// Yearly summary over all 12 months. The average monthly expense divides by
  /// 12 (months without spending count as zero). Highest month = max expense
  /// (earliest on ties, null when the year has no expense). Lowest month =
  /// minimum among months WITH expense (earliest on ties, null when none), so
  /// an empty month never "wins" as the cheapest.
  static YearlySummary yearlySummary(YearlyTotals t) {
    final totalExpense = t.expenseByMonth.fold(0, (a, b) => a + b);
    final totalIncome = t.incomeByMonth.fold(0, (a, b) => a + b);
    int? hi, lo;
    for (var i = 0; i < 12; i++) {
      final v = t.expenseByMonth[i];
      if (v <= 0) continue;
      if (hi == null || v > t.expenseByMonth[hi - 1]) hi = i + 1;
      if (lo == null || v < t.expenseByMonth[lo - 1]) lo = i + 1;
    }
    return YearlySummary(
      totalIncomeMinor: totalIncome,
      totalExpenseMinor: totalExpense,
      averageMonthlyExpenseMinor: (totalExpense + 6) ~/ 12,
      highestMonth: hi,
      lowestMonth: lo,
    );
  }
}
