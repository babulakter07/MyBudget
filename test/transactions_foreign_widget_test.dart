import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/currency/data/exchange_rate_repository.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/presentation/add_transaction_view.dart';
import 'package:my_budget/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:my_budget/features/transactions/presentation/transaction_form.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db, {bool rates = true}) async {
  await db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: 'P',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
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
  if (rates) {
    await ExchangeRateRepository(db)
        .upsert(profileId: 1, currencyCode: 'USD', rateMicro: 122500000);
  }
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

Future<void> _chooseCategory(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Food').last);
  await tester.pump(const Duration(milliseconds: 300));
  await _settle(tester);
}

void main() {
  testWidgets('selector hidden for transfer, shown for expense and income', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    expect(find.byKey(const ValueKey('currency-chip-USD')), findsOneWidget);
    expect(find.byKey(const ValueKey('currency-chip-BDT')), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('currency-chip-USD')), findsOneWidget);

    await tester.tap(find.text('Transfer'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('currency-chip-USD')), findsNothing);
    expect(find.byKey(const ValueKey('currency-chip-BDT')), findsNothing);
  });

  testWidgets('live conversion line and saved foreign expense', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));

    await _chooseCategory(tester);
    await tester.tap(find.byKey(const ValueKey('currency-chip-USD')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 USD = ৳122.5'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('amount-field')), '20');
    await tester.pump();
    expect(find.text('= ৳2,450.00 at 1 USD = 122.5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    await _settle(tester);

    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows.length, 1);
    expect(rows.single.amountMinor, 245000);
    expect(rows.single.originalAmountMinor, 2000);
    expect(rows.single.originalCurrency, 'USD');
    expect(rows.single.rateMicro, 122500000);
    // Form resets to base currency.
    expect(find.text('= ৳2,450.00 at 1 USD = 122.5'), findsNothing);
  });

  testWidgets('conversion that rounds to zero blocks save', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db, rates: false));
    await tester.runAsync(
      () =>
          ExchangeRateRepository(db)
              .upsert(profileId: 1, currencyCode: 'JPY', rateMicro: 1000),
    );
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    await _chooseCategory(tester);
    await tester.tap(find.byKey(const ValueKey('currency-chip-JPY')));
    await tester.pump(const Duration(milliseconds: 200));
    // 0.01 JPY x 0.001 = 0.00001 -> 0 base minor units.
    await tester.enterText(find.byKey(const ValueKey('amount-field')), '0.01');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    await _settle(tester);
    expect(find.textContaining('cannot be converted'), findsWidgets);
    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows, isEmpty);
  });

  testWidgets('no rates shows only base currency and an Add rates link', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db, rates: false));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    expect(find.byKey(const ValueKey('currency-chip-BDT')), findsOneWidget);
    expect(find.byKey(const ValueKey('currency-chip-USD')), findsNothing);
    expect(find.text('Add exchange rates'), findsOneWidget);
  });

  testWidgets('edit preloads saved original even if the rate was deactivated', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    final repo = TransactionRepository(db);
    final t = (await tester.runAsync(
      () => repo.createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 245000,
        originalAmountMinor: 2000,
        originalCurrency: 'USD',
        rateMicro: 122500000,
        date: '2026-02-10',
      ),
    ))!;
    await tester.runAsync(
      () => ExchangeRateRepository(db).setActive(1, 1, false),
    );
    await _pumpApp(
      tester,
      db,
      Scaffold(
        body: TransactionForm(existing: t, onSaved: () {}),
      ),
    );
    expect(find.byKey(const ValueKey('currency-chip-USD')), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('currency-chip-USD')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('amount-field')))
          .controller!
          .text,
      '20.00',
    );
    expect(find.text('= ৳2,450.00 at 1 USD = 122.5'), findsOneWidget);

    // Switch back to base and save: original fields are cleared.
    await tester.tap(find.byKey(const ValueKey('currency-chip-BDT')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    await _settle(tester);
    final row = (await tester.runAsync(() => repo.getById(1, t.id)))!;
    expect(row.isForeign, isFalse);
    expect(row.amountMinor, 2000);
  });

  testWidgets('detail shows original amount line and keeps base headline', (
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
        amountMinor: 245000,
        originalAmountMinor: 2000,
        originalCurrency: 'USD',
        rateMicro: 122500000,
        date: '2026-02-10',
      ),
    );
    await tester.runAsync(
      () => repo.updateExpense(
        profileId: 1,
        id: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 245000,
        date: '2026-02-10',
      ),
    );
    await _pumpApp(tester, db, const TransactionDetailScreen(transactionId: 1));
    expect(find.text('৳2,450.00'), findsOneWidget);
    // Edited back to base: no original line, and the history mentions it.
    expect(find.byKey(const ValueKey('detail-original')), findsNothing);
    expect(find.textContaining('original currency: USD'), findsOneWidget);
  });

  testWidgets('detail shows USD 20.00 at 1 USD = ৳122.5', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    final repo = TransactionRepository(db);
    await tester.runAsync(
      () => repo.createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 245000,
        originalAmountMinor: 2000,
        originalCurrency: 'USD',
        rateMicro: 122500000,
        date: '2026-02-10',
      ),
    );
    await _pumpApp(tester, db, const TransactionDetailScreen(transactionId: 1));
    expect(find.text('৳2,450.00'), findsOneWidget);
    expect(find.text('USD 20.00 at 1 USD = ৳122.5'), findsOneWidget);
  });
}
