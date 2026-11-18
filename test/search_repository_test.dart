import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/search/data/search_repository.dart';
import 'package:my_budget/features/search/domain/search_models.dart';

import 'ledger_test_helpers.dart';

void main() {
  late AppDatabase db;
  late SearchRepository repo;
  late int p1, p2, cash, bank, food, rent, food2;

  Future<int> tag(int profile, String name) => db
      .into(db.tags)
      .insert(
        TagsCompanion.insert(
          profileId: profile,
          name: name,
          createdAt: DateTime(2026),
        ),
      );
  Future<void> tagTxn(int profile, int txn, int tagId) => db
      .into(db.transactionTags)
      .insert(
        TransactionTagsCompanion.insert(
          profileId: profile,
          transactionId: txn,
          tagId: tagId,
        ),
      );
  Future<List<int>> ids(SearchFilter f, {int? profile}) async =>
      (await repo.search(profile ?? p1, f)).rows.map((r) => r.id).toList();

  Future<int> exp(
    String date, {
    int amount = 100,
    String? title,
    String? remarks,
    int? account,
    int? categoryId,
    String? category,
    String? costItem,
    String? subCategory,
    bool deleted = false,
    int? profile,
  }) => addTxn(
    db,
    profileId: profile ?? p1,
    type: 'expense',
    accountId: account ?? cash,
    amount: amount,
    date: date,
    title: title,
    remarks: remarks,
    categoryId: categoryId ?? ((profile ?? p1) == p1 ? food : food2),
    category: category,
    costItem: costItem,
    subCategory: subCategory,
    deleted: deleted,
  );

  setUp(() async {
    db = AppDatabase.memory();
    repo = SearchRepository(db);
    p1 = await addProfile(db, 'A');
    p2 = await addProfile(db, 'B');
    cash = await addAccount(db, p1, 'Cash');
    bank = await addAccount(db, p1, 'Bank');
    food = await addCategory(db, p1, 'Food');
    rent = await addCategory(db, p1, 'Rent');
    food2 = await addCategory(db, p2, 'Food');
  });
  tearDown(() => db.close());

  test('free text matches title, remarks, snapshots, income source', () async {
    final a = await exp(
      '2026-01-01',
      title: 'Lunch',
      category: 'Food',
      categoryId: food,
    );
    final b = await exp('2026-01-02', remarks: 'for the PARTY');
    final c = await addTxn(
      db,
      profileId: p1,
      type: 'income',
      accountId: bank,
      amount: 100,
      date: '2026-01-03',
      incomeSource: 'Salary',
      accountName: 'Bank',
    );
    final d = await exp('2026-01-04', costItem: 'Rice', subCategory: 'Grain');
    expect(await ids(const SearchFilter(query: 'lunch')), [a]);
    expect(await ids(const SearchFilter(query: 'party')), [b]);
    expect(await ids(const SearchFilter(query: 'SALARY')), [c]);
    expect(await ids(const SearchFilter(query: 'rice')), [d]);
    expect(await ids(const SearchFilter(query: 'grain')), [d]);
    expect(await ids(const SearchFilter(query: 'food')), [a]);
    expect(await ids(const SearchFilter(query: 'bank')), [c]);
  });

  test('paid_by / for_whom and tag names are searchable', () async {
    final a = await exp('2026-01-01');
    await (db.update(
      db.financialTransactions,
    )..where((t) => t.id.equals(a))).write(
      const FinancialTransactionsCompanion(
        paidBy: Value('Rahim'),
        forWhom: Value('Karim'),
      ),
    );
    final b = await exp('2026-01-02');
    await tagTxn(p1, b, await tag(p1, 'Vacation'));
    expect(await ids(const SearchFilter(query: 'rahim')), [a]);
    expect(await ids(const SearchFilter(query: 'karim')), [a]);
    expect(await ids(const SearchFilter(query: 'vacat')), [b]);
  });

  test('multiple terms are ANDed', () async {
    final a = await exp('2026-01-01', title: 'Big lunch', remarks: 'team');
    await exp('2026-01-02', title: 'lunch');
    expect(await ids(const SearchFilter(query: 'lunch team')), [a]);
  });

  test('LIKE wildcards are escaped', () async {
    final pct = await exp('2026-01-01', title: '50% off');
    final us = await exp('2026-01-02', title: 'a_b');
    await exp('2026-01-03', title: 'axb');
    await exp('2026-01-04', title: r'back\slash');
    expect(await ids(const SearchFilter(query: '%')), [pct]);
    expect(await ids(const SearchFilter(query: '_')), [us]);
    expect(await ids(const SearchFilter(query: 'a_b')), [us]);
    expect((await ids(const SearchFilter(query: r'\'))).length, 1);
  });

  test('type, amount, date filters', () async {
    final e = await exp('2026-01-10', amount: 500);
    final i = await addTxn(
      db,
      profileId: p1,
      type: 'income',
      accountId: cash,
      amount: 1500,
      date: '2026-02-10',
    );
    final t = await addTxn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: cash,
      toAccountId: bank,
      amount: 1000,
      date: '2026-03-10',
    );
    expect(await ids(const SearchFilter(types: {'income', 'transfer'})), [
      t,
      i,
    ]);
    expect(await ids(const SearchFilter(minAmountMinor: 1000)), [t, i]);
    expect(await ids(const SearchFilter(maxAmountMinor: 1000)), [t, e]);
    expect(
      await ids(const SearchFilter(minAmountMinor: 1000, maxAmountMinor: 1000)),
      [t],
    );
    expect(await ids(const SearchFilter(fromDate: '2026-02-10')), [t, i]);
    expect(await ids(const SearchFilter(toDate: '2026-02-10')), [i, e]);
    expect(
      await ids(
        const SearchFilter(fromDate: '2026-02-01', toDate: '2026-02-28'),
      ),
      [i],
    );
  });

  test('account (source or destination), category and tag filters', () async {
    final a = await exp('2026-01-01', categoryId: food, category: 'Food');
    final b = await exp(
      '2026-01-02',
      account: bank,
      categoryId: rent,
      category: 'Rent',
    );
    final t = await addTxn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: cash,
      toAccountId: bank,
      amount: 100,
      date: '2026-01-03',
    );
    expect(await ids(SearchFilter(accountIds: {bank})), [t, b]);
    expect(await ids(SearchFilter(accountIds: {cash})), [t, a]);
    expect(await ids(SearchFilter(categoryIds: {food})), [a]);
    expect(await ids(SearchFilter(categoryIds: {food, rent})), [b, a]);
    final g1 = await tag(p1, 'x');
    final g2 = await tag(p1, 'y');
    await tagTxn(p1, a, g1);
    await tagTxn(p1, a, g2);
    await tagTxn(p1, b, g2);
    expect(await ids(SearchFilter(tagIds: {g1})), [a]);
    expect(await ids(SearchFilter(tagIds: {g2})), [b, a]); // no duplicates
    expect((await repo.totals(p1, SearchFilter(tagIds: {g2}))).count, 2);
  });

  test('combination of filters', () async {
    await exp('2026-01-01', title: 'Lunch');
    final hit = await exp('2026-01-05', title: 'Lunch', amount: 900);
    await addTxn(
      db,
      profileId: p1,
      type: 'income',
      accountId: cash,
      amount: 900,
      date: '2026-01-05',
      title: 'Lunch refund',
    );
    expect(
      await ids(
        const SearchFilter(
          query: 'lunch',
          types: {'expense'},
          minAmountMinor: 500,
          fromDate: '2026-01-02',
        ),
      ),
      [hit],
    );
  });

  test('deleted rows are excluded from rows and totals', () async {
    await exp('2026-01-01', title: 'gone', deleted: true);
    final keep = await exp('2026-01-02', title: 'kept', amount: 200);
    expect(await ids(const SearchFilter()), [keep]);
    expect(await ids(const SearchFilter(query: 'gone')), isEmpty);
    final t = await repo.totals(p1, const SearchFilter());
    expect((t.count, t.expenseMinor), (1, 200));
  });

  test('cross-profile isolation', () async {
    final acc2 = await addAccount(db, p2, 'Cash');
    final mine = await exp('2026-01-01', title: 'shared');
    final theirs = await exp(
      '2026-01-01',
      title: 'shared',
      amount: 700,
      account: acc2,
      profile: p2,
    );
    final t2 = await tag(p2, 'shared');
    await tagTxn(p2, theirs, t2);
    expect(await ids(const SearchFilter(query: 'shared')), [mine]);
    expect(await ids(const SearchFilter(query: 'shared'), profile: p2), [
      theirs,
    ]);
    expect(await ids(SearchFilter(tagIds: {t2})), isEmpty);
    expect(await ids(SearchFilter(accountIds: {acc2})), isEmpty);
    expect((await repo.totals(p1, const SearchFilter())).expenseMinor, 100);
    expect((await repo.totals(p2, const SearchFilter())).expenseMinor, 700);
    expect((await repo.accounts(p2)).map((o) => o.id), [acc2]);
    expect(await repo.tags(p1), isEmpty);
  });

  test('totals cover the whole filtered set, not the page', () async {
    for (var i = 0; i < 12; i++) {
      final d = '2026-01-${(i + 1).toString().padLeft(2, '0')}';
      if (i.isEven) {
        await exp(d);
      } else {
        await addTxn(
          db,
          profileId: p1,
          type: 'income',
          accountId: cash,
          amount: 100,
          date: d,
        );
      }
    }
    await addTxn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: cash,
      toAccountId: bank,
      amount: 5000,
      date: '2026-02-01',
    );
    final page = await repo.search(p1, const SearchFilter(), limit: 5);
    expect(page.rows.length, 5);
    final t = await repo.totals(p1, const SearchFilter());
    expect((t.count, t.expenseMinor, t.incomeMinor), (13, 600, 600));
    final only = await repo.totals(p1, const SearchFilter(types: {'income'}));
    expect((only.count, only.expenseMinor, only.incomeMinor), (6, 0, 600));
    final none = await repo.totals(p1, const SearchFilter(query: 'zzz'));
    expect((none.count, none.expenseMinor, none.incomeMinor), (0, 0, 0));
  });

  test('sorting and paging', () async {
    final amounts = [300, 100, 500, 200, 400];
    final all = <int>[];
    for (var i = 0; i < 5; i++) {
      all.add(await exp('2026-01-0${i + 1}', amount: amounts[i]));
    }
    expect(await ids(const SearchFilter()), all.reversed.toList());
    expect(await ids(const SearchFilter(sort: SearchSort.dateAsc)), all);
    final byAmt = await repo.search(
      p1,
      const SearchFilter(sort: SearchSort.amountDesc),
    );
    expect(byAmt.rows.map((r) => r.amountMinor), [500, 400, 300, 200, 100]);
    final asc = await repo.search(
      p1,
      const SearchFilter(sort: SearchSort.amountAsc),
    );
    expect(asc.rows.map((r) => r.amountMinor), [100, 200, 300, 400, 500]);

    final a = await repo.search(p1, const SearchFilter(), limit: 2);
    final b = await repo.search(p1, const SearchFilter(), limit: 2, offset: 2);
    final c = await repo.search(p1, const SearchFilter(), limit: 2, offset: 4);
    expect([a.hasMore, b.hasMore, c.hasMore], [true, true, false]);
    expect(
      [...a.rows, ...b.rows, ...c.rows].map((r) => r.id),
      all.reversed.toList(),
    );
  });

  test('exact-multiple page does not report more', () async {
    for (var i = 0; i < 4; i++) {
      await exp('2026-01-01');
    }
    expect(
      (await repo.search(p1, const SearchFilter(), limit: 4)).hasMore,
      isFalse,
    );
  });

  test('display title and subtitle', () async {
    await addTxn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: cash,
      toAccountId: bank,
      amount: 1,
      date: '2026-01-01',
      accountName: 'Cash',
      toAccountName: 'Bank',
    );
    final r = (await repo.search(p1, const SearchFilter())).rows.single;
    expect(r.displayTitle, 'Transfer');
    expect(r.subtitle, 'Cash → Bank');
  });
}
