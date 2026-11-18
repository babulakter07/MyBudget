import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/security/data/app_lock_providers.dart';
import 'package:my_budget/features/security/data/biometric_authenticator.dart';
import 'package:my_budget/features/security/domain/app_lock_models.dart';
import 'package:my_budget/features/security/domain/pin_hasher.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBiometric implements BiometricAuthenticator {
  FakeBiometric({this.available = true, this.succeed = true});
  bool available;
  bool succeed;
  int prompts = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}

class Clock {
  DateTime now = DateTime(2026, 1, 1, 12);
  DateTime call() => now;
}

ProviderContainer makeContainer(
  SharedPreferences prefs,
  Clock clock, {
  FakeBiometric? bio,
}) {
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      pinHasherProvider.overrideWithValue(const PinHasher(iterations: 5)),
      appLockClockProvider.overrideWithValue(clock.call),
      if (bio != null) biometricAuthenticatorProvider.overrideWithValue(bio),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  late SharedPreferences prefs;
  late Clock clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = Clock();
  });

  group('PinHasher', () {
    test('matches RFC 7914 PBKDF2-HMAC-SHA256 vector', () {
      final dk = PinHasher.pbkdf2(
        utf8.encode('passwd'),
        utf8.encode('salt'),
        1,
      );
      final hex = dk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(
        hex,
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('salted, verifies, rejects wrong, never contains plaintext', () {
      const h = PinHasher(iterations: 10);
      final a = h.hash('123456');
      final b = h.hash('123456');
      expect(a, isNot(b)); // random salt
      expect(a, isNot('123456'));
      expect(a.contains('123456'), isFalse);
      expect(h.verify('123456', a), isTrue);
      expect(h.verify('123457', a), isFalse);
      expect(h.verify('123456', 'garbage'), isFalse);
      expect(PinHasher.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('controller', () {
    test('cold start locked only when enabled', () async {
      expect(
        makeContainer(prefs, clock).read(appLockControllerProvider).locked,
        isFalse,
      );
      final c1 = makeContainer(prefs, clock);
      await c1.read(appLockControllerProvider.notifier).enable('4821');
      final c2 = makeContainer(prefs, clock);
      expect(c2.read(appLockControllerProvider).locked, isTrue);
      expect(c2.read(appLockSettingsProvider).enabled, isTrue);
      expect(c2.read(appLockSettingsProvider).pinLength, 4);
    });

    test('stored values never contain plaintext PIN', () async {
      final c = makeContainer(prefs, clock);
      await c.read(appLockControllerProvider.notifier).enable('987654');
      for (final k in prefs.getKeys()) {
        if (k == 'app_lock_pin_length') continue;
        expect(prefs.get(k).toString().contains('987654'), isFalse, reason: k);
      }
      expect(prefs.getString('app_lock_pin_hash'), startsWith('pbkdf2-sha256'));
    });

    test('rejects invalid PIN formats', () async {
      final n = makeContainer(
        prefs,
        clock,
      ).read(appLockControllerProvider.notifier);
      for (final bad in ['123', '1234567', 'abcd', '12 4', '']) {
        expect(() => n.enable(bad), throwsA(isA<ValidationException>()));
      }
    });

    test('set, verify, change, disable', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      await n.enable('1234');
      expect(c.read(appLockControllerProvider).locked, isFalse);
      n.lockNow();
      expect(c.read(appLockControllerProvider).locked, isTrue);
      expect(await n.unlock('0000'), UnlockResult.wrong);
      expect(c.read(appLockControllerProvider).locked, isTrue);
      expect(await n.unlock('1234'), UnlockResult.success);
      expect(c.read(appLockControllerProvider).locked, isFalse);

      expect(await n.changePin('9999', '555555'), UnlockResult.wrong);
      expect(await n.changePin('1234', '555555'), UnlockResult.success);
      expect(c.read(appLockSettingsProvider).pinLength, 6);
      expect(await n.unlock('1234'), UnlockResult.wrong);
      expect(await n.unlock('555555'), UnlockResult.success);

      expect(await n.disable('0000'), UnlockResult.wrong);
      expect(c.read(appLockSettingsProvider).enabled, isTrue);
      expect(await n.disable('555555'), UnlockResult.success);
      expect(c.read(appLockSettingsProvider).enabled, isFalse);
      expect(prefs.getString('app_lock_pin_hash'), isNull);
      expect(await n.unlock('555555'), UnlockResult.notEnabled);
      n.lockNow();
      expect(c.read(appLockControllerProvider).locked, isFalse);
    });

    test('lockoutFor backoff doubles and is capped', () {
      expect(lockoutFor(4), Duration.zero);
      expect(lockoutFor(5), const Duration(seconds: 30));
      expect(lockoutFor(10), const Duration(seconds: 60));
      expect(lockoutFor(15), const Duration(seconds: 120));
      expect(lockoutFor(500), lockoutMax);
    });

    test(
      'lockout after 5 wrong, persists across restart, then expires',
      () async {
        final c = makeContainer(prefs, clock);
        final n = c.read(appLockControllerProvider.notifier);
        await n.enable('1234');
        n.lockNow();
        for (var i = 0; i < 4; i++) {
          expect(await n.unlock('0000'), UnlockResult.wrong);
        }
        expect(await n.unlock('0000'), UnlockResult.lockedOut);
        // Correct PIN is refused during lockout and does not count.
        expect(await n.unlock('1234'), UnlockResult.lockedOut);
        expect(c.read(appLockControllerProvider).failedAttempts, 5);

        // "Kill the app": new container, same prefs, same clock.
        final c2 = makeContainer(prefs, clock);
        final n2 = c2.read(appLockControllerProvider.notifier);
        expect(c2.read(appLockControllerProvider).failedAttempts, 5);
        expect(await n2.unlock('1234'), UnlockResult.lockedOut);

        clock.now = clock.now.add(const Duration(seconds: 31));
        expect(await n2.unlock('0000'), UnlockResult.wrong); // 6th
        for (var i = 0; i < 3; i++) {
          await n2.unlock('0000');
        }
        expect(await n2.unlock('0000'), UnlockResult.lockedOut); // 10th: 60s
        clock.now = clock.now.add(const Duration(seconds: 45));
        expect(await n2.unlock('1234'), UnlockResult.lockedOut);
        clock.now = clock.now.add(const Duration(seconds: 20));
        expect(await n2.unlock('1234'), UnlockResult.success);
        expect(c2.read(appLockControllerProvider).failedAttempts, 0);
        expect(prefs.getInt('app_lock_failed_attempts'), 0);
      },
    );

    test('auto-lock honours delay via lifecycle simulation', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      await n.enable('1234');
      bool locked() => c.read(appLockControllerProvider).locked;

      // Immediately (default): locks as soon as backgrounded.
      n.onLifecycle(AppLifecycleState.inactive);
      expect(locked(), isFalse);
      n.onLifecycle(AppLifecycleState.hidden);
      expect(locked(), isTrue);
      n.onLifecycle(AppLifecycleState.paused);
      n.onLifecycle(AppLifecycleState.resumed);
      await n.unlock('1234');

      await c
          .read(appLockSettingsProvider.notifier)
          .setAutoLockDelay(AutoLockDelay.minute1);
      n.onLifecycle(AppLifecycleState.hidden);
      n.onLifecycle(AppLifecycleState.paused);
      expect(locked(), isFalse);
      clock.now = clock.now.add(const Duration(seconds: 30));
      n.onLifecycle(AppLifecycleState.resumed);
      expect(locked(), isFalse);

      n.onLifecycle(AppLifecycleState.paused);
      clock.now = clock.now.add(const Duration(seconds: 61));
      n.onLifecycle(AppLifecycleState.resumed);
      expect(locked(), isTrue);
      expect(prefs.getInt('app_lock_delay_seconds'), 60);
    });

    test('lifecycle ignored when lock disabled', () {
      final c = makeContainer(prefs, clock);
      c.read(appLockControllerProvider.notifier)
        ..onLifecycle(AppLifecycleState.paused)
        ..onLifecycle(AppLifecycleState.resumed);
      expect(c.read(appLockControllerProvider).locked, isFalse);
    });
  });

  group('biometric', () {
    Future<(ProviderContainer, FakeBiometric)> setup({
      bool available = true,
      bool succeed = true,
      bool enabled = true,
    }) async {
      final bio = FakeBiometric(available: available, succeed: succeed);
      final c = makeContainer(prefs, clock, bio: bio);
      final n = c.read(appLockControllerProvider.notifier);
      await n.enable('1234');
      if (enabled) {
        await c
            .read(appLockSettingsProvider.notifier)
            .setBiometricEnabled(true);
      }
      n.lockNow();
      return (c, bio);
    }

    test('success unlocks', () async {
      final (c, bio) = await setup();
      final n = c.read(appLockControllerProvider.notifier);
      expect(await n.unlockWithBiometric(), isTrue);
      expect(bio.prompts, 1);
      expect(c.read(appLockControllerProvider).locked, isFalse);
    });

    test('failure keeps locked', () async {
      final (c, _) = await setup(succeed: false);
      final n = c.read(appLockControllerProvider.notifier);
      expect(await n.unlockWithBiometric(), isFalse);
      expect(c.read(appLockControllerProvider).locked, isTrue);
    });

    test('unavailable or disabled never prompts', () async {
      final (c, bio) = await setup(available: false);
      expect(
        await c.read(appLockControllerProvider.notifier).unlockWithBiometric(),
        isFalse,
      );
      await prefs.clear();
      final (c2, bio2) = await setup(enabled: false);
      expect(
        await c2.read(appLockControllerProvider.notifier).unlockWithBiometric(),
        isFalse,
      );
      expect(bio.prompts + bio2.prompts, 0);
      expect(c.read(appLockControllerProvider).locked, isTrue);
    });

    test('disabling the lock clears biometric flag', () async {
      final (c, _) = await setup();
      final n = c.read(appLockControllerProvider.notifier);
      await n.unlock('1234');
      await n.disable('1234');
      expect(c.read(appLockSettingsProvider).biometricEnabled, isFalse);
    });
  });

  group('recovery code', () {
    test('format, hashed storage, never plaintext', () async {
      final c = makeContainer(prefs, clock);
      final code = await c
          .read(appLockControllerProvider.notifier)
          .enable('1234');
      expect(code, matches(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$')));
      final stored = prefs.getString('app_lock_recovery_hash')!;
      expect(stored.contains(normalizeRecoveryCode(code)), isFalse);
      expect(stored, startsWith('pbkdf2-sha256'));
    });

    test('recover resets the lock; wrong code does nothing', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      final code = await n.enable('1234');
      n.lockNow();
      expect(await n.recoverWithCode('AAAA-BBBB-CCCC-DDDD'), isFalse);
      expect(c.read(appLockControllerProvider).locked, isTrue);
      expect(
        await n.recoverWithCode(code.toLowerCase().replaceAll('-', '')),
        isTrue,
      );
      expect(c.read(appLockSettingsProvider).enabled, isFalse);
      expect(c.read(appLockControllerProvider).locked, isFalse);
      expect(prefs.getString('app_lock_pin_hash'), isNull);
      expect(prefs.getString('app_lock_recovery_hash'), isNull);
      expect(await n.recoverWithCode(code), isFalse);
    });

    test('recovery works while PIN is locked out', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      final code = await n.enable('1234');
      n.lockNow();
      for (var i = 0; i < 5; i++) {
        await n.unlock('0000');
      }
      expect(await n.unlock('1234'), UnlockResult.lockedOut);
      expect(await n.recoverWithCode(code), isTrue);
      expect(c.read(appLockControllerProvider).failedAttempts, 0);
    });

    test('regenerate needs correct PIN and invalidates old code', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      final old = await n.enable('1234');
      final (r1, c1) = await n.regenerateRecoveryCode('0000');
      expect(r1, UnlockResult.wrong);
      expect(c1, isNull);
      final (r2, fresh) = await n.regenerateRecoveryCode('1234');
      expect(r2, UnlockResult.success);
      expect(fresh, isNot(old));
      expect(await n.recoverWithCode(old), isFalse);
      expect(await n.recoverWithCode(fresh!), isTrue);
    });

    test('disable removes recovery hash', () async {
      final c = makeContainer(prefs, clock);
      final n = c.read(appLockControllerProvider.notifier);
      await n.enable('1234');
      await n.disable('1234');
      expect(prefs.getString('app_lock_recovery_hash'), isNull);
    });
  });
}
