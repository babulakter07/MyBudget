import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/domain/transaction_models.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late int p1, p2;
  late int cash, bank, inactiveAcc, otherAcc, lateAcc;
  late int food, home, inactiveCat, otherCat;
  late int groceries, rent, inactiveSub;
  late int rice, flatRent, inactiveItem;
  final now = DateTime(2026, 1, 1);

  Future<int> profile(String n) => db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: n,
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> account(
    int p,
    String n, {
    bool active = true,
    String opening = '2026-01-01',
  }) => db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          profileId: p,
          name: n,
          openingDate: opening,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> category(int p, String n, {bool active = true}) => db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: p,
          name: n,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> sub(int p, int c, String n, {bool active = true}) => db
      .into(db.subCategories)
      .insert(
        SubCategoriesCompanion.insert(
          profileId: p,
          categoryId: c,
          name: n,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> item(int p, int s, String n, {bool active = true}) => db
      .into(db.costItems)
      .insert(
        CostItemsCompanion.insert(
          profileId: p,
          subCategoryId: s,
          name: n,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );

  setUp(() async {
    db = AppDatabase.memory();
    repo = TransactionRepository(db);
    p1 = await profile('One');
    p2 = await profile('Two');
    cash = await account(p1, 'Cash');
    bank = await account(p1, 'Bank');
    inactiveAcc = await account(p1, 'Old', active: false);
    lateAcc = await account(p1, 'Late', opening: '2026-03-01');
    otherAcc = await account(p2, 'Other cash');
    food = await category(p1, 'Food');
    home = await category(p1, 'Home');
    inactiveCat = await category(p1, 'Dead', active: false);
    otherCat = await category(p2, 'Foreign');
    groceries = await sub(p1, food, 'Groceries');
    rent = await sub(p1, home, 'Rent');
    inactiveSub = await sub(p1, food, 'OldSub', active: false);
    rice = await item(p1, groceries, 'Rice');
    flatRent = await item(p1, rent, 'Flat rent');
    inactiveItem = await item(p1, groceries, 'OldItem', active: false);
  });
  tearDown(() => db.close());

  Future<TransactionView> expense({
    int? account,
    int? cat,
    int? subId,
    int? itemId,
    int amount = 10000,
    String date = '2026-02-10',
    String? key,
    int? profile,
  }) => repo.createExpense(
    profileId: profile ?? p1,
    accountId: account ?? cash,
    categoryId: cat ?? food,
    subCategoryId: subId ?? groceries,
    costItemId: itemId ?? rice,
    amountMinor: amount,
    date: date,
    title: 'Shopping',
    idempotencyKey: key,
  );

  Future<List<TransactionView>> list([TransactionFilter? f]) =>
      repo.watchByFilter(p1, f ?? const TransactionFilter()).first;

  Future<int> count() async =>
      (await db.select(db.financialTransactions).get()).length;

  Future<List<AuditLogRow>> audits(int id) =>
      (db.select(db.transactionAuditLogs)
            ..where((a) => a.transactionId.equals(id))
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .get();

  /// Net effect of an account over non-deleted rows (reports are computed).
  Future<int> net(int accountId) async {
    final rows = await (db.select(
      db.financialTransactions,
    )..where((t) => t.isDeleted.equals(false))).get();
    var sum = 0;
    for (final r in rows) {
      if (r.type == 'income' && r.accountId == accountId) sum += r.amountMinor;
      if (r.type == 'expense' && r.accountId == accountId) {
        sum -= r.amountMinor;
      }
      if (r.type == 'transfer') {
        if (r.toAccountId == accountId) sum += r.amountMinor;
        if (r.accountId == accountId) sum -= r.amountMinor;
      }
    }
    return sum;
  }

  group('create', () {
    test('expense stores snapshots and an audit row', () async {
      final t = await expense();
      expect(t.isExpense, isTrue);
      expect(t.amountMinor, 10000);
      expect(t.accountName, 'Cash');
      expect(t.categoryName, 'Food');
      expect(t.subCategoryName, 'Groceries');
      expect(t.costItemName, 'Rice');
      final a = await audits(t.id);
      expect(a.single.action, 'create');
      expect(a.single.previousJson, isNull);
      expect(jsonDecode(a.single.newJson!)['amountMinor'], 10000);
    });

    test('expense with only a category is allowed', () async {
      final t = await repo.createExpense(
        profileId: p1,
        accountId: cash,
        categoryId: food,
        amountMinor: 500,
        date: '2026-02-10',
      );
      expect(t.subCategoryName, isNull);
      expect(t.description, 'Food');
    });

    test('income and transfer', () async {
      final i = await repo.createIncome(
        profileId: p1,
        accountId: bank,
        incomeSource: ' Salary ',
        amountMinor: 500000,
        date: '2026-02-01',
      );
      expect(i.isIncome, isTrue);
      expect(i.incomeSource, 'Salary');
      final tr = await repo.createTransfer(
        profileId: p1,
        fromAccountId: bank,
        toAccountId: cash,
        amountMinor: 20000,
        date: '2026-02-02',
      );
      expect(tr.isTransfer, isTrue);
      expect(tr.accountName, 'Bank');
      expect(tr.toAccountName, 'Cash');
      expect(await count(), 2);
    });

    test('income requires a source', () {
      expect(
        () => repo.createIncome(
          profileId: p1,
          accountId: cash,
          incomeSource: '  ',
          amountMinor: 1,
          date: '2026-02-01',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('snapshot survives a later rename', () async {
      final t = await expense();
      await (db.update(db.categories)..where((c) => c.id.equals(food))).write(
        const CategoriesCompanion(name: Value('Groceries & more')),
      );
      await (db.update(db.accounts)..where((c) => c.id.equals(cash))).write(
        const AccountsCompanion(name: Value('Wallet')),
      );
      final again = await repo.getById(p1, t.id);
      expect(again!.categoryName, 'Food');
      expect(again.accountName, 'Cash');
    });

    test('zero and negative amounts rejected', () async {
      for (final a in [0, -5]) {
        await expectLater(
          expense(amount: a),
          throwsA(isA<ValidationException>()),
        );
      }
      await expectLater(
        repo.createTransfer(
          profileId: p1,
          fromAccountId: cash,
          toAccountId: bank,
          amountMinor: 0,
          date: '2026-02-01',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(await count(), 0);
    });

    test('invalid dates rejected', () async {
      for (final d in ['2026-02-30', 'abc', '2026-2-3', '']) {
        await expectLater(
          expense(date: d),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('date before account opening date rejected', () async {
      await expectLater(
        expense(account: lateAcc, date: '2026-02-28'),
        throwsA(isA<ValidationException>()),
      );
      // On the opening date it is fine.
      await expense(account: lateAcc, date: '2026-03-01');
      // Transfer checks both accounts.
      await expectLater(
        repo.createTransfer(
          profileId: p1,
          fromAccountId: cash,
          toAccountId: lateAcc,
          amountMinor: 100,
          date: '2026-02-15',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cross-profile references rejected before writing', () async {
      await expectLater(
        expense(account: otherAcc),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.createExpense(
          profileId: p1,
          accountId: cash,
          categoryId: otherCat,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.createTransfer(
          profileId: p1,
          fromAccountId: cash,
          toAccountId: otherAcc,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        expense(account: 9999),
        throwsA(isA<NotFoundException>()),
      );
      expect(await count(), 0);
      expect(await db.select(db.transactionAuditLogs).get(), isEmpty);
    });

    test('hierarchy mismatch rejected', () async {
      // sub belongs to another category
      await expectLater(
        expense(cat: home, subId: groceries, itemId: rice),
        throwsA(isA<ValidationException>()),
      );
      // item belongs to another sub
      await expectLater(
        expense(cat: home, subId: rent, itemId: rice),
        throwsA(isA<ValidationException>()),
      );
      // item without sub
      await expectLater(
        repo.createExpense(
          profileId: p1,
          accountId: cash,
          categoryId: food,
          costItemId: rice,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(await count(), 0);
    });

    test('inactive account/category/sub/item rejected', () async {
      await expectLater(
        expense(account: inactiveAcc),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.createExpense(
          profileId: p1,
          accountId: cash,
          categoryId: inactiveCat,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.createExpense(
          profileId: p1,
          accountId: cash,
          categoryId: food,
          subCategoryId: inactiveSub,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        expense(itemId: inactiveItem),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.createTransfer(
          profileId: p1,
          fromAccountId: cash,
          toAccountId: inactiveAcc,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(await count(), 0);
    });

    test('idempotent retry returns the same row', () async {
      final a = await expense(key: 'k1');
      final b = await expense(key: 'k1');
      expect(b.id, a.id);
      expect(await count(), 1);
      expect((await audits(a.id)).length, 1);
      // Same key in another profile is independent.
      final c = await repo.createIncome(
        profileId: p2,
        accountId: otherAcc,
        incomeSource: 'Salary',
        amountMinor: 100,
        date: '2026-02-10',
        idempotencyKey: 'k1',
      );
      expect(c.id, isNot(a.id));
      expect(await count(), 2);
    });

    test('transfer to same account rejected', () async {
      await expectLater(
        repo.createTransfer(
          profileId: p1,
          fromAccountId: cash,
          toAccountId: cash,
          amountMinor: 100,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(await count(), 0);
    });

    test('transfer preserves total and is not income/expense', () async {
      await repo.createIncome(
        profileId: p1,
        accountId: cash,
        incomeSource: 'Salary',
        amountMinor: 100000,
        date: '2026-02-01',
      );
      await repo.createTransfer(
        profileId: p1,
        fromAccountId: cash,
        toAccountId: bank,
        amountMinor: 30000,
        date: '2026-02-02',
      );
      expect(await net(cash), 70000);
      expect(await net(bank), 30000);
      expect(await net(cash) + await net(bank), 100000);
      final rows = await db.select(db.financialTransactions).get();
      expect(rows.where((r) => r.type == 'income').length, 1);
      expect(rows.where((r) => r.type == 'expense'), isEmpty);
      expect(rows.where((r) => r.type == 'transfer').length, 1);
    });
  });

  group('update', () {
    test('edit expense incl. month change writes audit', () async {
      final t = await expense(amount: 10000, date: '2026-02-10');
      final u = await repo.updateExpense(
        profileId: p1,
        id: t.id,
        accountId: bank,
        categoryId: home,
        subCategoryId: rent,
        costItemId: flatRent,
        amountMinor: 250050,
        date: '2026-03-05',
        title: 'Rent',
      );
      expect(u.date, '2026-03-05');
      expect(u.amountMinor, 250050);
      expect(u.accountName, 'Bank');
      expect(u.categoryName, 'Home');
      expect(u.costItemName, 'Flat rent');
      final a = await audits(t.id);
      expect(a.map((e) => e.action), ['create', 'update']);
      expect(jsonDecode(a[1].previousJson!)['txnDate'], '2026-02-10');
      expect(jsonDecode(a[1].newJson!)['txnDate'], '2026-03-05');
      // Month filters follow the edit.
      expect(
        await list(
          const TransactionFilter(fromDate: '2026-02-01', toDate: '2026-02-28'),
        ),
        isEmpty,
      );
      expect(
        (await list(
          const TransactionFilter(fromDate: '2026-03-01', toDate: '2026-03-31'),
        )).length,
        1,
      );
    });

    test(
      'unchanged references keep snapshots after rename/deactivate',
      () async {
        final t = await expense();
        await (db.update(db.categories)..where((c) => c.id.equals(food))).write(
          const CategoriesCompanion(
            name: Value('Renamed'),
            isActive: Value(false),
          ),
        );
        final u = await repo.updateExpense(
          profileId: p1,
          id: t.id,
          accountId: cash,
          categoryId: food,
          subCategoryId: groceries,
          costItemId: rice,
          amountMinor: 20000,
          date: '2026-02-10',
        );
        expect(u.categoryName, 'Food');
        expect(u.amountMinor, 20000);
      },
    );

    test('edit validates and does not change type', () async {
      final t = await expense();
      await expectLater(
        repo.updateExpense(
          profileId: p1,
          id: t.id,
          accountId: cash,
          categoryId: food,
          amountMinor: 0,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.updateIncome(
          profileId: p1,
          id: t.id,
          accountId: cash,
          incomeSource: 'x',
          amountMinor: 5,
          date: '2026-02-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.updateExpense(
          profileId: p2,
          id: t.id,
          accountId: otherAcc,
          categoryId: otherCat,
          amountMinor: 5,
          date: '2026-02-10',
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect((await audits(t.id)).length, 1);
      expect((await repo.getById(p1, t.id))!.amountMinor, 10000);
    });

    test('edit income and transfer', () async {
      final i = await repo.createIncome(
        profileId: p1,
        accountId: cash,
        incomeSource: 'Salary',
        amountMinor: 1000,
        date: '2026-02-01',
      );
      final ui = await repo.updateIncome(
        profileId: p1,
        id: i.id,
        accountId: bank,
        incomeSource: 'Freelance',
        amountMinor: 2000,
        date: '2026-02-02',
      );
      expect(ui.incomeSource, 'Freelance');
      expect(ui.accountName, 'Bank');
      final t = await repo.createTransfer(
        profileId: p1,
        fromAccountId: cash,
        toAccountId: bank,
        amountMinor: 100,
        date: '2026-02-03',
      );
      await expectLater(
        repo.updateTransfer(
          profileId: p1,
          id: t.id,
          fromAccountId: bank,
          toAccountId: bank,
          amountMinor: 100,
          date: '2026-02-03',
        ),
        throwsA(isA<ValidationException>()),
      );
      final ut = await repo.updateTransfer(
        profileId: p1,
        id: t.id,
        fromAccountId: bank,
        toAccountId: cash,
        amountMinor: 300,
        date: '2026-02-03',
      );
      expect(ut.accountName, 'Bank');
      expect(ut.toAccountName, 'Cash');
    });
  });

  group('delete / restore', () {
    test('soft delete excludes from default queries and audits', () async {
      final t = await expense();
      await repo.softDelete(p1, t.id);
      expect(await list(), isEmpty);
      expect(
        (await list(const TransactionFilter(includeDeleted: true))).length,
        1,
      );
      final got = await repo.getById(p1, t.id);
      expect(got!.isDeleted, isTrue);
      expect(got.deletedAt, isNotNull);
      expect((await audits(t.id)).map((a) => a.action), ['create', 'delete']);
      expect(await count(), 1); // never hard deleted
    });

    test('deleting a transfer reverses both sides atomically', () async {
      await repo.createIncome(
        profileId: p1,
        accountId: cash,
        incomeSource: 'Salary',
        amountMinor: 100000,
        date: '2026-02-01',
      );
      final t = await repo.createTransfer(
        profileId: p1,
        fromAccountId: cash,
        toAccountId: bank,
        amountMinor: 40000,
        date: '2026-02-02',
      );
      expect(await net(bank), 40000);
      await repo.softDelete(p1, t.id);
      expect(await net(bank), 0);
      expect(await net(cash), 100000);
      await repo.restore(p1, t.id);
      expect(await net(bank), 40000);
      expect(await net(cash), 60000);
    });

    test('restore audits and brings the row back', () async {
      final t = await expense();
      await repo.softDelete(p1, t.id);
      await repo.restore(p1, t.id);
      expect((await list()).length, 1);
      expect((await audits(t.id)).map((a) => a.action), [
        'create',
        'delete',
        'restore',
      ]);
      // Idempotent no-ops write no extra audit rows.
      await repo.restore(p1, t.id);
      expect((await audits(t.id)).length, 3);
    });

    test(
      'deleted rows cannot be edited; cross-profile delete rejected',
      () async {
        final t = await expense();
        await repo.softDelete(p1, t.id);
        await expectLater(
          repo.updateExpense(
            profileId: p1,
            id: t.id,
            accountId: cash,
            categoryId: food,
            amountMinor: 5,
            date: '2026-02-10',
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          repo.softDelete(p2, t.id),
          throwsA(isA<NotFoundException>()),
        );
        expect(await repo.getById(p2, t.id), isNull);
      },
    );
  });

  group('queries', () {
    test('filters by type, date range and search; recent limit', () async {
      await expense(date: '2026-02-10');
      await repo.createIncome(
        profileId: p1,
        accountId: cash,
        incomeSource: 'Salary',
        amountMinor: 1000,
        date: '2026-02-20',
        remarks: 'Feb pay',
      );
      await repo.createTransfer(
        profileId: p1,
        fromAccountId: cash,
        toAccountId: bank,
        amountMinor: 10,
        date: '2026-03-01',
      );
      expect((await list()).map((t) => t.type), [
        'transfer',
        'income',
        'expense',
      ]);
      expect((await list(const TransactionFilter(type: 'income'))).length, 1);
      expect(
        (await list(const TransactionFilter(search: 'rice'))).single.isExpense,
        isTrue,
      );
      expect(
        (await list(const TransactionFilter(search: 'feb pay')))
            .single
            .isIncome,
        isTrue,
      );
      expect((await list(const TransactionFilter(search: '100%'))), isEmpty);
      expect((await repo.watchRecent(p1, limit: 2).first).length, 2);
      // Another profile sees nothing.
      expect(
        await repo.watchByFilter(p2, const TransactionFilter()).first,
        isEmpty,
      );
    });
  });

  group('member tags (paid by / for whom)', () {
    test(
      'stored on create, trimmed, editable, searchable, clearable',
      () async {
        final e = await repo.createExpense(
          profileId: p1,
          accountId: cash,
          categoryId: food,
          amountMinor: 600,
          date: '2026-02-10',
          paidBy: '  Father ',
          forWhom: 'Mother',
        );
        expect(e.paidBy, 'Father');
        expect(e.forWhom, 'Mother');

        final i = await repo.createIncome(
          profileId: p1,
          accountId: cash,
          incomeSource: 'Salary',
          amountMinor: 1000,
          date: '2026-02-11',
          paidBy: 'Self',
        );
        expect(i.paidBy, 'Self');
        expect(i.forWhom, isNull);

        // Search matches the tags.
        expect(
          (await list(const TransactionFilter(search: 'mother'))).single.id,
          e.id,
        );

        // Edit changes a tag; blank clears it.
        final u = await repo.updateExpense(
          profileId: p1,
          id: e.id,
          accountId: cash,
          categoryId: food,
          amountMinor: 600,
          date: '2026-02-10',
          paidBy: 'Brother',
          forWhom: '   ',
        );
        expect(u.paidBy, 'Brother');
        expect(u.forWhom, isNull);
        final a = await audits(e.id);
        final upd = a.singleWhere((x) => x.action == 'update');
        expect(jsonDecode(upd.newJson!)['paidBy'], 'Brother');
      },
    );

    test('name suggestions: distinct, case-insensitive, profile-scoped, '
        'skip deleted', () async {
      await repo.createExpense(
        profileId: p1,
        accountId: cash,
        categoryId: food,
        amountMinor: 100,
        date: '2026-02-10',
        paidBy: 'father',
        forWhom: 'Mother',
      );
      await repo.createExpense(
        profileId: p1,
        accountId: cash,
        categoryId: food,
        amountMinor: 100,
        date: '2026-02-10',
        paidBy: 'Father',
      );
      final gone = await repo.createExpense(
        profileId: p1,
        accountId: cash,
        categoryId: food,
        amountMinor: 100,
        date: '2026-02-10',
        paidBy: 'Ghost',
      );
      await repo.softDelete(p1, gone.id);

      final names = await repo.watchMemberNames(p1).first;
      expect(names.length, 2);
      expect(names.map((n) => n.toLowerCase()), ['father', 'mother']);
      expect(await repo.watchMemberNames(p2).first, isEmpty);
    });
  });

  test('sequential writes keep sums right', () async {
    for (var i = 0; i < 20; i++) {
      await expense(amount: 150, key: 'k$i');
      await expense(amount: 150, key: 'k$i'); // retry
    }
    final deleted = await expense(amount: 999999, key: 'big');
    await repo.softDelete(p1, deleted.id);
    expect(await count(), 21);
    expect(await net(cash), -3000);
    final futures = [
      for (var i = 0; i < 10; i++) expense(amount: 100, key: 'p$i'),
    ];
    await Future.wait(futures);
    expect(await net(cash), -4000);
  });
}
