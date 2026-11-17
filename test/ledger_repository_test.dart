import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/ledger/data/ledger_repository.dart';
import 'package:my_budget/features/ledger/domain/ledger_models.dart';

import 'ledger_test_helpers.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;
  late int p, acc, other, cat;

  setUp(() async {
    db = AppDatabase.memory();
    repo = LedgerRepository(db);
    p = await addProfile(db);
    acc = await addAccount(db, p, 'Cash', opening: 100000);
    other = await addAccount(db, p, 'Bank', opening: 50000);
    cat = await addCategory(db, p, 'Food');
  });
  tearDown(() => db.close());

  Future<AccountLedger> ledger({
    int? profile,
    int? account,
    String? from,
    String? to,
    String? search,
  }) => repo
      .watchAccountLedger(
        profileId: profile ?? p,
        accountId: account ?? acc,
        from: from,
        to: to,
        search: search,
      )
      .first;

  Future<int> income(int amount, String date, {int? account, String? src}) =>
      addTxn(
        db,
        profileId: p,
        type: 'income',
        accountId: account ?? acc,
        amount: amount,
        date: date,
        incomeSource: src,
      );
  Future<int> expense(int amount, String date, {int? account, String? title}) =>
      addTxn(
        db,
        profileId: p,
        type: 'expense',
        accountId: account ?? acc,
        amount: amount,
        date: date,
        categoryId: cat,
        category: 'Food',
        title: title,
      );
  Future<int> transfer(int amount, String date, int from, int to) => addTxn(
    db,
    profileId: p,
    type: 'transfer',
    accountId: from,
    toAccountId: to,
    amount: amount,
    date: date,
    accountName: from == acc ? 'Cash' : 'Bank',
    toAccountName: to == acc ? 'Cash' : 'Bank',
  );

  test('empty account has only the opening row', () async {
    final l = await ledger();
    expect(l.rows, hasLength(1));
    expect(l.rows.first.isOpening, isTrue);
    expect(l.rows.first.balanceMinor, 100000);
    expect(l.hasMovements, isFalse);
  });

  test(
    'income, expense and transfers in/out compute running balance',
    () async {
      await income(20000, '2026-03-01', src: 'Salary');
      await expense(5000, '2026-03-02');
      await transfer(10000, '2026-03-03', acc, other); // out of acc
      await transfer(4000, '2026-03-04', other, acc); // in to acc
      final l = await ledger();
      expect(l.rows.map((r) => r.balanceMinor).toList(), [
        100000,
        120000,
        115000,
        105000,
        109000,
      ]);
      expect(l.rows[1].incomeMinor, 20000);
      expect(l.rows[2].expenseMinor, 5000);
      expect(l.rows[3].transferOutMinor, 10000);
      expect(l.rows[3].description, 'Transfer to Bank');
      expect(l.rows[4].transferInMinor, 4000);
      expect(l.rows[4].description, 'Transfer from Bank');
      expect(l.totalIncomeMinor, 20000);
      expect(l.closingBalanceMinor, 109000);

      // Destination account sees the first transfer as Transfer In.
      final o = await ledger(account: other);
      expect(o.rows.map((r) => r.balanceMinor).toList(), [50000, 60000, 56000]);
      expect(o.rows[1].transferInMinor, 10000);
      expect(o.rows[2].transferOutMinor, 4000);
    },
  );

  test('soft-deleted rows are excluded', () async {
    await income(20000, '2026-03-01');
    await addTxn(
      db,
      profileId: p,
      type: 'income',
      accountId: acc,
      amount: 99999,
      date: '2026-03-02',
      deleted: true,
    );
    final l = await ledger();
    expect(l.rows, hasLength(2));
    expect(l.closingBalanceMinor, 120000);
  });

  test('same-day rows are ordered by id', () async {
    final a = await expense(1000, '2026-03-05', title: 'first');
    final b = await income(500, '2026-03-05');
    final c = await expense(200, '2026-03-05', title: 'third');
    final l = await ledger();
    expect(l.rows.skip(1).map((r) => r.id).toList(), [a, b, c]);
    expect(l.rows.map((r) => r.balanceMinor).toList(), [
      100000,
      99000,
      99500,
      99300,
    ]);
  });

  test('backdated insert changes later balances', () async {
    await expense(1000, '2026-03-10');
    var l = await ledger();
    expect(l.closingBalanceMinor, 99000);
    await income(5000, '2026-03-02'); // higher id but earlier date
    l = await ledger();
    expect(l.rows[1].incomeMinor, 5000);
    expect(l.rows[1].balanceMinor, 105000);
    expect(l.rows[2].balanceMinor, 104000);
  });

  test('range filter keeps opening carry-in from earlier rows', () async {
    await income(20000, '2026-02-10');
    await expense(5000, '2026-02-20');
    await expense(1000, '2026-03-05');
    await expense(2000, '2026-04-01');
    final l = await ledger(from: '2026-03-01', to: '2026-03-31');
    expect(l.rows, hasLength(2));
    expect(l.rows.first.balanceMinor, 115000); // 100000 + 20000 - 5000
    expect(l.rows.first.date, '2026-03-01');
    expect(l.rows[1].balanceMinor, 114000);
    expect(l.totalExpenseMinor, 1000);
    // A range with no rows still shows the carried balance.
    final e = await ledger(from: '2026-05-01', to: '2026-05-31');
    expect(e.rows, hasLength(1));
    expect(e.rows.first.balanceMinor, 112000 + 0);
  });

  test('rows before the opening date are ignored', () async {
    await income(7777, '2025-12-31');
    final l = await ledger();
    expect(l.closingBalanceMinor, 100000);
    expect(l.rows, hasLength(1));
  });

  test('search matches title, remarks, category, item and source', () async {
    await expense(1000, '2026-03-01', title: 'Lunch box');
    await income(2000, '2026-03-02', src: 'Freelance');
    await addTxn(
      db,
      profileId: p,
      type: 'expense',
      accountId: acc,
      amount: 300,
      date: '2026-03-03',
      categoryId: cat,
      category: 'Food',
      costItem: 'Rice',
      remarks: 'bulk 50% off',
    );
    expect((await ledger(search: 'lunch')).rows, hasLength(2));
    expect((await ledger(search: 'FREELANCE')).rows, hasLength(2));
    expect((await ledger(search: 'rice')).rows, hasLength(2));
    expect((await ledger(search: '50%')).rows, hasLength(2));
    expect((await ledger(search: 'food')).rows, hasLength(3)); // 2 expenses
    expect((await ledger(search: 'zzz')).rows, hasLength(1));
    // Search does not disturb balances of the rows that remain.
    final l = await ledger(search: 'freelance');
    expect(l.rows[1].balanceMinor, 100000 - 1000 + 2000);
  });

  test('cross-profile isolation', () async {
    final p2 = await addProfile(db, 'Q');
    final a2 = await addAccount(db, p2, 'Other cash', opening: 1);
    await addTxn(
      db,
      profileId: p2,
      type: 'income',
      accountId: a2,
      amount: 500,
      date: '2026-03-01',
    );
    final l = await ledger();
    expect(l.rows, hasLength(1));
    expect(
      () => ledger(profile: p2, account: acc),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(() => ledger(account: 9999), throwsA(isA<NotFoundException>()));
    final accounts = await repo.watchAccounts(p).first;
    expect(accounts.map((a) => a.name), containsAll(['Cash', 'Bank']));
    expect(accounts, hasLength(2));
  });

  group('budget ledger', () {
    Future<BudgetLedger> budget(int y, int m, [int? profile]) => repo
        .watchBudgetLedger(profileId: profile ?? p, year: y, month: m)
        .first;

    test('cumulative remaining can go negative', () async {
      await addBudget(db, p, 2026, 3, 10000);
      await expense(6000, '2026-03-02');
      await expense(5000, '2026-03-02');
      await income(99999, '2026-03-02'); // ignored
      final l = await budget(2026, 3);
      expect(l.budgetMinor, 10000);
      expect(l.rows.map((r) => r.remainingMinor).toList(), [4000, -1000]);
      expect(l.totalExpenseMinor, 11000);
      expect(l.remainingMinor, -1000);
    });

    test('no budget still lists expenses with null remaining', () async {
      await expense(600, '2026-03-02');
      final l = await budget(2026, 3);
      expect(l.budgetMinor, isNull);
      expect(l.rows, hasLength(1));
      expect(l.rows.single.remainingMinor, isNull);
      expect(l.remainingMinor, isNull);
    });

    test('month boundaries, deleted rows and profiles', () async {
      await addBudget(db, p, 2026, 2, 5000);
      await expense(100, '2026-01-31');
      await expense(200, '2026-02-01');
      await expense(300, '2026-02-28');
      await expense(400, '2026-03-01');
      await addTxn(
        db,
        profileId: p,
        type: 'expense',
        accountId: acc,
        amount: 9000,
        date: '2026-02-10',
        categoryId: cat,
        category: 'Food',
        deleted: true,
      );
      final l = await budget(2026, 2);
      expect(l.rows.map((r) => r.expenseMinor).toList(), [200, 300]);
      expect(l.rows.map((r) => r.remainingMinor).toList(), [4800, 4500]);
      final p2 = await addProfile(db, 'Q');
      expect((await budget(2026, 2, p2)).rows, isEmpty);
    });

    test('leap-day expense belongs to February', () async {
      await expense(100, '2028-02-29');
      await expense(100, '2028-03-01');
      expect((await budget(2028, 2)).rows, hasLength(1));
    });
  });
}
