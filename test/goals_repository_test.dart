import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/goals/data/goal_repository.dart';

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

Future<int> _account(
  AppDatabase db,
  int profileId,
  String name, {
  int opening = 0,
  String type = 'savings',
  bool active = true,
  String openingDate = '2026-01-01',
}) {
  final now = DateTime.now();
  return db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: name,
          type: Value(type),
          openingBalanceMinor: Value(opening),
          openingDate: openingDate,
          isActive: Value(active),
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
  bool deleted = false,
}) async {
  final now = DateTime.now();
  int? categoryId;
  if (type == 'expense') {
    categoryId = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            profileId: profileId,
            name: 'c${now.microsecondsSinceEpoch}$amount',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
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
  late GoalRepository repo;
  late int p1, p2, a1, a2, b1;

  setUp(() async {
    db = AppDatabase.memory();
    repo = GoalRepository(db, todayKey: () => '2026-06-01');
    p1 = await _profile(db, 'One');
    p2 = await _profile(db, 'Two');
    a1 = await _account(db, p1, 'Savings', opening: 10000);
    a2 = await _account(db, p1, 'Wallet', type: 'cash');
    b1 = await _account(db, p2, 'Other savings');
  });

  tearDown(() => db.close());

  Future<void> expectValidation(Future<Object?> f) =>
      expectLater(f, throwsA(isA<ValidationException>()));

  test('create + computed progress from account balance', () async {
    final g = await repo.create(
      profileId: p1,
      name: '  Laptop ',
      accountId: a1,
      targetMinor: 100000,
      targetDate: '2026-12-01',
    );
    expect(g.name, 'Laptop');
    await _txn(
      db,
      profileId: p1,
      type: 'income',
      accountId: a1,
      amount: 30000,
      date: '2026-02-01',
    );
    await _txn(
      db,
      profileId: p1,
      type: 'expense',
      accountId: a1,
      amount: 5000,
      date: '2026-02-02',
    );
    await _txn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: a2,
      toAccountId: a1,
      amount: 7000,
      date: '2026-02-03',
    );
    await _txn(
      db,
      profileId: p1,
      type: 'transfer',
      accountId: a1,
      toAccountId: a2,
      amount: 2000,
      date: '2026-02-04',
    );
    final item = await repo.progressOf(p1, g.id);
    // 10000 + 30000 - 5000 + 7000 - 2000
    expect(item.progress.currentMinor, 40000);
    expect(item.progress.percent, 40);
    expect(item.progress.remainingMinor, 60000);
    expect(item.accountName, 'Savings');
  });

  test('deleted transactions and pre-opening rows are ignored', () async {
    final g = await repo.create(
      profileId: p1,
      name: 'G',
      accountId: a1,
      targetMinor: 100000,
    );
    await _txn(
      db,
      profileId: p1,
      type: 'income',
      accountId: a1,
      amount: 50000,
      date: '2026-02-01',
      deleted: true,
    );
    await _txn(
      db,
      profileId: p1,
      type: 'income',
      accountId: a1,
      amount: 99999,
      date: '2025-12-31',
    );
    expect((await repo.progressOf(p1, g.id)).progress.currentMinor, 10000);
  });

  test('watchGoals reacts to new transactions', () async {
    await repo.create(
      profileId: p1,
      name: 'G',
      accountId: a1,
      targetMinor: 100000,
    );
    final stream = repo.watchGoals(p1);
    final expectation = expectLater(
      stream.map((l) => l.single.progress.currentMinor),
      emitsInOrder([10000, 15000]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _txn(
      db,
      profileId: p1,
      type: 'income',
      accountId: a1,
      amount: 5000,
      date: '2026-03-01',
    );
    await expectation;
  });

  group('validation', () {
    test('name required / too long', () async {
      await expectValidation(
        repo.create(profileId: p1, name: '  ', accountId: a1, targetMinor: 1),
      );
      await expectValidation(
        repo.create(
          profileId: p1,
          name: 'x' * 81,
          accountId: a1,
          targetMinor: 1,
        ),
      );
    });

    test('target must be > 0', () async {
      await expectValidation(
        repo.create(profileId: p1, name: 'G', accountId: a1, targetMinor: 0),
      );
      await expectValidation(
        repo.create(profileId: p1, name: 'G', accountId: a1, targetMinor: -5),
      );
    });

    test('target date not in the past at creation; today ok', () async {
      await expectValidation(
        repo.create(
          profileId: p1,
          name: 'G',
          accountId: a1,
          targetMinor: 1,
          targetDate: '2026-05-31',
        ),
      );
      await expectValidation(
        repo.create(
          profileId: p1,
          name: 'G',
          accountId: a1,
          targetMinor: 1,
          targetDate: 'nope',
        ),
      );
      final g = await repo.create(
        profileId: p1,
        name: 'G',
        accountId: a1,
        targetMinor: 1,
        targetDate: '2026-06-01',
      );
      expect(g.targetDate, '2026-06-01');
    });

    test('duplicate name is case-insensitive per profile', () async {
      await repo.create(
        profileId: p1,
        name: 'Trip',
        accountId: a1,
        targetMinor: 1,
      );
      await expectLater(
        repo.create(profileId: p1, name: 'TRIP', accountId: a2, targetMinor: 1),
        throwsA(isA<DuplicateNameException>()),
      );
      // same name allowed in another profile
      final g = await repo.create(
        profileId: p2,
        name: 'trip',
        accountId: b1,
        targetMinor: 1,
      );
      expect(g.profileId, p2);
    });

    test('inactive account rejected; any type allowed', () async {
      final off = await _account(db, p1, 'Old', active: false);
      await expectValidation(
        repo.create(profileId: p1, name: 'G', accountId: off, targetMinor: 1),
      );
      final g = await repo.create(
        profileId: p1,
        name: 'G',
        accountId: a2,
        targetMinor: 1,
      );
      expect(g.accountId, a2);
    });

    test('only one active goal per account; archive frees it', () async {
      final g1 = await repo.create(
        profileId: p1,
        name: 'One',
        accountId: a1,
        targetMinor: 1,
      );
      await expectValidation(
        repo.create(profileId: p1, name: 'Two', accountId: a1, targetMinor: 1),
      );
      await repo.setActive(p1, g1.id, false);
      final g2 = await repo.create(
        profileId: p1,
        name: 'Two',
        accountId: a1,
        targetMinor: 1,
      );
      // restoring the archived one now conflicts
      await expectValidation(repo.setActive(p1, g1.id, true));
      await repo.setActive(p1, g2.id, false);
      await repo.setActive(p1, g1.id, true);
      expect((await repo.getById(p1, g1.id))!.isActive, isTrue);
    });

    test(
      'edit: moving to an account with an active goal is rejected',
      () async {
        await repo.create(
          profileId: p1,
          name: 'One',
          accountId: a1,
          targetMinor: 1,
        );
        final g2 = await repo.create(
          profileId: p1,
          name: 'Two',
          accountId: a2,
          targetMinor: 1,
        );
        await expectValidation(
          repo.update(
            profileId: p1,
            id: g2.id,
            name: 'Two',
            accountId: a1,
            targetMinor: 1,
          ),
        );
      },
    );
  });

  test('cross-profile rejection', () async {
    await expectLater(
      repo.create(profileId: p1, name: 'G', accountId: b1, targetMinor: 1),
      throwsA(isA<ProfileMismatchException>()),
    );
    final g = await repo.create(
      profileId: p1,
      name: 'G',
      accountId: a1,
      targetMinor: 1,
    );
    expect(await repo.getById(p2, g.id), isNull);
    await expectLater(
      repo.setActive(p2, g.id, false),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      repo.update(
        profileId: p2,
        id: g.id,
        name: 'X',
        accountId: b1,
        targetMinor: 1,
      ),
      throwsA(isA<NotFoundException>()),
    );
    expect(await repo.watchGoals(p2).first, isEmpty);
  });

  test('edit keeps own name/account; changes persist', () async {
    final g = await repo.create(
      profileId: p1,
      name: 'G',
      accountId: a1,
      targetMinor: 100,
    );
    final u = await repo.update(
      profileId: p1,
      id: g.id,
      name: 'g',
      accountId: a1,
      targetMinor: 500,
      targetDate: '2027-01-01',
      note: ' hi ',
    );
    expect(u.name, 'g');
    expect(u.targetMinor, 500);
    expect(u.targetDate, '2027-01-01');
    expect(u.note, 'hi');
  });

  test('archive hides from default list, kept in archived list', () async {
    final g = await repo.create(
      profileId: p1,
      name: 'G',
      accountId: a1,
      targetMinor: 100,
    );
    await repo.setActive(p1, g.id, false);
    expect(await repo.watchGoals(p1).first, isEmpty);
    final all = await repo.watchGoals(p1, includeArchived: true).first;
    expect(all.single.goal.isActive, isFalse);
  });
}
