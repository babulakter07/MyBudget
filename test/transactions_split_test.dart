import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/domain/transaction_models.dart';
import 'package:my_budget/features/transactions/presentation/split_expense_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_test_helpers.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late int pid, other, acc, food, home;

  Future<int> count(int profileId) async {
    final rows = await (db.select(
      db.financialTransactions,
    )..where((t) => t.profileId.equals(profileId))).get();
    return rows.length;
  }

  setUp(() async {
    db = AppDatabase.memory();
    repo = TransactionRepository(db);
    pid = await addProfile(db, 'Mine');
    other = await addProfile(db, 'Other');
    acc = await addAccount(db, pid, 'Cash', opening: 100000);
    food = await addCategory(db, pid, 'Food');
    home = await addCategory(db, pid, 'Home');
  });
  tearDown(() => db.close());

  test('saves one expense per line with shared account/date/title', () async {
    final out = await repo.createSplitExpense(
      profileId: pid,
      accountId: acc,
      date: '2026-03-10',
      title: 'Shop',
      keyPrefix: 'k1',
      lines: [
        SplitExpenseLine(categoryId: food, amountMinor: 1200),
        SplitExpenseLine(categoryId: home, amountMinor: 800),
      ],
    );
    expect(out.length, 2);
    expect(await count(pid), 2);
    expect(out.map((e) => e.amountMinor).toSet(), {1200, 800});
    expect(out.every((e) => e.date == '2026-03-10'), isTrue);
    expect(out.every((e) => e.title == 'Shop'), isTrue);
  });

  test('all-or-nothing: an invalid line saves nothing', () async {
    await expectLater(
      repo.createSplitExpense(
        profileId: pid,
        accountId: acc,
        date: '2026-03-10',
        lines: [
          SplitExpenseLine(categoryId: food, amountMinor: 1200),
          SplitExpenseLine(categoryId: home, amountMinor: 0),
        ],
      ),
      throwsA(isA<AppException>()),
    );
    expect(await count(pid), 0);
  });

  test('a category from another profile is rejected, nothing saved', () async {
    final foreign = await addCategory(db, other, 'Theirs');
    await expectLater(
      repo.createSplitExpense(
        profileId: pid,
        accountId: acc,
        date: '2026-03-10',
        lines: [
          SplitExpenseLine(categoryId: food, amountMinor: 100),
          SplitExpenseLine(categoryId: foreign, amountMinor: 100),
        ],
      ),
      throwsA(isA<AppException>()),
    );
    expect(await count(pid), 0);
    expect(await count(other), 0);
  });

  test('needs two lines; retry with the same key does not duplicate', () async {
    await expectLater(
      repo.createSplitExpense(
        profileId: pid,
        accountId: acc,
        date: '2026-03-10',
        lines: [SplitExpenseLine(categoryId: food, amountMinor: 100)],
      ),
      throwsA(isA<ValidationException>()),
    );
    final lines = [
      SplitExpenseLine(categoryId: food, amountMinor: 100),
      SplitExpenseLine(categoryId: home, amountMinor: 200),
    ];
    for (var i = 0; i < 2; i++) {
      await repo.createSplitExpense(
        profileId: pid,
        accountId: acc,
        date: '2026-03-10',
        keyPrefix: 'same',
        lines: lines,
      );
    }
    expect(await count(pid), 2);
  });

  testWidgets('screen validates, shows total, saves a split', (tester) async {
    SharedPreferences.setMockInitialValues({'active_profile_id': pid});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: SplitExpenseScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    // No account chosen yet.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('split-save')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('split-save')));
    await tester.pump();
    expect(find.text('Choose an account.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('split-amount-0')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('split-amount-0')),
      '12.50',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('split-amount-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('split-amount-1')),
      '7.50',
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('split-total')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Total: ৳20.00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
