import '../../../l10n/l10n.dart';

/// A credit card with the bank's billing policy.
class CreditCard {
  const CreditCard({
    required this.id,
    required this.profileId,
    required this.name,
    required this.bankName,
    required this.lastFour,
    required this.creditLimitMinor,
    required this.statementDay,
    required this.dueDays,
    required this.aprBp,
    required this.minPaymentBp,
    required this.minPaymentFloorMinor,
    required this.lateFeeBp,
    required this.lateFeeFloorMinor,
    required this.interestFromStatement,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String name;
  final String bankName;
  final String? lastFour;
  final int creditLimitMinor;

  /// 1-28.
  final int statementDay;

  /// Due date = statement date + [dueDays].
  final int dueDays;

  /// Annual interest rate in basis points.
  final int aprBp;
  final int minPaymentBp;
  final int minPaymentFloorMinor;
  final int lateFeeBp;
  final int lateFeeFloorMinor;
  final bool interestFromStatement;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// One monthly statement: the NEW charges of that cycle.
class CreditCardBill {
  const CreditCardBill({
    required this.id,
    required this.profileId,
    required this.cardId,
    required this.billMonth,
    required this.statementDate,
    required this.dueDate,
    required this.amountMinor,
    required this.minPaymentMinor,
    required this.note,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final int cardId;

  /// 'yyyy-MM'
  final String billMonth;
  final String statementDate;
  final String dueDate;
  final int amountMinor;
  final int minPaymentMinor;
  final String? note;

  /// false = voided (kept for history).
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CardPayment {
  const CardPayment({
    required this.id,
    required this.profileId,
    required this.billId,
    required this.amountMinor,
    required this.paymentDate,
    required this.note,
    required this.isDeleted,
    required this.createdAt,
  });

  final int id;
  final int profileId;
  final int billId;
  final int amountMinor;
  final String paymentDate;
  final String? note;
  final bool isDeleted;
  final DateTime createdAt;
}

enum BillStatus { paid, unpaid, partial, minPaid, overdue }

String billStatusLabel(AppLocalizations l, BillStatus s) => switch (s) {
  BillStatus.paid => l.creditCardsStatusPaid,
  BillStatus.unpaid => l.creditCardsStatusUnpaid,
  BillStatus.partial => l.creditCardsStatusPartial,
  BillStatus.minPaid => l.creditCardsStatusMinPaid,
  BillStatus.overdue => l.creditCardsStatusOverdue,
};

/// A bill with everything derived at a given date (never stored).
class BillStatement {
  const BillStatement({
    required this.bill,
    required this.asOf,
    required this.paidMinor,
    required this.interestMinor,
    required this.lateFeeMinor,
    required this.status,
    required this.daysOverdue,
    required this.effectiveAnnualBp,
  });

  final CreditCardBill bill;

  /// 'yyyy-MM-dd' the figures are computed for.
  final String asOf;

  /// Sum of non-voided payments dated on/before [asOf].
  final int paidMinor;
  final int interestMinor;
  final int lateFeeMinor;
  final BillStatus status;
  final int daysOverdue;

  /// Interest + fees annualised over the days since interest started
  /// (basis points); 0 when no charges.
  final int effectiveAnnualBp;

  int get amountMinor => bill.amountMinor;
  int get minPaymentMinor => bill.minPaymentMinor;
  int get totalChargesMinor => interestMinor + lateFeeMinor;
  int get totalPayableMinor => amountMinor + totalChargesMinor;

  /// Still to pay (payments cover the bill first, then the charges).
  int get remainingMinor {
    final r = totalPayableMinor - paidMinor;
    return r < 0 ? 0 : r;
  }

  int get remainingPrincipalMinor {
    final r = amountMinor - paidMinor;
    return r < 0 ? 0 : r;
  }

  /// What is still missing to reach the minimum payment.
  int get minDueRemainingMinor {
    final r = minPaymentMinor - paidMinor;
    return r < 0 ? 0 : r;
  }

  /// Charges as basis points of the bill amount (1250 = "+12.5 %").
  int get extraBp => amountMinor == 0
      ? 0
      : (totalChargesMinor * 10000 + amountMinor ~/ 2) ~/ amountMinor;
  int get interestBp => amountMinor == 0
      ? 0
      : (interestMinor * 10000 + amountMinor ~/ 2) ~/ amountMinor;
  int get lateFeeBp => amountMinor == 0
      ? 0
      : (lateFeeMinor * 10000 + amountMinor ~/ 2) ~/ amountMinor;

  bool get isSettled => status == BillStatus.paid;
}

/// Extra charges expected by [horizon] under two payment behaviours.
class BillProjection {
  const BillProjection({
    required this.horizon,
    required this.chargesIfNothingMinor,
    required this.chargesIfMinimumMinor,
    required this.minimumMinor,
  });

  /// 'yyyy-MM-dd': 30 days after the later of today and the due date.
  final String horizon;

  /// Total interest + fee on the bill at [horizon] if nothing more is paid.
  final int chargesIfNothingMinor;

  /// Same, if only [minimumMinor] (the missing minimum) is paid today.
  final int chargesIfMinimumMinor;
  final int minimumMinor;
}

/// A card plus its totals as of a date.
class CardSummary {
  const CardSummary({
    required this.card,
    required this.outstandingMinor,
    required this.overdueCount,
    required this.unsettledBillCount,
    required this.chargesMinor,
    required this.nextDue,
  });

  final CreditCard card;

  /// Sum of remaining over active bills.
  final int outstandingMinor;
  final int overdueCount;
  final int unsettledBillCount;

  /// Interest + fees currently added across active bills.
  final int chargesMinor;

  /// Unsettled bill with the earliest due date (may be overdue).
  final BillStatement? nextDue;

  /// May be negative when over the limit.
  int get availableMinor => card.creditLimitMinor - outstandingMinor;
  int get utilisationBp => card.creditLimitMinor == 0
      ? 0
      : (outstandingMinor * 10000) ~/ card.creditLimitMinor;
}

class DueBill {
  const DueBill({required this.cardName, required this.statement});
  final String cardName;
  final BillStatement statement;
}

class OverallCardSummary {
  const OverallCardSummary({
    required this.cardCount,
    required this.totalOutstandingMinor,
    required this.totalLimitMinor,
    required this.overdueCount,
    required this.nextDue,
  });

  static const empty = OverallCardSummary(
    cardCount: 0,
    totalOutstandingMinor: 0,
    totalLimitMinor: 0,
    overdueCount: 0,
    nextDue: null,
  );

  final int cardCount;
  final int totalOutstandingMinor;
  final int totalLimitMinor;
  final int overdueCount;
  final DueBill? nextDue;

  int get availableMinor => totalLimitMinor - totalOutstandingMinor;
  int get utilisationBp => totalLimitMinor == 0
      ? 0
      : (totalOutstandingMinor * 10000) ~/ totalLimitMinor;
}
