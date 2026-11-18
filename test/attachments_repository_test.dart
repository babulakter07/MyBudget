import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/core/storage/app_paths.dart';
import 'package:my_budget/features/attachments/data/attachment_repository.dart';
import 'package:my_budget/features/attachments/domain/attachment.dart';
import 'package:path/path.dart' as p;

import 'ledger_test_helpers.dart';

void main() {
  late AppDatabase db;
  late AttachmentRepository repo;
  late Directory tmp;
  late Directory attDir;
  late int p1, p2, acc1, acc2, txn1, txn2;

  File src(String name, {int bytes = 10}) {
    final f = File(p.join(tmp.path, name));
    f.writeAsBytesSync(List.filled(bytes, 7));
    return f;
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('att_test');
    attDir = Directory(p.join(tmp.path, 'attachments'));
    attachmentsDirectoryOverride = attDir;
    db = AppDatabase.memory();
    repo = AttachmentRepository(db);
    p1 = await addProfile(db, 'A');
    p2 = await addProfile(db, 'B');
    acc1 = await addAccount(db, p1, 'Cash');
    acc2 = await addAccount(db, p2, 'Cash');
    final c1 = await addCategory(db, p1, 'C');
    final c2 = await addCategory(db, p2, 'C');
    txn1 = await addTxn(
      db,
      profileId: p1,
      type: 'expense',
      accountId: acc1,
      amount: 100,
      date: '2026-03-01',
      categoryId: c1,
      category: 'C',
    );
    txn2 = await addTxn(
      db,
      profileId: p2,
      type: 'expense',
      accountId: acc2,
      amount: 100,
      date: '2026-03-01',
      categoryId: c2,
      category: 'C',
    );
  });

  tearDown(() async {
    await db.close();
    attachmentsDirectoryOverride = null;
    tmp.deleteSync(recursive: true);
  });

  test('add copies file under generated relative name and lists it', () async {
    final a = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: src('a.jpg', bytes: 123),
    );
    expect(a.relativePath, startsWith('$p1/${txn1}_'));
    expect(a.relativePath, endsWith('.jpg'));
    expect(a.mimeType, 'image/jpeg');
    expect(a.sizeBytes, 123);
    expect(p.isAbsolute(a.relativePath), isFalse);
    final f = await repo.resolve(a.relativePath);
    expect(f.existsSync(), isTrue);
    expect(f.lengthSync(), 123);
    final png = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: src('b.PNG'),
    );
    expect(png.mimeType, 'image/png');
    expect(png.relativePath, endsWith('.png'));
    expect(png.relativePath, isNot(a.relativePath));
    expect(await repo.list(p1, txn1), hasLength(2));
  });

  test('names never collide for rapid adds', () async {
    final s = src('a.jpg');
    final names = <String>{};
    for (var i = 0; i < 5; i++) {
      names.add(
        (await repo.addFromFile(
          profileId: p1,
          transactionId: txn1,
          source: s,
        )).relativePath,
      );
    }
    expect(names, hasLength(5));
  });

  test('limit of 5 per transaction and 10 MB per file', () async {
    final s = src('a.jpg');
    for (var i = 0; i < 5; i++) {
      await repo.addFromFile(profileId: p1, transactionId: txn1, source: s);
    }
    await expectLater(
      repo.addFromFile(profileId: p1, transactionId: txn1, source: s),
      throwsA(isA<ValidationException>()),
    );
    expect(attDir.listSync(recursive: true).whereType<File>(), hasLength(5));
    final big = src('big.jpg', bytes: AttachmentLimits.maxBytes + 1);
    await expectLater(
      repo.addFromFile(profileId: p1, transactionId: txn1, source: big),
      throwsA(isA<ValidationException>()),
    );
  });

  test('soft delete frees a slot and removes the file', () async {
    final a = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: src('a.jpg'),
    );
    final f = await repo.resolve(a.relativePath);
    await repo.delete(p1, a.id);
    expect(f.existsSync(), isFalse);
    expect(await repo.list(p1, txn1), isEmpty);
    final row = await db.select(db.transactionAttachments).getSingle();
    expect(row.isDeleted, isTrue);
    await expectLater(repo.delete(p1, a.id), throwsA(isA<NotFoundException>()));
  });

  test('cross-profile and missing transaction rejected', () async {
    final s = src('a.jpg');
    await expectLater(
      repo.addFromFile(profileId: p1, transactionId: txn2, source: s),
      throwsA(isA<ProfileMismatchException>()),
    );
    await expectLater(
      repo.addFromFile(profileId: p1, transactionId: 9999, source: s),
      throwsA(isA<NotFoundException>()),
    );
    final a = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: s,
    );
    await expectLater(
      repo.delete(p2, a.id),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(await repo.list(p2, txn1), isEmpty);
  });

  test('resolve rejects traversal and absolute paths', () async {
    for (final bad in [
      '../x.jpg',
      '1/../../x.jpg',
      '..\\x.jpg',
      '/etc/passwd',
      'C:\\Windows\\a.jpg',
      '',
    ]) {
      await expectLater(
        repo.resolve(bad),
        throwsA(isA<ValidationException>()),
        reason: bad,
      );
    }
    expect((await repo.resolve('1/a.jpg')).path, startsWith(attDir.path));
  });

  test('pending attachments commit after save', () async {
    final pending = PendingAttachments();
    await pending.add(src('a.jpg'));
    await pending.add(src('b.png'));
    expect(pending.length, 2);
    final done = await repo.commitPending(
      profileId: p1,
      transactionId: txn1,
      pending: pending,
    );
    expect(done, hasLength(2));
    expect(pending.isEmpty, isTrue);
    expect(await repo.list(p1, txn1), hasLength(2));
  });

  test('pending enforces count and size', () async {
    final pending = PendingAttachments();
    for (var i = 0; i < 5; i++) {
      await pending.add(src('a$i.jpg'));
    }
    await expectLater(
      pending.add(src('x.jpg')),
      throwsA(isA<ValidationException>()),
    );
    final p2n = PendingAttachments();
    await expectLater(
      p2n.add(src('big.jpg', bytes: AttachmentLimits.maxBytes + 1)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('purge removes files of long-deleted transactions only', () async {
    final keep = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: src('keep.jpg'),
    );
    final gone = await repo.addFromFile(
      profileId: p2,
      transactionId: txn2,
      source: src('gone.jpg'),
    );
    final goneFile = await repo.resolve(gone.relativePath);
    expect(goneFile.existsSync(), isTrue);

    // txn2 deleted 40 days ago; txn1 is live.
    final now = DateTime(2026, 6, 1);
    await (db.update(
      db.financialTransactions,
    )..where((t) => t.id.equals(txn2))).write(
      FinancialTransactionsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now.subtract(const Duration(days: 40))),
      ),
    );
    expect(await repo.purgeDeletedTransactionAttachments(now: now), 1);
    expect(goneFile.existsSync(), isFalse);
    expect((await repo.resolve(keep.relativePath)).existsSync(), isTrue);
    // Idempotent.
    expect(await repo.purgeDeletedTransactionAttachments(now: now), 0);
  });

  test('purge keeps files inside the undo window', () async {
    final a = await repo.addFromFile(
      profileId: p1,
      transactionId: txn1,
      source: src('recent.jpg'),
    );
    final now = DateTime(2026, 6, 1);
    await (db.update(
      db.financialTransactions,
    )..where((t) => t.id.equals(txn1))).write(
      FinancialTransactionsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now.subtract(const Duration(days: 5))),
      ),
    );
    expect(await repo.purgeDeletedTransactionAttachments(now: now), 0);
    expect((await repo.resolve(a.relativePath)).existsSync(), isTrue);
  });
}
