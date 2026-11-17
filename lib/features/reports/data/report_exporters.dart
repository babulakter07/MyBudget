import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/report_document.dart';

/// Pure CSV encoder (no file IO). Amounts must already be plain decimals
/// (see [plainDecimal]); text cells are escaped by the csv package and
/// neutralised against spreadsheet formula injection.
class CsvExporter {
  const CsvExporter();

  /// Prefixes a quote when a user-supplied text cell would be interpreted as a
  /// formula by spreadsheet software.
  static String safeText(String s) {
    if (s.isEmpty) return s;
    const risky = {'=', '+', '-', '@', '\t', '\r'};
    return risky.contains(s[0]) ? "'$s" : s;
  }

  String encode(ReportDocument doc) {
    final rows = <List<String>>[
      [doc.title],
      ['Profile', safeText(doc.profileName)],
      ['Period', doc.period],
    ];
    for (final s in doc.sections) {
      rows.add(const []);
      rows.add([s.title]);
      rows.add(s.headers);
      for (final r in s.rows) {
        // Numeric-looking cells (plain decimals / '-' placeholder) stay as is.
        rows.add([for (final c in r) _isNumeric(c) ? c : safeText(c)]);
      }
    }
    return csv.encode(rows);
  }

  static final _num = RegExp(r'^-?\d+(\.\d+)?$');
  static bool _isNumeric(String c) => _num.hasMatch(c);

  /// UTF-8 with BOM so Excel detects the encoding (Bengali names).
  Uint8List bytes(ReportDocument doc) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(encode(doc))]);
}

/// Pure PDF builder. The default PDF fonts lack the Bengali taka sign and
/// Bengali glyphs, so callers should format money with a text prefix such as
/// 'BDT ' (see [pdfMoneyFormatter]); non-Latin names may render as blanks
/// unless a font is bundled.
class PdfExporter {
  const PdfExporter();

  Future<Uint8List> build(ReportDocument doc) async {
    final pdf = pw.Document(title: doc.title, author: 'MyBudget');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Text(
            doc.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Profile: ${doc.profileName}'),
          pw.Text('Period: ${doc.period}'),
          for (final s in doc.sections) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              s.title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            if (s.rows.isEmpty)
              pw.Text('No data', style: const pw.TextStyle(fontSize: 9))
            else
              pw.TableHelper.fromTextArray(
                headers: s.headers,
                data: s.rows,
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignments: {
                  for (var i = 1; i < s.headers.length; i++)
                    i: pw.Alignment.centerRight,
                },
              ),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }
}

/// Money text safe for default PDF fonts, e.g. 'BDT 12,000.50'.
MoneyFormatter pdfMoneyFormatter(String currencyCode) {
  return (minor) {
    final abs = minor.abs();
    final major = (abs ~/ 100).toString();
    final buf = StringBuffer();
    for (var i = 0; i < major.length; i++) {
      if (i > 0 && (major.length - i) % 3 == 0) buf.write(',');
      buf.write(major[i]);
    }
    final frac = (abs % 100).toString().padLeft(2, '0');
    return '${minor < 0 ? '-' : ''}$currencyCode $buf.$frac';
  };
}
