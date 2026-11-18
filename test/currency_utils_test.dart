import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/utils/currency.dart';

void main() {
  test('parseRateToMicro accepts up to 6 decimals and rejects junk', () {
    expect(parseRateToMicro('122.5'), 122500000);
    expect(parseRateToMicro('0.0082'), 8200);
    expect(parseRateToMicro('1,200.123456'), 1200123456);
    expect(parseRateToMicro('7'), 7000000);
    expect(parseRateToMicro('0'), isNull);
    expect(parseRateToMicro(''), isNull);
    expect(parseRateToMicro('1.1234567'), isNull);
    expect(parseRateToMicro('-3'), isNull);
    expect(parseRateToMicro('abc'), isNull);
    expect(parseRateToMicro('99999999999'), isNull);
  });

  test('formatRate trims trailing zeros', () {
    expect(formatRate(122500000), '122.5');
    expect(formatRate(7000000), '7');
    expect(formatRate(8200), '0.0082');
    expect(formatRate(1200123456), '1200.123456');
  });

  test('convertToBaseMinor rounds half up with integers only', () {
    // USD 20.00 @ 122.5 = 2450.00
    expect(
      convertToBaseMinor(originalMinor: 2000, rateMicro: 122500000),
      245000,
    );
    // 0.01 @ 0.5 = 0.005 -> rounds up to 0.01
    expect(convertToBaseMinor(originalMinor: 1, rateMicro: 500000), 1);
    // 0.01 @ 0.4 = 0.004 -> rounds to 0 -> invalid
    expect(convertToBaseMinor(originalMinor: 1, rateMicro: 400000), isNull);
    expect(convertToBaseMinor(originalMinor: 0, rateMicro: 1000000), isNull);
    expect(convertToBaseMinor(originalMinor: 100, rateMicro: 0), isNull);
    // 3.00 x 33.333333 = 99.999999 -> 100.00
    expect(convertToBaseMinor(originalMinor: 300, rateMicro: 33333333), 10000);
  });

  test('currency code normalisation and display', () {
    expect(normalizeCurrencyCode(' usd '), 'USD');
    expect(normalizeCurrencyCode('US'), isNull);
    expect(normalizeCurrencyCode('US1'), isNull);
    expect(currencySymbol('usd'), r'$');
    expect(currencySymbol('XYZ'), 'XYZ');
    expect(formatOriginal(1234567, 'USD'), 'USD 12,345.67');
  });
}
