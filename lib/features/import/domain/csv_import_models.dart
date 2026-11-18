// CSV import domain types (no Flutter, no Drift).

/// Date layouts the user can pick for the date column.
enum CsvDateFormat {
  ddMmYyyySlash('dd/MM/yyyy'),
  yyyyMmDdDash('yyyy-MM-dd'),
  ddMmYyyyDash('dd-MM-yyyy'),
  mmDdYyyySlash('MM/dd/yyyy');

  const CsvDateFormat(this.label);
  final String label;
}

/// A parsed CSV file: an optional header row plus data rows (all strings).
class CsvTable {
  const CsvTable({
    required this.headers,
    required this.rows,
    required this.delimiter,
    required this.hasHeader,
  });

  /// Column names (generated "Column N" labels when there is no header row).
  final List<String> headers;
  final List<List<String>> rows;
  final String delimiter;
  final bool hasHeader;

  int get columnCount => headers.length;
}

/// Which CSV column feeds which field. `null` = not mapped.
class ColumnMapping {
  const ColumnMapping({
    this.date,
    this.amount,
    this.description,
    this.type,
    this.category,
    this.dateFormat = CsvDateFormat.ddMmYyyySlash,
  });

  final int? date;
  final int? amount;
  final int? description;

  /// Optional: a column holding expense/income words. When null the SIGN of
  /// the amount decides (negative = expense, positive = income).
  final int? type;

  /// Optional: category text matched to existing categories by exact
  /// case-insensitive name.
  final int? category;
  final CsvDateFormat dateFormat;

  bool get isComplete => date != null && amount != null;

  ColumnMapping copyWith({
    int? Function()? date,
    int? Function()? amount,
    int? Function()? description,
    int? Function()? type,
    int? Function()? category,
    CsvDateFormat? dateFormat,
  }) => ColumnMapping(
    date: date != null ? date() : this.date,
    amount: amount != null ? amount() : this.amount,
    description: description != null ? description() : this.description,
    type: type != null ? type() : this.type,
    category: category != null ? category() : this.category,
    dateFormat: dateFormat ?? this.dateFormat,
  );
}

enum ImportRowStatus { valid, duplicate, invalid }

class ImportRowPlan {
  const ImportRowPlan({
    required this.number,
    required this.cells,
    required this.status,
    this.errors = const [],
    this.isExpense,
    this.amountMinor,
    this.date,
    this.description,
    this.categoryId,
    this.categoryName,
    this.incomeSource,
    this.key,
  });

  /// 1-based data row number (header excluded).
  final int number;
  final List<String> cells;
  final ImportRowStatus status;
  final List<String> errors;
  final bool? isExpense;
  final int? amountMinor;

  /// 'yyyy-MM-dd'
  final String? date;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String? incomeSource;

  /// Idempotency key, `import:<sha256>:<n>`.
  final String? key;
}

class ImportPlan {
  const ImportPlan(this.rows);
  final List<ImportRowPlan> rows;

  int get validCount =>
      rows.where((r) => r.status == ImportRowStatus.valid).length;
  int get duplicateCount =>
      rows.where((r) => r.status == ImportRowStatus.duplicate).length;
  int get invalidCount =>
      rows.where((r) => r.status == ImportRowStatus.invalid).length;
}

class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skippedDuplicates,
    required this.invalid,
  });
  final int imported;
  final int skippedDuplicates;
  final int invalid;
}

/// What the user chose besides the column mapping.
class ImportSettings {
  const ImportSettings({
    required this.accountId,
    this.defaultCategoryId,
    required this.mapping,
  });
  final int accountId;

  /// Used for expense rows without a (matching) category.
  final int? defaultCategoryId;
  final ColumnMapping mapping;
}

/// File chosen through the [CsvFileGateway].
class PickedCsv {
  const PickedCsv({required this.name, required this.text});
  final String name;
  final String text;
}
