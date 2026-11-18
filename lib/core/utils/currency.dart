// Integer-only currency helpers for manual exchange rates.
//
// A rate is stored as `rateMicro` = base major units per 1 foreign major unit
// x 1,000,000 (e.g. 1 USD = 122.5 BDT -> 122500000). Money is never a double.

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol);
  final String code;
  final String name;
  final String symbol;
}

/// Currencies offered in pickers. Any 3-letter code is also accepted.
const List<CurrencyInfo> knownCurrencies = [
  CurrencyInfo('BDT', 'Bangladeshi Taka', '\u09F3'),
  CurrencyInfo('USD', 'US Dollar', '\$'),
  CurrencyInfo('EUR', 'Euro', '\u20AC'),
  CurrencyInfo('GBP', 'British Pound', '\u00A3'),
  CurrencyInfo('INR', 'Indian Rupee', '\u20B9'),
  CurrencyInfo('SAR', 'Saudi Riyal', 'SAR'),
  CurrencyInfo('AED', 'UAE Dirham', 'AED'),
  CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM'),
  CurrencyInfo('SGD', 'Singapore Dollar', 'S\$'),
  CurrencyInfo('CAD', 'Canadian Dollar', 'C\$'),
  CurrencyInfo('AUD', 'Australian Dollar', 'A\$'),
  CurrencyInfo('JPY', 'Japanese Yen', '\u00A5'),
  CurrencyInfo('CNY', 'Chinese Yuan', 'CN\u00A5'),
  CurrencyInfo('KWD', 'Kuwaiti Dinar', 'KWD'),
  CurrencyInfo('QAR', 'Qatari Riyal', 'QAR'),
  CurrencyInfo('OMR', 'Omani Rial', 'OMR'),
];

String currencySymbol(String code) {
  final c = code.toUpperCase();
  for (final i in knownCurrencies) {
    if (i.code == c) return i.symbol;
  }
  return c;
}

final RegExp _codePattern = RegExp(r'^[A-Z]{3}$');

/// Upper-cases and validates a 3-letter currency code; null if invalid.
String? normalizeCurrencyCode(String input) {
  final c = input.trim().toUpperCase();
  return _codePattern.hasMatch(c) ? c : null;
}

const int rateScale = 1000000;

/// Largest accepted rate (base per 1 foreign): 1,000,000.
const int maxRateMicro = 1000000 * rateScale;

/// Parses "122.5", "0.0082", "1,200.123456" into rateMicro. Up to 6 decimals;
/// null when empty, malformed, zero, or above [maxRateMicro].
int? parseRateToMicro(String input) {
  var s = input.trim().replaceAll(',', '');
  if (s.isEmpty || !RegExp(r'^\d+(\.\d{1,6})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final major = BigInt.parse(parts[0]);
  final frac = (parts.length > 1 ? parts[1] : '').padRight(6, '0');
  final micro = major * BigInt.from(rateScale) + BigInt.parse(frac);
  if (micro <= BigInt.zero || micro > BigInt.from(maxRateMicro)) return null;
  return micro.toInt();
}

/// 122500000 -> "122.5" (trailing zeros trimmed, at least 2 decimals shown
/// only when needed).
String formatRate(int rateMicro) {
  final major = rateMicro ~/ rateScale;
  var frac = (rateMicro % rateScale).toString().padLeft(6, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$major' : '$major.$frac';
}

/// Converts a foreign-currency amount (minor units) to base minor units,
/// rounding half up. Returns null if the result is not positive or too large
/// for a safe integer.
int? convertToBaseMinor({required int originalMinor, required int rateMicro}) {
  if (originalMinor <= 0 || rateMicro <= 0) return null;
  final scaled = BigInt.from(originalMinor) * BigInt.from(rateMicro);
  final base = (scaled + BigInt.from(rateScale ~/ 2)) ~/ BigInt.from(rateScale);
  if (base <= BigInt.zero || base > BigInt.from(9007199254740991)) return null;
  return base.toInt();
}

/// "USD 20.00" style text for an original foreign amount.
String formatOriginal(int originalMinor, String code) {
  final major = originalMinor ~/ 100;
  final frac = (originalMinor % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  final digits = major.toString();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$code $buf.$frac';
}
