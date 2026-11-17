import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/report_document.dart';
import '../domain/report_models.dart';
import '../providers/report_providers.dart';
import 'report_widgets.dart';

/// Route: /reports/range
class CustomRangeReportScreen extends ConsumerStatefulWidget {
  const CustomRangeReportScreen({super.key, this.from, this.to});

  /// Optional initial bounds ('yyyy-MM-dd'); default is this month to today.
  final String? from;
  final String? to;

  @override
  ConsumerState<CustomRangeReportScreen> createState() =>
      _CustomRangeReportScreenState();
}

class _CustomRangeReportScreenState
    extends ConsumerState<CustomRangeReportScreen> {
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.from ?? monthStartKey(now.year, now.month);
    _to = widget.to ?? dateKey(now);
  }

  Future<void> _pick() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: isValidDateKey(_from) && isValidDateKey(_to)
          ? DateTimeRange(start: parseDateKey(_from), end: parseDateKey(_to))
          : null,
    );
    if (picked != null) {
      setState(() {
        _from = dateKey(picked.start);
        _to = dateKey(picked.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (_from, _to);
    final async = ref.watch(rangeReportProvider(key));
    final report = async.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom range report'),
        actions: exportActions(
          context: context,
          ref: ref,
          enabled: report != null && !report.isEmpty,
          currencyCode: report?.currencyCode ?? 'BDT',
          build: (f) => ReportDocumentBuilder.range(report!, f),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.date_range),
                label: Text('$_from  to  $_to'),
              ),
            ),
          ),
          Expanded(
            child: ReportAsyncBody<RangeReport>(
              value: async,
              onRetry: () => ref.invalidate(rangeReportProvider(key)),
              builder: (r) => r.isEmpty
                  ? const EmptyState(
                      message: 'No transactions in this range.',
                      icon: Icons.insert_chart_outlined,
                    )
                  : _RangeBody(report: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBody extends StatelessWidget {
  const _RangeBody({required this.report});
  final RangeReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    String m(int v) => moneyText(v, r.currencyCode);
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
            SummaryCard(label: 'Net', value: m(r.netMinor)),
          ],
        ),
        const SectionTitle('Category-wise expense'),
        if (r.categories.isEmpty)
          const Text('No expenses in this range.')
        else
          CategoryPie(categories: r.categories, currencyCode: r.currencyCode),
        const SectionTitle('Daily expenditure'),
        DailyBarChart(daily: r.daily),
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
      ],
    );
  }
}
