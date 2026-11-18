import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/security/data/app_lock_providers.dart';
import 'package:my_budget/features/security/data/biometric_authenticator.dart';
import 'package:my_budget/features/security/domain/app_lock_models.dart';
import 'package:my_budget/features/security/domain/pin_hasher.dart';
import 'package:my_budget/features/security/presentation/app_lock_gate.dart';
import 'package:my_budget/features/security/presentation/security_settings_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bio implements BiometricAuthenticator {
  _Bio({this.available = true, this.succeed = true});
  final bool available;
  final bool succeed;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async => succeed;
}

ProviderContainer _container(SharedPreferences prefs, [_Bio? bio]) {
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      pinHasherProvider.overrideWithValue(const PinHasher(iterations: 5)),
      biometricAuthenticatorProvider.overrideWithValue(
        bio ?? _Bio(available: false),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Sets up a PIN (and optionally biometric) in [prefs] before the UI starts.
Future<void> _seedPin(SharedPreferences prefs, {bool biometric = false}) async {
  final c = _container(prefs);
  await c.read(appLockControllerProvider.notifier).enable('2468');
  if (biometric) {
    await c.read(appLockSettingsProvider.notifier).setBiometricEnabled(true);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  SharedPreferences prefs,
  Widget home, {
  _Bio? bio,
}) async {
  final container = _container(prefs, bio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  return container;
}

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin-key-$d')));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('gate passes through when lock disabled', (tester) async {
    await _pump(tester, prefs, const AppLockGate(child: Text('SECRET')));
    expect(find.text('SECRET'), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-key-1')), findsNothing);
  });

  testWidgets('gate shows lock screen, hides child, unlocks with PIN', (
    tester,
  ) async {
    await _seedPin(prefs);
    await _pump(tester, prefs, const AppLockGate(child: Text('SECRET')));
    expect(find.byKey(const ValueKey('pin-key-1')), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);

    await _typePin(tester, '1111');
    expect(find.text('Incorrect PIN'), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);

    await _typePin(tester, '2468');
    expect(find.text('SECRET'), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-key-1')), findsNothing);
  });

  testWidgets('gate relocks on background and covers app switcher', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      prefs,
      const AppLockGate(child: Text('SECRET')),
    );
    await c.read(appLockControllerProvider.notifier).enable('2468');
    await tester.pump();
    expect(find.text('SECRET'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(const ValueKey('privacy-cover')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(c.read(appLockControllerProvider).locked, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const ValueKey('pin-key-5')), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);
    await _typePin(tester, '2468');
    expect(find.text('SECRET'), findsOneWidget);
  });

  testWidgets('biometric failure keeps lock screen with biometric button', (
    tester,
  ) async {
    await _seedPin(prefs, biometric: true);
    await _pump(
      tester,
      prefs,
      const AppLockGate(child: Text('SECRET')),
      bio: _Bio(succeed: false),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('pin-biometric')), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);
  });

  testWidgets('biometric success unlocks automatically', (tester) async {
    await _seedPin(prefs, biometric: true);
    await _pump(
      tester,
      prefs,
      const AppLockGate(child: Text('SECRET')),
      bio: _Bio(),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('SECRET'), findsOneWidget);
  });

  testWidgets('lockout message shown after 5 wrong PINs', (tester) async {
    await _seedPin(prefs);
    await _pump(tester, prefs, const AppLockGate(child: Text('SECRET')));
    for (var i = 0; i < 5; i++) {
      await _typePin(tester, '1111');
    }
    expect(find.textContaining('Too many attempts'), findsOneWidget);
    await _typePin(tester, '2468'); // ignored while locked out
    expect(find.text('SECRET'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings: enable, change, disable PIN', (tester) async {
    final c = await _pump(tester, prefs, const SecuritySettingsScreen());
    expect(find.text('Change PIN'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('app-lock-switch')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '1234');
    await tester.enterText(find.byKey(const ValueKey('pin-field-1')), '1235');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PINs do not match.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('pin-field-1')), '1234');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(appLockSettingsProvider).enabled, isTrue);
    // One-time recovery code is shown after setting the PIN.
    expect(find.byKey(const ValueKey('recovery-code')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recovery-saved')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Auto-lock'), findsOneWidget);
    expect(find.text('Unlock with biometrics'), findsNothing); // unavailable

    await tester.tap(find.text('Change PIN'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '0000');
    await tester.enterText(find.byKey(const ValueKey('pin-field-1')), '5555');
    await tester.enterText(find.byKey(const ValueKey('pin-field-2')), '5555');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '1234');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PIN changed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byKey(const ValueKey('app-lock-switch')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '5555');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(appLockSettingsProvider).enabled, isFalse);
    expect(find.text('Change PIN'), findsNothing);
  });

  testWidgets('settings: auto-lock picker and biometric toggle', (
    tester,
  ) async {
    await _seedPin(prefs);
    final c = await _pump(
      tester,
      prefs,
      const SecuritySettingsScreen(),
      bio: _Bio(),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Unlock with biometrics'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('biometric-switch')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.read(appLockSettingsProvider).biometricEnabled, isTrue);

    await tester.tap(find.byKey(const ValueKey('auto-lock-dropdown')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('After 5 minutes').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      c.read(appLockSettingsProvider).autoLockDelay,
      AutoLockDelay.minutes5,
    );
  });

  testWidgets('settings: new recovery code needs the current PIN', (
    tester,
  ) async {
    await _seedPin(prefs);
    final before = prefs.getString('app_lock_recovery_hash');
    await _pump(tester, prefs, const SecuritySettingsScreen());
    await tester.tap(find.byKey(const ValueKey('new-recovery-tile')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '0000');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(prefs.getString('app_lock_recovery_hash'), before);
    await tester.enterText(find.byKey(const ValueKey('pin-field-0')), '2468');
    await tester.tap(find.byKey(const ValueKey('pin-dialog-ok')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('recovery-code')), findsOneWidget);
    expect(prefs.getString('app_lock_recovery_hash'), isNot(before));
  });

  testWidgets('lock screen: forgot PIN with recovery code unlocks', (
    tester,
  ) async {
    final c0 = _container(prefs);
    final code = await c0
        .read(appLockControllerProvider.notifier)
        .enable('2468');
    await _pump(tester, prefs, const AppLockGate(child: Text('SECRET')));
    expect(find.text('SECRET'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('forgot-pin')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('recovery-input')),
      'WRONG',
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('That recovery code is not correct.'), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('recovery-input')),
      code.toLowerCase().replaceAll('-', ' '),
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SECRET'), findsOneWidget);
    expect(prefs.getString('app_lock_pin_hash'), isNull);
  });
}
