import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/pdf/shaped_text.dart';
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

/// PDF builder. Latin text and numbers are real PDF text; any string with
/// Bengali characters is shaped by Flutter's text engine and embedded as a
/// high-resolution image (the `pdf` package cannot shape Bengali itself), so
/// download, share and print all render Bangla names correctly. Money should
/// still be formatted with a text prefix such as 'BDT ' (see
/// [pdfMoneyFormatter]) because default PDF fonts lack the taka sign.
class PdfExporter {
  const PdfExporter({this.rasterizer = const ShapedTextRasterizer()});

  final ShapedTextRasterizer rasterizer;

  static const double _pageWidth = 595.28 - 56; // A4 minus margins

  Future<Uint8List> build(ReportDocument doc) async {
    final tf = PdfTextFactory(rasterizer);
    final children = <pw.Widget>[
      await tf.text(doc.title, fontSize: 20, bold: true),
      pw.SizedBox(height: 4),
      await tf.text('Profile: ${doc.profileName}'),
      await tf.text('Period: ${doc.period}'),
    ];
    for (final s in doc.sections) {
      children
        ..add(pw.SizedBox(height: 14))
        ..add(await tf.text(s.title, fontSize: 13, bold: true))
        ..add(pw.SizedBox(height: 4));
      if (s.rows.isEmpty) {
        children.add(await tf.text('No data', fontSize: 9));
      } else {
        children.add(await _table(tf, s));
      }
    }

    final pdf = pw.Document(title: doc.title, author: 'MyBudget');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => children,
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  Future<pw.Widget> _table(PdfTextFactory tf, ReportSection s) async {
    final cols = s.headers.length;
    final maxCell = (_pageWidth / cols - 10).clamp(40.0, 400.0);

    Future<pw.Widget> cell(String v, int i, {bool bold = false}) async {
      final align = i == 0 ? pw.Alignment.centerLeft : pw.Alignment.centerRight;
      return pw.Container(
        padding: const pw.EdgeInsets.all(5),
        alignment: align,
        child: await tf.text(
          v,
          fontSize: 8,
          bold: bold,
          maxWidth: maxCell,
          alignment: align,
        ),
      );
    }

    final header = pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        for (var i = 0; i < cols; i++) await cell(s.headers[i], i, bold: true),
      ],
    );
    final rows = <pw.TableRow>[];
    for (final r in s.rows) {
      rows.add(
        pw.TableRow(
          children: [
            for (var i = 0; i < cols; i++)
              await cell(i < r.length ? r[i] : '', i),
          ],
        ),
      );
    }
    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
      children: [header, ...rows],
    );
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
