import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/report_document.dart';
import '../domain/report_models.dart';
import '../providers/report_providers.dart';
import 'report_widgets.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key, this.year, this.month});
  final int? year;
  final int? month;

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.year ?? now.year;
    _month = (widget.month ?? now.month).clamp(1, 12);
  }

  void _shift(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select any day in the month',
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (_year, _month);
    final async = ref.watch(monthlyReportProvider(key));
    final report = async.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly report'),
        actions: exportActions(
          context: context,
          ref: ref,
          enabled: report != null && !report.isEmpty,
          currencyCode: report?.currencyCode ?? 'BDT',
          build: (f) => ReportDocumentBuilder.monthly(report!, f),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PeriodNavigator(
              label: '${monthName(_month)} $_year',
              onPrev: () => _shift(-1),
              onNext: () => _shift(1),
              onPick: _pick,
            ),
          ),
          Expanded(
            child: ReportAsyncBody<MonthlyReport>(
              value: async,
              onRetry: () => ref.invalidate(monthlyReportProvider(key)),
              builder: (r) => r.isEmpty
                  ? const EmptyState(
                      message: 'No data for this month.',
                      icon: Icons.insert_chart_outlined,
                    )
                  : _MonthlyBody(report: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBody extends StatelessWidget {
  const _MonthlyBody({required this.report});
  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final cur = r.currencyCode;
    String m(int v) => moneyText(v, cur);
    final remaining = r.remainingMinor;
    final util = r.utilizationPermille;
    final negative = remaining != null && remaining < 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SummaryGrid(
          cards: [
            SummaryCard(
              label: 'Income',
              value: m(r.incomeMinor),
              color: AppColors.income,
            ),
            SummaryCard(
              label: 'Expense',
              value: m(r.expenseMinor),
              color: AppColors.expense,
            ),
            SummaryCard(
              label: 'Budget',
              value: r.budgetMinor == null ? 'Not set' : m(r.budgetMinor!),
            ),
            SummaryCard(
              label: 'Remaining',
              value: remaining == null ? '-' : m(remaining),
              color: negative ? AppColors.expense : null,
              subtitle: negative ? 'Over budget' : null,
            ),
            SummaryCard(label: 'Utilization', value: percentText(util)),
            SummaryCard(label: 'Net', value: m(r.netMinor)),
          ],
        ),
        const SectionTitle('Category-wise expense'),
        if (r.categories.isEmpty)
          const Text('No expenses this month.')
        else
          CategoryPie(categories: r.categories, currencyCode: cur),
        const SectionTitle('Daily expenditure'),
        DailyBarChart(daily: r.daily),
        const SectionTitle('Sub-categories'),
        SimpleTable(
          headers: const ['Sub-category', 'Amount'],
          rows: [
            for (final s in r.subCategories)
              ['${s.categoryName} / ${s.name}', m(s.amountMinor)],
          ],
        ),
        const SectionTitle('Items'),
        SimpleTable(
          headers: const ['Item', 'Amount'],
          rows: [
            for (final i in r.items)
              [
                '${i.name}\n${i.categoryName} / ${i.subCategoryName}',
                m(i.amountMinor),
              ],
          ],
        ),
        const SectionTitle('Account movements'),
        SimpleTable(
          headers: const ['Account', 'Opening', 'Closing'],
          rows: [
            for (final a in r.accounts)
              [
                '${a.accountName}\n+${m(a.incomeMinor)}  -${m(a.expenseMinor)}  '
                    'in ${m(a.transferInMinor)}  out ${m(a.transferOutMinor)}',
                m(a.openingMinor),
                m(a.closingMinor),
              ],
          ],
        ),
      ],
    );
  }
}
