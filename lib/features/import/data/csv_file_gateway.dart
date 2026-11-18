import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/csv_import_models.dart';

/// Picks a CSV file. Behind an interface so tests can inject text without a
/// platform file picker.
abstract class CsvFileGateway {
  /// Returns null when the user cancels.
  Future<PickedCsv?> pick();
}

class FilePickerCsvGateway implements CsvFileGateway {
  const FilePickerCsvGateway();

  /// Files larger than this are refused (about 20k rows of typical data).
  static const int maxBytes = 8 * 1024 * 1024;

  @override
  Future<PickedCsv?> pick() async {
    // FileType.any: Android reports CSV with inconsistent MIME types, so an
    // extension filter hides valid files on some devices.
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw ValidationException('That file is too large (max 8 MB).');
    }
    try {
      return PickedCsv(name: file.name, text: utf8.decode(bytes));
    } on FormatException {
      // Excel "CSV" exports are sometimes Latin-1; decode leniently.
      return PickedCsv(name: file.name, text: latin1.decode(bytes));
    }
  }
}
