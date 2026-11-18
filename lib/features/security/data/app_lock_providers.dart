import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/providers/core_providers.dart';
import '../../preferences/data/app_l10n_resolver.dart';
import '../domain/app_lock_models.dart';
import '../domain/pin_hasher.dart';
import 'biometric_authenticator.dart';

const _kPinHash = 'app_lock_pin_hash';
const _kPinLength = 'app_lock_pin_length';
const _kBiometric = 'app_lock_biometric';
const _kDelay = 'app_lock_delay_seconds';
const _kFailed = 'app_lock_failed_attempts';
const _kLockoutUntil = 'app_lock_lockout_until_ms';
const _kRecoveryHash = 'app_lock_recovery_hash';

const _recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Random 16-char recovery code shown as XXXX-XXXX-XXXX-XXXX (80 bits).
String generateRecoveryCode() {
  final r = Random.secure();
  final raw = List.generate(
    16,
    (_) => _recoveryAlphabet[r.nextInt(_recoveryAlphabet.length)],
  ).join();
  return [for (var i = 0; i < 16; i += 4) raw.substring(i, i + 4)].join('-');
}

/// Case/dash/space-insensitive form used for hashing and comparing codes.
String normalizeRecoveryCode(String code) =>
    code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Wrong tries per lockout tier, first lockout length, and its cap.
const lockoutThreshold = 5;
const lockoutBase = Duration(seconds: 30);
const lockoutMax = Duration(hours: 1);

/// Lockout length after [failed] total consecutive wrong attempts
/// (zero when [failed] is not a multiple of [lockoutThreshold]).
Duration lockoutFor(int failed) {
  if (failed <= 0 || failed % lockoutThreshold != 0) return Duration.zero;
  final tier = failed ~/ lockoutThreshold; // 1, 2, 3...
  var d = lockoutBase;
  for (var i = 1; i < tier; i++) {
    d *= 2;
    if (d >= lockoutMax) return lockoutMax;
  }
  return d;
}

final pinHasherProvider = Provider<PinHasher>((ref) => const PinHasher());

/// Injectable clock (tests override).
final appLockClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class AppLockSettingsNotifier extends Notifier<AppLockSettings> {
  @override
  AppLockSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppLockSettings(
      enabled: p.getString(_kPinHash) != null,
      pinLength: p.getInt(_kPinLength) ?? 4,
      biometricEnabled: p.getBool(_kBiometric) ?? false,
      autoLockDelay: AutoLockDelay.fromSeconds(p.getInt(_kDelay)),
    );
  }

  Future<void> setAutoLockDelay(AutoLockDelay d) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_kDelay, d.duration.inSeconds);
    state = state.copyWith(autoLockDelay: d);
  }

  Future<void> setBiometricEnabled(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(_kBiometric, v);
    state = state.copyWith(biometricEnabled: v);
  }

  /// Internal: used by [AppLockController] only.
  Future<void> storePinHash(String hash, int length) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setString(_kPinHash, hash);
    await p.setInt(_kPinLength, length);
    state = state.copyWith(enabled: true, pinLength: length);
  }

  /// Internal: used by [AppLockController] only.
  Future<void> clearPin() async {
    final p = ref.read(sharedPreferencesProvider);
    await p.remove(_kPinHash);
    await p.remove(_kPinLength);
    await p.remove(_kBiometric);
    await p.remove(_kRecoveryHash);
    state = state.copyWith(enabled: false, biometricEnabled: false);
  }
}

final appLockSettingsProvider =
    NotifierProvider<AppLockSettingsNotifier, AppLockSettings>(
      AppLockSettingsNotifier.new,
    );

class AppLockController extends Notifier<AppLockState> {
  DateTime? _backgroundedAt;

  @override
  AppLockState build() {
    final p = ref.read(sharedPreferencesProvider);
    final enabled = p.getString(_kPinHash) != null;
    final until = p.getInt(_kLockoutUntil);
    return AppLockState(
      locked: enabled, // cold start: locked whenever a PIN is set
      failedAttempts: p.getInt(_kFailed) ?? 0,
      lockoutUntil: until == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(until),
    );
  }

  DateTime get _now => ref.read(appLockClockProvider)();
  AppLockSettingsNotifier get _settings =>
      ref.read(appLockSettingsProvider.notifier);

  static bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  void _requireValid(String pin) {
    if (!isValidPin(pin)) {
      throw ValidationException('PIN must be 4 to 6 digits.');
    }
  }

  String? get _hash => ref.read(sharedPreferencesProvider).getString(_kPinHash);

