import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/ledger/data/ledger_repository.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/wallets/data/wallet_repository.dart';
import 'package:my_budget/features/wallets/domain/wallet_models.dart';

import 'ledger_test_helpers.dart';

final _now = DateTime(2026, 3, 15);

Future<int> _acc(
  AppDatabase db,
  int profileId,
  String name,
  String type, {
  int opening = 0,
  bool active = true,
}) => db
    .into(db.accounts)
    .insert(
      AccountsCompanion.insert(
        profileId: profileId,
        name: name,
        type: Value(type),
        openingBalanceMinor: Value(opening),
        openingDate: '2026-01-01',
        isActive: Value(active),
        createdAt: _now,
        updatedAt: _now,
      ),
    );

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  late TransactionRepository txns;

  setUp(() async {
    db = AppDatabase.memory();
    repo = WalletRepository(db);
    txns = TransactionRepository(db);
    await addProfile(db); // 1
    await addProfile(db, 'Other'); // 2
  });
  tearDown(() => db.close());

  test(
    'groups by type, excludes credit cards and inactive from total',
    () async {
      await _acc(db, 1, 'Wallet', 'cash', opening: 10000);
      await _acc(db, 1, 'DBBL', 'bank', opening: 500000);
      await _acc(db, 1, 'bKash', 'mobile', opening: 20000);
      await _acc(db, 1, 'FDR', 'savings', opening: 100000);
      await _acc(db, 1, 'Visa', 'credit_card', opening: -300000);
      await _acc(db, 1, 'Old', 'cash', opening: 99999, active: false);
      await _acc(db, 2, 'Foreign', 'cash', opening: 777);

      final o = await repo.watchOverview(1, now: _now).first;
      expect(o.groups.map((g) => g.type).toList(), [
        'cash',
        'bank',
        'mobile',
        'savings',
        'credit_card',
      ]);
      expect(o.groups.first.items.single.account.name, 'Wallet');
      expect(o.groups.first.subtotalMinor, 10000);
      expect(o.groups.last.subtotalMinor, -300000);
      expect(o.totalMinor, 10000 + 500000 + 20000 + 100000);
    },
  );

  test('empty profile gives an empty overview', () async {
    final o = await repo.watchOverview(1, now: _now).first;
    expect(o.isEmpty, isTrue);
    expect(o.totalMinor, 0);
  });

  test('this-month in/out counts income, expense and transfers only', () async {
    final cash = await _acc(db, 1, 'Cash', 'cash', opening: 1000);
    final bank = await _acc(db, 1, 'Bank', 'bank');
    final cat = await addCategory(db, 1, 'Food');
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: cash,
      amount: 5000,
      date: '2026-03-02',
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'expense',
      accountId: cash,
      amount: 700,
      date: '2026-03-03',
      categoryId: cat,
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'transfer',
      accountId: bank,
      toAccountId: cash,
      amount: 300,
      date: '2026-03-04',
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'transfer',
      accountId: cash,
      toAccountId: bank,
      amount: 100,
      date: '2026-03-05',
    );
    // other month and soft-deleted rows must not count in the month figures
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: cash,
      amount: 9000,
      date: '2026-02-20',
    );
    await addTxn(
      db,
      profileId: 1,
      type: 'income',
      accountId: cash,
      amount: 4000,
      date: '2026-03-06',
      deleted: true,
    );

    final o = await repo.watchOverview(1, now: _now).first;
    final c = o.groups.firstWhere((g) => g.type == 'cash').items.single;
    expect(c.monthInMinor, 5300);
    expect(c.monthOutMinor, 800);
    expect(c.balanceMinor, 1000 + 5000 - 700 + 300 - 100 + 9000);
  });

  test('watchWallet rejects missing and cross-profile accounts', () async {
    final foreign = await _acc(db, 2, 'Foreign', 'cash');
    expect(
      () => repo.watchWallet(1, foreign, now: _now).first,
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(
      () => repo.watchWallet(1, 999, now: _now).first,
      throwsA(isA<NotFoundException>()),
    );
  });

  test('add money updates balance and ledger running balance', () async {
    final bank = await _acc(db, 1, 'Bank', 'bank', opening: 1000000);
    await txns.createIncome(
      profileId: 1,
      accountId: bank,
      incomeSource: 'Deposit',
      amountMinor: 200000,
      date: '2026-03-10',
    );
    final w = await repo.watchWallet(1, bank, now: _now).first;
    expect(w.balanceMinor, 1200000);
    expect(w.monthInMinor, 200000);

    final ledger = await LedgerRepository(db)
        .watchAccountLedger(
          profileId: 1,
          accountId: bank,
          from: '2026-03-01',
          to: '2026-03-31',
        )
        .first;
    expect(ledger.rows.first.balanceMinor, 1000000);
    expect(ledger.rows.last.balanceMinor, 1200000);
    expect(ledger.rows.last.incomeMinor, 200000);
  });

  test('transfer (withdraw) updates both accounts', () async {
    final bank = await _acc(db, 1, 'Bank', 'bank', opening: 500000);
    final cash = await _acc(db, 1, 'Cash', 'cash', opening: 1000);
    await txns.createTransfer(
      profileId: 1,
      fromAccountId: bank,
      toAccountId: cash,
      amountMinor: 100000,
      date: '2026-03-10',
    );
    final b = await repo.watchWallet(1, bank, now: _now).first;
    final c = await repo.watchWallet(1, cash, now: _now).first;
    expect(b.balanceMinor, 400000);
    expect(b.monthOutMinor, 100000);
    expect(c.balanceMinor, 101000);
    expect(c.monthInMinor, 100000);
    final o = await repo.watchOverview(1, now: _now).first;
    expect(o.totalMinor, 501000); // a transfer never changes the total
  });

  test('zero amount and inactive account are rejected', () async {
    final cash = await _acc(db, 1, 'Cash', 'cash');
    final off = await _acc(db, 1, 'Off', 'cash', active: false);
    expect(
      () => txns.createIncome(
        profileId: 1,
        accountId: cash,
        incomeSource: 'Deposit',
        amountMinor: 0,
        date: '2026-03-10',
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => txns.createIncome(
        profileId: 1,
        accountId: off,
        incomeSource: 'Deposit',
        amountMinor: 100,
        date: '2026-03-10',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('walletPeriodRange', () {
    final n = DateTime(2026, 2, 10);
    expect(walletPeriodRange(WalletPeriod.thisMonth, n).from, '2026-02-01');
    expect(walletPeriodRange(WalletPeriod.thisMonth, n).to, '2026-02-28');
    expect(walletPeriodRange(WalletPeriod.last3Months, n).from, '2025-12-01');
    expect(walletPeriodRange(WalletPeriod.thisYear, n).to, '2026-12-31');
    expect(walletPeriodRange(WalletPeriod.all, n).from, isNull);
  });
}
