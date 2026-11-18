import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/transactions/domain/amount_calculator.dart';

void main() {
  int ev(String s) => AmountCalculator.evaluateToMinor(s);

  test('plain numbers and decimals', () {
    expect(ev('120'), 12000);
    expect(ev('120.5'), 12050);
    expect(ev('.5'), 50);
    expect(ev('5.'), 500);
  });

  test('precedence and unicode operators', () {
    expect(ev('10+2×3'), 1600);
    expect(ev('10−2×3'), 400);
    expect(ev('10-2*3'), 400);
    expect(ev('100÷4+1'), 2600);
    expect(ev('2×3×4'), 2400);
    expect(ev('10÷4÷5'), 50);
  });

  test('no floating point drift', () {
    expect(ev('0.1+0.2'), 30);
    expect(ev('1.10×3'), 330);
    expect(ev('19.99×3'), 5997);
  });

  test('rounds half up to 2 decimals', () {
    expect(ev('10÷3'), 333);
    expect(ev('20÷3'), 667);
    expect(ev('1.005'), 101);
    expect(ev('0.125×1'), 13);
    expect(ev('0.124×1'), 12);
    expect(ev('1÷8'), 13);
  });

  test('unary minus allowed inside as long as result is not negative', () {
    expect(ev('-5+10'), 500);
  });

  test('divide by zero is an error', () {
    expect(() => ev('5÷0'), throwsA(isA<ValidationException>()));
    expect(() => ev('5÷0.00'), throwsA(isA<ValidationException>()));
  });

  test('negative result rejected', () {
    expect(() => ev('5−10'), throwsA(isA<ValidationException>()));
    expect(() => ev('-3'), throwsA(isA<ValidationException>()));
  });

  test('malformed input rejected', () {
    for (final s in ['', '+', '5+', '1..2', 'abc', '5++', '×3', '1.2.3']) {
      expect(() => ev(s), throwsA(isA<ValidationException>()), reason: s);
    }
  });

  test('zero is returned as zero (caller validates > 0)', () {
    expect(ev('5−5'), 0);
  });

  test('huge values are rejected, not overflowed', () {
    expect(
      () => ev('99999999999999999999×99999999999999999999'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('isExpression', () {
    expect(AmountCalculator.isExpression('12.5'), isFalse);
    expect(AmountCalculator.isExpression('12+3'), isTrue);
  });
}
