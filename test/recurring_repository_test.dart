import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/recurring/data/recurring_repository.dart';
import 'package:my_budget/features/recurring/data/recurring_service.dart';
import 'package:my_budget/features/recurring/domain/recurring_models.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository repo;
  late RecurringService svc;
  late int p1, p2, cash, bank, oldAcc, otherAcc, lateAcc, food, otherCat;
  late int groceries, rice;
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

  setUp(() async {
    db = AppDatabase.memory();
    repo = RecurringRepository(db);
    svc = RecurringService(db, TransactionRepository(db));
    p1 = await profile('One');
    p2 = await profile('Two');
    cash = await account(p1, 'Cash');
    bank = await account(p1, 'Bank');
    oldAcc = await account(p1, 'Old', active: false);
    lateAcc = await account(p1, 'Late', opening: '2026-06-01');
    otherAcc = await account(p2, 'Other');
    food = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            profileId: p1,
            name: 'Food',
            createdAt: now,
            updatedAt: now,
          ),
        );
    otherCat = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            profileId: p2,
            name: 'Foreign',
            createdAt: now,
            updatedAt: now,
          ),
        );
    groceries = await db
        .into(db.subCategories)
        .insert(
          SubCategoriesCompanion.insert(
            profileId: p1,
            categoryId: food,
            name: 'Groceries',
            createdAt: now,
            updatedAt: now,
          ),
        );
    rice = await db
        .into(db.costItems)
        .insert(
          CostItemsCompanion.insert(
            profileId: p1,
            subCategoryId: groceries,
            name: 'Rice',
            createdAt: now,
            updatedAt: now,
          ),
        );
  });
  tearDown(() => db.close());

  RecurringInput expense({
    int? account,
    int? cat,
    String start = '2026-01-31',
    String? end,
    String freq = 'monthly',
    int interval = 1,
    int amount = 5000,
    String title = 'Rent',
    int? sub,
    int? item,
  }) => RecurringInput(
    type: 'expense',
    accountId: account ?? cash,
    categoryId: cat ?? food,
    subCategoryId: sub,
    costItemId: item,
    amountMinor: amount,
    title: title,
    frequency: freq,
    intervalCount: interval,
    startDate: start,
    endDate: end,
  );

  Future<List<TransactionRow>> txns() => (db.select(
    db.financialTransactions,
  )..orderBy([(t) => OrderingTerm.asc(t.txnDate)])).get();

  group('validation', () {
    test('creates a rule with next due = start', () async {
      final r = await repo.create(
        p1,
        expense(sub: groceries, item: rice, end: '2026-12-31'),
      );
      expect(r.nextDueDate, '2026-01-31');
      expect(r.isActive, true);
      expect(r.nextDue, '2026-01-31');
      expect(r.subCategoryId, groceries);
    });

    test('rejects bad values', () async {
      expect(
        () => repo.create(p1, expense(amount: 0)),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, expense(interval: 0)),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, expense(freq: 'hourly')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, expense(title: '  ')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, expense(start: '2026-05-01', end: '2026-04-01')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, expense(start: '2026-13-01')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(
          p1,
          const RecurringInput(
            type: 'expense',
            accountId: 1,
            amountMinor: 1,
            title: 't',
            frequency: 'daily',
            startDate: '2026-01-01',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(
          p1,
          const RecurringInput(
            type: 'income',
            accountId: 1,
            amountMinor: 1,
            title: 't',
            frequency: 'daily',
            startDate: '2026-01-01',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer needs distinct accounts', () async {
      RecurringInput t(int? to) => RecurringInput(
        type: 'transfer',
        accountId: cash,
        toAccountId: to,
        amountMinor: 100,
        title: 'Save',
        frequency: 'weekly',
        startDate: '2026-01-01',
      );
      expect(
        () => repo.create(p1, t(null)),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(p1, t(cash)),
        throwsA(isA<ValidationException>()),
      );
      final r = await repo.create(p1, t(bank));
      expect(r.toAccountId, bank);
    });

    test('inactive parents rejected', () async {
      expect(
        () => repo.create(p1, expense(account: oldAcc)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cross-profile parents rejected', () async {
      expect(
        () => repo.create(p1, expense(account: otherAcc)),
        throwsA(isA<ProfileMismatchException>()),
      );
      expect(
        () => repo.create(p1, expense(cat: otherCat)),
        throwsA(isA<ProfileMismatchException>()),
      );
      expect(
        () => repo.create(p2, expense()),
        throwsA(isA<ProfileMismatchException>()),
      );
    });

    test('cross-profile rule access rejected', () async {
      final r = await repo.create(p1, expense());
      expect(await repo.getById(p2, r.id), isNull);
      expect(
        () => repo.setActive(p2, r.id, false),
        throwsA(isA<ProfileMismatchException>()),
      );
      expect(
        () => repo.update(p2, r.id, expense()),
        throwsA(isA<ProfileMismatchException>()),
      );
      expect(await repo.list(p2), isEmpty);
    });

    test('sub-category must belong to the category', () async {
      final other = await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              profileId: p1,
              name: 'Home',
              createdAt: now,
              updatedAt: now,
            ),
          );
      expect(
        () => repo.create(p1, expense(cat: other, sub: groceries)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('edit / pause / list', () {
    test('edit changes fields; schedule change re-anchors next due', () async {
      final r = await repo.create(p1, expense(start: '2026-01-10'));
      final e = await repo.update(
        p1,
        r.id,
        expense(start: '2026-01-10', title: 'New', amount: 900),
      );
      expect(e.title, 'New');
      expect(e.amountMinor, 900);
      expect(e.nextDueDate, '2026-01-10');
      await db.customStatement(
        "UPDATE recurring_rules SET next_due_date='2026-03-10' WHERE id=${r.id}",
      );
      final s = await repo.update(
        p1,
        r.id,
        expense(start: '2026-01-10', freq: 'weekly'),
      );
      expect(
        s.nextDueDate,
        '2026-03-14',
      ); // weekly from Jan 10, first >= Mar 10
    });

    test('pause/resume; resume skips missed occurrences', () async {
      final r = await repo.create(p1, expense(start: '2026-01-01'));
      final p = await repo.setActive(p1, r.id, false);
      expect(p.isActive, false);
      expect(p.nextDue, isNull);
      final back = await repo.setActive(
        p1,
        r.id,
        true,
        today: DateTime(2026, 3, 15),
      );
      expect(back.isActive, true);
      expect(back.nextDueDate, '2026-04-01');
    });

    test('list: active first; rows never hard-deleted', () async {
      final a = await repo.create(p1, expense(start: '2026-05-01', title: 'A'));
      final b = await repo.create(p1, expense(start: '2026-02-01', title: 'B'));
      await repo.setActive(p1, b.id, false);
      final l = await repo.list(p1);
      expect(l.map((e) => e.id), [a.id, b.id]);
    });

    test('upcoming(days) includes overdue, excludes paused/far', () async {
      final soon = await repo.create(
        p1,
        expense(start: '2026-03-05', title: 'soon'),
      );
      await repo.create(p1, expense(start: '2026-04-30', title: 'far'));
      final overdue = await repo.create(
        p1,
        expense(start: '2026-02-20', title: 'od'),
      );
      final paused = await repo.create(
        p1,
        expense(start: '2026-03-02', title: 'p'),
      );
      await repo.setActive(p1, paused.id, false);
      final u = await repo.upcoming(p1, 7, today: DateTime(2026, 3, 1));
      expect(u.map((e) => e.id), [overdue.id, soon.id]);
      expect(await repo.upcoming(p2, 7, today: DateTime(2026, 3, 1)), isEmpty);
    });
  });

  group('generation', () {
    test('catch-up posts every missed occurrence with clamping', () async {
      final r = await repo.create(p1, expense(start: '2026-01-31'));
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 4, 5),
      );
      expect(res.posted.map((p) => p.date), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
      ]);
      expect(res.skipped, isEmpty);
      final rows = await txns();
      expect(rows.length, 3);
      expect(rows.first.idempotencyKey, 'rec:${r.id}:2026-01-31');
      expect(rows.first.accountNameSnapshot, 'Cash');
      expect(rows.first.categoryNameSnapshot, 'Food');
      expect(rows.first.title, 'Rent');
      final after = (await repo.getById(p1, r.id))!;
      expect(after.nextDueDate, '2026-04-30');
      final audits = await db.select(db.transactionAuditLogs).get();
      expect(audits.length, 3);
    });

    test('running twice does not duplicate', () async {
      await repo.create(p1, expense(start: '2026-01-01', freq: 'weekly'));
      final a = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 2, 1),
      );
      final b = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 2, 1),
      );
      expect(a.posted.length, 5);
      expect(b.posted, isEmpty);
      expect((await txns()).length, 5);
    });

    test('concurrent runs do not duplicate', () async {
      await repo.create(p1, expense(start: '2026-01-01', freq: 'weekly'));
      final fs = await Future.wait([
        svc.generateDue(profileId: p1, today: DateTime(2026, 2, 1)),
        svc.generateDue(profileId: p1, today: DateTime(2026, 2, 1)),
        RecurringService(
          db,
          TransactionRepository(db),
        ).generateDue(profileId: p1, today: DateTime(2026, 2, 1)),
      ]);
      expect(fs.toSet().fold<int>(0, (s, r) => s + r.posted.length), 5);
      expect(identical(fs[0], fs[1]), true); // same-instance calls share a run
      expect((await txns()).length, 5);
    });

    test('existing key (e.g. stale next_due) is not double-posted', () async {
      final r = await repo.create(p1, expense(start: '2026-01-01'));
      await svc.generateDue(profileId: p1, today: DateTime(2026, 1, 1));
      await db.customStatement(
        "UPDATE recurring_rules SET next_due_date='2026-01-01' WHERE id=${r.id}",
      );
      await svc.generateDue(profileId: p1, today: DateTime(2026, 1, 1));
      expect((await txns()).length, 1);
    });

    test('end date: stops after final occurrence and deactivates', () async {
      final r = await repo.create(
        p1,
        expense(start: '2026-01-01', end: '2026-01-20', freq: 'weekly'),
      );
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 6, 1),
      );
      expect(res.posted.map((p) => p.date), [
        '2026-01-01',
        '2026-01-08',
        '2026-01-15',
      ]);
      expect(res.completedRuleIds, [r.id]);
      final after = (await repo.getById(p1, r.id))!;
      expect(after.isActive, false);
      expect(after.isCompleted, true);
      expect(after.nextDue, isNull);
      expect(
        () => repo.setActive(p1, r.id, true, today: DateTime(2026, 6, 1)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('paused and future rules are skipped', () async {
      final r = await repo.create(p1, expense(start: '2026-01-01'));
      await repo.create(p1, expense(start: '2026-09-01', title: 'future'));
      await repo.setActive(p1, r.id, false);
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 3, 1),
      );
      expect(res.isEmpty, true);
      expect(await txns(), isEmpty);
    });

    test('income and transfer rules post', () async {
      await repo.create(
        p1,
        const RecurringInput(
          type: 'income',
          accountId: 1,
          incomeSource: 'Salary',
          amountMinor: 100000,
          title: 'Pay',
          frequency: 'monthly',
          startDate: '2026-01-05',
        ).copyWithAccount(cash),
      );
      await repo.create(
        p1,
        RecurringInput(
          type: 'transfer',
          accountId: cash,
          toAccountId: bank,
          amountMinor: 2000,
          title: 'Save',
          frequency: 'monthly',
          startDate: '2026-01-06',
        ),
      );
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 1, 31),
      );
      expect(res.posted.length, 2);
      final rows = await txns();
      expect(rows.map((r) => r.type).toSet(), {'income', 'transfer'});
      expect(
        rows.firstWhere((r) => r.type == 'transfer').toAccountNameSnapshot,
        'Bank',
      );
    });

    test(
      'failure isolation: failing rule is skipped whole, others continue',
      () async {
        final bad = await repo.create(
          p1,
          expense(start: '2026-01-10', title: 'bad'),
        );
        final good = await repo.create(
          p1,
          expense(start: '2026-01-10', title: 'good'),
        );
        // Archive the account used by the bad rule after creation.
        final arch = await account(p1, 'Archived');
        await db.customStatement(
          'UPDATE recurring_rules SET account_id=$arch WHERE id=${bad.id}',
        );
        await db.customStatement(
          'UPDATE accounts SET is_active=0 WHERE id=$arch',
        );
        final res = await svc.generateDue(
          profileId: p1,
          today: DateTime(2026, 2, 15),
        );
        expect(res.skipped.length, 1);
        expect(res.skipped.single.ruleId, bad.id);
        expect(res.skipped.single.date, '2026-01-10');
        expect(res.skipped.single.reason, contains('inactive'));
        expect(res.posted.every((p) => p.ruleId == good.id), true);
        expect(res.posted.length, 2);
        final b = (await repo.getById(p1, bad.id))!;
        expect(b.nextDueDate, '2026-01-10'); // nothing partial
        expect((await txns()).length, 2);
        // Fix the account: next run posts the backlog.
        await db.customStatement(
          'UPDATE accounts SET is_active=1 WHERE id=$arch',
        );
        final again = await svc.generateDue(
          profileId: p1,
          today: DateTime(2026, 2, 15),
        );
        expect(again.posted.map((p) => p.ruleId).toSet(), {bad.id});
        expect(again.posted.length, 2);
      },
    );

    test(
      'occurrence before account opening date is skipped with reason',
      () async {
        final r = await repo.create(
          p1,
          expense(account: lateAcc, start: '2026-03-01'),
        );
        final res = await svc.generateDue(
          profileId: p1,
          today: DateTime(2026, 3, 2),
        );
        expect(res.skipped.single.reason, contains('opening date'));
        expect(await txns(), isEmpty);
        expect((await repo.getById(p1, r.id))!.nextDueDate, '2026-03-01');
      },
    );

    test('cross-profile: only the requested profile is processed', () async {
      await repo.create(p1, expense(start: '2026-01-01'));
      final cat2 = otherCat;
      await repo.create(
        p2,
        RecurringInput(
          type: 'expense',
          accountId: otherAcc,
          categoryId: cat2,
          amountMinor: 100,
          title: 'p2',
          frequency: 'monthly',
          startDate: '2026-01-01',
        ),
      );
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 1, 15),
      );
      expect(res.posted.length, 1);
      final all = await txns();
      expect(all.single.profileId, p1);
      expect((await repo.list(p2)).single.nextDueDate, '2026-01-01');
    });

    test('caps at 366 occurrences per rule per run', () async {
      final r = await repo.create(
        p1,
        expense(start: '2025-01-01', freq: 'daily'),
      );
      // account opening is 2026-01-01; move it back so postings are legal
      await db.customStatement(
        "UPDATE accounts SET opening_date='2025-01-01' WHERE id=$cash",
      );
      final res = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 12, 31),
      );
      expect(res.posted.length, 366);
      expect((await repo.getById(p1, r.id))!.nextDueDate, '2026-01-02');
      final res2 = await svc.generateDue(
        profileId: p1,
        today: DateTime(2026, 12, 31),
      );
      expect(res2.posted.length, 364);
    });
  });
}

extension on RecurringInput {
  RecurringInput copyWithAccount(int id) => RecurringInput(
    type: type,
    accountId: id,
    incomeSource: incomeSource,
    amountMinor: amountMinor,
    title: title,
    frequency: frequency,
    startDate: startDate,
  );
}
