import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/search/presentation/search_screen.dart';
import 'package:my_budget/features/search/providers/search_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester, [int ms = 200]) async {
  await tester.runAsync(() => Future.delayed(Duration(milliseconds: ms)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<SharedPreferences> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db);
    final acc = await addAccount(db, 1, 'Cash');
    final cat = await addCategory(db, 1, 'Food');
    await addTxn(
      db,
      profileId: 1,
      type: 'expense',
      categoryId: cat,
      accountId: acc,
      amount: 25000,
      date: '2026-03-05',
      title: 'Lunch',
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'expense',
      categoryId: cat,
      accountId: acc,
      amount: 10000,
      date: '2026-03-05',
      title: 'Taxi',
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: acc,
      amount: 500000,
      date: '2026-03-01',
      incomeSource: 'Salary',
    );
  });
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/transactions/:id',
        builder: (_, s) =>
            Scaffold(body: Text('detail ${s.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(sp),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return sp;
}

void main() {
  testWidgets('empty query shows recents; typing shows grouped results', (
    tester,
  ) async {
    await _pump(
      tester,
      prefs: {
        recentSearchesKey: ['old query'],
      },
    );
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('old query'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lunch');
    await tester.pump(const Duration(milliseconds: 350));
    await _settle(tester);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Taxi'), findsNothing);
    expect(find.text('2026-03-05'), findsOneWidget);
    expect(find.text('-৳250.00'), findsOneWidget);
  });

  testWidgets('tapping a recent runs it; tapping a row opens detail', (
    tester,
  ) async {
    await _pump(
      tester,
      prefs: {
        recentSearchesKey: ['salary'],
      },
    );
    await tester.tap(find.text('salary'));
    await _settle(tester);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('+৳5,000.00'), findsOneWidget);
    await tester.tap(find.text('Salary'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('detail 3'), findsOneWidget);
  });

  testWidgets('no match shows empty state; submit saves recent', (
    tester,
  ) async {
    final sp = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(find.text('No matching transactions.'), findsOneWidget);
    expect(sp.getStringList(recentSearchesKey), ['zzz']);
  });

  testWidgets('filter sheet applies type filter and clear filters resets', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Filters'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Income'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await _settle(tester);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);

    await tester.tap(find.text('Clear filters').first);
    await _settle(tester);
    expect(find.text('Recent searches'), findsNothing);
    expect(
      find.text('Search by title, remarks, category, account, tag…'),
      findsOneWidget,
    );
  });
}
