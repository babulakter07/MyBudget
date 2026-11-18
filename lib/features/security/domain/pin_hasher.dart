import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 for PINs. Stored format:
/// `pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>`.
class PinHasher {
  const PinHasher({this.iterations = 20000});

  final int iterations;

  static const _prefix = 'pbkdf2-sha256';
  static const _saltBytes = 16;

  String hash(String pin, {List<int>? salt}) {
    final s = salt ?? _randomBytes(_saltBytes);
    final dk = pbkdf2(utf8.encode(pin), s, iterations);
    return '$_prefix\$$iterations\$${base64.encode(s)}\$${base64.encode(dk)}';
  }

  /// Constant-time verification against a stored string.
  bool verify(String pin, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null || iters < 1) return false;
    final List<int> salt, expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = pbkdf2(utf8.encode(pin), salt, iters);
    return constantTimeEquals(actual, expected);
  }

  /// PBKDF2-HMAC-SHA256, single 32-byte block.
  static List<int> pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final n = min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }
}
