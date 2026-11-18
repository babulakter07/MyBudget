import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/insights_calculations.dart';
import '../domain/insights_models.dart';
import '../providers/insights_providers.dart';

/// Pushed screen (route /insights) with its own Scaffold.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(insightsMonthProvider);
    final now = ref.watch(insightsClockProvider)();
    final canNext = DateTime(
      month.year,
      month.month + 1,
    ).isBefore(DateTime(now.year, now.month + 1));
    final async = ref.watch(selectedInsightsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.insightsTitle)),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: context.l10n.insightsPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                onPressed: ref.read(insightsMonthProvider.notifier).previous,
              ),
              Text(
                '${DateFormat.MMMM().format(month)} ${month.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: context.l10n.insightsNextMonth,
                icon: const Icon(Icons.chevron_right),
                onPressed: canNext
                    ? ref.read(insightsMonthProvider.notifier).next
                    : null,
              ),
            ],
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(error: e),
              data: (i) => i == null || !i.hasData
                  ? EmptyState(
                      message: context.l10n.insightsNoData,
                      icon: Icons.insights,
                    )
                  : _Body(insights: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.insights});
  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final i = insights;
    final c = i.comparison;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (i.forecast != null) _ForecastCard(forecast: i.forecast!),
        _Card(
          title: context.l10n.insightsVsLastMonth,
          children: [
            Text(InsightMessages.totalDelta(context.l10n, c)),
            for (final d in c.categories.take(5))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(InsightMessages.categoryDelta(context.l10n, d)),
              ),
          ],
        ),
        _Card(
          title: context.l10n.insightsUnusualSpending,
          children: [
            if (i.unusual.isEmpty)
              Text(context.l10n.insightsNothingUnusual)
            else
              for (final u in i.unusual)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(InsightMessages.unusual(context.l10n, u)),
                ),
          ],
        ),
        _Card(
          title: context.l10n.insightsWeekdayCardTitle,
          children: [
            SizedBox(height: 180, child: _WeekdayChart(buckets: i.weekdays)),
            if (InsightMessages.weekday(context.l10n, i.weekdays) case final w?)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(w)),
          ],
        ),
        _Card(
          title: context.l10n.insightsTopItems,
          children: [
            if (i.topItems.isEmpty)
              Text(context.l10n.insightsNoExpenses)
            else
              for (final t in i.topItems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                      Text(formatMinor(t.totalMinor)),
                    ],
                  ),
                ),
          ],
        ),
        _Card(
          title: context.l10n.insightsSavingsRate,
          children: [
            Text(
              InsightMessages.savings(context.l10n, i.savings) ??
                  context.l10n.insightsNoIncome,
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});
  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (f.status) {
      ForecastStatus.overBudget => scheme.error,
      ForecastStatus.atRisk => AppColors.expense,
      ForecastStatus.onTrack => AppColors.income,
      null => scheme.onSurface,
    };
    return _Card(
      title: context.l10n.insightsForecastTitle,
      children: [
        Text(
          InsightMessages.forecast(context.l10n, f),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.insightsForecastDetail(
            formatMinor(f.spentSoFarMinor),
            formatMinor(f.dailyAverageMinor),
            f.daysRemaining,
          ),
        ),
        if (f.recurringRemainingMinor > 0)
          Text(
            context.l10n.insightsForecastRecurring(
              formatMinor(f.recurringRemainingMinor),
            ),
          ),
      ],
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.buckets});
  final List<WeekdayBucket> buckets;

  /// Narrow weekday letter, Monday = 0 (2024-01-01 was a Monday).
  static String _label(int n) =>
      DateFormat.EEEEE().format(DateTime(2024, 1, 1 + n));

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_label(v.toInt().clamp(0, 6))),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              formatMinor(buckets[group.x].totalMinor),
              const TextStyle(),
            ),
          ),
        ),
        barGroups: [
          for (var n = 0; n < buckets.length; n++)
            BarChartGroupData(
              x: n,
              barRods: [
                BarChartRodData(
                  toY: buckets[n].totalMinor / 100,
                  color: color,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
