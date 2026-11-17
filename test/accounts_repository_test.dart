import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/accounts/data/account_repository.dart';

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime.now();
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<int> _category(AppDatabase db, int profileId, String name) {
  final now = DateTime.now();
  return db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: profileId,
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<int> _txn(
  AppDatabase db, {
  required int profileId,
  required String type,
  required int accountId,
  required int amount,
  required String date,
  int? toAccountId,
  int? categoryId,
  bool deleted = false,
}) {
  final now = DateTime.now();
  return db
      .into(db.financialTransactions)
      .insert(
        FinancialTransactionsCompanion.insert(
          profileId: profileId,
          type: type,
          accountId: accountId,
          toAccountId: Value(toAccountId),
          categoryId: Value(categoryId),
          accountNameSnapshot: 'acc',
          amountMinor: amount,
          txnDate: date,
          isDeleted: Value(deleted),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late AccountRepository repo;
  late int p1, p2;

  setUp(() async {
    db = AppDatabase.memory();
    repo = AccountRepository(db);
    p1 = await _profile(db, 'A');
    p2 = await _profile(db, 'B');
  });
  tearDown(() => db.close());

  Future<int> mk(
    String name, {
    int opening = 0,
    String date = '2026-01-01',
  }) async => (await repo.create(
    profileId: p1,
    name: name,
    type: 'bank',
    openingBalanceMinor: opening,
    openingDate: date,
  )).id;

  test('create trims and persists', () async {
    final a = await repo.create(
      profileId: p1,
      name: '  Wallet ',
      type: 'cash',
      openingBalanceMinor: 12050,
      openingDate: '2026-01-01',
    );
    expect(a.name, 'Wallet');
    expect(a.openingBalanceMinor, 12050);
    expect(a.isActive, isTrue);
  });

  test('validation', () async {
    Future<void> c(String n, String t, int ob, String d) => repo.create(
      profileId: p1,
      name: n,
      type: t,
      openingBalanceMinor: ob,
      openingDate: d,
    );
    expect(
      c(' ', 'cash', 0, '2026-01-01'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      c('x', 'crypto', 0, '2026-01-01'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      c('x', 'cash', -1, '2026-01-01'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      c('x', 'cash', 0, '2026-02-30'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('duplicate name is case-insensitive per profile only', () async {
    await mk('Cash');
    expect(mk('cASH'), throwsA(isA<DuplicateNameException>()));
    final other = await repo.create(
      profileId: p2,
      name: 'cash',
      type: 'cash',
      openingBalanceMinor: 0,
      openingDate: '2026-01-01',
    );
    expect(other.profileId, p2);
  });

  test('cross-profile access rejected', () async {
    final id = await mk('Cash');
    expect(await repo.getById(p2, id), isNull);
    expect(
      repo.update(
        profileId: p2,
        id: id,
        name: 'x',
        type: 'cash',
        openingBalanceMinor: 0,
        openingDate: '2026-01-01',
      ),
      throwsA(isA<NotFoundException>()),
    );
    expect(repo.setActive(p2, id, false), throwsA(isA<NotFoundException>()));
    expect(await repo.watchAll(p2).first, isEmpty);
  });

  test('FK: unknown profile rejected', () async {
    expect(
      repo.create(
        profileId: 9999,
        name: 'x',
        type: 'cash',
        openingBalanceMinor: 0,
        openingDate: '2026-01-01',
      ),
      throwsA(anything),
    );
  });

  test('edit updates fields and keeps own name', () async {
    final id = await mk('Cash');
    final u = await repo.update(
      profileId: p1,
      id: id,
      name: 'Cash',
      type: 'mobile',
      openingBalanceMinor: 500,
      openingDate: '2026-01-01',
    );
    expect(u.type, 'mobile');
    expect(u.openingBalanceMinor, 500);
    await mk('Bank');
    expect(
      repo.update(
        profileId: p1,
        id: id,
        name: 'bank',
        type: 'cash',
        openingBalanceMinor: 0,
        openingDate: '2026-01-01',
      ),
      throwsA(isA<DuplicateNameException>()),
    );
  });

  test('deactivate preserves record and transactions', () async {
    final id = await mk('Cash', opening: 1000);
    final cat = await _category(db, p1, 'Food');
    await _txn(
      db,
      profileId: p1,
      type: 'expense',
      accountId: id,
      amount: 100,
      date: '2026-02-01',
      categoryId: cat,
    );
    await repo.setActive(p1, id, false);
    expect((await repo.getById(p1, id))!.isActive, isFalse);
    expect(await repo.watchAll(p1).first, isEmpty);
    expect(await repo.watchAll(p1, includeInactive: true).first, hasLength(1));
    expect(await repo.balanceOf(p1, id), 900);
    await repo.setActive(p1, id, true);
    expect(await repo.watchAll(p1).first, hasLength(1));
  });

  test('search is case-insensitive and escapes wildcards', () async {
    await mk('Main Wallet');
    await mk('Savings');
    expect(
      (await repo.watchAll(p1, search: 'WALL').first).single.name,
      'Main Wallet',
    );
    expect(await repo.watchAll(p1, search: '%').first, isEmpty);
    expect(
      (await repo.watchBalances(p1, search: 'sav').first).single.account.name,
      'Savings',
    );
  });

  group('balances', () {
    test(
      'opening + income - expense +/- transfers, deleted excluded',
      () async {
        final a = await mk('A', opening: 100000);
        final b = await mk('B', opening: 5000);
        final cat = await _category(db, p1, 'Food');
        Future<void> t(
          String type,
          int acc,
          int amt, {
          int? to,
          bool del = false,
          String date = '2026-03-10',
        }) => _txn(
          db,
          profileId: p1,
          type: type,
          accountId: acc,
          amount: amt,
          date: date,
          toAccountId: to,
          deleted: del,
          categoryId: type == 'expense' ? cat : null,
        );
        await t('income', a, 20000);
        await t('expense', a, 3000);
        await t('transfer', a, 10000, to: b);
        await t('transfer', b, 2000, to: a);
        await t('expense', a, 99999, del: true);
        await t('income', a, 77777, del: true);
        await t('transfer', a, 5555, to: b, del: true);

        // a: 100000 + 20000 - 3000 - 10000 + 2000 = 109000
        // b: 5000 + 10000 - 2000 = 13000
        expect(await repo.balanceOf(p1, a), 109000);
        expect(await repo.balanceOf(p1, b), 13000);
        // transfers preserve the total
        final list = await repo.watchBalances(p1).first;
        expect(list.fold<int>(0, (s, e) => s + e.balanceMinor), 122000);
      },
    );

    test(
      'no transactions = opening balance; rows before opening date ignored',
      () async {
        final a = await mk('A', opening: 700, date: '2026-05-01');
        expect(await repo.balanceOf(p1, a), 700);
        await _txn(
          db,
          profileId: p1,
          type: 'income',
          accountId: a,
          amount: 50,
          date: '2026-04-30',
        );
        expect(await repo.balanceOf(p1, a), 700);
        await _txn(
          db,
          profileId: p1,
          type: 'income',
          accountId: a,
          amount: 50,
          date: '2026-05-01',
        );
        expect(await repo.balanceOf(p1, a), 750);
      },
    );

    test('balance stream reacts to new transactions', () async {
      final a = await mk('A', opening: 100);
      final stream = repo.watchBalances(p1);
      final expectation = expectLater(
        stream.map((l) => l.single.balanceMinor),
        emitsInOrder([100, 350]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _txn(
        db,
        profileId: p1,
        type: 'income',
        accountId: a,
        amount: 250,
        date: '2026-02-01',
      );
      await expectation;
    });

    test('balance is profile isolated', () async {
      final a = await mk('A', opening: 100);
      expect(await repo.watchBalances(p2).first, isEmpty);
      expect(repo.balanceOf(p2, a), throwsA(isA<NotFoundException>()));
    });
  });

  group('opening date edit', () {
    test(
      'refused after an existing transaction, allowed when earlier',
      () async {
        final a = await mk('A', date: '2026-01-01');
        await _txn(
          db,
          profileId: p1,
          type: 'income',
          accountId: a,
          amount: 10,
          date: '2026-03-15',
        );
        Future<String> upd(String d) => repo
            .update(
              profileId: p1,
              id: a,
              name: 'A',
              type: 'bank',
              openingBalanceMinor: 0,
              openingDate: d,
            )
            .then((x) => x.openingDate);
        expect(upd('2026-03-16'), throwsA(isA<ValidationException>()));
        expect((await upd('2026-03-15')), '2026-03-15');
        expect((await upd('2025-12-01')), '2025-12-01');
      },
    );

    test(
      'soft-deleted transactions do not block, transfers to account do',
      () async {
        final a = await mk('A', date: '2026-01-01');
        final b = await mk('B', date: '2026-01-01');
        await _txn(
          db,
          profileId: p1,
          type: 'income',
          accountId: a,
          amount: 10,
          date: '2026-03-15',
          deleted: true,
        );
        await repo.update(
          profileId: p1,
          id: a,
          name: 'A',
          type: 'bank',
          openingBalanceMinor: 0,
          openingDate: '2026-06-01',
        );
        await _txn(
          db,
          profileId: p1,
          type: 'transfer',
          accountId: a,
          toAccountId: b,
          amount: 10,
          date: '2026-07-01',
        );
        expect(
          repo.update(
            profileId: p1,
            id: b,
            name: 'B',
            type: 'bank',
            openingBalanceMinor: 0,
            openingDate: '2026-08-01',
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
