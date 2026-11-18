import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/insights/domain/insights_calculations.dart';
import 'package:my_budget/features/insights/domain/insights_models.dart';
import 'package:my_budget/l10n/generated/app_localizations_en.dart';

({String name, int minor}) e(String n, int m) => (name: n, minor: m);

final l = AppLocalizationsEn();

void main() {
  group('categoryDeltas', () {
    test('sorted by absolute delta; new and absent categories handled', () {
      final d = InsightsCalculations.categoryDeltas(
        {1: e('Food', 11200), 2: e('Fun', 2000), 3: e('Bills', 3000)},
        {1: e('Food', 10000), 4: e('Rent', 5000), 3: e('Bills', 3000)},
      );
      expect(d.map((x) => x.name), ['Rent', 'Fun', 'Food']); // Bills omitted
      final rent = d[0];
      expect(rent.isAbsent, isTrue);
      expect(rent.deltaMinor, -5000);
      expect(rent.percent, -1.0);
      final fun = d[1];
      expect(fun.isNew, isTrue);
      expect(fun.percent, isNull); // prev = 0 -> no divide by zero
      expect(d[2].percent, closeTo(0.12, 1e-9));
    });

    test('risers and fallers split', () {
      final c = MonthComparison(
        currentMinor: 0,
        previousMinor: 0,
        categories: InsightsCalculations.categoryDeltas(
          {1: e('A', 300), 2: e('B', 100)},
          {1: e('A', 100), 2: e('B', 500)},
        ),
      );
      expect(c.risers.map((x) => x.name), ['A']);
      expect(c.fallers.map((x) => x.name), ['B']);
    });
  });

  group('isOutlier', () {
    // samples 1000,1100,900,1000,1000,1000: n=6 sum=6000 sumSq=6020000
    const n = 6, sum = 6000, sq = 6020000;
    test('threshold is mean + 2*stddev', () {
      // population sd = 57.735 -> threshold 1115.47
      expect(InsightsCalculations.isOutlier(1115, n, sum, sq), isFalse);
      expect(InsightsCalculations.isOutlier(1116, n, sum, sq), isTrue);
      expect(InsightsCalculations.isOutlier(900, n, sum, sq), isFalse);
    });
    test('needs at least 5 samples', () {
      expect(InsightsCalculations.isOutlier(5000, 4, 4000, 4000000), isFalse);
      expect(InsightsCalculations.isOutlier(5000, 5, 5000, 5000000), isTrue);
    });
  });

  group('occurrencesInMonth', () {
    int occ(String f, String start, String next, {int i = 1, String? end}) =>
        InsightsCalculations.occurrencesInMonth(
          frequency: f,
          interval: i,
          startDate: start,
          nextDue: next,
          endDate: end,
          monthStart: '2026-03-01',
          monthEnd: '2026-03-31',
        );
    test('daily, weekly, monthly, yearly', () {
      expect(occ('daily', '2026-03-01', '2026-03-29'), 3);
      expect(occ('weekly', '2026-03-01', '2026-03-20'), 2); // 20, 27
      expect(occ('weekly', '2026-03-01', '2026-03-20', i: 2), 1);
      expect(occ('monthly', '2026-01-25', '2026-03-25'), 1);
      expect(occ('monthly', '2026-01-25', '2026-04-25'), 0);
      expect(occ('yearly', '2025-03-30', '2026-03-30'), 1);
    });
    test('respects end date; month-end clamping', () {
      expect(occ('daily', '2026-03-01', '2026-03-29', end: '2026-03-30'), 2);
      expect(
        InsightsCalculations.occurrencesInMonth(
          frequency: 'monthly',
          interval: 1,
          startDate: '2026-01-31',
          nextDue: '2026-02-28',
          monthStart: '2026-02-01',
          monthEnd: '2026-02-28',
        ),
        1,
      );
    });
    test('stale overdue occurrences before the month are skipped', () {
      expect(occ('monthly', '2026-01-10', '2026-01-10'), 1); // only Mar 10
    });
  });

  group('forecast', () {
    Forecast f(int budget, {int recurring = 0, int elapsed = 20}) =>
        InsightsCalculations.forecast(
          spentSoFarMinor: 16000,
          last14Minor: 14000,
          daysElapsed: elapsed,
          daysInThisMonth: 31,
          recurringRemainingMinor: recurring,
          budgetMinor: budget,
        );
    test('math with 14-day run rate', () {
      final x = f(0);
      expect(x.dailyAverageMinor, 1000);
      expect(x.runRateRemainingMinor, 11000);
      expect(x.projectedMinor, 27000);
      expect(x.status, isNull);
    });
    test('recurring is added', () {
      expect(f(0, recurring: 5000).projectedMinor, 32000);
    });
    test('under 7 days uses month-to-date average', () {
      final x = InsightsCalculations.forecast(
        spentSoFarMinor: 3000,
        last14Minor: 99999,
        daysElapsed: 3,
        daysInThisMonth: 30,
        recurringRemainingMinor: 0,
        budgetMinor: 0,
      );
      expect(x.projectedMinor, 3000 + 1000 * 27);
    });
    test('status thresholds', () {
      expect(f(40000).status, ForecastStatus.onTrack);
      expect(f(30000).status, ForecastStatus.atRisk); // exactly 90%
      expect(f(31000).status, ForecastStatus.onTrack); // below 90%
      expect(f(27000).status, ForecastStatus.atRisk); // projected == budget
      final over = f(20000);
      expect(over.status, ForecastStatus.overBudget);
      expect(over.overageMinor, 7000);
    });
    test('last day of month has no run-rate part', () {
      expect(f(0, elapsed: 31).projectedMinor, 16000);
    });
  });

  group('messages', () {
    test('category and total deltas', () {
      const food = CategoryDelta(
        categoryId: 1,
        name: 'Food',
        currentMinor: 120000,
        previousMinor: 0,
      );
      expect(
        InsightMessages.categoryDelta(l, food),
        'Food is new this month: ৳1,200.00',
      );
      const up = CategoryDelta(
        categoryId: 1,
        name: 'Food',
        currentMinor: 786700,
        previousMinor: 666700,
      );
      expect(
        InsightMessages.categoryDelta(l, up),
        'Food is up ৳1,200.00 (18%) vs last month',
      );
      const down = CategoryDelta(
        categoryId: 1,
        name: 'Food',
        currentMinor: 500,
        previousMinor: 1000,
      );
      expect(
        InsightMessages.categoryDelta(l, down),
        'Food is down ৳5.00 (50%) vs last month',
      );
      const cmp = MonthComparison(
        currentMinor: 500,
        previousMinor: 0,
        categories: [],
      );
      expect(
        InsightMessages.totalDelta(l, cmp),
        'You spent ৳5.00 with no spending last month',
      );
    });
    test('savings', () {
      expect(
        InsightMessages.savings(
          l,
          const SavingsRate(incomeMinor: 0, expenseMinor: 500),
        ),
        isNull,
      );
      expect(
        InsightMessages.savings(
          l,
          const SavingsRate(incomeMinor: 1000, expenseMinor: 750),
        ),
        'You saved 25% of your income this month',
      );
      expect(
        InsightMessages.savings(
          l,
          const SavingsRate(incomeMinor: 1000, expenseMinor: 1500),
        ),
        'You spent 50% more than you earned this month',
      );
    });
    test('forecast messages by status', () {
      Forecast mk(ForecastStatus? s) => Forecast(
        spentSoFarMinor: 0,
        dailyAverageMinor: 0,
        runRateRemainingMinor: 0,
        recurringRemainingMinor: 0,
        projectedMinor: 120000,
        budgetMinor: 100000,
        status: s,
        overageMinor: 20000,
        daysElapsed: 1,
        daysRemaining: 1,
      );
      expect(
        InsightMessages.forecast(l, mk(ForecastStatus.overBudget)),
        contains('exceed your budget by ৳200.00'),
      );
      expect(
        InsightMessages.forecast(l, mk(ForecastStatus.onTrack)),
        startsWith('On track'),
      );
      expect(
        InsightMessages.forecast(l, mk(ForecastStatus.atRisk)),
        startsWith('At risk'),
      );
      expect(InsightMessages.forecast(l, mk(null)), contains('no budget'));
    });
  });
}
