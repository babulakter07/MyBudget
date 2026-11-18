import 'package:csv/csv.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../domain/csv_import_models.dart';

/// Hard cap so a huge file cannot freeze the app.
const int maxCsvImportRows = 20000;

/// Picks `,` `;` tab or `|` by counting delimiters outside quotes in the first
/// non-empty lines. Ties go to the comma.
String detectDelimiter(String text) {
  const candidates = [',', ';', '\t', '|'];
  final counts = {for (final c in candidates) c: 0};
  var inQuotes = false;
  var lines = 0;
  for (var i = 0; i < text.length && lines < 5; i++) {
    final ch = text[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (!inQuotes) {
      if (ch == '\n') {
        lines++;
      } else if (counts.containsKey(ch)) {
        counts[ch] = counts[ch]! + 1;
      }
    }
  }
  var best = ',';
  var bestCount = 0;
  for (final c in candidates) {
    if (counts[c]! > bestCount) {
      best = c;
      bestCount = counts[c]!;
    }
  }
  return best;
}

/// Parses CSV text: BOM, CRLF/LF/CR line endings, quoted fields with embedded
/// commas/quotes/newlines, `,` / `;` / tab / `|` delimiters (auto-detected).
/// Blank lines are skipped. Throws [ValidationException] for empty input.
CsvTable parseCsv(String text, {bool hasHeader = true, String? delimiter}) {
  var t = text;
  if (t.startsWith('﻿')) t = t.substring(1);
  if (t.trim().isEmpty) {
    throw ValidationException('The file is empty.');
  }
  final d = delimiter ?? detectDelimiter(t);
  final raw = Csv(
    fieldDelimiter: d,
    autoDetect: false,
    skipEmptyLines: true,
  ).decode(t);
  final all = <List<String>>[];
  for (final r in raw) {
    final cells = [for (final c in r) '$c'.trim()];
    if (cells.every((c) => c.isEmpty)) continue;
    all.add(cells);
  }
  if (all.isEmpty) throw ValidationException('The file has no rows.');
  final width = all.fold<int>(0, (m, r) => r.length > m ? r.length : m);
  List<String> pad(List<String> r) =>
      r.length >= width ? r : [...r, for (var i = r.length; i < width; i++) ''];
  final headers = hasHeader
      ? [
          for (var i = 0; i < width; i++)
            (i < all.first.length && all.first[i].isNotEmpty)
                ? all.first[i]
                : 'Column ${i + 1}',
        ]
      : [for (var i = 0; i < width; i++) 'Column ${i + 1}'];
  final dataRows = (hasHeader ? all.skip(1) : all).map(pad).toList();
  if (dataRows.length > maxCsvImportRows) {
    throw ValidationException(
      'The file has more than $maxCsvImportRows rows. Split it and import '
      'in parts.',
    );
  }
  return CsvTable(
    headers: headers,
    rows: dataRows,
    delimiter: d,
    hasHeader: hasHeader,
  );
}

/// Best-effort column guess from header names (each column used once).
ColumnMapping guessMapping(CsvTable table) {
  final used = <int>{};
  int? find(List<String> words, {bool exact = false}) {
    for (var i = 0; i < table.headers.length; i++) {
      if (used.contains(i)) continue;
      final h = table.headers[i].toLowerCase().trim();
      final hit = exact ? words.contains(h) : words.any(h.contains);
      if (hit) {
        used.add(i);
        return i;
      }
    }
    return null;
  }

  final date = find(['date', 'time', 'day']);
  final amount = find(['amount', 'amt', 'value', 'total', 'sum', 'price']);
  final type = find(['type', 'dr/cr', 'kind', 'direction']);
  final category = find(['category', 'cat']);
  final description = find([
    'description',
    'desc',
    'detail',
    'narration',
    'memo',
    'note',
    'title',
    'particular',
    'remark',
    'payee',
    'name',
  ]);
  return ColumnMapping(
    date: date,
    amount: amount,
    description: description,
    type: type,
    category: category,
    dateFormat: guessDateFormat(table, date),
  );
}

/// Sniffs the date layout from sample values; defaults to dd/MM/yyyy.
CsvDateFormat guessDateFormat(CsvTable table, int? col) {
  if (col == null) return CsvDateFormat.ddMmYyyySlash;
  var iso = false, dash = false, firstOver12 = false, secondOver12 = false;
  for (final r in table.rows.take(50)) {
    final v = col < r.length ? r[col].trim() : '';
    if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}').hasMatch(v)) iso = true;
    final m = RegExp(r'^(\d{1,2})([/.-])(\d{1,2})[/.-]\d{4}').firstMatch(v);
    if (m != null) {
      if (m[2] == '-') dash = true;
      if (int.parse(m[1]!) > 12) firstOver12 = true;
      if (int.parse(m[3]!) > 12) secondOver12 = true;
    }
  }
  if (iso) return CsvDateFormat.yyyyMmDdDash;
  if (secondOver12 && !firstOver12) return CsvDateFormat.mmDdYyyySlash;
  if (dash) return CsvDateFormat.ddMmYyyyDash;
  return CsvDateFormat.ddMmYyyySlash;
}

