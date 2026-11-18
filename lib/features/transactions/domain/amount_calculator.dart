import '../../../core/errors/app_exception.dart';

/// Pure, double-free evaluator for the amount keypad.
///
/// Supports `+ - × ÷` (also `* /` and the unicode minus), decimal operands,
/// unary minus, and standard precedence. All arithmetic is exact (BigInt
/// rationals); only the final result is rounded to minor units, half-up.
class AmountCalculator {
  const AmountCalculator._();

  static const _maxMinor = 9007199254740991 ~/ 100;

  /// Evaluates [expression] and returns a positive-or-zero result in integer
  /// minor units. Throws [ValidationException] for malformed input, divide
  /// by zero, a negative result, or overflow.
  static int evaluateToMinor(String expression) {
    final r = _Parser(expression).parse();
    if (r.num.isNegative) {
      throw ValidationException('Result cannot be negative.');
    }
    final scaled = r.num * BigInt.from(100);
    final minor = (scaled * BigInt.two + r.den) ~/ (r.den * BigInt.two);
    if (minor > BigInt.from(_maxMinor * 100)) {
      throw ValidationException('Amount is too large.');
    }
    return minor.toInt();
  }

  /// True when [text] has an operator, i.e. needs evaluating.
  static bool isExpression(String text) {
    final t = text.trim();
    for (var i = 1; i < t.length; i++) {
      if ('+-−×÷*/'.contains(t[i])) return true;
    }
    return false;
  }
}

class _Rat {
  _Rat(BigInt n, BigInt d) : num = d.isNegative ? -n : n, den = d.abs();
  final BigInt num;
  final BigInt den;

  _Rat operator +(_Rat o) => _norm(num * o.den + o.num * den, den * o.den);
  _Rat operator -(_Rat o) => _norm(num * o.den - o.num * den, den * o.den);
  _Rat operator *(_Rat o) => _norm(num * o.num, den * o.den);
  _Rat operator /(_Rat o) {
    if (o.num == BigInt.zero) {
      throw ValidationException('Cannot divide by zero.');
    }
    return _norm(num * o.den, den * o.num);
  }

  _Rat operator -() => _Rat(-num, den);

  static _Rat _norm(BigInt n, BigInt d) {
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) return _Rat(n ~/ g, d ~/ g);
    return _Rat(n, d);
  }
}

class _Parser {
  _Parser(String s) : _s = s.replaceAll(RegExp(r'[\s,৳]'), '');
  final String _s;
  int _i = 0;

  static ValidationException _bad() =>
      ValidationException('Enter a valid calculation, like 120+35.50×2.');

  _Rat parse() {
    if (_s.isEmpty) throw _bad();
    final v = _expr();
    if (_i != _s.length) throw _bad();
    return v;
  }

  String? get _c => _i < _s.length ? _s[_i] : null;

  _Rat _expr() {
    var v = _term();
    while (true) {
      final c = _c;
      if (c == '+') {
        _i++;
        v = v + _term();
      } else if (c == '-' || c == '−') {
        _i++;
        v = v - _term();
      } else {
        return v;
      }
    }
  }

  _Rat _term() {
    var v = _unary();
    while (true) {
      final c = _c;
      if (c == '×' || c == '*') {
        _i++;
        v = v * _unary();
      } else if (c == '÷' || c == '/') {
        _i++;
        v = v / _unary();
      } else {
        return v;
      }
    }
  }

  _Rat _unary() {
    final c = _c;
    if (c == '-' || c == '−') {
      _i++;
      return -_unary();
    }
    return _number();
  }

  _Rat _number() {
    final start = _i;
    var digits = 0;
    var dot = -1;
    while (_i < _s.length) {
      final ch = _s[_i];
      if (ch == '.') {
        if (dot >= 0) throw _bad();
        dot = _i;
      } else if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        digits++;
      } else {
        break;
      }
      _i++;
    }
    if (digits == 0) throw _bad();
    final text = _s.substring(start, _i);
    if (dot < 0) return _Rat(BigInt.parse(text), BigInt.one);
    final parts = text.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts[1];
    return _Rat(BigInt.parse('$whole$frac'), BigInt.from(10).pow(frac.length));
  }
}
