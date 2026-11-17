import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/report_document.dart';
import 'report_exporters.dart';

/// Writes exports to the temp directory and shares/prints them. Kept apart
/// from the pure exporters so those stay unit-testable.
class ReportFileService {
  ReportFileService({Future<Directory> Function()? directoryProvider})
    : _dir = directoryProvider ?? getTemporaryDirectory;

  final Future<Directory> Function() _dir;

  Future<File> writeBytes(String fileName, Uint8List bytes) async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      return await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      throw AppException('Could not write the export file: ${e.message}');
    }
  }

  Future<File> saveCsv(ReportDocument csvDoc) => writeBytes(
    '${csvDoc.fileBaseName}.csv',
    const CsvExporter().bytes(csvDoc),
  );

  Future<File> savePdf(ReportDocument pdfDoc) async => writeBytes(
    '${pdfDoc.fileBaseName}.pdf',
    await const PdfExporter().build(pdfDoc),
  );

  Future<void> shareFile(File file, String mime, String subject) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: subject,
      ),
    );
  }

  Future<void> shareCsv(ReportDocument csvDoc) async {
    final f = await saveCsv(csvDoc);
    await shareFile(f, 'text/csv', '${csvDoc.title} - ${csvDoc.period}');
  }

  Future<void> sharePdf(ReportDocument pdfDoc) async {
    final f = await savePdf(pdfDoc);
    await shareFile(f, 'application/pdf', '${pdfDoc.title} - ${pdfDoc.period}');
  }

  /// Opens the system print / preview dialog.
  Future<void> printPdf(ReportDocument pdfDoc) async {
    final bytes = await const PdfExporter().build(pdfDoc);
    await Printing.layoutPdf(
      name: pdfDoc.fileBaseName,
      onLayout: (_) async => bytes,
    );
  }
}
