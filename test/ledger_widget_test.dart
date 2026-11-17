import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/ledger/presentation/budget_ledger_tab.dart';
import 'package:my_budget/features/ledger/presentation/ledger_view.dart';
import 'package:my_budget/features/ledger/providers/ledger_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

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

Future<AppDatabase> _pump(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed,
) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db);
    await seed(db);
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: LedgerView()),
      ),
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
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ledgerClockProvider.overrideWithValue(() => DateTime(2026, 3, 15)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return db;
}

Finder _inBudget(String text) => find.descendant(
  of: find.byType(BudgetLedgerTab),
  matching: find.text(text),
);

void main() {
  testWidgets('account ledger lists rows, balances and navigates on tap', (
    tester,
  ) async {
    await _pump(tester, (db) async {
      final acc = await addAccount(db, 1, 'Cash', opening: 100000);
      final cat = await addCategory(db, 1, 'Food');
      await addTxn(
        db,
        profileId: 1,
        type: 'income',
        accountId: acc,
        amount: 50000,
        date: '2026-03-02',
        incomeSource: 'Salary',
      );
      await addTxn(
        db,
        profileId: 1,
        type: 'expense',
        accountId: acc,
        amount: 20050,
        date: '2026-03-05',
        categoryId: cat,
        category: 'Food',
        title: 'Lunch',
      );
    });

    expect(find.text('Account Ledger'), findsOneWidget);
    expect(find.text('Opening Balance'), findsOneWidget);
    expect(find.text('Salary'), findsWidgets);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('৳1,500.00'), findsOneWidget); // after income
    expect(find.text('৳1,299.50'), findsWidgets); // after expense + footer
    expect(find.text('Total'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('detail 2'), findsOneWidget);
  });

  testWidgets('account ledger search narrows rows', (tester) async {
    await _pump(tester, (db) async {
      final acc = await addAccount(db, 1, 'Cash', opening: 1000);
      await addTxn(
        db,
        profileId: 1,
        type: 'income',
        accountId: acc,
        amount: 500,
        date: '2026-03-02',
        title: 'Bonus payout',
      );
      await addTxn(
        db,
        profileId: 1,
        type: 'income',
        accountId: acc,
        amount: 700,
        date: '2026-03-03',
        title: 'Refund',
      );
    });
    expect(find.text('Bonus payout'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'bonus');
    await _settle(tester);
    expect(find.text('Bonus payout'), findsOneWidget);
    expect(find.text('Refund'), findsNothing);
  });

  testWidgets('account ledger empty states', (tester) async {
    await _pump(tester, (_) async {});
    expect(find.textContaining('No accounts yet'), findsOneWidget);
  });

  testWidgets('empty account shows opening row and empty hint', (tester) async {
    await _pump(tester, (db) async {
      await addAccount(db, 1, 'Cash', opening: 5000);
    });
    expect(find.text('Opening Balance'), findsOneWidget);
    expect(find.text('No transactions in this period.'), findsOneWidget);
    expect(find.text('৳50.00'), findsWidgets);
  });

  testWidgets('budget ledger shows negative remaining and no-budget state', (
    tester,
  ) async {
    await _pump(tester, (db) async {
      final acc = await addAccount(db, 1, 'Cash', opening: 100000);
      final cat = await addCategory(db, 1, 'Food');
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
        costItem: 'Groceries',
      );
      await addTxn(
        db,
        profileId: 1,
        type: 'expense',
        accountId: acc,
        amount: 100,
        date: '2026-02-04',
        categoryId: cat,
        category: 'Food',
        costItem: 'Tea',
      );
    });
    await tester.tap(find.text('Budget Ledger'));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    await _settle(tester);
    expect(_inBudget('Groceries'), findsOneWidget);
    expect(_inBudget('Tea'), findsNothing);
    final remaining = tester.widget<Text>(_inBudget('-৳20.00').first);
    final ctx = tester.element(_inBudget('-৳20.00').first);
    expect(remaining.style?.color, Theme.of(ctx).colorScheme.error);

    // Previous month has an expense but no budget.
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left))
        .onPressed!();
    await _settle(tester);
    await _settle(tester);
    expect(_inBudget('Tea'), findsOneWidget);
    expect(find.text('No budget set for this month.'), findsOneWidget);
    expect(find.text('No budget'), findsWidgets);
  });

  testWidgets('budget ledger empty month', (tester) async {
    await _pump(tester, (db) async {
      await addAccount(db, 1, 'Cash');
    });
    await tester.tap(find.text('Budget Ledger'));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    await _settle(tester);
    expect(find.text('No expenses in this month.'), findsOneWidget);
  });
}
