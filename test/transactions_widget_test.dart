import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/presentation/add_transaction_view.dart';
import 'package:my_budget/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db, {bool accounts = true}) async {
  await db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: 'P',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  if (accounts) {
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: 1,
            name: 'Cash',
            openingDate: '2020-01-01',
            createdAt: _now,
            updatedAt: _now,
          ),
        );
  }
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: 1,
          name: 'Food',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.subCategories)
      .insert(
        SubCategoriesCompanion.insert(
          profileId: 1,
          categoryId: 1,
          name: 'Groceries',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.costItems)
      .insert(
        CostItemsCompanion.insert(
          profileId: 1,
          subCategoryId: 1,
          name: 'Rice',
          defaultAmountMinor: const Value(1200050),
          createdAt: _now,
          updatedAt: _now,
        ),
      );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpApp(WidgetTester tester, AppDatabase db, Widget child) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await _settle(tester);
}

Future<void> _choose(
  WidgetTester tester,
  int dropdownIndex,
  String text,
) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>).at(dropdownIndex));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 300));
  await _settle(tester);
}

void main() {
  testWidgets('add expense happy path with cascading dropdowns', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));

    await _choose(tester, 0, 'Food');
    await _choose(tester, 1, 'Groceries');
    await _choose(tester, 2, 'Rice');
    // Default amount prefilled, still editable.
    expect(find.text('12,000.50'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('amount-field')), '250.5');

    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    await _settle(tester);

    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows.length, 1);
    expect(rows.single.amountMinor, 25050);
    expect(rows.single.type, 'expense');
    expect(rows.single.categoryNameSnapshot, 'Food');
    expect(rows.single.costItemNameSnapshot, 'Rice');
    expect(rows.single.idempotencyKey, isNotNull);
    expect(find.text('Transaction saved'), findsOneWidget);
    // Form reset.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('amount-field')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('invalid amount shows a helpful error and saves nothing', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));

    await _choose(tester, 0, 'Food');
    await tester.enterText(
      find.byKey(const ValueKey('amount-field')),
      '12.345',
    );
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    expect(find.textContaining('valid amount'), findsOneWidget);
    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows, isEmpty);
  });

  testWidgets('shows guidance when the profile has no active accounts', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db, accounts: false));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    expect(find.textContaining('Settings > Accounts'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-button')), findsNothing);
  });

  testWidgets('detail shows fields and history; delete, undo and restore', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    final repo = TransactionRepository(db);
    await tester.runAsync(
      () => repo.createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        subCategoryId: 1,
        costItemId: 1,
        amountMinor: 1200050,
        date: '2026-02-10',
        title: 'Weekly rice',
        remarks: 'bulk',
      ),
    );
    await _pumpApp(tester, db, const TransactionDetailScreen(transactionId: 1));

    expect(find.text('৳12,000.50'), findsOneWidget);
    expect(find.text('Weekly rice'), findsWidgets);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('2026-02-10'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Delete').last);
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);

    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-button')), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await tester.pump();
    await _settle(tester);
    expect(find.byKey(const ValueKey('restore-button')), findsNothing);
    expect(find.text('Restored'), findsOneWidget);
    final row = (await tester.runAsync(() => repo.getById(1, 1)))!;
    expect(row.isDeleted, isFalse);
  });
}
