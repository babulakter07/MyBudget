import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:my_budget/core/pdf/shaped_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/reports/data/report_exporters.dart';
import 'package:my_budget/features/reports/data/report_file_service.dart';
import 'package:my_budget/features/reports/domain/report_document.dart';
import 'package:my_budget/features/reports/domain/report_models.dart';

MonthlyReport _report({String catName = 'Food', String profile = 'Home'}) =>
    MonthlyReport(
      profileId: 1,
      profileName: profile,
      currencyCode: 'BDT',
      year: 2026,
      month: 3,
      incomeMinor: 1200050,
      expenseMinor: 5,
      budgetMinor: null,
      categories: [CategoryTotal(categoryId: 1, name: catName, amountMinor: 5)],
      subCategories: const [],
      items: const [],
      daily: const [DailyTotal(date: '2026-03-01', amountMinor: 5)],
      accounts: const [],
    );

void main() {
  test('plainDecimal formats minor units without float math', () {
    expect(plainDecimal(1200050), '12000.50');
    expect(plainDecimal(5), '0.05');
    expect(plainDecimal(0), '0.00');
    expect(plainDecimal(-1999), '-19.99');
    expect(plainDecimal(100), '1.00');
    expect(percentText(null), '-');
    expect(percentText(505), '50.5%');
  });

  test('CSV escapes commas, quotes and newlines (round trip)', () {
    const nasty = 'Eat, "out"\nsecond line';
    final doc = ReportDocumentBuilder.monthly(
      _report(catName: nasty),
      plainDecimal,
    );
    final text = const CsvExporter().encode(doc);
    final rows = csv.decode(text);
    final catRow = rows.firstWhere((r) => r.isNotEmpty && r[0] == nasty);
    expect(catRow[1].toString(), '0.05');
    // Amount cell is a plain decimal.
    final inc = rows.firstWhere((r) => r.isNotEmpty && r[0] == 'Total income');
    expect(inc[1].toString(), '12000.50');
    final bytes = const CsvExporter().bytes(doc);
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.sublist(3)), text);
  });

  test('CSV neutralises formula injection in text cells', () {
    final doc = ReportDocumentBuilder.monthly(
      _report(catName: '=HYPERLINK("x")', profile: '+cmd'),
      plainDecimal,
    );
    final rows = csv.decode(const CsvExporter().encode(doc));
    expect(
      rows.any((r) => r.isNotEmpty && r[0] == "'=HYPERLINK(\"x\")"),
      isTrue,
    );
    expect(rows.any((r) => r.length > 1 && r[1] == "'+cmd"), isTrue);
    // Negative amounts are not mangled.
    final neg = ReportDocumentBuilder.range(
      RangeReport(
        profileId: 1,
        profileName: 'P',
        currencyCode: 'BDT',
        from: '2026-01-01',
        to: '2026-01-01',
        incomeMinor: 0,
        expenseMinor: 500,
        categories: const [],
        subCategories: const [],
        items: const [],
        daily: const [],
      ),
      plainDecimal,
    );
    final text = const CsvExporter().encode(neg);
    expect(text, contains('-5.00'));
    expect(text, isNot(contains("'-5.00")));
  });

  test('PDF bytes start with %PDF', () async {
    final doc = ReportDocumentBuilder.monthly(
      _report(),
      pdfMoneyFormatter('BDT'),
    );
    final bytes = await const PdfExporter().build(doc);
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });

  test('PDF money formatter uses currency text, not the taka sign', () {
    final f = pdfMoneyFormatter('BDT');
    expect(f(1200050), 'BDT 12,000.50');
    expect(f(-5), '-BDT 0.05');
  });

  test('yearly document has 12 monthly rows and PDF builds', () async {
    final y = YearlyReport(
      profileId: 1,
      profileName: 'Home',
      currencyCode: 'BDT',
      year: 2026,
      months: [
        for (var m = 1; m <= 12; m++)
          YearlyMonthRow(
            month: m,
            incomeMinor: 0,
            expenseMinor: m == 2 ? 100 : 0,
            budgetMinor: null,
          ),
      ],
      categories: [
        CategoryYearRow(
          categoryId: 1,
          name: 'Food',
          monthlyMinor: List.generate(12, (i) => i == 1 ? 100 : 0),
        ),
      ],
    );
    final doc = ReportDocumentBuilder.yearly(y, plainDecimal);
    expect(
      doc.sections.firstWhere((s) => s.title == 'Monthly comparison').rows,
      hasLength(12),
    );
    final bytes = await const PdfExporter().build(
      ReportDocumentBuilder.yearly(y, pdfMoneyFormatter('BDT')),
    );
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('ReportFileService writes files into the given directory', () async {
    final dir = await Directory.systemTemp.createTemp('rep_test');
    addTearDown(() => dir.delete(recursive: true));
    final svc = ReportFileService(directoryProvider: () async => dir);
    final doc = ReportDocumentBuilder.monthly(_report(), plainDecimal);
    final f = await svc.saveCsv(doc);
    expect(f.path, endsWith('.csv'));
    expect(await f.exists(), isTrue);
    final p = await svc.savePdf(
      ReportDocumentBuilder.monthly(_report(), pdfMoneyFormatter('BDT')),
    );
    expect(String.fromCharCodes((await p.readAsBytes()).sublist(0, 4)), '%PDF');
  });

  testWidgets('PDF with Bangla names embeds shaped images, Latin stays text', (
    tester,
  ) async {
    const doc = ReportDocument(
      title: 'Monthly Report',
      profileName: 'আমার পরিবার',
      period: 'May 2026',
      fileBaseName: 'bn',
      sections: [
        ReportSection(
          title: 'Category-wise expense',
          headers: ['Category', 'Amount'],
          rows: [
            ['বাজার খরচ', 'BDT 1,200.00'],
            ['Food', 'BDT 5.00'],
          ],
        ),
      ],
    );
    final bytes = await tester.runAsync(() => const PdfExporter().build(doc));
    final raw = String.fromCharCodes(bytes!);
    expect(raw.substring(0, 5), '%PDF-');
    expect(raw, contains('/Subtype/Image'));
    expect(needsShaping('বাজার'), isTrue);
    expect(needsShaping('Food 12'), isFalse);
  });
}
