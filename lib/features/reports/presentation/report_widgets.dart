import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../data/report_exporters.dart';
import '../domain/report_document.dart';
import '../domain/report_models.dart';
import '../providers/report_providers.dart';

/// Money text for the UI ('৳' for BDT, otherwise the currency code).
String moneyText(int minor, String currencyCode) =>
    formatMinor(minor, symbol: currencyCode == 'BDT' ? '৳' : '$currencyCode ');

const chartPalette = <Color>[
  Color(0xFF1B7F5C),
  Color(0xFF1565C0),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFFC62828),
  Color(0xFF00838F),
  Color(0xFF9E9D24),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
  Color(0xFF546E7A),
];

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.subtitle,
  });
  final String label;
  final String value;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (subtitle != null)
              Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Two-column grid of summary cards.
class SummaryGrid extends StatelessWidget {
  const SummaryGrid({super.key, required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Simple responsive table (no horizontal overflow on phones).
class SimpleTable extends StatelessWidget {
  const SimpleTable({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyText = 'No data',
  });
  final List<String> headers;
  final List<List<String>> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(emptyText, style: theme.textTheme.bodyMedium),
      );
    }
    Widget cell(String t, int i, {bool bold = false}) => Expanded(
      flex: i == 0 ? 3 : 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          t,
          textAlign: i == 0 ? TextAlign.start : TextAlign.end,
          style:
              (bold ? theme.textTheme.labelMedium : theme.textTheme.bodySmall)
                  ?.copyWith(fontWeight: bold ? FontWeight.bold : null),
        ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  cell(headers[i], i, bold: true),
              ],
            ),
            const Divider(height: 1),
            for (final r in rows)
              Row(children: [for (var i = 0; i < r.length; i++) cell(r[i], i)]),
          ],
        ),
      ),
    );
  }
}

class CategoryPie extends StatelessWidget {
  const CategoryPie({
    super.key,
    required this.categories,
    required this.currencyCode,
  });
  final List<CategoryTotal> categories;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = categories.fold<int>(0, (a, c) => a + c.amountMinor);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < categories.length; i++)
                  PieChartSectionData(
                    value: categories[i].amountMinor / 100,
                    color: chartPalette[i % chartPalette.length],
                    radius: 56,
                    title:
                        (permille(categories[i].amountMinor, total) ?? 0) >= 50
                        ? percentText(
                            permille(categories[i].amountMinor, total),
                          )
                        : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < categories.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: chartPalette[i % chartPalette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categories[i].name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  moneyText(categories[i].amountMinor, currencyCode),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DailyBarChart extends StatelessWidget {
  const DailyBarChart({super.key, required this.daily});
  final List<DailyTotal> daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = daily.fold<int>(0, (a, d) => math.max(a, d.amountMinor));
    final step = daily.length > 40 ? 10 : 5;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY / 100 * 1.1,
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
                  if (i < 0 || i >= daily.length) return const SizedBox();
                  final show = i == 0 || (i + 1) % step == 0;
                  if (!show) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      daily[i].date.substring(8),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < daily.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: daily[i].amountMinor / 100,
                    color: AppColors.expense,
                    width: daily.length > 40 ? 3 : 5,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading / error / empty-aware wrapper for async report bodies.
class ReportAsyncBody<T> extends StatelessWidget {
  const ReportAsyncBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: builder,
    );
  }
}

/// AppBar export actions (PDF, CSV, print). [build] receives the money
/// formatter to use (plain decimals for CSV, 'BDT ' text for PDF).
List<Widget> exportActions({
  required BuildContext context,
  required WidgetRef ref,
  required bool enabled,
  required String currencyCode,
  required ReportDocument Function(MoneyFormatter f) build,
}) {
  Future<void> run(Future<void> Function() task) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  final svc = ref.read(reportFileServiceProvider);
  return [
    IconButton(
      tooltip: 'Export PDF',
      icon: const Icon(Icons.picture_as_pdf_outlined),
      onPressed: enabled
          ? () =>
                run(() => svc.sharePdf(build(pdfMoneyFormatter(currencyCode))))
          : null,
    ),
    IconButton(
      tooltip: 'Export CSV',
      icon: const Icon(Icons.table_view_outlined),
      onPressed: enabled
          ? () => run(() => svc.shareCsv(build(plainDecimal)))
          : null,
    ),
    IconButton(
      tooltip: 'Print',
      icon: const Icon(Icons.print_outlined),
      onPressed: enabled
          ? () =>
                run(() => svc.printPdf(build(pdfMoneyFormatter(currencyCode))))
          : null,
    ),
  ];
}

/// Prev / label / next navigation row used by month and year pickers.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Previous',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(label),
        ),
        IconButton(
          tooltip: 'Next',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}
