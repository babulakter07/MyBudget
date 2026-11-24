import '../../../l10n/l10n.dart';

const loanTypes = [
  'personal',
  'home',
  'vehicle',
  'education',
  'business',
  'other',
];
const loanFrequencies = ['weekly', 'monthly', 'yearly'];
const loanMethods = ['reducing', 'flat'];

String loanTypeLabel(AppLocalizations l, String type) => switch (type) {
  'personal' => l.loansTypePersonal,
  'home' => l.loansTypeHome,
  'vehicle' => l.loansTypeVehicle,
  'education' => l.loansTypeEducation,
  'business' => l.loansTypeBusiness,
  _ => l.loansTypeOther,
};

String loanFrequencyLabel(AppLocalizations l, String f) => switch (f) {
  'weekly' => l.loansFreqWeekly,
  'yearly' => l.loansFreqYearly,
  _ => l.loansFreqMonthly,
};

String loanMethodLabel(AppLocalizations l, String m) =>
    m == 'flat' ? l.loansMethodFlat : l.loansMethodReducing;

/// "৳8,884.88 / month" style text.
String loanPerPeriod(AppLocalizations l, String frequency, String amount) =>
    switch (frequency) {
      'weekly' => l.loansPerWeek(amount),
      'yearly' => l.loansPerYear(amount),
      _ => l.loansPerMonth(amount),
    };

/// The stored loan parameters. Everything else (schedule, remaining, status)
/// is derived at query time by [LoanCalculator].
class Loan {
  const Loan({
    required this.id,
    required this.profileId,
    required this.lenderName,
    required this.loanType,
    required this.referenceNo,
    required this.principalMinor,
    required this.interestRateBp,
    required this.interestMethod,
    required this.frequency,
    required this.tenureCount,
    required this.installmentMinor,
    required this.processingFeeMinor,
    required this.startDate,
    required this.firstDueDate,
    required this.note,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.closingType,
    this.closedDate,
    this.closingRemarks,
    this.closingPaidMinor,
    this.parentLoanId,
  });

  final int id;
  final int profileId;
  final String lenderName;
  final String loanType;
  final String? referenceNo;
  final int principalMinor;

  /// Annual rate in basis points (1150 = 11.50 %).
  final int interestRateBp;
  final String interestMethod;
  final String frequency;
  final int tenureCount;
  final int installmentMinor;
  final int processingFeeMinor;
  final String startDate;
  final String firstDueDate;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 'early' (settled before the schedule ended) | 'adjusted' (rolled into a
  /// newer loan) | null. A closed loan is history: no edits, no payments.
  final String? closingType;
  final String? closedDate;
  final String? closingRemarks;

  /// Amount paid to settle an early closure (recorded as a payment too).
  final int? closingPaidMinor;

  /// The loan this one replaced (adjustment / top-up).
  final int? parentLoanId;

  bool get isClosedByUser => closingType != null;
}

class LoanPayment {
  const LoanPayment({
    required this.id,
    required this.profileId,
    required this.loanId,
    required this.amountMinor,
    required this.paymentDate,
    required this.note,
    required this.isDeleted,
    required this.createdAt,
  });

  final int id;
  final int profileId;
  final int loanId;
  final int amountMinor;
  final String paymentDate;
  final String? note;
  final bool isDeleted;
  final DateTime createdAt;
}

/// Totals over the active (non-archived) loans of a profile.
class LoanSummary {
  const LoanSummary({
    required this.remainingMinor,
    required this.overdueMinor,
    required this.overdueCount,
    required this.activeCount,
    required this.monthlyCommitmentMinor,
    required this.nextDueDate,
    required this.nextDueMinor,
  });

  static const empty = LoanSummary(
    remainingMinor: 0,
    overdueMinor: 0,
    overdueCount: 0,
    activeCount: 0,
    monthlyCommitmentMinor: 0,
    nextDueDate: null,
    nextDueMinor: 0,
  );

  final int remainingMinor;
  final int overdueMinor;

  /// Number of overdue installments across all loans.
  final int overdueCount;

  /// Non-archived loans (including closed ones).
  final int activeCount;

  /// Installments of open loans normalised to one month.
  final int monthlyCommitmentMinor;
  final String? nextDueDate;
  final int nextDueMinor;
}
