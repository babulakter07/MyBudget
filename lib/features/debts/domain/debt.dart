import '../../../l10n/l10n.dart';

const debtDirections = ['lent', 'borrowed'];

enum DebtStatus { open, overdue, settled }

/// A loan ledger entry. Outstanding is computed at query time.
class Debt {
  const Debt({
    required this.id,
    required this.profileId,
    required this.direction,
    required this.personName,
    required this.principalMinor,
    required this.paidMinor,
    required this.startDate,
    required this.dueDate,
    required this.note,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;

  /// 'lent' (they owe me) | 'borrowed' (I owe them)
  final String direction;
  final String personName;
  final int principalMinor;
  final int paidMinor;
  final String startDate;
  final String? dueDate;
  final String? note;
  final bool isActive;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get outstandingMinor => principalMinor - paidMinor;
  bool get isLent => direction == 'lent';
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.profileId,
    required this.debtId,
    required this.amountMinor,
    required this.paymentDate,
    required this.note,
    required this.isDeleted,
    required this.createdAt,
  });

  final int id;
  final int profileId;
  final int debtId;
  final int amountMinor;
  final String paymentDate;
  final String? note;
  final bool isDeleted;
  final DateTime createdAt;
}

/// Outstanding per person (case-insensitive grouping).
class PersonBalance {
  const PersonBalance({
    required this.personName,
    required this.lentOutstandingMinor,
    required this.borrowedOutstandingMinor,
    required this.debtCount,
  });

  /// Display name (one of the spellings used).
  final String personName;
  final int lentOutstandingMinor;
  final int borrowedOutstandingMinor;
  final int debtCount;

  /// Positive: they owe me net.
  int get netMinor => lentOutstandingMinor - borrowedOutstandingMinor;
}

class DebtSummary {
  const DebtSummary({
    required this.owedToMeMinor,
    required this.iOweMinor,
    required this.overdueCount,
    required this.people,
    this.activeCount = 0,
  });

  static const empty = DebtSummary(
    owedToMeMinor: 0,
    iOweMinor: 0,
    overdueCount: 0,
    people: [],
  );

  final int owedToMeMinor;
  final int iOweMinor;
  final int overdueCount;
  final List<PersonBalance> people;

  /// Number of non-archived debts (including settled).
  final int activeCount;

  int get netMinor => owedToMeMinor - iOweMinor;
}

String debtStatusLabel(AppLocalizations l, DebtStatus s) => switch (s) {
  DebtStatus.open => l.debtsStatusOpen,
  DebtStatus.overdue => l.debtsStatusOverdue,
  DebtStatus.settled => l.debtsStatusSettled,
};
