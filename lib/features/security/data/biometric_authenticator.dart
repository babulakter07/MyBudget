import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Abstraction over the platform biometric prompt so tests can fake it.
abstract class BiometricAuthenticator {
  /// True when the device has enrolled biometrics usable for unlock.
  Future<bool> isAvailable();

  /// Shows the system prompt. Never throws; returns false on any failure.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
);

final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricAuthenticatorProvider).isAvailable(),
);
