/// How long the app may stay in the background before it locks again.
enum AutoLockDelay {
  immediately(Duration.zero, 'Immediately'),
  seconds30(Duration(seconds: 30), 'After 30 seconds'),
  minute1(Duration(minutes: 1), 'After 1 minute'),
  minutes5(Duration(minutes: 5), 'After 5 minutes');

  const AutoLockDelay(this.duration, this.label);
  final Duration duration;
  final String label;

  static AutoLockDelay fromSeconds(int? s) => AutoLockDelay.values.firstWhere(
    (d) => d.duration.inSeconds == s,
    orElse: () => AutoLockDelay.immediately,
  );
}

/// Persisted lock configuration (never contains the PIN or its hash).
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.pinLength = 4,
    this.biometricEnabled = false,
    this.autoLockDelay = AutoLockDelay.immediately,
  });

  final bool enabled;
  final int pinLength;
  final bool biometricEnabled;
  final AutoLockDelay autoLockDelay;

  AppLockSettings copyWith({
    bool? enabled,
    int? pinLength,
    bool? biometricEnabled,
    AutoLockDelay? autoLockDelay,
  }) => AppLockSettings(
    enabled: enabled ?? this.enabled,
    pinLength: pinLength ?? this.pinLength,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    autoLockDelay: autoLockDelay ?? this.autoLockDelay,
  );
}

class AppLockState {
  const AppLockState({
    required this.locked,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  final bool locked;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  Duration lockoutRemaining(DateTime now) {
    final u = lockoutUntil;
    if (u == null || !u.isAfter(now)) return Duration.zero;
    return u.difference(now);
  }

  AppLockState copyWith({
    bool? locked,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearLockout = false,
  }) => AppLockState(
    locked: locked ?? this.locked,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
  );
}

enum UnlockResult { success, wrong, lockedOut, notEnabled }
