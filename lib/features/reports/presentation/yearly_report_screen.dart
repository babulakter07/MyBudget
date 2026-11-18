import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/report_document.dart';
import '../domain/report_models.dart';
import '../providers/report_providers.dart';
import 'report_widgets.dart';

class YearlyReportScreen extends ConsumerStatefulWidget {
  const YearlyReportScreen({super.key, this.year});
  final int? year;

  @override
  ConsumerState<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends ConsumerState<YearlyReportScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.year ?? DateTime.now().year;
  }

  Future<void> _pick() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.reportsSelectYear),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            selectedDate: DateTime(_year),
            onChanged: (d) => Navigator.pop(ctx, d.year),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _year = picked);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(yearlyReportProvider(_year));
    final report = async.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reportsYearlyReport),
        actions: exportActions(
          context: context,
          ref: ref,
          enabled: report != null && !report.isEmpty,
          currencyCode: report?.currencyCode ?? 'BDT',
          build: (f) => ReportDocumentBuilder.yearly(report!, f),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PeriodNavigator(
              label: '$_year',
              onPrev: () => setState(() => _year--),
              onNext: () => setState(() => _year++),
              onPick: _pick,
            ),
          ),
          Expanded(
            child: ReportAsyncBody<YearlyReport>(
              value: async,
              onRetry: () => ref.invalidate(yearlyReportProvider(_year)),
              builder: (r) => r.isEmpty
                  ? EmptyState(
                      message: context.l10n.reportsNoDataYear,
                      icon: Icons.insert_chart_outlined,
                    )
                  : _YearlyBody(report: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearlyBody extends StatelessWidget {
  const _YearlyBody({required this.report});
  final YearlyReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;
    final cur = r.currencyCode;
    String m(int v) => moneyText(v, cur);
    String monthOf(YearlyMonthRow? row) => row == null
        ? '-'
        : '${localMonthShort(l, row.month)} (${m(row.expenseMinor)})';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SummaryGrid(
          cards: [
            SummaryCard(
              label: l.reportsIncome,
              value: m(r.incomeMinor),
              color: AppColors.income,
            ),
            SummaryCard(
              label: l.reportsExpense,
              value: m(r.expenseMinor),
              color: AppColors.expense,
            ),
            SummaryCard(
              label: l.reportsBudget,
              value: r.budgetMinor == null
                  ? l.reportsNotSet
                  : m(r.budgetMinor!),
            ),
            SummaryCard(
              label: l.reportsAvgMonthlyExpense,
              value: m(r.averageMonthlyExpenseMinor),
            ),
            SummaryCard(
              label: l.reportsHighestMonth,
              value: monthOf(r.highestSpendingMonth),
            ),
            SummaryCard(
              label: l.reportsLowestMonth,
              value: monthOf(r.lowestSpendingMonth),
            ),
          ],
        ),
        SectionTitle(l.reportsIncomeVsExpense),
        _IncomeExpenseChart(months: r.months),
        SectionTitle(l.reportsMonthlyComparison),
        SimpleTable(
          headers: [
            l.reportsMonth,
            l.reportsIncome,
            l.reportsExpense,
            l.reportsRemaining,
          ],
          rows: [
            for (final row in r.months)
              [
                localMonthName(l, row.month),
                m(row.incomeMinor),
                m(row.expenseMinor),
                row.remainingMinor == null ? '-' : m(row.remainingMinor!),
              ],
          ],
        ),
        SectionTitle(l.reportsCategoryComparison),
        SimpleTable(
          headers: [l.reportsCategory, l.reportsTotal],
          rows: [
            for (final c in r.categories) [c.name, m(c.totalMinor)],
          ],
        ),
      ],
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.months});
  final List<YearlyMonthRow> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i > 11) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          localMonthShort(context.l10n, i + 1).substring(0, 1),
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 1,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].incomeMinor / 100,
                        color: AppColors.income,
                        width: 7,
                      ),
                      BarChartRodData(
                        toY: months[i].expenseMinor / 100,
                        color: AppColors.expense,
                        width: 7,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: AppColors.income),
            const SizedBox(width: 4),
            Text(context.l10n.reportsIncome, style: theme.textTheme.bodySmall),
            const SizedBox(width: 16),
            Icon(Icons.circle, size: 10, color: AppColors.expense),
            const SizedBox(width: 4),
            Text(context.l10n.reportsExpense, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
