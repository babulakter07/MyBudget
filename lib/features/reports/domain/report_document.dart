/// Neutral, export-ready tabular form of a report (pure Dart, no Flutter).
library;

import '../../../core/utils/date_keys.dart';
import 'report_models.dart';

typedef MoneyFormatter = String Function(int minor);

/// Plain decimal like `12000.50` / `-5.00` from minor units, ints only.
String plainDecimal(int minor) {
  final abs = minor.abs();
  return '${minor < 0 ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

/// "12.5%" from per-mille ints; '-' when null.
String percentText(int? permilleValue) {
  if (permilleValue == null) return '-';
  return '${permilleValue ~/ 10}.${permilleValue % 10}%';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthName(int month) => _monthNames[month - 1];

class ReportSection {
  const ReportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

class ReportDocument {
  const ReportDocument({
    required this.title,
    required this.profileName,
    required this.period,
    required this.fileBaseName,
    required this.sections,
  });
  final String title;
  final String profileName;
  final String period;

  /// File name without extension.
  final String fileBaseName;
  final List<ReportSection> sections;
}

String _slug(String s) {
  final out = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return out.isEmpty ? 'profile' : out;
}

List<List<String>> _catRows(
  List<CategoryTotal> cats,
  int total,
  MoneyFormatter f,
) => [
  for (final c in cats)
    [c.name, f(c.amountMinor), percentText(permille(c.amountMinor, total))],
];

/// Builds [ReportDocument]s with the supplied money formatter (plain decimals
/// for CSV, currency-prefixed text for PDF).
List<List<String>> _txnRows(List<ReportTxn> txns, MoneyFormatter f) => [
  for (final t in txns)
    [
      t.date,
      t.type == 'income' ? 'Income' : 'Expense',
      '${t.categoryName} / ${t.itemName}',
      t.title ?? '-',
      t.remarks ?? '-',
      f(t.amountMinor),
    ],
];

const _txnHeaders = [
  'Date',
  'Type',
  'Category / Item',
  'Title',
  'Comment',
  'Amount',
];

class ReportDocumentBuilder {
  ReportDocumentBuilder._();

  static ReportDocument monthly(MonthlyReport r, MoneyFormatter f) {
    final period = '${monthName(r.month)} ${r.year}';
    return ReportDocument(
      title: 'Monthly Report',
      profileName: r.profileName,
      period: period,
      fileBaseName:
          'monthly_report_${_slug(r.profileName)}_${monthKey(r.year, r.month)}',
      sections: [
        ReportSection(
          title: 'Summary',
          headers: const ['Item', 'Amount'],
          rows: [
            ['Total income', f(r.incomeMinor)],
            ['Total expense', f(r.expenseMinor)],
            ['Budget', r.budgetMinor == null ? '-' : f(r.budgetMinor!)],
            [
              'Remaining',
              r.remainingMinor == null ? '-' : f(r.remainingMinor!),
            ],
            ['Budget utilization', percentText(r.utilizationPermille)],
          ],
        ),
        ReportSection(
          title: 'Category-wise expense',
          headers: const ['Category', 'Amount', 'Share'],
          rows: _catRows(r.categories, r.expenseMinor, f),
        ),
        ReportSection(
          title: 'Sub-category-wise expense',
          headers: const ['Category', 'Sub-category', 'Amount'],
          rows: [
            for (final s in r.subCategories)
              [s.categoryName, s.name, f(s.amountMinor)],
          ],
        ),
        ReportSection(
          title: 'Item-wise expense',
          headers: const ['Category', 'Sub-category', 'Item', 'Amount'],
          rows: [
            for (final i in r.items)
              [i.categoryName, i.subCategoryName, i.name, f(i.amountMinor)],
          ],
        ),
        ReportSection(
          title: 'Transactions',
          headers: _txnHeaders,
          rows: _txnRows(r.transactions, f),
        ),
        ReportSection(
          title: 'Daily expenditure',
          headers: const ['Date', 'Expense'],
          rows: [
            for (final d in r.daily) [d.date, f(d.amountMinor)],
          ],
        ),
        ReportSection(
          title: 'Account movements',
          headers: const [
            'Account',
            'Opening',
            'Income',
            'Expense',
            'Transfer in',
            'Transfer out',
            'Closing',
          ],
          rows: [
            for (final a in r.accounts)
              [
                a.accountName,
                f(a.openingMinor),
                f(a.incomeMinor),
                f(a.expenseMinor),
                f(a.transferInMinor),
                f(a.transferOutMinor),
                f(a.closingMinor),
              ],
          ],
        ),
      ],
    );
  }

  static ReportDocument yearly(YearlyReport r, MoneyFormatter f) {
    String monthOf(YearlyMonthRow? m) =>
        m == null ? '-' : '${monthName(m.month)} (${f(m.expenseMinor)})';
    return ReportDocument(
      title: 'Yearly Report',
      profileName: r.profileName,
      period: '${r.year}',
      fileBaseName: 'yearly_report_${_slug(r.profileName)}_${r.year}',
      sections: [
        ReportSection(
          title: 'Summary',
          headers: const ['Item', 'Amount'],
          rows: [
            ['Total income', f(r.incomeMinor)],
            ['Total expense', f(r.expenseMinor)],
            ['Budget', r.budgetMinor == null ? '-' : f(r.budgetMinor!)],
            [
              'Remaining',
              r.remainingMinor == null ? '-' : f(r.remainingMinor!),
            ],
            ['Average monthly expense', f(r.averageMonthlyExpenseMinor)],
            ['Highest spending month', monthOf(r.highestSpendingMonth)],
            ['Lowest spending month', monthOf(r.lowestSpendingMonth)],
          ],
        ),
        ReportSection(
          title: 'Monthly comparison',
          headers: const ['Month', 'Income', 'Expense', 'Budget', 'Remaining'],
          rows: [
            for (final m in r.months)
              [
                monthName(m.month),
                f(m.incomeMinor),
                f(m.expenseMinor),
                m.budgetMinor == null ? '-' : f(m.budgetMinor!),
                m.remainingMinor == null ? '-' : f(m.remainingMinor!),
              ],
          ],
        ),
        ReportSection(
          title: 'Category comparison',
          headers: [
            'Category',
            for (var m = 1; m <= 12; m++) monthName(m).substring(0, 3),
            'Total',
          ],
          rows: [
            for (final c in r.categories)
              [c.name, for (final v in c.monthlyMinor) f(v), f(c.totalMinor)],
          ],
        ),
      ],
    );
  }

  static ReportDocument range(RangeReport r, MoneyFormatter f) {
    return ReportDocument(
      title: 'Custom Range Report',
      profileName: r.profileName,
      period: '${r.from} to ${r.to}',
      fileBaseName: 'range_report_${_slug(r.profileName)}_${r.from}_${r.to}',
      sections: [
        ReportSection(
          title: 'Summary',
          headers: const ['Item', 'Amount'],
          rows: [
            ['Total income', f(r.incomeMinor)],
            ['Total expense', f(r.expenseMinor)],
            ['Net', f(r.netMinor)],
          ],
        ),
        ReportSection(
          title: 'Category-wise expense',
          headers: const ['Category', 'Amount', 'Share'],
          rows: _catRows(r.categories, r.expenseMinor, f),
        ),
        ReportSection(
          title: 'Item-wise expense',
          headers: const ['Category', 'Sub-category', 'Item', 'Amount'],
          rows: [
            for (final i in r.items)
              [i.categoryName, i.subCategoryName, i.name, f(i.amountMinor)],
          ],
        ),
        ReportSection(
          title: 'Transactions',
          headers: _txnHeaders,
          rows: _txnRows(r.transactions, f),
        ),
        ReportSection(
          title: 'Daily expenditure',
          headers: const ['Date', 'Expense'],
          rows: [
            for (final d in r.daily) [d.date, f(d.amountMinor)],
          ],
        ),
      ],
    );
  }
}