/// Parses [raw] with the user's chosen [format] into 'yyyy-MM-dd', or null.
/// A trailing time part ("2024-05-01 10:30", "...T10:30:00") is ignored.
String? parseCsvDate(String raw, CsvDateFormat format) {
  var v = raw.trim();
  if (v.isEmpty) return null;
  final cut = RegExp(r'[ T]').firstMatch(v);
  if (cut != null) v = v.substring(0, cut.start);
  final RegExp re;
  switch (format) {
    case CsvDateFormat.ddMmYyyySlash:
      re = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    case CsvDateFormat.yyyyMmDdDash:
      re = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
    case CsvDateFormat.ddMmYyyyDash:
      re = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$');
    case CsvDateFormat.mmDdYyyySlash:
      re = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
  }
  final m = re.firstMatch(v);
  if (m == null) return null;
  final a = int.parse(m[1]!), b = int.parse(m[2]!), c = int.parse(m[3]!);
  final int y, mo, d;
  switch (format) {
    case CsvDateFormat.yyyyMmDdDash:
      y = a;
      mo = b;
      d = c;
    case CsvDateFormat.mmDdYyyySlash:
      y = c;
      mo = a;
      d = b;
    default:
      y = c;
      mo = b;
      d = a;
  }
  if (y < 1970 || y > 9999) return null;
  final key = '${y.toString().padLeft(4, '0')}-${two(mo)}-${two(d)}';
  return isValidDateKey(key) ? key : null;
}

/// Parses a statement-style amount into SIGNED minor units, or null.
/// Accepts "1,234.50", "-500", "(500)", "৳500", "-৳500", "500-", "+75.5",
/// "BDT 1,000", "Tk. 20". Never uses doubles. Zero is returned as 0 (callers
/// reject it).
int? parseSignedAmount(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  var negative = false;
  if (s.startsWith('(') && s.endsWith(')')) {
    negative = true;
    s = s.substring(1, s.length - 1).trim();
  }
  s = s.replaceAll('−', '-'); // unicode minus
  for (var i = 0; i < 3; i++) {
    s = s.trim();
    if (s.startsWith('-')) {
      negative = !negative;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    } else if (s.endsWith('-')) {
      negative = !negative;
      s = s.substring(0, s.length - 1);
    } else if (s.startsWith('৳')) {
      s = s.substring(1);
    } else if (s.endsWith('৳')) {
      s = s.substring(0, s.length - 1);
    } else {
      final low = s.toLowerCase();
      if (low.startsWith('bdt')) {
        s = s.substring(3);
      } else if (low.startsWith('tk.')) {
        s = s.substring(3);
      } else if (low.startsWith('tk')) {
        s = s.substring(2);
      } else if (low.endsWith('bdt')) {
        s = s.substring(0, s.length - 3);
      } else if (low.endsWith('tk')) {
        s = s.substring(0, s.length - 2);
      } else {
        break;
      }
    }
  }
  final minor = parseMajorToMinor(s.trim());
  if (minor == null) return null;
  return negative ? -minor : minor;
}

/// Maps a type-column value to expense (true) / income (false) / unknown.
bool? parseTypeWord(String raw) {
  final v = raw.trim().toLowerCase();
  const expense = {
    'expense',
    'expenses',
    'debit',
    'dr',
    'withdrawal',
    'withdraw',
    'out',
    'payment',
    'spent',
    'cost',
  };
  const income = {
    'income',
    'credit',
    'cr',
    'deposit',
    'in',
    'received',
    'salary',
    'earning',
  };
  if (expense.contains(v)) return true;
  if (income.contains(v)) return false;
  return null;
}
