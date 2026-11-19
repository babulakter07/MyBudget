import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/loans/domain/loan.dart';
import 'package:my_budget/features/loans/domain/loan_calculator.dart';

Loan _loan({
  int principal = 1200000,
  int rateBp = 1200,
  String method = 'reducing',
  String frequency = 'monthly',
  int count = 12,
  int? installment,
  String firstDue = '2026-02-01',
  int fee = 0,
}) => Loan(
  id: 1,
  profileId: 1,
  lenderName: 'Bank',
  loanType: 'personal',
  referenceNo: null,
  principalMinor: principal,
  interestRateBp: rateBp,
  interestMethod: method,
  frequency: frequency,
  tenureCount: count,
  installmentMinor:
      installment ??
      LoanCalculator.computeInstallment(
        principalMinor: principal,
        rateBp: rateBp,
        method: method,
        frequency: frequency,
        count: count,
      ),
  processingFeeMinor: fee,
  startDate: '2026-01-01',
  firstDueDate: firstDue,
  note: null,
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('computeInstallment', () {
    test('reducing balance 100,000 @ 12% for 12 months = 8,884.88', () {
      expect(
        LoanCalculator.computeInstallment(
          principalMinor: 10000000,
          rateBp: 1200,
          method: 'reducing',
          frequency: 'monthly',
          count: 12,
        ),
        888488,
      );
    });

    test('flat 100,000 @ 10% for 12 months = 9,166.67', () {
      expect(
        LoanCalculator.computeInstallment(
          principalMinor: 10000000,
          rateBp: 1000,
          method: 'flat',
          frequency: 'monthly',
          count: 12,
        ),
        916667,
      );
    });

    test('zero rate splits the principal evenly', () {
      expect(
        LoanCalculator.computeInstallment(
          principalMinor: 120000,
          rateBp: 0,
          method: 'reducing',
          frequency: 'monthly',
          count: 12,
        ),
        10000,
      );
    });

    test('weekly rate uses 52 periods per year', () {
      final weekly = LoanCalculator.computeInstallment(
        principalMinor: 5200000,
        rateBp: 0,
        method: 'reducing',
        frequency: 'weekly',
        count: 52,
      );
      expect(weekly, 100000);
      // flat 10% over exactly one year = 10% of principal in total
      final flat = LoanCalculator.computeInstallment(
        principalMinor: 5200000,
        rateBp: 1000,
        method: 'flat',
        frequency: 'weekly',
        count: 52,
      );
      expect(flat, 110000);
    });

    test('degenerate input yields zero', () {
      expect(
        LoanCalculator.computeInstallment(
          principalMinor: 0,
          rateBp: 100,
          method: 'reducing',
          frequency: 'monthly',
          count: 12,
        ),
        0,
      );
    });
  });

  group('schedule', () {
    test('reducing: principal sums exactly, balance ends at zero', () {
      final l = _loan();
      final s = LoanCalculator.evaluate(l, 0, '2026-01-01');
      expect(s.schedule, hasLength(12));
      expect(s.schedule.fold<int>(0, (a, i) => a + i.principalMinor), 1200000);
      expect(s.schedule.last.balanceAfterMinor, 0);
      expect(s.schedule.first.interestMinor, 12000); // 1% of 12,000.00
      for (final i in s.schedule) {
        expect(i.installmentMinor, i.principalMinor + i.interestMinor);
      }
      expect(s.totalPayableMinor, s.totalInterestMinor + 1200000);
      expect(s.totalCostMinor, s.totalPayableMinor);
    });

    test('last installment absorbs rounding', () {
      final l = _loan(principal: 100000, rateBp: 1350, count: 7);
      final s = LoanCalculator.evaluate(l, 0, '2026-01-01').schedule;
      expect(s.fold<int>(0, (a, i) => a + i.principalMinor), 100000);
      expect(s.last.balanceAfterMinor, 0);
      // all but the last are the fixed installment
      for (final i in s.take(6)) {
        expect(i.installmentMinor, l.installmentMinor);
      }
    });

    test('flat: interest is even, total = P * rate * years', () {
      final l = _loan(principal: 1200000, rateBp: 1000, method: 'flat');
      final s = LoanCalculator.evaluate(l, 0, '2026-01-01');
      expect(s.totalInterestMinor, 120000);
      expect(s.totalPayableMinor, 1320000);
      expect(s.schedule.every((i) => i.interestMinor == 10000), isTrue);
      expect(s.schedule.last.balanceAfterMinor, 0);
    });

    test('processing fee is part of total cost only', () {
      final s = LoanCalculator.evaluate(_loan(fee: 5000), 0, '2026-01-01');
      expect(s.totalCostMinor, s.totalPayableMinor + 5000);
    });

    test('a higher bank installment closes the loan early', () {
      final l = _loan(
        principal: 100000,
        rateBp: 0,
        count: 10,
        installment: 40000,
      );
      final s = LoanCalculator.evaluate(l, 0, '2026-01-01').schedule;
      expect(s, hasLength(3));
      expect(s.map((i) => i.installmentMinor), [40000, 40000, 20000]);
    });
  });

  group('due dates', () {
    test('weekly adds 7 days', () {
      expect(LoanCalculator.dueDateAt('2026-02-26', 'weekly', 0), '2026-02-26');
      expect(LoanCalculator.dueDateAt('2026-02-26', 'weekly', 1), '2026-03-05');
      expect(LoanCalculator.dueDateAt('2026-12-28', 'weekly', 1), '2027-01-04');
    });

    test('monthly clamps to month end without drifting', () {
      expect(
        LoanCalculator.dueDateAt('2026-01-31', 'monthly', 1),
        '2026-02-28',
      );
      expect(
        LoanCalculator.dueDateAt('2026-01-31', 'monthly', 2),
        '2026-03-31',
      );
      expect(
        LoanCalculator.dueDateAt('2026-01-31', 'monthly', 3),
        '2026-04-30',
      );
      expect(
        LoanCalculator.dueDateAt('2026-11-15', 'monthly', 3),
        '2027-02-15',
      );
      expect(
        LoanCalculator.dueDateAt('2026-11-15', 'monthly', 14),
        '2028-01-15',
      );
    });

    test('yearly keeps the day, clamps 29 Feb', () {
      expect(LoanCalculator.dueDateAt('2028-02-29', 'yearly', 1), '2029-02-28');
      expect(LoanCalculator.dueDateAt('2028-02-29', 'yearly', 4), '2032-02-29');
      expect(LoanCalculator.dueDateAt('2026-06-10', 'yearly', 2), '2028-06-10');
    });

    test('schedule dates follow the frequency', () {
      final s = LoanCalculator.evaluate(
        _loan(frequency: 'weekly', count: 3, firstDue: '2026-02-01'),
        0,
        '2026-01-01',
      ).schedule;
      expect(s.map((i) => i.dueDate), [
        '2026-02-01',
        '2026-02-08',
        '2026-02-15',
      ]);
    });
  });

  group('allocation (waterfall)', () {
    final loan = _loan(
      principal: 300000,
      rateBp: 0,
      count: 3,
      firstDue: '2026-02-01',
    );
    // 3 installments of 1,000.00 due 2026-02-01, 03-01, 04-01.

    test('nothing paid, before the first due date', () {
      final p = LoanCalculator.evaluate(loan, 0, '2026-01-15');
      expect(p.status, LoanStatus.active);
      expect(
        p.schedule.every((i) => i.status == InstallmentStatus.due),
        isTrue,
      );
      expect(p.nextDue!.no, 1);
      expect(p.remainingMinor, 300000);
      expect(p.progress, 0);
    });

    test('partial payment of the first installment', () {
      final p = LoanCalculator.evaluate(loan, 40000, '2026-01-15');
      expect(p.schedule[0].status, InstallmentStatus.partial);
      expect(p.schedule[0].paidMinor, 40000);
      expect(p.nextDue!.no, 1);
      expect(p.nextDue!.unpaidMinor, 60000);
    });

    test('extra payment covers later installments', () {
      final p = LoanCalculator.evaluate(loan, 150000, '2026-02-10');
      expect(p.schedule[0].status, InstallmentStatus.paid);
      expect(p.schedule[1].status, InstallmentStatus.partial);
      expect(p.schedule[2].status, InstallmentStatus.due);
      expect(p.paidMinor, 150000);
      expect(p.remainingMinor, 150000);
      expect(p.nextDue!.no, 2);
      expect(p.status, LoanStatus.active);
    });

    test('unpaid past-due installments are overdue', () {
      final p = LoanCalculator.evaluate(loan, 50000, '2026-03-05');
      expect(p.schedule[0].status, InstallmentStatus.overdue);
      expect(p.schedule[0].unpaidMinor, 50000);
      expect(p.schedule[1].status, InstallmentStatus.overdue);
      expect(p.overdueCount, 2);
      expect(p.overdueMinor, 50000 + 100000);
      expect(p.status, LoanStatus.overdue);
    });

    test('fully paid loan is closed even long after the dates', () {
      final p = LoanCalculator.evaluate(loan, 300000, '2030-01-01');
      expect(p.status, LoanStatus.closed);
      expect(p.remainingMinor, 0);
      expect(p.nextDue, isNull);
      expect(p.overdueCount, 0);
      expect(p.progress, 1);
    });
  });

  test('paid installments carry the actual settlement date', () {
    final loan = _loan(
      principal: 300000,
      rateBp: 0,
      count: 3,
      firstDue: '2026-02-08',
    );
    // Installment 1 (due 8 Feb) paid early on 4 Feb; installment 2 (due
    // 8 Mar) settled late on 10 Mar by two payments; installment 3 untouched.
    final p = LoanCalculator.evaluate(
      loan,
      200000,
      '2026-03-15',
      payments: const [
        (date: '2026-02-04', amount: 100000),
        (date: '2026-03-09', amount: 40000),
        (date: '2026-03-10', amount: 60000),
      ],
    );
    expect(p.schedule[0].status, InstallmentStatus.paid);
    expect(p.schedule[0].paidDate, '2026-02-04');
    expect(p.schedule[1].paidDate, '2026-03-10');
    expect(p.schedule[2].paidDate, isNull);
    expect(p.nextDue!.no, 3);
  });

  test('an early payment covering two installments dates both by it', () {
    final loan = _loan(
      principal: 300000,
      rateBp: 0,
      count: 3,
      firstDue: '2026-02-08',
    );
    final p = LoanCalculator.evaluate(
      loan,
      200000,
      '2026-02-05',
      payments: const [(date: '2026-02-04', amount: 200000)],
    );
    expect(p.schedule[0].paidDate, '2026-02-04');
    expect(p.schedule[1].paidDate, '2026-02-04');
  });

  test('monthlyEquivalent normalises the installment', () {
    expect(LoanCalculator.monthlyEquivalent(12000, 'yearly'), 1000);
    expect(LoanCalculator.monthlyEquivalent(12000, 'monthly'), 12000);
    expect(LoanCalculator.monthlyEquivalent(1200, 'weekly'), 5200);
  });
}
