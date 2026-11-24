import 'dart:math' as math;

import '../../../core/utils/date_keys.dart';
import 'loan.dart';

enum InstallmentStatus { paid, partial, due, overdue }

enum LoanStatus { active, overdue, closed }

class LoanInstallment {
  const LoanInstallment({
    required this.no,
    required this.dueDate,
    required this.installmentMinor,
    required this.principalMinor,
    required this.interestMinor,
    required this.balanceAfterMinor,
    this.paidMinor = 0,
    this.status = InstallmentStatus.due,
    this.paidDate,
  });

  final int no;
  final String dueDate;
  final int installmentMinor;
  final int principalMinor;
  final int interestMinor;
  final int balanceAfterMinor;

  /// Part of this installment covered by payments (waterfall).
  final int paidMinor;
  final InstallmentStatus status;

  /// 'yyyy-MM-dd' of the settlement that completed this installment (the
  /// actual payment date, which may differ from [dueDate]); null until paid.
  final String? paidDate;

  int get unpaidMinor => installmentMinor - paidMinor;

  LoanInstallment withPayment(
    int paid,
    InstallmentStatus s, {
    String? paidDate,
  }) => LoanInstallment(
    no: no,
    dueDate: dueDate,
    installmentMinor: installmentMinor,
    principalMinor: principalMinor,
    interestMinor: interestMinor,
    balanceAfterMinor: balanceAfterMinor,
    paidMinor: paid,
    status: s,
    paidDate: paidDate,
  );
}

/// A loan together with its derived schedule and settlement position.
class LoanPosition {
  const LoanPosition({
    required this.loan,
    required this.schedule,
    required this.paidMinor,
    required this.status,
  });

  final Loan loan;

  /// Installments with their waterfall allocation and status.
  final List<LoanInstallment> schedule;

  /// Sum of non-deleted payments.
  final int paidMinor;
  final LoanStatus status;

  int get totalInterestMinor => schedule.fold(0, (s, i) => s + i.interestMinor);
  int get totalPayableMinor =>
      schedule.fold(0, (s, i) => s + i.installmentMinor);

  /// Principal + interest + one-off processing fee.
  int get totalCostMinor => totalPayableMinor + loan.processingFeeMinor;
  int get remainingMinor => totalPayableMinor - paidMinor;

  /// Interest still to be paid in the unpaid installments. What an early
  /// settlement really costs is the lender quote, entered by hand.
  int get remainingInterestMinor {
    var interest = 0;
    for (final i in schedule) {
      if (i.status != InstallmentStatus.paid) interest += i.interestMinor;
    }
    return interest > remainingMinor ? remainingMinor : interest;
  }

  /// Principal still outstanding = remaining - remaining interest.
  int get remainingPrincipalMinor => remainingMinor - remainingInterestMinor;

  int get remainingInstallments =>
      schedule.where((i) => i.status != InstallmentStatus.paid).length;

  bool get isEarlyClosed => loan.closingType == 'early';
  bool get isAdjusted => loan.closingType == 'adjusted';

  /// 0.0 .. 1.0
  double get progress =>
      totalPayableMinor <= 0 ? 0 : (paidMinor / totalPayableMinor).clamp(0, 1);

  LoanInstallment? get nextDue {
    for (final i in schedule) {
      if (i.status != InstallmentStatus.paid) return i;
    }
    return null;
  }

  Iterable<LoanInstallment> get _overdue =>
      schedule.where((i) => i.status == InstallmentStatus.overdue);
  int get overdueCount => _overdue.length;
  int get overdueMinor => _overdue.fold(0, (s, i) => s + i.unpaidMinor);
  bool get isClosed => status == LoanStatus.closed;
}

/// Pure loan arithmetic. Money stays in integer minor units; doubles are used
/// only inside the interest formulas and every result is rounded to an int.
class LoanCalculator {
  const LoanCalculator._();

  static int periodsPerYear(String frequency) => switch (frequency) {
    'weekly' => 52,
    'yearly' => 1,
    _ => 12,
  };

  static double _periodRate(int rateBp, String frequency) =>
      rateBp / 10000 / periodsPerYear(frequency);

  /// Fixed installment for the given terms.
  static int computeInstallment({
    required int principalMinor,
    required int rateBp,
    required String method,
    required String frequency,
    required int count,
  }) {
    if (principalMinor <= 0 || count <= 0) return 0;
    if (method == 'flat') {
      final interest = _flatInterest(principalMinor, rateBp, frequency, count);
      return ((principalMinor + interest) / count).round();
    }
    final r = _periodRate(rateBp, frequency);
    if (r == 0) return (principalMinor / count).round();
    final emi = principalMinor * r / (1 - math.pow(1 + r, -count));
    return emi.round();
  }

  static int _flatInterest(
    int principalMinor,
    int rateBp,
    String frequency,
    int count,
  ) => (principalMinor * (rateBp / 10000) * count / periodsPerYear(frequency))
      .round();

