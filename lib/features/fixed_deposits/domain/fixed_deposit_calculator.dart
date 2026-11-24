import '../../../core/utils/date_keys.dart';
import 'fixed_deposit.dart';

/// Pure deposit-scheme maths. Like MegaFeed, maturity = start date + tenure
/// days and the interest actually earned is entered by the user when the
/// instrument is closed; [suggestedInterest] only pre-fills that field.
class FixedDepositCalculator {
  const FixedDepositCalculator._();

  /// Adds days to a 'yyyy-MM-dd' key.
  static String addDays(String key, int days) {
    final d = parseDateKey(key);
    return dateKey(DateTime(d.year, d.month, d.day + days));
  }

  static String maturityDate(String startDate, int tenureDays) =>
      addDays(startDate, tenureDays);

  /// Tenure in months (30 days = 1 month), one decimal.
  static double tenureMonths(int tenureDays) =>
      (tenureDays / fdDaysPerMonth * 10).round() / 10;

  /// Simple interest (principal x rate x days / 365), rounded to a paisa.
  static int suggestedInterest({
    required int principalMinor,
    required int rateBp,
    required int days,
  }) => (principalMinor * rateBp * days / (365 * 10000)).round();

  /// principal + interest - tax - bank charge.
  static int calculatedNet({
    required int principalMinor,
    required int interestMinor,
    required int taxMinor,
    required int bankChargeMinor,
  }) => principalMinor + interestMinor - taxMinor - bankChargeMinor;

  /// Whole days between two date keys (negative when [to] is earlier).
  static int daysBetween(String from, String to) =>
      parseDateKey(to).difference(parseDateKey(from)).inDays;
}

/// A deposit with its instrument chain and derived status.
class FixedDepositPosition {
  const FixedDepositPosition({
    required this.deposit,
    required this.terms,
    required this.today,
  });

  final FixedDeposit deposit;

  /// Ordered by term number (oldest first).
  final List<FixedDepositTerm> terms;
  final String today;

  FixedDepositTerm get current => terms.last;

  String get maturityDate => FixedDepositCalculator.maturityDate(
    current.startDate,
    current.tenureDays,
  );

  /// Interest the app would suggest for the running instrument.
  int get expectedInterestMinor => FixedDepositCalculator.suggestedInterest(
    principalMinor: current.principalMinor,
    rateBp: current.rateBp,
    days: current.tenureDays,
  );

  FdStatus get status {
    if (!current.isActive) return FdStatus.closed;
    return maturityDate.compareTo(today) <= 0
        ? FdStatus.matured
        : FdStatus.active;
  }

  /// Days until the running instrument matures (negative once matured); null
  /// when the deposit is closed.
  int? get daysToMaturity => current.isActive
      ? FixedDepositCalculator.daysBetween(today, maturityDate)
      : null;

  int get reissueCount => terms.where((t) => t.isReissue).length;

  /// Principal of the running instrument, 0 once closed.
  int get placedMinor => current.isActive ? current.principalMinor : 0;

  /// Interest recorded on the closed instruments of this deposit.
  int get earnedInterestMinor =>
      terms.fold(0, (s, t) => s + (t.interestMinor ?? 0));
}

/// Totals over the non-archived, not-closed deposits of a profile.
class FixedDepositSummary {
  const FixedDepositSummary({
    required this.openCount,
    required this.maturedCount,
    required this.placedMinor,
    required this.expectedInterestMinor,
    required this.earnedInterestMinor,
    required this.nextMaturityDate,
    required this.nextMaturityPrincipalMinor,
  });

  static const empty = FixedDepositSummary(
    openCount: 0,
    maturedCount: 0,
    placedMinor: 0,
    expectedInterestMinor: 0,
    earnedInterestMinor: 0,
    nextMaturityDate: null,
    nextMaturityPrincipalMinor: 0,
  );

  final int openCount;
  final int maturedCount;
  final int placedMinor;

  /// Suggested (not yet received) interest of the open instruments.
  final int expectedInterestMinor;

  /// Interest already recorded on closed instruments of the open deposits.
  final int earnedInterestMinor;
  final String? nextMaturityDate;
  final int nextMaturityPrincipalMinor;

  static FixedDepositSummary of(List<FixedDepositPosition> positions) {
    var open = 0, matured = 0, placed = 0, expected = 0, earned = 0, nextP = 0;
    String? next;
    for (final p in positions) {
      if (!p.deposit.isActive || p.status == FdStatus.closed) continue;
      open++;
      if (p.status == FdStatus.matured) matured++;
      placed += p.placedMinor;
      expected += p.expectedInterestMinor;
      earned += p.earnedInterestMinor;
      if (next == null || p.maturityDate.compareTo(next) < 0) {
        next = p.maturityDate;
        nextP = p.placedMinor;
      }
    }
    return FixedDepositSummary(
      openCount: open,
      maturedCount: matured,
      placedMinor: placed,
      expectedInterestMinor: expected,
      earnedInterestMinor: earned,
      nextMaturityDate: next,
      nextMaturityPrincipalMinor: nextP,
    );
  }
}
