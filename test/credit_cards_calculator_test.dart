import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/credit_cards/domain/credit_card.dart';
import 'package:my_budget/features/credit_cards/domain/credit_card_calculator.dart';

CreditCard _card({
  bool fromStatement = false,
  int lateFeeBp = 200,
  int lateFeeFloor = 30000,
  int apr = 2400,
}) => CreditCard(
  id: 1,
  profileId: 1,
  name: 'Visa',
  bankName: 'Bank',
  lastFour: null,
  creditLimitMinor: 10000000,
  statementDay: 5,
  dueDays: 20,
  aprBp: apr,
  minPaymentBp: 500,
  minPaymentFloorMinor: 50000,
  lateFeeBp: lateFeeBp,
  lateFeeFloorMinor: lateFeeFloor,
  interestFromStatement: fromStatement,
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// 10,000.00 bill; statement 2026-06-05, due 2026-06-25, minimum 500.00.
CreditCardBill _bill() => CreditCardBill(
  id: 1,
  profileId: 1,
  cardId: 1,
  billMonth: '2026-06',
  statementDate: '2026-06-05',
  dueDate: '2026-06-25',
  amountMinor: 1000000,
  minPaymentMinor: 50000,
  note: null,
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

CardPayment _pay(int amount, String date, {bool voided = false}) => CardPayment(
  id: 1,
  profileId: 1,
  billId: 1,
  amountMinor: amount,
  paymentDate: date,
  note: null,
  isDeleted: voided,
  createdAt: DateTime(2024),
);

BillStatement _st(
  String asOf, {
  List<CardPayment> pays = const [],
  CreditCard? card,
}) => computeStatement(
  card: card ?? _card(),
  bill: _bill(),
  payments: pays,
  asOf: asOf,
);

void main() {
  group('helpers', () {
    test('minimum payment: floor, percent, cap at the bill', () {
      // 5% of 10,000.00 = 500.00 -> equals floor
      expect(
        minimumPayment(
          billMinor: 1000000,
          minPaymentBp: 500,
          floorMinor: 50000,
        ),
        50000,
      );
      // percent wins over the floor
      expect(
        minimumPayment(
          billMinor: 2000000,
          minPaymentBp: 500,
          floorMinor: 50000,
        ),
        100000,
      );
      // floor wins over a tiny percent
      expect(
        minimumPayment(billMinor: 400000, minPaymentBp: 100, floorMinor: 50000),
        50000,
      );
      // never more than the bill
      expect(
        minimumPayment(billMinor: 30000, minPaymentBp: 500, floorMinor: 50000),
        30000,
      );
    });

    test('statement and due dates', () {
      expect(statementDateFor('2026-06', 5), '2026-06-05');
      expect(dueDateFor('2026-06-05', 20), '2026-06-25');
      expect(dueDateFor('2026-06-28', 20), '2026-07-18');
      expect(dueDateFor('2026-12-28', 10), '2027-01-07');
      expect(daysBetween('2026-06-25', '2026-07-25'), 30);
    });

    test('percent parsing and formatting', () {
      expect(parsePercentToBp('12.5'), 1250);
      expect(parsePercentToBp('24'), 2400);
      expect(parsePercentToBp('2.25%'), 225);
      expect(parsePercentToBp('abc'), isNull);
      expect(parsePercentToBp('1.234'), isNull);
      expect(formatBp(1250), '12.5%');
      expect(formatBp(2400), '24%');
      expect(formatBp(225), '2.25%');
      expect(bpToInput(1250), '12.5');
    });
  });

  group('statement', () {
    test('no interest or fee on or before the due date', () {
      final s = _st('2026-06-25');
      expect(s.interestMinor, 0);
      expect(s.lateFeeMinor, 0);
      expect(s.status, BillStatus.unpaid);
      expect(s.remainingMinor, 1000000);
      expect(s.daysOverdue, 0);
    });

    test('unpaid 30 days after due: interest + fee, overdue', () {
      final s = _st('2026-07-25');
      // 1,000,000 * 24% * 30/365 = 19,726
      expect(s.interestMinor, 19726);
      // max(300.00 floor, 2% of 500.00 = 10.00)
      expect(s.lateFeeMinor, 30000);
      expect(s.totalChargesMinor, 49726);
      expect(s.totalPayableMinor, 1049726);
      expect(s.remainingMinor, 1049726);
      expect(s.status, BillStatus.overdue);
      expect(s.daysOverdue, 30);
      expect(s.extraBp, 497); // +4.97 %
      expect(s.effectiveAnnualBp, 6050);
    });

    test('late fee uses the percentage when it beats the floor', () {
      final s = _st(
        '2026-06-26',
        card: _card(lateFeeBp: 10000, lateFeeFloor: 0),
      );
      // 100% of the unpaid minimum (500.00)
      expect(s.lateFeeMinor, 50000);
    });

    test('paid in full by the due date: zero charges forever', () {
      final pays = [_pay(1000000, '2026-06-24')];
      final s = _st('2026-09-01', pays: pays);
      expect(s.interestMinor, 0);
      expect(s.lateFeeMinor, 0);
      expect(s.status, BillStatus.paid);
      expect(s.remainingMinor, 0);
    });

    test('minimum paid by due: no late fee, interest on the rest', () {
      final s = _st('2026-07-25', pays: [_pay(50000, '2026-06-20')]);
      expect(s.lateFeeMinor, 0);
      expect(s.interestMinor, 18740); // 950,000 * 24% * 30/365
      expect(s.status, BillStatus.minPaid);
      expect(s.remainingMinor, 1000000 + 18740 - 50000);
      expect(s.minDueRemainingMinor, 0);
    });

    test('payment after the due date reduces the balance from that day', () {
      final s = _st('2026-07-25', pays: [_pay(500000, '2026-07-05')]);
      // 10 days on 1,000,000 then 20 days on 500,000
      expect(s.interestMinor, 13151);
      expect(s.lateFeeMinor, 30000); // minimum was not paid by the due date
      expect(s.remainingMinor, 1000000 + 13151 + 30000 - 500000);
      expect(s.status, BillStatus.overdue);
    });

    test('interest stops once the principal is paid', () {
      final early = _st('2026-07-05', pays: [_pay(1000000, '2026-07-05')]);
      final late = _st('2026-09-05', pays: [_pay(1000000, '2026-07-05')]);
      expect(early.interestMinor, 6575);
      expect(late.interestMinor, 6575);
      // fee + interest still owed after the principal is cleared
      expect(late.remainingMinor, 6575 + 30000);
      expect(late.status, BillStatus.overdue);
    });

    test('voided payments and future payments are ignored', () {
      final s = _st(
        '2026-06-20',
        pays: [_pay(100000, '2026-06-10', voided: true), _pay(5, '2026-07-01')],
      );
      expect(s.paidMinor, 0);
      expect(s.status, BillStatus.unpaid);
    });

    test('status before due: partial once something is paid', () {
      expect(
        _st('2026-06-15', pays: [_pay(10000, '2026-06-10')]).status,
        BillStatus.partial,
      );
      expect(
        _st('2026-06-15', pays: [_pay(1000000, '2026-06-10')]).status,
        BillStatus.paid,
      );
    });

    test('interest from statement date once the grace period is lost', () {
      final c = _card(fromStatement: true);
      // still inside the grace window
      expect(_st('2026-06-25', card: c).interestMinor, 0);
      // 50 days from 06-05 to 07-25
      expect(_st('2026-07-25', card: c).interestMinor, 32877);
      // minimum paid by due: balance 950,000 after the payment day
      expect(
        _st(
          '2026-07-25',
          card: c,
          pays: [_pay(50000, '2026-06-20')],
        ).interestMinor,
        31726,
      );
      // paid in full by due: nothing, even with the strict policy
      expect(
        _st(
          '2026-07-25',
          card: c,
          pays: [_pay(1000000, '2026-06-25')],
        ).interestMinor,
        0,
      );
    });

    test('zero APR means no interest', () {
      expect(_st('2026-08-01', card: _card(apr: 0)).interestMinor, 0);
    });
  });

  group('projection', () {
    test('minimum now vs nothing, 30 days after the due date', () {
      final p = projectCharges(
        card: _card(),
        bill: _bill(),
        payments: const [],
        asOf: '2026-06-10',
      );
      expect(p.horizon, '2026-07-25');
      expect(p.minimumMinor, 50000);
      expect(p.chargesIfNothingMinor, 49726);
      // paying the minimum avoids the fee; interest only on the remainder
      expect(p.chargesIfMinimumMinor, 18740);
    });

    test('already past due: horizon is 30 days from today', () {
      final p = projectCharges(
        card: _card(),
        bill: _bill(),
        payments: const [],
        asOf: '2026-07-25',
      );
      expect(p.horizon, '2026-08-24');
      expect(p.chargesIfNothingMinor, greaterThan(49726));
    });
  });
}
