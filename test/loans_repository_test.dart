import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/loans/data/loan_repository.dart';
import 'package:my_budget/features/loans/domain/loan_calculator.dart';

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

  // 3 x 1,000.00 at 0% due 2026-02-01 / 03-01 / 04-01.
  Future<LoanPosition> make({
    int? profile,
    String lender = 'City Bank',
    int principal = 300000,
    int rateBp = 0,
    int count = 3,
    String frequency = 'monthly',
    String method = 'reducing',
    int? installment,
    int fee = 0,
    String start = '2026-01-01',
    String firstDue = '2026-02-01',
  }) => repo.create(
    profileId: profile ?? p1,
    lenderName: lender,
    principalMinor: principal,
    interestRateBp: rateBp,
    interestMethod: method,
    frequency: frequency,
    tenureCount: count,
    installmentMinor: installment,
    processingFeeMinor: fee,
    startDate: start,
    firstDueDate: firstDue,
  );

  group('create', () {
    test('computes the installment and derives the position', () async {
      final pos = await make(
        principal: 10000000,
        rateBp: 1200,
        count: 12,
        fee: 50000,
      );
      expect(pos.loan.installmentMinor, 888488);
      expect(pos.loan.loanType, 'personal');
      expect(pos.paidMinor, 0);
      expect(pos.schedule, hasLength(12));
      expect(pos.remainingMinor, pos.totalPayableMinor);
      expect(pos.totalCostMinor, pos.totalPayableMinor + 50000);
    });

    test('keeps the bank installment when supplied', () async {
      final pos = await make(
        principal: 10000000,
        rateBp: 1200,
        count: 12,
        installment: 890000,
      );
      expect(pos.loan.installmentMinor, 890000);
      expect(pos.schedule.last.balanceAfterMinor, 0);
    });

    test('trims and cleans optional text', () async {
      final pos = await repo.create(
        profileId: p1,
        lenderName: '  DBBL ',
        referenceNo: '  ',
        note: ' car ',
        principalMinor: 100000,
        interestRateBp: 0,
        tenureCount: 2,
        startDate: '2026-01-01',
        firstDueDate: '2026-02-01',
      );
      expect(pos.loan.lenderName, 'DBBL');
      expect(pos.loan.referenceNo, isNull);
      expect(pos.loan.note, 'car');
    });

    test('validation', () async {
      Future<void> bad(Future<Object?> Function() f) =>
          expectLater(f, throwsA(isA<ValidationException>()));
      await bad(() => make(lender: ' '));
      await bad(() => make(lender: 'x' * 81));
      await bad(() => make(principal: 0));
      await bad(() => make(rateBp: -1));
      await bad(() => make(rateBp: 10001));
      await bad(() => make(count: 0));
      await bad(() => make(count: 1201));
      await bad(() => make(fee: -1));
      await bad(() => make(installment: 0));
      await bad(() => make(start: '2026-13-01'));
      await bad(() => make(firstDue: 'nope'));
      await bad(() => make(start: '2026-02-10', firstDue: '2026-02-01'));
      await bad(() => make(frequency: 'daily'));
      await bad(() => make(method: 'compound'));
      await expectLater(
        repo.create(
          profileId: p1,
          lenderName: 'B',
          loanType: 'boat',
          principalMinor: 100,
          interestRateBp: 0,
          tenureCount: 1,
          startDate: '2026-01-01',
          firstDueDate: '2026-02-01',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('unknown profile is rejected', () async {
      await expectLater(make(profile: 999), throwsA(isA<NotFoundException>()));
    });
  });

  group('profile isolation', () {
    test('other profiles never see or touch a loan', () async {
      final a = await make();
      expect(await repo.getById(p2, a.loan.id), isNull);
      expect(await repo.watchAll(p2).first, isEmpty);
      expect((await repo.watchAll(p1).first), hasLength(1));
      await expectLater(
        repo.addPayment(
          profileId: p2,
          loanId: a.loan.id,
          amountMinor: 100,
          paymentDate: '2026-02-01',
        ),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        repo.setArchived(p2, a.loan.id, true),
        throwsA(isA<NotFoundException>()),
      );
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 100,
        paymentDate: '2026-02-01',
      );
      final pay = await db.select(db.loanPayments).getSingle();
      await expectLater(
        repo.voidPayment(p2, pay.id),
        throwsA(isA<NotFoundException>()),
      );
      expect((await repo.summary(p2)).activeCount, 0);
    });

    test(
      'composite FK rejects a payment pointing at another profile',
      () async {
        final a = await make();
        await expectLater(
          db
              .into(db.loanPayments)
              .insert(
                LoanPaymentsCompanion.insert(
                  profileId: p2,
                  loanId: a.loan.id,
                  amountMinor: 100,
                  paymentDate: '2026-02-01',
                  createdAt: DateTime.now(),
                ),
              ),
          throwsA(anything),
        );
      },
    );
  });

  group('payments', () {
    test('record, remaining and settlement history', () async {
      final a = await make();
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 100000,
        paymentDate: '2026-02-01',
        note: ' first ',
      );
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 50000,
        paymentDate: '2026-03-01',
      );
      final pos = (await repo.getById(p1, a.loan.id))!;
      expect(pos.paidMinor, 150000);
      expect(pos.remainingMinor, 150000);
      expect(pos.schedule[0].status, InstallmentStatus.paid);
      expect(
        pos.schedule[1].status,
        InstallmentStatus.overdue,
      ); // 03-01 < 03-15
      final list = await repo.watchPayments(p1, a.loan.id).first;
      expect(list, hasLength(2));
      expect(list.first.paymentDate, '2026-03-01'); // newest first
      expect(list.last.note, 'first');
    });

    test('rejects invalid, early and excessive payments', () async {
      final a = await make();
      Future<void> bad({
        int amount = 1000,
        String date = '2026-02-01',
        int? loan,
      }) => expectLater(
        repo.addPayment(
          profileId: p1,
          loanId: loan ?? a.loan.id,
          amountMinor: amount,
          paymentDate: date,
        ),
        throwsA(isA<AppException>()),
      );
      await bad(amount: 0);
      await bad(amount: -5);
      await bad(date: '2026-02-30');
      await bad(date: '2025-12-31'); // before disbursement
      await bad(amount: 300001); // more than total payable
      await bad(loan: 9999);
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 300000,
        paymentDate: '2026-02-01',
      );
      await bad(amount: 1); // already fully paid
      final closed = (await repo.getById(p1, a.loan.id))!;
      expect(closed.isClosed, isTrue);
      expect(closed.remainingMinor, 0);
    });

    test('voiding restores the remaining balance, never deletes', () async {
      final a = await make();
      final pay = await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 200000,
        paymentDate: '2026-02-01',
      );
      expect((await repo.getById(p1, a.loan.id))!.remainingMinor, 100000);
      await repo.voidPayment(p1, pay.id);
      expect((await repo.getById(p1, a.loan.id))!.remainingMinor, 300000);
      final rows = await repo.watchPayments(p1, a.loan.id).first;
      expect(rows.single.isDeleted, isTrue);
      await expectLater(
        repo.voidPayment(p1, pay.id),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.voidPayment(p1, 9999),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('archived loans reject payments', () async {
      final a = await make();
      await repo.setArchived(p1, a.loan.id, true);
      await expectLater(
        repo.addPayment(
          profileId: p1,
          loanId: a.loan.id,
          amountMinor: 100,
          paymentDate: '2026-02-01',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test(
    'paying before the due date stores that date on the installment',
    () async {
      final a = await make(firstDue: '2026-02-08');
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 100000,
        paymentDate: '2026-02-04',
      );
      final one = (await repo.getById(p1, a.loan.id))!;
      expect(one.schedule[0].paidDate, '2026-02-04');
      expect(one.schedule[0].dueDate, '2026-02-08');
      expect(one.nextDue!.no, 2);
      final watched = await repo.watchById(p1, a.loan.id).first;
      expect(watched!.schedule[0].paidDate, '2026-02-04');
      final all = await repo.watchAll(p1).first;
      expect(all.single.schedule[0].paidDate, '2026-02-04');
    },
  );

  group('edit rules', () {
    Future<LoanPosition> edit(
      LoanPosition a, {
      String? lender,
      int? principal,
      int? fee,
      int? rateBp,
      int? installment,
      String? note,
    }) => repo.update(
      profileId: p1,
      id: a.loan.id,
      lenderName: lender ?? a.loan.lenderName,
      loanType: 'home',
      referenceNo: 'REF-1',
      principalMinor: principal ?? a.loan.principalMinor,
      interestRateBp: rateBp ?? a.loan.interestRateBp,
      interestMethod: a.loan.interestMethod,
      frequency: a.loan.frequency,
      tenureCount: a.loan.tenureCount,
      installmentMinor: installment ?? a.loan.installmentMinor,
      processingFeeMinor: fee ?? a.loan.processingFeeMinor,
      startDate: a.loan.startDate,
      firstDueDate: a.loan.firstDueDate,
      note: note,
    );

    test('terms are editable before any payment', () async {
      final a = await make();
      final b = await repo.update(
        profileId: p1,
        id: a.loan.id,
        lenderName: 'New Bank',
        loanType: 'home',
        referenceNo: 'R9',
        principalMinor: 600000,
        interestRateBp: 0,
        interestMethod: 'reducing',
        frequency: 'monthly',
        tenureCount: 6,
        processingFeeMinor: 0,
        startDate: '2026-01-01',
        firstDueDate: '2026-02-01',
      );
      expect(b.loan.lenderName, 'New Bank');
      expect(b.loan.principalMinor, 600000);
      expect(b.loan.installmentMinor, 100000); // recomputed
      expect(b.schedule, hasLength(6));
    });

    test('after a payment only lender/type/ref/fee/note may change', () async {
      final a = await make();
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 1000,
        paymentDate: '2026-02-01',
      );
      final b = await edit(a, lender: 'Renamed', fee: 7000, note: 'n');
      expect(b.loan.lenderName, 'Renamed');
      expect(b.loan.loanType, 'home');
      expect(b.loan.referenceNo, 'REF-1');
      expect(b.loan.processingFeeMinor, 7000);
      expect(b.loan.note, 'n');
      await expectLater(
        edit(a, principal: 400000),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rate and installment can be revised after payments', () async {
      final a = await make();
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 1000,
        paymentDate: '2026-02-01',
      );
      final b = await edit(a, rateBp: 1500, installment: 120000);
      expect(b.loan.interestRateBp, 1500);
      expect(b.loan.installmentMinor, 120000);
      expect(b.paidMinor, 1000);
      // Other terms stay locked.
      await expectLater(
        edit(b, principal: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('terms unlock again after the payment is voided', () async {
      final a = await make();
      final pay = await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 1000,
        paymentDate: '2026-02-01',
      );
      await repo.voidPayment(p1, pay.id);
      final b = await edit(a, principal: 400000);
      expect(b.loan.principalMinor, 400000);
    });

    test('unknown loan', () async {
      final a = await make();
      await expectLater(
        repo.update(
          profileId: p1,
          id: 9999,
          lenderName: 'x',
          loanType: 'home',
          principalMinor: 1,
          interestRateBp: 0,
          interestMethod: 'reducing',
          frequency: 'monthly',
          tenureCount: 1,
          processingFeeMinor: 0,
          startDate: a.loan.startDate,
          firstDueDate: a.loan.firstDueDate,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('archive and listing', () {
    test('archive hides but preserves; includeArchived shows', () async {
      final a = await make(lender: 'Zeta');
      await make(lender: 'alpha');
      await repo.setArchived(p1, a.loan.id, true);
      final active = await repo.watchAll(p1).first;
      expect(active.map((l) => l.loan.lenderName), ['alpha']);
      final all = await repo.watchAll(p1, includeArchived: true).first;
      expect(all.map((l) => l.loan.lenderName), ['alpha', 'Zeta']);
      expect((await repo.getById(p1, a.loan.id))!.loan.isActive, isFalse);
      await repo.setArchived(p1, a.loan.id, false);
      expect(await repo.watchAll(p1).first, hasLength(2));
      expect(await db.select(db.loans).get(), hasLength(2));
    });

    test('watchById emits null for another profile', () async {
      final a = await make();
      expect(await repo.watchById(p1, a.loan.id).first, isNotNull);
      expect(await repo.watchById(p2, a.loan.id).first, isNull);
    });
  });

  group('summary', () {
    test('empty', () async {
      final s = await repo.summary(p1);
      expect(s.activeCount, 0);
      expect(s.remainingMinor, 0);
      expect(s.nextDueDate, isNull);
    });

    test('totals across loans, ignoring closed and archived', () async {
      final a = await make(); // 3 x 1,000 monthly, due 02-01 03-01 04-01
      await make(
        lender: 'Weekly Bank',
        principal: 200000,
        count: 2,
        frequency: 'weekly',
        firstDue: '2026-04-10',
      ); // 2 x 1,000 weekly
      final closed = await make(lender: 'Done', principal: 100000, count: 1);
      await repo.addPayment(
        profileId: p1,
        loanId: closed.loan.id,
        amountMinor: 100000,
        paymentDate: '2026-02-01',
      );
      final archived = await make(lender: 'Old');
      await repo.setArchived(p1, archived.loan.id, true);
      await repo.addPayment(
        profileId: p1,
        loanId: a.loan.id,
        amountMinor: 100000,
        paymentDate: '2026-02-01',
      );
      final s = await repo.summary(p1);
      expect(s.activeCount, 3); // closed counts as non-archived
      expect(s.remainingMinor, 200000 + 200000);
      expect(s.overdueCount, 1); // installment 2 of loan a (03-01 < 03-15)
      expect(s.overdueMinor, 100000);
      expect(s.nextDueDate, '2026-03-01');
      expect(s.nextDueMinor, 100000);
      // 1,000 monthly + 1,000 weekly * 52/12
      expect(s.monthlyCommitmentMinor, 100000 + 433333);
      // summary stream agrees
      expect((await repo.watchSummary(p1).first).remainingMinor, 400000);
    });

    test('next due moves as dates pass', () async {
      await make();
      today = '2026-01-10';
      expect((await repo.summary(p1)).nextDueDate, '2026-02-01');
      expect((await repo.summary(p1)).overdueCount, 0);
    });
  });
}
