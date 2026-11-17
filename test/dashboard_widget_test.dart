import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/dashboard/presentation/dashboard_view.dart';
import 'package:my_budget/features/dashboard/providers/dashboard_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed,
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        dashboardClockProvider.overrideWithValue(() => DateTime(2026, 3, 10)),
      ],
      child: const MaterialApp(home: Scaffold(body: DashboardView())),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('populated dashboard shows overview, analytics and yearly', (
    tester,
  ) async {
    await _pump(tester, (db) async {
      final acc = await addAccount(db, 1, 'Cash', opening: 100000);
      final cat = await addCategory(db, 1, 'Food');
      final sub = await addSubCategory(db, 1, cat, 'Daily');
      final item = await addCostItem(db, 1, sub, 'Rice');
      await addBudget(db, 1, 2026, 3, 10000);
      await addTxn(
        db,
        profileId: 1,
        type: 'expense',
        accountId: acc,
        amount: 12000,
        date: '2026-03-04',
        categoryId: cat,
        category: 'Food',
        costItemId: item,
        costItem: 'Rice',
      );
      await addTxn(
        db,
        profileId: 1,
        type: 'income',
        accountId: acc,
        amount: 30000,
        date: '2026-03-05',
      );
    });

    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('৳100.00'), findsWidgets); // budget
    expect(find.text('৳120.00'), findsWidgets); // expense
    expect(find.text('-৳20.00'), findsOneWidget); // negative remaining
    expect(find.text('120.0%'), findsOneWidget);
    // cash = 1000 - 120 + 300 = 1180, independent of budget
    expect(find.text('৳1,180.00'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Mar 2026'), findsOneWidget);
    // 12000 over 10 elapsed days
    expect(find.text('৳12.00'), findsOneWidget);
    expect(find.text('Year 2026'), findsOneWidget);
    expect(find.text('March'), findsWidgets); // highest + lowest month
  });

  testWidgets('empty dashboard renders zero-safe values', (tester) async {
    await _pump(tester, (_) async {});
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('0.0%'), findsOneWidget);
    expect(find.text('No cost-item expenses this month.'), findsOneWidget);
    expect(find.text('No expenses to chart this month.'), findsOneWidget);
    expect(find.text('Highest spending day'), findsOneWidget);
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('switching to previous month refreshes data', (tester) async {
    await _pump(tester, (db) async {
      final acc = await addAccount(db, 1, 'Cash');
      final cat = await addCategory(db, 1, 'Food');
      await addTxn(
        db,
        profileId: 1,
        type: 'expense',
        accountId: acc,
        amount: 4200,
        date: '2026-02-10',
        categoryId: cat,
        category: 'Food',
      );
    });
    expect(find.text('No expenses to chart this month.'), findsOneWidget);
    await tester.tap(find.text('Previous month'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Feb 2026'), findsOneWidget);
    expect(find.text('No expenses to chart this month.'), findsNothing);
    expect(find.text('৳42.00'), findsWidgets);
  });
}
