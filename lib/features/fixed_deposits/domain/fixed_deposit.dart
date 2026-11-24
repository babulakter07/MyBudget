/// Outcome of an instrument. An instrument is either running, encashed
/// (paid out) or reissued (its net received amount became the principal of the
/// next, linked instrument).
const fdOutcomeActive = 'active';
const fdOutcomeEncashed = 'encashed';
const fdOutcomeReissued = 'reissued';

/// 30 days = 1 month (the MegaFeed deposit-scheme convention).
const fdDaysPerMonth = 30;

/// The scheme at a bank (FDR, DPS, Sanchaypatra, ...). The money terms live in
/// [FixedDepositTerm], one per instrument.
class FixedDeposit {
  const FixedDeposit({
    required this.id,
    required this.profileId,
    required this.schemeType,
    required this.bankName,
    required this.beneficiaryName,
    required this.note,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String schemeType;
  final String bankName;
  final String? beneficiaryName;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// One instrument (issue or reissue) of a deposit.
class FixedDepositTerm {
  const FixedDepositTerm({
    required this.id,
    required this.profileId,
    required this.depositId,
    required this.termNo,
    required this.instrumentNumber,
    required this.startDate,
    required this.tenureDays,
    required this.rateBp,
    required this.principalMinor,
    required this.outcome,
    required this.settledDate,
    required this.interestMinor,
    required this.taxMinor,
    required this.bankChargeMinor,
    required this.netReceivedMinor,
    required this.renewedFromTermId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final int depositId;
  final int termNo;
  final String instrumentNumber;
  final String startDate;
  final int tenureDays;

  /// Annual rate in basis points (1050 = 10.50 %).
  final int rateBp;
  final int principalMinor;
  final String outcome;
  final String? settledDate;
  final int? interestMinor;
  final int? taxMinor;
  final int? bankChargeMinor;
  final int? netReceivedMinor;
  final int? renewedFromTermId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => outcome == fdOutcomeActive;
  bool get isReissue => renewedFromTermId != null;
}

enum FdStatus {
  /// Running, maturity date still ahead.
  active,

  /// Maturity date reached, the instrument is not encashed or reissued yet.
  matured,

  /// Last instrument was encashed.
  closed,
}
