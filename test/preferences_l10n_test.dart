import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/preferences/data/locale_provider.dart';
import 'package:my_budget/features/preferences/presentation/preferences_screen.dart';
import 'package:my_budget/l10n/l10n.dart';

import 'app_shell_localized_app.dart';

import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors lib/app/app.dart: the app locale comes from `localeProvider`.
class _App extends ConsumerWidget {
  const _App();
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    locale: ref.watch(localeProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: appTestDelegates,
    home: const PreferencesScreen(),
  );
}

void main() {
  tearDown(() => Intl.defaultLocale = null);

  testWidgets('switching to বাংলা changes the screen text immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const _App(),
      ),
    );
    await tester.pump();
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);

    await tester.tap(find.text('বাংলা'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('পছন্দসমূহ'), findsOneWidget);
    expect(find.text('ভাষা'), findsOneWidget);
    expect(find.text('সিস্টেমের ডিফল্ট'), findsOneWidget);
    expect(find.text('Preferences'), findsNothing);
    // Language names are never translated.
    expect(find.text('English'), findsOneWidget);
    expect(prefs.getString(localeKey), 'bn');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Preferences'), findsOneWidget);
    expect(prefs.getString(localeKey), 'en');

    await tester.tap(find.text('System default'));
    await tester.pump();
    expect(prefs.getString(localeKey), isNull);
  });
}
