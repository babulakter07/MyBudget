import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/tags/data/tag_repository.dart';

import 'ledger_test_helpers.dart';

var _n = 0;

void main() {
  late AppDatabase db;
  late TagRepository repo;
  late int p1, p2, acc1, acc2;

  setUp(() async {
    db = AppDatabase.memory();
    repo = TagRepository(db);
    p1 = await addProfile(db, 'A');
    p2 = await addProfile(db, 'B');
    acc1 = await addAccount(db, p1, 'Cash');
    acc2 = await addAccount(db, p2, 'Cash');
  });
  tearDown(() => db.close());

  Future<int> expense(
    int profile,
    int acc,
    int amount,
    String date, {
    bool deleted = false,
    String type = 'expense',
  }) async {
    final cat = await addCategory(db, profile, 'C${_n++}');
    return addTxn(
      db,
      profileId: profile,
      type: type,
      accountId: acc,
      amount: amount,
      date: date,
      categoryId: type == 'expense' ? cat : null,
      category: type == 'expense' ? 'C' : null,
      deleted: deleted,
    );
  }

  test(
    'create trims, validates and rejects case-insensitive duplicates',
    () async {
      final t = await repo.create(
        profileId: p1,
        name: '  Eid ',
        color: 0xFF112233,
      );
      expect(t.name, 'Eid');
      expect(t.color, 0xFF112233);
      await expectLater(
        repo.create(profileId: p1, name: 'eid'),
        throwsA(isA<DuplicateNameException>()),
      );
      await expectLater(
        repo.create(profileId: p1, name: '   '),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.create(profileId: p1, name: 'x' * 41),
        throwsA(isA<ValidationException>()),
      );
      // Same name allowed in another profile.
      await repo.create(profileId: p2, name: 'Eid');
    },
  );

  test('rename, recolor, archive and cross-profile rejection', () async {
    final a = await repo.create(profileId: p1, name: 'A');
    final b = await repo.create(profileId: p1, name: 'B');
    expect((await repo.rename(p1, a.id, 'Alpha')).name, 'Alpha');
    await expectLater(
      repo.rename(p1, a.id, 'b'),
      throwsA(isA<DuplicateNameException>()),
    );
    // Renaming to its own name in other case is fine.
    expect((await repo.rename(p1, b.id, 'BEE')).name, 'BEE');
    expect((await repo.recolor(p1, a.id, 0xFF000001)).color, 0xFF000001);
    expect((await repo.recolor(p1, a.id, null)).color, isNull);
    expect((await repo.archive(p1, a.id)).isActive, false);
    expect((await repo.listTags(p1)).map((t) => t.name), ['BEE']);
    expect(await repo.listTags(p1, includeArchived: true), hasLength(2));
    await expectLater(
      repo.rename(p2, a.id, 'Z'),
      throwsA(isA<ProfileMismatchException>()),
    );
    await expectLater(
      repo.archive(p1, 9999),
      throwsA(isA<NotFoundException>()),
    );
    expect(await repo.listTags(p2), isEmpty);
  });

  test('setTagsForTransaction replaces the set', () async {
    final txn = await expense(p1, acc1, 1000, '2026-03-01');
    final a = await repo.create(profileId: p1, name: 'A');
    final b = await repo.create(profileId: p1, name: 'B');
    final c = await repo.create(profileId: p1, name: 'C');
    await repo.setTagsForTransaction(p1, txn, [a.id, b.id]);
    expect((await repo.tagsForTransaction(p1, txn).first).map((t) => t.name), [
      'A',
      'B',
    ]);
    await repo.setTagsForTransaction(p1, txn, [c.id, c.id]);
    expect((await repo.tagsForTransaction(p1, txn).first).map((t) => t.name), [
      'C',
    ]);
    final bulk = await repo.tagsForTransactions(p1, [txn, 999]).first;
    expect(bulk.keys, [txn]);
    await repo.setTagsForTransaction(p1, txn, []);
    expect(await repo.tagsForTransaction(p1, txn).first, isEmpty);
  });

  test(
    'cross-profile, missing, deleted txn and archived tags rejected',
    () async {
      final txn1 = await expense(p1, acc1, 1000, '2026-03-01');
      final txn2 = await expense(p2, acc2, 1000, '2026-03-01');
      final del = await expense(p1, acc1, 500, '2026-03-01', deleted: true);
      final a = await repo.create(profileId: p1, name: 'A');
      final other = await repo.create(profileId: p2, name: 'Other');
      await expectLater(
        repo.setTagsForTransaction(p1, txn2, [a.id]),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.setTagsForTransaction(p1, txn1, [other.id]),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.setTagsForTransaction(p1, 9999, [a.id]),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repo.setTagsForTransaction(p1, del, [a.id]),
        throwsA(isA<NotFoundException>()),
      );
      // Failure is atomic: previous set preserved.
      await repo.setTagsForTransaction(p1, txn1, [a.id]);
      await expectLater(
        repo.setTagsForTransaction(p1, txn1, [a.id, 9999]),
        throwsA(isA<NotFoundException>()),
      );
      expect(await repo.tagsForTransaction(p1, txn1).first, hasLength(1));
    },
  );

  test(
    'archived tags stay on old transactions but cannot be newly assigned',
    () async {
      final txn = await expense(p1, acc1, 1000, '2026-03-01');
      final txn2 = await expense(p1, acc1, 700, '2026-03-02');
      final a = await repo.create(profileId: p1, name: 'A');
      await repo.setTagsForTransaction(p1, txn, [a.id]);
      await repo.archive(p1, a.id);
      expect(await repo.tagsForTransaction(p1, txn).first, hasLength(1));
      await expectLater(
        repo.setTagsForTransaction(p1, txn2, [a.id]),
        throwsA(isA<ValidationException>()),
      );
      // Keeping an already attached archived tag is allowed.
      await repo.setTagsForTransaction(p1, txn, [a.id]);
    },
  );

  test(
    'tagTotals sums expense/income in range, ignoring deleted txns',
    () async {
      final e1 = await expense(p1, acc1, 1000, '2026-03-01');
      final e2 = await expense(p1, acc1, 250, '2026-03-31');
      final inc = await expense(p1, acc1, 5000, '2026-03-10', type: 'income');
      final out = await expense(p1, acc1, 999, '2026-04-01');
      final del = await expense(p1, acc1, 777, '2026-03-05', deleted: true);
      final a = await repo.create(profileId: p1, name: 'Trip');
      final b = await repo.create(profileId: p1, name: 'Other');
      for (final t in [e1, e2, inc, out]) {
        await repo.setTagsForTransaction(p1, t, [a.id]);
      }
      // Tag attached before the transaction was soft-deleted.
      await db
          .into(db.transactionTags)
          .insert(
            TransactionTagsCompanion.insert(
              profileId: p1,
              transactionId: del,
              tagId: a.id,
            ),
          );
      await repo.setTagsForTransaction(p1, e1, [a.id, b.id]);
      final totals = await repo.tagTotals(
        p1,
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31),
      );
      expect(totals, hasLength(2));
      final trip = totals.firstWhere((t) => t.name == 'Trip');
      expect(trip.expenseMinor, 1250);
      expect(trip.incomeMinor, 5000);
      expect(trip.count, 3);
      final other = totals.firstWhere((t) => t.name == 'Other');
      expect(other.expenseMinor, 1000);
      expect(other.count, 1);
      expect(totals.first.name, 'Trip'); // highest expense first
      expect(
        await repo.tagTotals(p2, DateTime(2026, 3, 1), DateTime(2026, 3, 31)),
        isEmpty,
      );
    },
  );
}
