import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/security/data/app_lock_providers.dart';
import 'package:my_budget/features/security/data/biometric_authenticator.dart';
import 'package:my_budget/features/security/domain/pin_hasher.dart';
import 'package:my_budget/features/security/presentation/app_lock_screen.dart';
import 'package:my_budget/features/security/presentation/security_settings_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell_localized_app.dart';

class _NoBio implements BiometricAuthenticator {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget app, {
    bool seed = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pinHasherProvider.overrideWithValue(const PinHasher(iterations: 5)),
        biometricAuthenticatorProvider.overrideWithValue(_NoBio()),
      ],
    );
    if (seed) {
      final c = make();
      await c.read(appLockControllerProvider.notifier).enable('2468');
      c.dispose();
    }
    final container = make();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: app),
    );
    await tester.pump();
    return container;
  }

  testWidgets('security settings in Bangla', (tester) async {
    await pump(
      tester,
      localizedApp(home: const SecuritySettingsScreen()),
      seed: true,
    );
    expect(find.text('নিরাপত্তা'), findsOneWidget);
    expect(find.text('অ্যাপ লক'), findsOneWidget);
    expect(find.text('পিন পরিবর্তন'), findsOneWidget);
    expect(find.text('সঙ্গে সঙ্গে'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lock screen shows Bangla prompt and wrong-PIN message', (
    tester,
  ) async {
    await pump(tester, localizedApp(home: const AppLockScreen()), seed: true);
    expect(find.text('আনলক করতে পিন দিন'), findsOneWidget);
    for (final d in '1111'.split('')) {
      await tester.tap(find.byKey(ValueKey('pin-key-$d')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ভুল পিন'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('English smoke', (tester) async {
    await pump(tester, const MaterialApp(home: SecuritySettingsScreen()));
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('App lock'), findsOneWidget);
  });
}
