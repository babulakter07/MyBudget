import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/fixed_deposits/domain/fixed_deposit.dart';
import 'package:my_budget/features/fixed_deposits/domain/fixed_deposit_calculator.dart';

FixedDepositTerm term({
  String start = '2026-01-15',
  int days = 365,
  int rate = 1000,
  int principal = 100000000,
  String outcome = 'active',
  int? interest,
  int? renewedFrom,
}) => FixedDepositTerm(
  id: 1,
  profileId: 1,
  depositId: 1,
  termNo: 1,
  instrumentNumber: 'FDR-1',
  startDate: start,
  tenureDays: days,
  rateBp: rate,
  principalMinor: principal,
  outcome: outcome,
  settledDate: outcome == 'active' ? null : '2027-01-15',
  interestMinor: interest,
  taxMinor: interest == null ? null : 0,
  bankChargeMinor: interest == null ? null : 0,
  netReceivedMinor: interest == null ? null : principal + interest,
  renewedFromTermId: renewedFrom,
  note: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

FixedDepositPosition pos(String today, List<FixedDepositTerm> terms) =>
    FixedDepositPosition(
      deposit: FixedDeposit(
        id: 1,
        profileId: 1,
        schemeType: 'FDR',
        bankName: 'B',
        beneficiaryName: null,
        note: null,
        isActive: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      terms: terms,
      today: today,
    );

void main() {
  group('dates and amounts', () {
    test('maturity = start + tenure days', () {
      expect(
        FixedDepositCalculator.maturityDate('2026-01-15', 365),
        '2027-01-15',
      );
      expect(
        FixedDepositCalculator.maturityDate('2028-02-28', 2),
        '2028-03-01',
      );
      expect(
        FixedDepositCalculator.maturityDate('2026-12-31', 1),
        '2027-01-01',
      );
    });

    test('30 days = 1 month', () {
      expect(FixedDepositCalculator.tenureMonths(180), 6.0);
      expect(FixedDepositCalculator.tenureMonths(365), 12.2);
    });

    test('suggested interest is simple interest on 365 days', () {
      // 10,00,000.00 at 10% for 365 days = 1,00,000.00
      expect(
        FixedDepositCalculator.suggestedInterest(
          principalMinor: 100000000,
          rateBp: 1000,
          days: 365,
        ),
        10000000,
      );
      expect(
        FixedDepositCalculator.suggestedInterest(
          principalMinor: 100000000,
          rateBp: 1000,
          days: 0,
        ),
        0,
      );
    });

    test('calculated net', () {
      expect(
        FixedDepositCalculator.calculatedNet(
          principalMinor: 100000000,
          interestMinor: 10000000,
          taxMinor: 1000000,
          bankChargeMinor: 50000,
        ),
        108950000,
      );
    });
  });

  group('position', () {
    test('status flips to matured on the maturity date', () {
      final t = [term()];
      expect(pos('2027-01-14', t).status, FdStatus.active);
      expect(pos('2027-01-15', t).status, FdStatus.matured);
      expect(pos('2027-01-14', t).daysToMaturity, 1);
      expect(pos('2027-02-01', t).daysToMaturity, -17);
    });

    test('closed deposit has no placed money', () {
      final p = pos('2027-02-01', [term(outcome: 'encashed', interest: 1)]);
      expect(p.status, FdStatus.closed);
      expect(p.placedMinor, 0);
      expect(p.daysToMaturity, isNull);
    });

    test('reissue chain counts and sums interest', () {
      final p = pos('2027-06-01', [
        term(outcome: 'reissued', interest: 9000000),
        term(renewedFrom: 1),
      ]);
      expect(p.reissueCount, 1);
      expect(p.earnedInterestMinor, 9000000);
      expect(p.current.isReissue, isTrue);
      expect(p.status, FdStatus.matured);
    });

    test('summary counts open and matured deposits', () {
      final s = FixedDepositSummary.of([
        pos('2026-06-01', [term()]),
        pos('2027-02-01', [term()]),
        pos('2027-02-01', [term(outcome: 'encashed', interest: 1)]),
      ]);
      expect(s.openCount, 2);
      expect(s.maturedCount, 1);
      expect(s.placedMinor, 200000000);
      expect(s.expectedInterestMinor, 20000000);
      expect(s.nextMaturityDate, '2027-01-15');
    });
  });
}
