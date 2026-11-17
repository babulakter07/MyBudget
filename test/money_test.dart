import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/utils/money.dart';

void main() {
  group('parseMajorToMinor', () {
    test('valid', () {
      expect(parseMajorToMinor('12000'), 1200000);
      expect(parseMajorToMinor('12,000.50'), 1200050);
      expect(parseMajorToMinor('0.5'), 50);
      expect(parseMajorToMinor('0.05'), 5);
      expect(parseMajorToMinor(' 10.10 '), 1010);
      expect(parseMajorToMinor('0'), 0);
      expect(parseMajorToMinor('19.99'), 1999);
    });
    test('invalid', () {
      for (final s in [
        '',
        ' ',
        '-5',
        'abc',
        '1.234',
        '1.',
        '.5',
        '1,2',
        '1..2',
        '1e5',
        '12,00,0',
        '--1',
        '1 000',
      ]) {
        expect(parseMajorToMinor(s), isNull, reason: s);
      }
    });
  });
  group('formatMinor', () {
    test('formats', () {
      expect(formatMinor(1200050), '৳12,000.50');
      expect(formatMinor(0), '৳0.00');
      expect(formatMinor(5), '৳0.05');
      expect(formatMinor(100000000), '৳1,000,000.00');
      expect(formatMinor(99900, symbol: 'Tk '), 'Tk 999.00');
      expect(formatMinor(-150), '-৳1.50');
    });
    test('roundtrip', () {
      for (final m in [0, 1, 99, 100, 123456789]) {
        expect(parseMajorToMinor(formatMinor(m, symbol: '')), m);
      }
    });
  });
}
