import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../ledger/presentation/period_pickers.dart';
import '../domain/dashboard_calculations.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'analytics_section.dart' show monthName, shortMonthName;
import 'dashboard_widgets.dart';

class YearlySection extends ConsumerWidget {
  const YearlySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(dashboardFilterProvider.select((f) => f.year));
    return SectionCard(
      title: context.l10n.dashboardYearlyOverview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showMonthYearPicker(
                context,
                initial: DateTime(year),
                yearOnly: true,
              );
              if (picked != null) {
                ref
                    .read(dashboardFilterProvider.notifier)
                    .selectYear(picked.year);
              }
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(context.l10n.dashboardYear(year)),
          ),
          const SizedBox(height: 12),
          AsyncSection<YearlyTotals>(
            value: ref.watch(yearlyTotalsProvider),
            builder: (t) {
              final s = DashboardCalculations.yearlySummary(t);
              String monthOrDash(int? m) => m == null ? '-' : monthName(m);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(
                    children: [
                      StatCard(
                        label: context.l10n.dashboardTotalIncome,
                        value: formatMinor(s.totalIncomeMinor),
                        color: AppColors.income,
                      ),
                      StatCard(
                        label: context.l10n.dashboardTotalExpense,
                        value: formatMinor(s.totalExpenseMinor),
                        color: AppColors.expense,
                      ),
                      StatCard(
                        label: context.l10n.dashboardAverageMonthlyExpense,
                        value: formatMinor(s.averageMonthlyExpenseMinor),
                      ),
                      StatCard(
                        label: context.l10n.dashboardHighestSpendingMonth,
                        value: monthOrDash(s.highestMonth),
                      ),
                      StatCard(
                        label: context.l10n.dashboardLowestSpendingMonth,
                        value: monthOrDash(s.lowestMonth),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.dashboardMonthlyExpenseTrend,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 220, child: _TrendChart(t)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(this.totals);
  final YearlyTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  shortMonthName(v.toInt() + 1).substring(0, 1),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 12; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals.expenseByMonth[i] / 100,
                  color: theme.colorScheme.primary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
