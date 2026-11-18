import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/search/presentation/search_screen.dart';
import 'package:my_budget/features/search/providers/search_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pump(WidgetTester tester, {required bool bangla}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    recentSearchesKey: ['old query'],
  });
  final sp = await SharedPreferences.getInstance();
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() => addProfile(db));
  const home = SearchScreen();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(sp),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
      ],
      child: bangla ? localizedApp(home: home) : const MaterialApp(home: home),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('search screen and filter sheet render in Bangla', (
    tester,
  ) async {
    await _pump(tester, bangla: true);
    expect(find.text('লেনদেন খুঁজুন'), findsOneWidget);
    expect(find.text('সাম্প্রতিক খোঁজা'), findsOneWidget);
    expect(find.text('সব মুছুন'), findsOneWidget);
    expect(find.text('old query'), findsOneWidget);

    await tester.tap(find.byTooltip('ফিল্টার'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ধরন'), findsOneWidget);
    expect(find.text('খরচ'), findsOneWidget);
    expect(find.text('আয়'), findsOneWidget);
    expect(find.text('সাজানোর ক্রম'), findsOneWidget);
    expect(find.text('নতুন আগে'), findsOneWidget);
    expect(find.text('রিসেট'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search screen still renders in English by default', (
    tester,
  ) async {
    await _pump(tester, bangla: false);
    expect(find.text('Search transactions'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
