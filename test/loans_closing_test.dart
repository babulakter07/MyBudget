import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/loans/data/loan_repository.dart';
import 'package:my_budget/features/loans/domain/loan_calculator.dart';

const _ts = 1700000000;

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

void main() {
  group('closing a loan early / adjusting it', () {
    late AppDatabase db;
    late LoanRepository repo;
    late int p1;
    late int p2;
    var today = '2026-03-15';

    setUp(() async {
      today = '2026-03-15';
      db = AppDatabase.memory();
      repo = LoanRepository(db, today: () => today);
      p1 = await _profile(db, 'One');
      p2 = await _profile(db, 'Two');
    });
    tearDown(() => db.close());

    // 12 x 1,000.00 at 0 % due monthly from 2026-02-01.
    Future<LoanPosition> make({int? profile}) => repo.create(
      profileId: profile ?? p1,
      lenderName: 'City Bank',
      principalMinor: 1200000,
      interestRateBp: 0,
      tenureCount: 12,
      startDate: '2026-01-01',
      firstDueDate: '2026-02-01',
    );

    test('early closure with a settlement amount', () async {
      final l = await make();
      await repo.addPayment(
        profileId: p1,
        loanId: l.loan.id,
        amountMinor: 200000,
        paymentDate: '2026-03-01',
      );
      final r = await repo.closeEarly(
        profileId: p1,
        loanId: l.loan.id,
        closedDate: '2026-03-15',
        remarks: 'Paid from bonus',
        paidMinor: 900000,
      );
      expect(r.isClosed, isTrue);
      expect(r.isEarlyClosed, isTrue);
      expect(r.loan.closedDate, '2026-03-15');
      expect(r.loan.closingRemarks, 'Paid from bonus');
      expect(r.loan.closingPaidMinor, 900000);
      expect(r.paidMinor, 1100000);
      expect(r.status, LoanStatus.closed);
    });

    test('early closure with nothing paid (waived)', () async {
      final l = await make();
      final r = await repo.closeEarly(
        profileId: p1,
        loanId: l.loan.id,
        closedDate: '2026-03-15',
      );
      expect(r.isEarlyClosed, isTrue);
      expect(r.loan.closingPaidMinor, isNull);
      expect(r.paidMinor, 0);
    });

    test('remaining principal and interest are exposed', () async {
      final l = await repo.create(
        profileId: p1,
        lenderName: 'Bank',
        principalMinor: 1000000,
        interestRateBp: 1200,
        tenureCount: 10,
        startDate: '2026-01-01',
        firstDueDate: '2026-02-01',
      );
      expect(l.remainingInterestMinor, greaterThan(0));
      expect(
        l.remainingPrincipalMinor + l.remainingInterestMinor,
        l.remainingMinor,
      );
      expect(l.remainingInstallments, 10);
    });

    test('closed loans leave the summary', () async {
      final l = await make();
      expect((await repo.summary(p1)).activeCount, 1);
      expect((await repo.summary(p1)).remainingMinor, 1200000);
      await repo.closeEarly(
        profileId: p1,
        loanId: l.loan.id,
        closedDate: '2026-03-15',
        paidMinor: 1200000,
      );
      expect((await repo.summary(p1)).remainingMinor, 0);
    });

    test(
      'a closed loan cannot be edited, paid, voided or closed again',
      () async {
        final l = await make();
        final pay = await repo.addPayment(
          profileId: p1,
          loanId: l.loan.id,
          amountMinor: 100000,
          paymentDate: '2026-02-01',
        );
        await repo.closeEarly(
          profileId: p1,
          loanId: l.loan.id,
          closedDate: '2026-03-15',
        );
        await expectLater(
          repo.addPayment(
            profileId: p1,
            loanId: l.loan.id,
            amountMinor: 100,
            paymentDate: '2026-03-16',
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          repo.voidPayment(p1, pay.id),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          repo.closeEarly(
            profileId: p1,
            loanId: l.loan.id,
            closedDate: '2026-03-16',
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          repo.update(
            profileId: p1,
            id: l.loan.id,
            lenderName: 'Other',
            loanType: 'personal',
            principalMinor: 1200000,
            interestRateBp: 0,
            interestMethod: 'reducing',
            frequency: 'monthly',
            tenureCount: 12,
            processingFeeMinor: 0,
            startDate: '2026-01-01',
            firstDueDate: '2026-02-01',
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('validation and isolation', () async {
      final l = await make();
      await expectLater(
        repo.closeEarly(
          profileId: p1,
          loanId: l.loan.id,
          closedDate: '2026-03-15',
          paidMinor: 1200001,
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.closeEarly(
          profileId: p1,
          loanId: l.loan.id,
          closedDate: '2025-12-31',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.closeEarly(profileId: p1, loanId: l.loan.id, closedDate: 'bad'),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.closeEarly(
          profileId: p2,
          loanId: l.loan.id,
          closedDate: '2026-03-15',
        ),
        throwsA(isA<NotFoundException>()),
      );
      // Failed attempts must not close it.
      expect((await repo.getById(p1, l.loan.id))!.isClosed, isFalse);
    });

    test('adjusting rolls the loan into a new linked loan', () async {
      final l = await make();
      await repo.addPayment(
        profileId: p1,
        loanId: l.loan.id,
        amountMinor: 200000,
        paymentDate: '2026-03-01',
      );
      final before = (await repo.getById(p1, l.loan.id))!;
      final created = await repo.adjust(
        profileId: p1,
        loanId: l.loan.id,
        closedDate: '2026-03-15',
        remarks: 'Top-up',
        lenderName: 'City Bank',
        // remaining 10,000.00 plus 5,000.00 of new money
        principalMinor: before.remainingMinor + 500000,
        interestRateBp: 0,
        tenureCount: 15,
        startDate: '2026-03-15',
        firstDueDate: '2026-04-01',
      );
      expect(created.loan.parentLoanId, l.loan.id);
      expect(created.isClosed, isFalse);
      expect(created.loan.principalMinor, 1500000);
      final old = (await repo.getById(p1, l.loan.id))!;
      expect(old.isAdjusted, isTrue);
      expect(old.isClosed, isTrue);
      expect(old.loan.closingRemarks, 'Top-up');
      expect(old.paidMinor, 200000, reason: 'no payment is invented');
      final s = await repo.summary(p1);
      expect(s.remainingMinor, 1500000, reason: 'only the new loan counts');
    });

    test('a failed adjustment leaves the old loan open', () async {
      final l = await make();
      await expectLater(
        repo.adjust(
          profileId: p1,
          loanId: l.loan.id,
          closedDate: '2026-03-15',
          lenderName: 'City Bank',
          principalMinor: 0,
          interestRateBp: 0,
          tenureCount: 12,
          startDate: '2026-03-15',
          firstDueDate: '2026-04-01',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect((await repo.getById(p1, l.loan.id))!.isClosed, isFalse);
      expect((await repo.watchAll(p1).first).length, 1);
    });
  });

  group('migration v6 -> v7 keeps loans and adds the closing columns', () {
    test('existing loan row survives', () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
CREATE TABLE financial_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'BDT',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
            raw.execute(
              "INSERT INTO financial_profiles VALUES (1,'Home','BDT',1,$_ts,$_ts)",
            );
            raw.execute('''
CREATE TABLE loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  lender_name TEXT NOT NULL,
  loan_type TEXT NOT NULL DEFAULT 'personal',
  reference_no TEXT,
  principal_minor INTEGER NOT NULL,
  interest_rate_bp INTEGER NOT NULL,
  interest_method TEXT NOT NULL DEFAULT 'reducing',
  frequency TEXT NOT NULL DEFAULT 'monthly',
  tenure_count INTEGER NOT NULL,
  installment_minor INTEGER NOT NULL,
  processing_fee_minor INTEGER NOT NULL DEFAULT 0,
  start_date TEXT NOT NULL,
  first_due_date TEXT NOT NULL,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id)
)''');
            raw.execute('''
CREATE TABLE loan_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  loan_id INTEGER NOT NULL,
  amount_minor INTEGER NOT NULL,
  payment_date TEXT NOT NULL,
  note TEXT,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''');
            raw.execute(
              "INSERT INTO loans (id,profile_id,lender_name,principal_minor,interest_rate_bp,tenure_count,installment_minor,start_date,first_due_date,created_at,updated_at) "
              "VALUES (1,1,'City Bank',10000000,1200,12,888488,'2026-01-01','2026-02-01',$_ts,$_ts)",
            );
            raw.execute('PRAGMA user_version = 6');
          },
        ),
      );
      addTearDown(db.close);
      final rows =
          (await db
                  .customSelect(
                    'SELECT lender_name, closing_type, closed_date, closing_remarks, '
                    'closing_paid_minor, parent_loan_id FROM loans',
                  )
                  .get())
              .map((r) => r.data)
              .toList();
      expect(rows, [
        {
          'lender_name': 'City Bank',
          'closing_type': null,
          'closed_date': null,
          'closing_remarks': null,
          'closing_paid_minor': null,
          'parent_loan_id': null,
        },
      ]);
      final repo = LoanRepository(db, today: () => '2026-03-15');
      final closed = await repo.closeEarly(
        profileId: 1,
        loanId: 1,
        closedDate: '2026-03-15',
      );
      expect(closed.isEarlyClosed, isTrue);
    });
  });

  group('backup', () {
    late AppDatabase db;
    late Directory dir;
    late BackupService service;

    setUp(() async {
      db = AppDatabase.memory();
      dir = Directory.systemTemp.createTempSync('mybudget_loan_close_');
      service = BackupService(
        db,
        backupsDirectory: Directory('${dir.path}/backups'),
        crypto: const BackupCrypto(iterations: 1000),
      );
      final p = await _profile(db, 'Home');
      final repo = LoanRepository(db, today: () => '2026-03-15');
      final a = await repo.create(
        profileId: p,
        lenderName: 'City Bank',
        principalMinor: 1200000,
        interestRateBp: 0,
        tenureCount: 12,
        startDate: '2026-01-01',
        firstDueDate: '2026-02-01',
      );
      await repo.adjust(
        profileId: p,
        loanId: a.loan.id,
        closedDate: '2026-03-15',
        remarks: 'Top-up',
        lenderName: 'City Bank',
        principalMinor: 1500000,
        interestRateBp: 0,
        tenureCount: 15,
        startDate: '2026-03-15',
        firstDueDate: '2026-04-01',
      );
    });

    tearDown(() async {
      await db.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('round trip keeps closing data and the parent link', () async {
      final text = await service.exportJson();
      Future<List<Map<String, Object?>>> dump() async =>
          (await db.customSelect('SELECT * FROM loans ORDER BY id').get())
              .map((r) => r.data)
              .toList();
      final before = await dump();
      await db.customStatement('DELETE FROM loan_payments');
      await db.customStatement('DELETE FROM loans');
      await service.restore(text);
      expect(await dump(), before);
      expect(before.last['parent_loan_id'], before.first['id']);
      expect(before.first['closing_type'], 'adjusted');
    });

    test('validator rejects bad closing data', () async {
      final j = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
      final loans = (j['tables'] as Map)['loans'] as List;
      (loans[0] as Map)['closing_type'] = 'weird';
      (loans[1] as Map)['parent_loan_id'] = 99;
      final r = service.validate(jsonEncode(j));
      expect(r.isValid, isFalse);
      final e = r.errors.join('\n');
      expect(e, contains('unknown closing type'));
      expect(e, contains('does not exist'));
    });
  });
}
