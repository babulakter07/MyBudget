import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/insights/presentation/insights_highlights_card.dart';
import 'package:my_budget/features/insights/presentation/insights_screen.dart';
import 'package:my_budget/features/insights/providers/insights_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed,
  Widget home,
) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db, 'Family');
    await seed(db);
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: '/insights',
        builder: (_, _) => const Scaffold(body: Text('INSIGHTS PAGE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        insightsClockProvider.overrideWithValue(() => DateTime(2026, 3, 20)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _seed(AppDatabase db) async {
  final acc = await addAccount(db, 1, 'Cash');
  final food = await addCategory(db, 1, 'Food');
  await addBudget(db, 1, 2026, 3, 100000);
  await addTxn(
    db,
    profileId: 1,
    type: 'expense',
    accountId: acc,
    amount: 20000,
    date: '2026-03-05',
    categoryId: food,
    category: 'Food',
    title: 'Rice',
  );
  await addTxn(
    db,
    profileId: 1,
    type: 'expense',
    accountId: acc,
    amount: 10000,
    date: '2026-02-05',
    categoryId: food,
    category: 'Food',
  );
}

void main() {
  testWidgets('highlights card shows messages and navigates on tap', (
    tester,
  ) async {
    await _pump(tester, _seed, const InsightsHighlightsCard());
    expect(find.text('Insights'), findsOneWidget);
    expect(find.textContaining('On track'), findsOneWidget);
    expect(find.textContaining('Food is up ৳100.00 (100%)'), findsOneWidget);
    await tester.tap(find.byType(InsightsHighlightsCard));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('INSIGHTS PAGE'), findsOneWidget);
  });

  testWidgets('highlights card hides when there is no data', (tester) async {
    await _pump(tester, (_) async {}, const InsightsHighlightsCard());
    expect(find.text('Insights'), findsNothing);
  });

  testWidgets('insights screen shows cards and month navigation', (
    tester,
  ) async {
    await _pump(tester, _seed, const InsightsScreen());
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('Month-end forecast'), findsOneWidget);
    expect(find.text('Spending by weekday (last 90 days)'), findsOneWidget);
    expect(find.text('Rice'), findsWidgets);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.text('Month-end forecast'), findsNothing);
  });

  testWidgets('insights screen empty state', (tester) async {
    await _pump(tester, (_) async {}, const InsightsScreen());
    expect(find.textContaining('No spending data'), findsOneWidget);
  });
}