  Future<void> _persistCounters(int failed, DateTime? until) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setInt(_kFailed, failed);
    if (until == null) {
      await p.remove(_kLockoutUntil);
    } else {
      await p.setInt(_kLockoutUntil, until.millisecondsSinceEpoch);
    }
  }

  /// Checks [pin] honouring lockout/backoff. Updates counters.
  Future<UnlockResult> _check(String pin) async {
    final stored = _hash;
    if (stored == null) return UnlockResult.notEnabled;
    final now = _now;
    if (state.lockoutRemaining(now) > Duration.zero) {
      return UnlockResult.lockedOut;
    }
    if (ref.read(pinHasherProvider).verify(pin, stored)) {
      await _persistCounters(0, null);
      state = state.copyWith(failedAttempts: 0, clearLockout: true);
      return UnlockResult.success;
    }
    final failed = state.failedAttempts + 1;
    final wait = lockoutFor(failed);
    final until = wait == Duration.zero ? null : now.add(wait);
    await _persistCounters(failed, until);
    state = state.copyWith(
      failedAttempts: failed,
      lockoutUntil: until,
      clearLockout: until == null,
    );
    return wait == Duration.zero ? UnlockResult.wrong : UnlockResult.lockedOut;
  }

  /// Unlocks the app with [pin].
  Future<UnlockResult> unlock(String pin) async {
    final r = await _check(pin);
    if (r == UnlockResult.success) state = state.copyWith(locked: false);
    return r;
  }

  /// Unlocks via the platform biometric prompt (if enabled in settings).
  Future<bool> unlockWithBiometric() async {
    if (!ref.read(appLockSettingsProvider).biometricEnabled) return false;
    final bio = ref.read(biometricAuthenticatorProvider);
    if (!await bio.isAvailable()) return false;
    final ok = await bio.authenticate(
      resolveAppLocalizations(ref.read(sharedPreferencesProvider))
          .securityBiometricUnlock,
    );
    if (ok) {
      await _persistCounters(0, null);
      state = state.copyWith(
        locked: false,
        failedAttempts: 0,
        clearLockout: true,
      );
    }
    return ok;
  }

  Future<String> _storeNewRecoveryCode() async {
    final code = generateRecoveryCode();
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _kRecoveryHash,
          ref.read(pinHasherProvider).hash(normalizeRecoveryCode(code)),
        );
    return code;
  }

  /// Turns the lock on with a new PIN and returns a one-time recovery code
  /// (only its hash is stored). Does not lock the current session.
  Future<String> enable(String pin) async {
    _requireValid(pin);
    await _settings.storePinHash(
      ref.read(pinHasherProvider).hash(pin),
      pin.length,
    );
    final code = await _storeNewRecoveryCode();
    await _persistCounters(0, null);
    state = const AppLockState(locked: false);
    return code;
  }

  /// Verifies [currentPin], then replaces the recovery code. The code is null
  /// unless the result is [UnlockResult.success].
  Future<(UnlockResult, String?)> regenerateRecoveryCode(
    String currentPin,
  ) async {
    final r = await _check(currentPin);
    if (r != UnlockResult.success) return (r, null);
    return (r, await _storeNewRecoveryCode());
  }

  /// Forgot-PIN path: a correct recovery code turns app lock off (the user
  /// can then set a new PIN). Returns false for a wrong or missing code.
  Future<bool> recoverWithCode(String code) async {
    final stored = ref
        .read(sharedPreferencesProvider)
        .getString(_kRecoveryHash);
    if (stored == null) return false;
    if (!ref
        .read(pinHasherProvider)
        .verify(normalizeRecoveryCode(code), stored)) {
      return false;
    }
    await _settings.clearPin();
    await _persistCounters(0, null);
    state = const AppLockState(locked: false);
    return true;
  }

  /// Verifies [current] then stores [newPin].
  Future<UnlockResult> changePin(String current, String newPin) async {
    _requireValid(newPin);
    final r = await _check(current);
    if (r != UnlockResult.success) return r;
    await _settings.storePinHash(
      ref.read(pinHasherProvider).hash(newPin),
      newPin.length,
    );
    return r;
  }

  /// Verifies [current] then removes the lock entirely.
  Future<UnlockResult> disable(String current) async {
    final r = await _check(current);
    if (r != UnlockResult.success) return r;
    await _settings.clearPin();
    await _persistCounters(0, null);
    state = const AppLockState(locked: false);
    return r;
  }

  void lockNow() {
    if (ref.read(appLockSettingsProvider).enabled) {
      state = state.copyWith(locked: true);
    }
  }

  /// Feed from a [WidgetsBindingObserver]. Locks per the auto-lock delay.
  void onLifecycle(AppLifecycleState s) {
    final settings = ref.read(appLockSettingsProvider);
    if (!settings.enabled) {
      _backgroundedAt = null;
      return;
    }
    switch (s) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_backgroundedAt == null) {
          _backgroundedAt = _now;
          if (settings.autoLockDelay == AutoLockDelay.immediately) lockNow();
        }
      case AppLifecycleState.resumed:
        final at = _backgroundedAt;
        _backgroundedAt = null;
        if (at != null &&
            _now.difference(at) >= settings.autoLockDelay.duration) {
          lockNow();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
