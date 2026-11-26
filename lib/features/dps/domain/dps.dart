import 'dart:math';

import '../../../core/utils/date_keys.dart';

/// How a DPS ended.
enum DpsClosingType {
  matured('matured'),
  premature('premature'),
  bankClosed('bank_closed');

  const DpsClosingType(this.code);

  /// Stored value.
  final String code;

  static DpsClosingType? parse(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

enum DpsStatus {
  /// Nothing is overdue.
  active,

  /// At least one installment is past its grace period.
  overdue,

  /// Overdue installments reached the bank's missed limit.
  atRisk,

  /// All installments paid and the maturity date has come.
  matured,
  closed,
}

enum DpsInstallmentStatus { paid, overdue, due, upcoming }

/// The terms the user entered. Money is integer minor units, rates basis
/// points.
class DpsTerms {
  const DpsTerms({
    required this.bankName,
    this.accountNumber,
    required this.installmentMinor,
    required this.tenureMonths,
    required this.openDate,
    required this.firstDueDate,
    required this.rateBp,
    this.bankMaturityMinor,
    this.taxRateBp = 1000,
    this.lateFeeMinor = 0,
    this.graceDays = 0,
    this.missedLimit = 3,
    this.note,
  });

  final String bankName;
  final String? accountNumber;
  final int installmentMinor;
  final int tenureMonths;
  final String openDate;
  final String firstDueDate;
  final int rateBp;
  final int? bankMaturityMinor;
  final int taxRateBp;
  final int lateFeeMinor;
  final int graceDays;
  final int missedLimit;
  final String? note;
}

class DpsAccount {
  const DpsAccount({
    required this.id,
    required this.profileId,
    required this.terms,
    required this.isActive,
    this.closingType,
    this.closedDate,
    this.profitMinor,
    this.taxMinor,
    this.chargeMinor,
    this.netReceivedMinor,
  });

  final int id;
  final int profileId;
  final DpsTerms terms;

  /// False when archived.
  final bool isActive;
  final DpsClosingType? closingType;
  final String? closedDate;
  final int? profitMinor;
  final int? taxMinor;
  final int? chargeMinor;
  final int? netReceivedMinor;
}

class DpsPayment {
  const DpsPayment({
    required this.id,
    required this.dpsId,
    required this.installments,
    required this.lateFeeMinor,
    required this.paymentDate,
    required this.isDeleted,
    this.note,
  });

  final int id;
  final int dpsId;
  final int installments;
  final int lateFeeMinor;
  final String paymentDate;
  final bool isDeleted;
  final String? note;
}

class DpsInstallment {
  const DpsInstallment({
    required this.no,
    required this.dueDate,
    required this.status,
    this.paidDate,
  });

  /// 1-based.
  final int no;
  final String dueDate;
  final DpsInstallmentStatus status;
  final String? paidDate;
}

/// An account with everything derived from its terms and payments.
class DpsPosition {
  const DpsPosition({
    required this.account,
    required this.schedule,
    required this.paidCount,
    required this.lateFeesPaidMinor,
    required this.status,
    required this.maturityDate,
    required this.estimatedMaturityMinor,
  });

  final DpsAccount account;
  final List<DpsInstallment> schedule;
  final int paidCount;
  final int lateFeesPaidMinor;
  final DpsStatus status;
  final String maturityDate;

  /// The app's own estimate (see [DpsCalculator.estimatedMaturity]).
  final int estimatedMaturityMinor;

  DpsTerms get terms => account.terms;
  bool get isClosed => status == DpsStatus.closed;
  int get depositedMinor => paidCount * terms.installmentMinor;
  int get totalDepositMinor => terms.tenureMonths * terms.installmentMinor;
  int get remainingCount => terms.tenureMonths - paidCount;

  /// The bank's figure when entered, otherwise the estimate. Before tax.
  int get maturityMinor => terms.bankMaturityMinor ?? estimatedMaturityMinor;
  int get expectedProfitMinor => max(0, maturityMinor - totalDepositMinor);
  int get expectedTaxMinor =>
      DpsCalculator.taxOn(expectedProfitMinor, terms.taxRateBp);

  /// After tax on profit only. Excise duty and bank charges are not known.
  int get expectedNetMinor => maturityMinor - expectedTaxMinor;

  int get overdueCount =>
      schedule.where((i) => i.status == DpsInstallmentStatus.overdue).length;
  int get overdueMinor => overdueCount * terms.installmentMinor;

  /// One more missed installment reaches the bank's limit.
  bool get isOneMissFromLimit =>
      terms.missedLimit > 1 && overdueCount == terms.missedLimit - 1;

  /// Oldest unpaid installment; null when all are paid.
  DpsInstallment? get nextDue =>
      paidCount >= schedule.length ? null : schedule[paidCount];

  double get progress => paidCount / terms.tenureMonths;

  /// Late fee the bank's rule gives for paying [installments] on [date].
  int suggestedLateFee(int installments, String date) {
    var late = 0;
    for (final i in schedule.skip(paidCount).take(installments)) {
      if (date.compareTo(DpsCalculator.graceEnd(i.dueDate, terms.graceDays)) >
          0) {
        late++;
      }
    }
    return late * terms.lateFeeMinor;
  }
}

/// Pure DPS arithmetic.
class DpsCalculator {
  const DpsCalculator._();

  /// [first] plus [months] months, keeping its day of month where the month is
  /// long enough (31 Jan, 28 Feb, 31 Mar).
  static String addMonths(String first, int months) {
    final d = parseDateKey(first);
    final month = DateTime(d.year, d.month + months);
    final last = daysInMonth(month.year, month.month);
    return dateKey(
      DateTime(month.year, month.month, d.day > last ? last : d.day),
    );
  }

  static String graceEnd(String dueDate, int graceDays) {
    final d = parseDateKey(dueDate);
    return dateKey(DateTime(d.year, d.month, d.day + graceDays));
  }

  /// One month after the last installment.
  static String maturityDate(String firstDueDate, int tenureMonths) =>
      addMonths(firstDueDate, tenureMonths);

  /// Value before tax when every installment is paid on time and profit is
  /// added monthly: each installment earns rate/12 for every month it stays.
  /// Banks round and compound in their own way, so this is only a guide.
  static int estimatedMaturity({
    required int installmentMinor,
    required int tenureMonths,
    required int rateBp,
  }) {
    if (rateBp == 0) return installmentMinor * tenureMonths;
    final r = rateBp / 10000 / 12;
    final factor = (pow(1 + r, tenureMonths) - 1) / r * (1 + r);
    return (installmentMinor * factor).round();
  }

  /// Rounded half up.
  static int taxOn(int profitMinor, int taxRateBp) =>
      (profitMinor * taxRateBp + 5000) ~/ 10000;

  static DpsPosition position({
    required DpsAccount account,
    required List<DpsPayment> payments,
    required String today,
  }) {
    final t = account.terms;
    final live = payments.where((p) => !p.isDeleted).toList()
      ..sort((a, b) {
        final c = a.paymentDate.compareTo(b.paymentDate);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    // Installments are settled oldest first.
    final paidDates = [
      for (final p in live)
        for (var i = 0; i < p.installments; i++) p.paymentDate,
    ];
    final paid = min(paidDates.length, t.tenureMonths);
    final closed = account.closingType != null;

    final schedule = <DpsInstallment>[];
    for (var i = 0; i < t.tenureMonths; i++) {
      final due = addMonths(t.firstDueDate, i);
      final DpsInstallmentStatus status;
      if (i < paid) {
        status = DpsInstallmentStatus.paid;
      } else if (!closed && today.compareTo(graceEnd(due, t.graceDays)) > 0) {
        status = DpsInstallmentStatus.overdue;
      } else if (!closed && today.compareTo(due) >= 0) {
        status = DpsInstallmentStatus.due;
      } else {
        status = DpsInstallmentStatus.upcoming;
      }
      schedule.add(
        DpsInstallment(
          no: i + 1,
          dueDate: due,
          status: status,
          paidDate: i < paid ? paidDates[i] : null,
        ),
      );
    }

    final maturity = maturityDate(t.firstDueDate, t.tenureMonths);
    final overdue = schedule
        .where((i) => i.status == DpsInstallmentStatus.overdue)
        .length;
    final DpsStatus status;
    if (closed) {
      status = DpsStatus.closed;
    } else if (paid == t.tenureMonths && today.compareTo(maturity) >= 0) {
      status = DpsStatus.matured;
    } else if (t.missedLimit > 0 && overdue >= t.missedLimit) {
      status = DpsStatus.atRisk;
    } else if (overdue > 0) {
      status = DpsStatus.overdue;
    } else {
      status = DpsStatus.active;
    }

    return DpsPosition(
      account: account,
      schedule: schedule,
      paidCount: paid,
      lateFeesPaidMinor: live.fold(0, (s, p) => s + p.lateFeeMinor),
      status: status,
      maturityDate: maturity,
      estimatedMaturityMinor: estimatedMaturity(
        installmentMinor: t.installmentMinor,
        tenureMonths: t.tenureMonths,
        rateBp: t.rateBp,
      ),
    );
  }
}
