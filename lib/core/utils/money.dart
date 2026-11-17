// Decimal-safe money helpers. Amounts are integer minor units (paisa).

final RegExp _moneyPattern = RegExp(r'^\d+(\.\d{1,2})?$');

/// Parses "12000", "12,000.50", "12000.5" into minor units. Returns null for
/// empty, negative, malformed, or >2-decimal input.
int? parseMajorToMinor(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('৳')) s = s.substring(1).trim();
  if (s.contains(',')) {
    final intPart = s.split('.').first;
    if (!RegExp(r'^\d{1,3}(,\d{3})*$').hasMatch(intPart)) return null;
    s = s.replaceAll(',', '');
  }
  if (!_moneyPattern.hasMatch(s)) return null;
  final parts = s.split('.');
  final major = int.tryParse(parts[0]);
  if (major == null) return null;
  var frac = parts.length > 1 ? parts[1] : '';
  frac = frac.padRight(2, '0');
  final minor = major * 100 + int.parse(frac);
  if (major > 9007199254740991 ~/ 100) return null;
  return minor;
}

/// Formats minor units, e.g. 1200050 -> "৳12,000.50".
String formatMinor(int minor, {String symbol = '৳'}) {
  final negative = minor < 0;
  final abs = minor.abs();
  final major = (abs ~/ 100).toString();
  final frac = (abs % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < major.length; i++) {
    if (i > 0 && (major.length - i) % 3 == 0) buf.write(',');
    buf.write(major[i]);
  }
  return '${negative ? '-' : ''}$symbol$buf.$frac';
}
