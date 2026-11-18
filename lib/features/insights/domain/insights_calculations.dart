import 'dart:math' as math;

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'insights_models.dart';

/// Pure insight rules (no Flutter/Drift).
class InsightsCalculations {
  const InsightsCalculations._();

  /// Minimum historical samples (prior 6 months, same category) for outlier
  /// detection.
  static const minOutlierSamples = 5;

  /// Projected spend >= 90% of budget (but not over) is "at risk".
  static const atRiskNumerator = 9;
  static const atRiskDenominator = 10;

  /// Category deltas sorted by absolute change (desc); zero deltas dropped.
  /// Categories new this month or absent this month are included.
  static List<CategoryDelta> categoryDeltas(
    Map<int?, ({String name, int minor})> current,
    Map<int?, ({String name, int minor})> previous,
  ) {
    final keys = {...current.keys, ...previous.keys};
    final out = <CategoryDelta>[];
    for (final k in keys) {
      final c = current[k];
      final p = previous[k];
      final d = CategoryDelta(
        categoryId: k,
        name: (c ?? p)!.name,
        currentMinor: c?.minor ?? 0,
        previousMinor: p?.minor ?? 0,
      );
      if (d.deltaMinor != 0) out.add(d);
    }
    out.sort((a, b) {
      final r = b.deltaMinor.abs().compareTo(a.deltaMinor.abs());
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    return out;
  }

  /// Outlier test, exact integer math. With population mean m = sum/n and
  /// stddev s = sqrt(n*sumSq - sum^2)/n, "amount > m + 2s" is equivalent to
  /// d = n*amount - sum > 0 and d^2 > 4*(n*sumSq - sum^2).
  /// Returns false when n < [minOutlierSamples].
  static bool isOutlier(int amount, int n, int sum, int sumSq) {
    if (n < minOutlierSamples) return false;
    final d = n * amount - sum;
    if (d <= 0) return false;
    final s = n * sumSq - sum * sum;
    return d * d > 4 * s;
  }

  /// Integer mean (rounded down).
  static int mean(int n, int sum) => n == 0 ? 0 : sum ~/ n;

  /// Number of occurrences of a recurring rule dated within
  /// [monthStart, monthEnd], iterating from [nextDue] (so occurrences already
  /// posted, which advanced nextDue, are not counted again). Overdue
  /// unposted occurrences dated inside the month are included. Respects
  /// [endDate]. frequency: daily|weekly|monthly|yearly.
  static int occurrencesInMonth({
    required String frequency,
    required int interval,
    required String startDate,
    required String nextDue,
    String? endDate,
    required String monthStart,
    required String monthEnd,
  }) {
    final step = interval < 1 ? 1 : interval;
    final DateTime start, ms, me;
    DateTime cur;
    final DateTime? end;
    try {
      start = parseDateKey(startDate);
      cur = parseDateKey(nextDue);
      ms = parseDateKey(monthStart);
      me = parseDateKey(monthEnd);
      end = endDate == null ? null : parseDateKey(endDate);
    } on FormatException {
      return 0;
    }
    final limit = (end != null && end.isBefore(me)) ? end : me;
    DateTime advance(DateTime d) {
      switch (frequency) {
        case 'daily':
          return DateTime(d.year, d.month, d.day + step);
        case 'weekly':
          return DateTime(d.year, d.month, d.day + 7 * step);
        case 'monthly':
          return _addMonths(d, step, start.day);
        case 'yearly':
          return _addMonths(d, 12 * step, start.day);
        default:
          return DateTime(9999);
      }
    }

    var count = 0;
    for (var i = 0; i < 5000 && !cur.isAfter(limit); i++) {
      if (!cur.isBefore(ms)) count++;
      cur = advance(cur);
    }
    return count;
  }

  static DateTime _addMonths(DateTime d, int n, int anchorDay) {
    final t = DateTime(d.year, d.month + n, 1);
    return DateTime(
      t.year,
      t.month,
      math.min(anchorDay, daysInMonth(t.year, t.month)),
    );
  }

  /// Month-end forecast.
  ///
  /// projected = spentSoFar + runRate*daysRemaining + recurringRemaining
  /// - runRate = last-14-day spend / 14, or month-to-date spend / daysElapsed
  ///   when fewer than 7 days have elapsed (integer math: the multiplication
  ///   happens before the division).
  /// - recurringRemaining = sum of ACTIVE expense recurring rules' occurrences
  ///   still to come (from next_due_date through month end). Posted occurrences
  ///   already sit in spentSoFar and have advanced next_due_date, so the
  ///   explicit recurring term never counts them twice; the run rate is an
  ///   undifferentiated daily average and may still include past posted
  ///   recurring spend (documented, accepted approximation).
  /// Status vs budget: projected > budget -> overBudget; projected >= 90% of
  /// budget -> atRisk; else onTrack; null when no budget.
  static Forecast forecast({
    required int spentSoFarMinor,
    required int last14Minor,
    required int daysElapsed,
    required int daysInThisMonth,
    required int recurringRemainingMinor,
    required int budgetMinor,
  }) {
    final remaining = math.max(0, daysInThisMonth - daysElapsed);
    final int window;
    final int windowSum;
    if (daysElapsed < 7) {
      window = math.max(1, daysElapsed);
      windowSum = spentSoFarMinor;
    } else {
      window = 14;
      windowSum = last14Minor;
    }
    final runRateRemaining = (windowSum * remaining) ~/ window;
    final projected =
        spentSoFarMinor + runRateRemaining + recurringRemainingMinor;
    ForecastStatus? status;
    var overage = 0;
    if (budgetMinor > 0) {
      overage = math.max(0, projected - budgetMinor);
      if (projected > budgetMinor) {
        status = ForecastStatus.overBudget;
      } else if (projected * atRiskDenominator >=
          budgetMinor * atRiskNumerator) {
        status = ForecastStatus.atRisk;
      } else {
        status = ForecastStatus.onTrack;
      }
    }
    return Forecast(
      spentSoFarMinor: spentSoFarMinor,
      dailyAverageMinor: windowSum ~/ window,
      runRateRemainingMinor: runRateRemaining,
      recurringRemainingMinor: recurringRemainingMinor,
      projectedMinor: projected,
      budgetMinor: budgetMinor,
      status: status,
      overageMinor: overage,
      daysElapsed: daysElapsed,
      daysRemaining: remaining,
    );
  }
}

/// Pure message builders. Percent is display-only. Every builder takes the
/// [AppLocalizations] to write the sentence in.
class InsightMessages {
  const InsightMessages._();

  static String _pct(double? ratio) =>
      ratio == null ? '' : ' (${(ratio.abs() * 100).round()}%)';

  static String categoryDelta(
    AppLocalizations l,
    CategoryDelta d, {
    String symbol = '৳',
  }) {
    if (d.isNew) {
      return l.insightsCategoryNew(
        d.name,
        formatMinor(d.currentMinor, symbol: symbol),
      );
    }
    final amt = formatMinor(d.deltaMinor.abs(), symbol: symbol);
    return d.deltaMinor >= 0
        ? l.insightsCategoryUp(d.name, amt, _pct(d.percent))
        : l.insightsCategoryDown(d.name, amt, _pct(d.percent));
  }

  static String totalDelta(
    AppLocalizations l,
    MonthComparison c, {
    String symbol = '৳',
  }) {
    if (c.previousMinor == 0) {
      return c.currentMinor == 0
          ? l.insightsTotalNone
          : l.insightsTotalNoPrevious(
              formatMinor(c.currentMinor, symbol: symbol),
            );
    }
    if (c.deltaMinor == 0) return l.insightsTotalSame;
    final amt = formatMinor(c.deltaMinor.abs(), symbol: symbol);
    return c.deltaMinor > 0
        ? l.insightsTotalUp(amt, _pct(c.percent))
        : l.insightsTotalDown(amt, _pct(c.percent));
  }

  static String unusual(
    AppLocalizations l,
    UnusualTransaction u, {
    String symbol = '৳',
  }) {
    final label = (u.title != null && u.title!.trim().isNotEmpty)
        ? '${u.title} (${u.categoryName})'
        : u.categoryName;
    return l.insightsUnusual(
      formatMinor(u.amountMinor, symbol: symbol),
      label,
      formatMinor(u.excessMinor, symbol: symbol),
      formatMinor(u.usualMinor, symbol: symbol),
    );
  }

  static String forecast(
    AppLocalizations l,
    Forecast f, {
    String symbol = '৳',
  }) {
    final proj = formatMinor(f.projectedMinor, symbol: symbol);
    final budget = formatMinor(f.budgetMinor, symbol: symbol);
    switch (f.status) {
      case null:
        return l.insightsForecastNoBudget(proj);
      case ForecastStatus.onTrack:
        return l.insightsForecastOnTrack(proj, budget);
      case ForecastStatus.atRisk:
        return l.insightsForecastAtRisk(proj, budget);
      case ForecastStatus.overBudget:
        return l.insightsForecastOver(
          formatMinor(f.overageMinor, symbol: symbol),
          proj,
          budget,
        );
    }
  }

  static String? savings(AppLocalizations l, SavingsRate s) {
    final r = s.rate;
    if (r == null) return null;
    final pct = (r.abs() * 100).round();
    return r >= 0
        ? l.insightsSavingsSaved(pct)
        : l.insightsSavingsOverspent(pct);
  }

  static String? weekday(AppLocalizations l, List<WeekdayBucket> buckets) {
    WeekdayBucket? best;
    for (final b in buckets) {
      if (b.totalMinor > 0 &&
          (best == null || b.totalMinor > best.totalMinor)) {
        best = b;
      }
    }
    if (best == null) return null;
    return switch (best.weekday) {
      1 => l.insightsWeekdayMostMon,
      2 => l.insightsWeekdayMostTue,
      3 => l.insightsWeekdayMostWed,
      4 => l.insightsWeekdayMostThu,
      5 => l.insightsWeekdayMostFri,
      6 => l.insightsWeekdayMostSat,
      _ => l.insightsWeekdayMostSun,
    };
  }

  /// All messages, forecast first.
  static List<InsightMessage> all(
    AppLocalizations l,
    Insights i, {
    String symbol = '৳',
  }) {
    final out = <InsightMessage>[];
    final f = i.forecast;
    if (f != null) {
      out.add(InsightMessage('forecast', forecast(l, f, symbol: symbol)));
    }
    final c = i.comparison;
    if (c.currentMinor > 0 || c.previousMinor > 0) {
      out.add(InsightMessage('total', totalDelta(l, c, symbol: symbol)));
    }
    final top = c.categories.isEmpty ? null : c.categories.first;
    if (top != null) {
      out.add(
        InsightMessage('category', categoryDelta(l, top, symbol: symbol)),
      );
    }
    if (i.unusual.isNotEmpty) {
      out.add(
        InsightMessage('unusual', unusual(l, i.unusual.first, symbol: symbol)),
      );
    }
    final s = savings(l, i.savings);
    if (s != null) out.add(InsightMessage('savings', s));
    final w = weekday(l, i.weekdays);
    if (w != null) out.add(InsightMessage('weekday', w));
    return out;
  }
}
