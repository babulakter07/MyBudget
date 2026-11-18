import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../../core/errors/app_exception.dart';

/// Marker header of a password-protected backup envelope.
const String encryptedBackupMagic = 'MYBUDGET-ENC';
const int encryptedBackupVersion = 1;

/// Production PBKDF2 work factor (OWASP 2023: >= 210,000 for HMAC-SHA256).
const int defaultKdfIterations = 210000;

/// Upper bound accepted from a file header so a hostile file cannot make the
/// app spin for minutes deriving a key.
const int maxKdfIterations = 5000000;

const int minBackupPasswordLength = 6;

const int _saltLength = 16;
const int _nonceLength = 12;
const int _macLength = 16;

/// Thrown when an encrypted backup is restored without a password.
class BackupPasswordRequired extends ValidationException {
  BackupPasswordRequired()
    : super('This backup is password protected. Enter its password.');
}

/// Password-based authenticated encryption for backup files.
///
/// Envelope (JSON, so it is distinguishable from a plain backup by `magic`):
/// `{"magic":"MYBUDGET-ENC","version":1,
///   "kdf":{"name":"PBKDF2-HMAC-SHA256","iterations":210000},
///   "cipher":"AES-256-GCM","salt":"b64","nonce":"b64",
///   "ciphertext":"b64(ciphertext + 16-byte tag)"}`
///
/// The header fields are bound into the GCM tag as associated data, so any
/// tampering (iterations, version, ciphertext, ...) fails authentication.
/// Passwords are never stored or logged.
class BackupCrypto {
  const BackupCrypto({this.iterations = defaultKdfIterations});

  /// PBKDF2 iterations used when ENCRYPTING. Production code keeps the
  /// default; tests inject a small value. Decryption always uses the value
  /// recorded in the file header.
  final int iterations;

  /// Cheap detection: true when [text] is an encrypted-backup envelope.
  static bool isEncrypted(String text) {
    final t = text.trimLeft();
    if (!t.startsWith('{')) return false;
    try {
      final d = jsonDecode(t);
      return d is Map<String, dynamic> && d['magic'] == encryptedBackupMagic;
    } catch (_) {
      return false;
    }
  }

  static const String _kdfName = 'PBKDF2-HMAC-SHA256';

  static List<int> _aad(int version, int iterations) =>
      utf8.encode('$encryptedBackupMagic|$version|$_kdfName|$iterations');

  static Future<SecretKey> _key(
    String password,
    List<int> salt,
    int iterations,
  ) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);

  static void checkPassword(String password) {
    if (password.length < minBackupPasswordLength) {
      throw ValidationException(
        'The password must be at least $minBackupPasswordLength characters.',
      );
    }
  }

  Future<String> encrypt(String plainText, String password) async {
    checkPassword(password);
    if (iterations < 1) {
      throw ValidationException('Invalid key derivation setting.');
    }
    final aes = AesGcm.with256bits();
    final salt = SecretKeyData.random(length: _saltLength).bytes;
    final nonce = aes.newNonce();
    final key = await _key(password, salt, iterations);
    final box = await aes.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
      aad: _aad(encryptedBackupVersion, iterations),
    );
    return jsonEncode({
      'magic': encryptedBackupMagic,
      'version': encryptedBackupVersion,
      'kdf': {'name': _kdfName, 'iterations': iterations},
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode([...box.cipherText, ...box.mac.bytes]),
    });
  }

  /// Returns the plain backup JSON. Wrong password, a damaged file or any
  /// tampering raises a [ValidationException]; nothing else escapes.
  Future<String> decrypt(String envelope, String password) async {
    final List<int> salt, nonce, data;
    final int iterations;
    final int version;
    try {
      final d = jsonDecode(envelope);
      if (d is! Map<String, dynamic> || d['magic'] != encryptedBackupMagic) {
        throw const FormatException('not an envelope');
      }
      final v = d['version'];
      if (v is! int) throw const FormatException('version');
      version = v;
      final kdf = d['kdf'];
      if (kdf is! Map<String, dynamic> ||
          kdf['name'] != _kdfName ||
          kdf['iterations'] is! int) {
        throw const FormatException('kdf');
      }
      iterations = kdf['iterations'] as int;
      if (d['cipher'] != 'AES-256-GCM') throw const FormatException('cipher');
      salt = base64Decode(d['salt'] as String);
      nonce = base64Decode(d['nonce'] as String);
      data = base64Decode(d['ciphertext'] as String);
    } catch (_) {
      throw ValidationException(
        'This encrypted backup file is damaged or not readable.',
      );
    }
    if (version > encryptedBackupVersion) {
      throw ValidationException(
        'This encrypted backup was made by a newer version of the app.',
      );
    }
    if (version < 1 ||
        iterations < 1 ||
        iterations > maxKdfIterations ||
        salt.length < 8 ||
        nonce.length != _nonceLength ||
        data.length < _macLength) {
      throw ValidationException(
        'This encrypted backup file is damaged or not readable.',
      );
    }
    if (password.isEmpty) throw BackupPasswordRequired();
    try {
      final key = await _key(password, salt, iterations);
      final box = SecretBox(
        data.sublist(0, data.length - _macLength),
        nonce: nonce,
        mac: Mac(data.sublist(data.length - _macLength)),
      );
      final clear = await AesGcm.with256bits().decrypt(
        box,
        secretKey: key,
        aad: _aad(version, iterations),
      );
      return utf8.decode(clear);
    } catch (_) {
      throw ValidationException(
        'Wrong password, or the backup file was modified or damaged. '
        'Nothing was restored.',
      );
    }
  }
}
