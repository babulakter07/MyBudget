import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/dashboard_calculations.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_widgets.dart';

class AnalyticsSection extends ConsumerWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(dashboardMonthProvider);
    final now = ref.watch(dashboardClockProvider)();
    final overview = ref.watch(monthOverviewProvider);
    final days = ref.watch(dailyExpensesProvider);
    final cats = ref.watch(categoryTotalsProvider);
    final items = ref.watch(topCostItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: context.l10n.dashboardSpendingHighlights,
          child: AsyncSection(
            value: days,
            builder: (d) {
              final best = DashboardCalculations.highestDay(d);
              final expense = overview.asData?.value.expenseMinor ?? 0;
              final avg = DashboardCalculations.averageDailyExpense(
                expense,
                month.year,
                month.month,
                now,
              );
              return StatGrid(
                children: [
                  StatCard(
                    label: context.l10n.dashboardHighestSpendingDay,
                    value: best == null
                        ? '-'
                        : '${formatMinor(best.amountMinor)} (${best.date})',
                  ),
                  StatCard(
                    label: context.l10n.dashboardAverageDailyExpense,
                    value: formatMinor(avg),
                  ),
                ],
              );
            },
          ),
        ),
        SectionCard(
          title: context.l10n.dashboardTop5CostItems,
          child: AsyncSection(
            value: items,
            builder: (list) => _RankedList(
              list,
              emptyText: context.l10n.dashboardNoCostItemExpenses,
            ),
          ),
        ),
        SectionCard(
          title: context.l10n.dashboardTop5Categories,
          child: AsyncSection(
            value: cats,
            builder: (list) => _RankedList(
              list.take(5).toList(),
              emptyText: context.l10n.dashboardNoCategoryExpenses,
            ),
          ),
        ),
        SectionCard(
          title: context.l10n.dashboardCategoryDistribution,
          child: AsyncSection(
            value: cats,
            builder: (list) => CategoryPie(list),
          ),
        ),
      ],
    );
  }
}

class _RankedList extends StatelessWidget {
  const _RankedList(this.items, {required this.emptyText});
  final List<RankedAmount> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(emptyText);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 12, child: Text('${i + 1}')),
            title: Text(items[i].name, overflow: TextOverflow.ellipsis),
            trailing: Text(formatMinor(items[i].amountMinor)),
          ),
      ],
    );
  }
}

class CategoryPie extends StatelessWidget {
  const CategoryPie(this.items, {super.key});
  final List<RankedAmount> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(context.l10n.dashboardNoExpensesToChart);
    final total = items.fold(0, (s, e) => s + e.amountMinor);
    Color colorAt(int i) => dashboardPalette[i % dashboardPalette.length];
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < items.length; i++)
                  PieChartSectionData(
                    value: items[i].amountMinor.toDouble(),
                    color: colorAt(i),
                    title: '',
                    radius: 56,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: colorAt(i)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(items[i].name, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  '${formatMinor(items[i].amountMinor)} '
                  '(${(items[i].amountMinor * 100 / total).toStringAsFixed(1)}%)',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String monthName(int month) =>
    DateFormat.MMMM().format(DateTime(2000, month)).toString();

String shortMonthName(int month) =>
    DateFormat.MMM().format(DateTime(2000, month));
