import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/goals/domain/goal.dart';
import 'package:my_budget/features/goals/presentation/goal_list_screen.dart';
import 'package:my_budget/features/goals/presentation/goals_summary_card.dart';
import 'package:my_budget/features/goals/providers/goal_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

GoalWithProgress _g(
  int id,
  String name,
  int balance,
  int target, {
  String? date,
  bool active = true,
}) => GoalWithProgress(
  goal: Goal(
    id: id,
    profileId: 1,
    name: name,
    accountId: 1,
    targetMinor: target,
    targetDate: date,
    note: null,
    isActive: active,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  accountName: 'Savings',
  accountActive: true,
  progress: computeGoalProgress(
    balanceMinor: balance,
    targetMinor: target,
    today: '2026-06-01',
    targetDate: date,
  ),
);

List<Override> _overrides(List<GoalWithProgress> items) => [
  activeProfileIdProvider.overrideWith(_FixedProfile.new),
  goalsProvider.overrideWith((ref) => Stream.value(items)),
  activeGoalsProvider.overrideWith((ref) => Stream.value(items)),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('list shows cards, percent, achieved badge, fab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides([
          _g(1, 'Laptop', 25000, 100000, date: '2026-08-30'),
          _g(2, 'Phone', 60000, 50000),
        ]),
        child: const MaterialApp(home: GoalListScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Achieved'), findsOneWidget);
    expect(find.textContaining('remaining'), findsOneWidget);
    expect(find.textContaining('/ month'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('list empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides([]),
        child: const MaterialApp(home: GoalListScreen()),
      ),
    );
    await _settle(tester);
    expect(find.textContaining('No savings goals'), findsOneWidget);
  });

  testWidgets('list error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
          goalsProvider.overrideWith((ref) => Stream.error('boom')),
        ],
        child: const MaterialApp(home: GoalListScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('archive asks for confirmation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides([_g(1, 'Laptop', 0, 100000)]),
        child: const MaterialApp(home: GoalListScreen()),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byTooltip('Archive goal'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Archive goal?'), findsOneWidget);
  });

  testWidgets('fab opens the form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides([]),
          goalAccountOptionsProvider.overrideWith(
            (ref) => Stream.value(const <GoalAccountOption>[]),
          ),
        ],
        child: const MaterialApp(home: GoalListScreen()),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add goal'), findsOneWidget);
    expect(find.text('Target amount'), findsOneWidget);
  });

  testWidgets('summary card shows top 3 and navigates to /goals', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: GoalsSummaryCard()),
        ),
        GoRoute(
          path: '/goals',
          builder: (_, _) => const Scaffold(body: Text('GOALS PAGE')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides([
          _g(1, 'A', 10000, 100000),
          _g(2, 'B', 20000, 100000),
          _g(3, 'C', 30000, 100000),
          _g(4, 'D', 40000, 100000),
        ]),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _settle(tester);
    expect(find.text('Savings goals'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    await tester.tap(find.text('Savings goals'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('GOALS PAGE'), findsOneWidget);
  });

  testWidgets('summary card hides itself when no goals', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides([]),
        child: const MaterialApp(home: Scaffold(body: GoalsSummaryCard())),
      ),
    );
    await _settle(tester);
    expect(find.text('Savings goals'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });
}
