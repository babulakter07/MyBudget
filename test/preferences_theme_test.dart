import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/preferences/data/theme_mode_provider.dart';
import 'package:my_budget/features/preferences/presentation/preferences_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to system, persists, and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    final c = make();
    expect(c.read(themeModeProvider), ThemeMode.system);
    await c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    expect(make().read(themeModeProvider), ThemeMode.dark);
  });

  test('unknown stored value falls back to system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'bogus'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('PreferencesScreen selects theme and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: PreferencesScreen()),
      ),
    );
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(prefs.getString('theme_mode'), 'dark');
    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
