import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/dashboard/domain/dashboard_calculations.dart';
import 'package:my_budget/features/dashboard/domain/dashboard_models.dart';

RankedAmount r(int id, String name, int amt) =>
    RankedAmount(id: id, name: name, amountMinor: amt);

void main() {
  group('utilization', () {
    test('zero budget is safe', () {
      expect(DashboardCalculations.utilizationPercent(0, 5000), 0);
      expect(DashboardCalculations.utilizationProgress(0, 5000), 0);
    });
    test('normal, empty and over budget', () {
      expect(DashboardCalculations.utilizationPercent(10000, 2500), 25);
      expect(DashboardCalculations.utilizationPercent(10000, 0), 0);
      expect(DashboardCalculations.utilizationPercent(10000, 15000), 150);
      expect(DashboardCalculations.utilizationProgress(10000, 15000), 1);
    });
    test('remaining can be negative', () {
      const o = MonthOverview(
        budgetMinor: 1000,
        expenseMinor: 1500,
        incomeMinor: 0,
      );
      expect(o.remainingMinor, -500);
      const none = MonthOverview(
        budgetMinor: 0,
        expenseMinor: 0,
        incomeMinor: 0,
      );
      expect(none.hasBudget, isFalse);
      expect(none.remainingMinor, 0);
    });
  });

  group('average daily expense', () {
    test('past month divides by full month length', () {
      expect(
        DashboardCalculations.averageDailyExpense(
          3100,
          2026,
          1,
          DateTime(2026, 5, 20),
        ),
        100,
      );
    });
    test('leap February 2028 has 29 days, 2027 has 28', () {
      expect(
        DashboardCalculations.averageDailyExpense(
          2900,
          2028,
          2,
          DateTime(2028, 6, 1),
        ),
        100,
      );
      expect(
        DashboardCalculations.averageDailyExpense(
          2800,
          2027,
          2,
          DateTime(2028, 6, 1),
        ),
        100,
      );
    });
    test('current month divides by days elapsed', () {
      expect(
        DashboardCalculations.averageDailyExpense(
          1000,
          2026,
          3,
          DateTime(2026, 3, 10),
        ),
        100,
      );
      expect(
        DashboardCalculations.daysForAverage(2026, 3, DateTime(2026, 3, 1)),
        1,
      );
    });
    test('rounds half up and empty month is zero', () {
      expect(
        DashboardCalculations.averageDailyExpense(
          5,
          2026,
          3,
          DateTime(2026, 3, 2),
        ),
        3,
      );
      expect(
        DashboardCalculations.averageDailyExpense(
          0,
          2026,
          3,
          DateTime(2026, 3, 2),
        ),
        0,
      );
    });
  });

  group('topN', () {
    test('limits to five, sorted desc', () {
      final list = [for (var i = 1; i <= 8; i++) r(i, 'I$i', i * 100)];
      final top = DashboardCalculations.topN(list);
      expect(top.map((e) => e.name), ['I8', 'I7', 'I6', 'I5', 'I4']);
    });
    test('ties break by name then id; fewer than five is fine', () {
      final top = DashboardCalculations.topN([
        r(3, 'b', 100),
        r(1, 'B', 100),
        r(2, 'a', 100),
        r(4, 'z', 50),
      ]);
      expect(top.map((e) => e.id), [2, 1, 3, 4]);
    });
    test('empty and zero amounts', () {
      expect(DashboardCalculations.topN(const []), isEmpty);
      expect(DashboardCalculations.topN([r(1, 'x', 0)]), isEmpty);
    });
  });

  group('highestDay', () {
    test('picks the max and the earliest on ties', () {
      final d = DashboardCalculations.highestDay(const [
        DayAmount('2026-03-09', 500),
        DayAmount('2026-03-02', 500),
        DayAmount('2026-03-05', 100),
      ]);
      expect(d!.date, '2026-03-02');
    });
    test('null when no spending', () {
      expect(DashboardCalculations.highestDay(const []), isNull);
    });
  });

  group('yearlySummary', () {
    test('empty year', () {
      final s = DashboardCalculations.yearlySummary(
        YearlyTotals(
          year: 2026,
          expenseByMonth: List.filled(12, 0),
          incomeByMonth: List.filled(12, 0),
        ),
      );
      expect(s.totalExpenseMinor, 0);
      expect(s.averageMonthlyExpenseMinor, 0);
      expect(s.highestMonth, isNull);
      expect(s.lowestMonth, isNull);
    });
    test('average over 12 months; lowest ignores empty months', () {
      final exp = List.filled(12, 0)
        ..[0] = 1200
        ..[4] = 300
        ..[8] = 300
        ..[11] = 6000;
      final inc = List.filled(12, 0)..[1] = 10000;
      final s = DashboardCalculations.yearlySummary(
        YearlyTotals(year: 2026, expenseByMonth: exp, incomeByMonth: inc),
      );
      expect(s.totalExpenseMinor, 7800);
      expect(s.totalIncomeMinor, 10000);
      expect(s.averageMonthlyExpenseMinor, 650);
      expect(s.highestMonth, 12);
      expect(s.lowestMonth, 5); // earliest of the tied 300s
    });
  });
}
