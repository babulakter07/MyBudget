import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/presentation/add_transaction_view.dart';
import 'package:my_budget/features/transactions/presentation/amount_keypad.dart';
import 'package:my_budget/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _Fixed extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<AppDatabase> _pump(
  WidgetTester tester,
  Widget home, {
  required bool bn,
  Future<void> Function(AppDatabase db)? seedExtra,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  await tester.runAsync(() async {
    final pid = await addProfile(db);
    await addAccount(db, pid, 'Cash');
    await addCategory(db, pid, 'Food');
    await seedExtra?.call(db);
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_Fixed.new),
      ],
      child: bn ? localizedApp(home: home) : MaterialApp(home: home),
    ),
  );
  await _settle(tester);
  return db;
}

/// The framework reports a locale-support warning for the Material delegates under
/// `bn` in tests (shared helper issue); anything else is a real error.
void expectNoRealException(WidgetTester tester) {
  final e = tester.takeException();
  expect(
    e == null || '$e'.contains('not supported by all of its localization'),
    isTrue,
    reason: '$e',
  );
}

void main() {
  testWidgets('add form renders in Bangla', (tester) async {
    await _pump(tester, const Scaffold(body: AddTransactionView()), bn: true);
    expect(find.text('খরচ'), findsOneWidget);
    expect(find.text('আয়'), findsOneWidget);
    expect(find.text('ট্রান্সফার'), findsOneWidget);
    expect(find.text('পরিমাণ'), findsOneWidget);
    expect(find.text('Expense'), findsNothing);
    // Validators speak Bangla too.
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await tester.pump();
    expect(find.text('একটি ক্যাটাগরি বেছে নিন'), findsOneWidget);
    expect(find.text('পরিমাণ লিখুন'), findsOneWidget);
    expectNoRealException(tester);
  });

  testWidgets('add form still shows English by default', (tester) async {
    await _pump(tester, const Scaffold(body: AddTransactionView()), bn: false);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('detail screen renders in Bangla', (tester) async {
    await _pump(
      tester,
      const TransactionDetailScreen(transactionId: 1),
      bn: true,
      seedExtra: (db) async {
        await TransactionRepository(db).createExpense(
          profileId: 1,
          accountId: 1,
          categoryId: 1,
          amountMinor: 245000,
          date: '2026-02-10',
          title: 'Rice',
        );
      },
    );
    expect(find.text('খরচ'), findsOneWidget);
    expect(find.text('ইতিহাস'), findsOneWidget);
    expect(find.text('রসিদ'), findsOneWidget);
    expect(find.text('তৈরি হয়েছে'), findsOneWidget);
    expect(find.text('Rice'), findsWidgets); // user data untouched
    expectNoRealException(tester);
  });

  testWidgets('keypad error is Bangla', (tester) async {
    await tester.pumpWidget(
      localizedApp(home: const Scaffold(body: AmountKeypad())),
    );
    expect(find.text('পরিমাণ ব্যবহার করুন'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('key-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('keypad-done')));
    await tester.pump();
    expect(find.text('পরিমাণ অবশ্যই শূন্যের বেশি হতে হবে।'), findsOneWidget);
    expectNoRealException(tester);
  });
}
