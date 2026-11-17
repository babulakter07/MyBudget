// Date helpers. Transaction/opening dates are stored as local 'yyyy-MM-dd'
// text so they sort, group and filter correctly without timezone drift.

String two(int n) => n.toString().padLeft(2, '0');

/// 'yyyy-MM-dd' for a local calendar date.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';

/// Parses 'yyyy-MM-dd' to a local midnight DateTime (throws FormatException).
DateTime parseDateKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) throw FormatException('Invalid date key: $key');
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) {
    throw FormatException('Invalid calendar date: $key');
  }
  return dt;
}

bool isValidDateKey(String key) {
  try {
    parseDateKey(key);
    return true;
  } on FormatException {
    return false;
  }
}

/// First day of the month, 'yyyy-MM-dd'.
String monthStartKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${two(month)}-01';

/// Last day of the month (leap-year safe), 'yyyy-MM-dd'.
String monthEndKey(int year, int month) =>
    dateKey(DateTime(year, month + 1, 0));

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// 'yyyy-MM' prefix, handy for `substr(txn_date,1,7)` grouping.
String monthKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${two(month)}';