  /// Due date of installment [index] (0-based) counted from [firstDue].
  /// Monthly/yearly dates stay anchored on the first due day (clamped to the
  /// month end) so they never drift (31 Jan -> 28 Feb -> 31 Mar).
  static String dueDateAt(String firstDue, String frequency, int index) {
    final first = parseDateKey(firstDue);
    switch (frequency) {
      case 'weekly':
        return dateKey(
          DateTime(first.year, first.month, first.day + 7 * index),
        );
      case 'yearly':
        final y = first.year + index;
        final d = math.min(first.day, daysInMonth(y, first.month));
        return dateKey(DateTime(y, first.month, d));
      default:
        final total = first.month - 1 + index;
        final y = first.year + total ~/ 12;
        final m = total % 12 + 1;
        final d = math.min(first.day, daysInMonth(y, m));
        return dateKey(DateTime(y, m, d));
    }
  }

  /// Repayment schedule (without payment allocation). The first
  /// `count - 1` installments equal [installmentMinor] (their split between
  /// interest and principal follows the method); the last one clears the exact
  /// remaining balance, so principal always sums to [principalMinor].
  static List<LoanInstallment> buildSchedule({
    required int principalMinor,
    required int rateBp,
    required String method,
    required String frequency,
    required int count,
    required int installmentMinor,
    required String firstDueDate,
  }) {
    final out = <LoanInstallment>[];
    final r = _periodRate(rateBp, frequency);
    final flatTotal = method == 'flat'
        ? _flatInterest(principalMinor, rateBp, frequency, count)
        : 0;
    var balance = principalMinor;
    for (var i = 1; i <= count && balance > 0; i++) {
      final int interest;
      if (method == 'flat') {
        // Even split of the total interest; rounding drift cancels out.
        interest =
            (flatTotal * i / count).round() -
            (flatTotal * (i - 1) / count).round();
      } else {
        interest = (balance * r).round();
      }
      int principal;
      if (i == count) {
        principal = balance;
      } else {
        principal = math.min(math.max(installmentMinor - interest, 0), balance);
      }
      balance -= principal;
      out.add(
        LoanInstallment(
          no: i,
          dueDate: dueDateAt(firstDueDate, frequency, i - 1),
          installmentMinor: principal + interest,
          principalMinor: principal,
          interestMinor: interest,
          balanceAfterMinor: balance,
        ),
      );
    }
    return out;
  }

  /// Applies [paidMinor] as a waterfall over [schedule] and classifies each
  /// installment. [today] is 'yyyy-MM-dd'.
  ///
  /// [payments] (non-deleted, ordered by date then id) only supplies the
  /// settlement date of each fully paid installment: it is the date of the
  /// payment that brought the running total up to that installment.
  static List<LoanInstallment> allocate(
    List<LoanInstallment> schedule,
    int paidMinor,
    String today, {
    List<({String date, int amount})> payments = const [],
  }) {
    var left = paidMinor;
    var target = 0;
    var running = 0;
    var pi = 0;
    final out = <LoanInstallment>[];
    for (final i in schedule) {
      target += i.installmentMinor;
      final covered = math.min(left, i.installmentMinor);
      left -= covered;
      final InstallmentStatus s;
      if (covered >= i.installmentMinor) {
        s = InstallmentStatus.paid;
      } else if (i.dueDate.compareTo(today) < 0) {
        s = InstallmentStatus.overdue;
      } else if (covered > 0) {
        s = InstallmentStatus.partial;
      } else {
        s = InstallmentStatus.due;
      }
      String? paidDate;
      if (s == InstallmentStatus.paid) {
        while (running < target && pi < payments.length) {
          running += payments[pi].amount;
          pi++;
        }
        if (pi > 0 && running >= target) paidDate = payments[pi - 1].date;
      }
      out.add(i.withPayment(covered, s, paidDate: paidDate));
    }
    return out;
  }

  /// Full derived position of [loan] given the non-deleted payments total.
  static LoanPosition evaluate(
    Loan loan,
    int paidMinor,
    String today, {
    List<({String date, int amount})> payments = const [],
  }) {
    final base = buildSchedule(
      principalMinor: loan.principalMinor,
      rateBp: loan.interestRateBp,
      method: loan.interestMethod,
      frequency: loan.frequency,
      count: loan.tenureCount,
      installmentMinor: loan.installmentMinor,
      firstDueDate: loan.firstDueDate,
    );
    final schedule = allocate(base, paidMinor, today, payments: payments);
    final total = schedule.fold<int>(0, (s, i) => s + i.installmentMinor);
    final status = (paidMinor >= total || loan.closingType != null)
        ? LoanStatus.closed
        : schedule.any((i) => i.status == InstallmentStatus.overdue)
        ? LoanStatus.overdue
        : LoanStatus.active;
    return LoanPosition(
      loan: loan,
      schedule: schedule,
      paidMinor: paidMinor,
      status: status,
    );
  }

  /// Installment amount normalised to one month (for "monthly commitment").
  static int monthlyEquivalent(int installmentMinor, String frequency) =>
      switch (frequency) {
        'weekly' => (installmentMinor * 52 / 12).round(),
        'yearly' => (installmentMinor / 12).round(),
        _ => installmentMinor,
      };
}
