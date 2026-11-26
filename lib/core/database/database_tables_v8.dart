import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Schema v8: DPS (monthly deposit pension scheme). A separate ledger like
// loans and fixed deposits: it never touches accounts, budgets or
// transactions. Banks set their own late fee, grace period, closure and tax
// rules, so those are stored per account. The installment schedule is derived
// at query time; only real deposits are stored in [DpsPayments].
// ---------------------------------------------------------------------------

@DataClassName('DpsAccountRow')
class DpsAccounts extends Table {
  @override
  String get tableName => 'dps_accounts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get bankName => text().withLength(min: 1, max: 80)();

  /// Unique per profile (case-insensitive) when given.
  TextColumn get accountNumber => text().nullable()();
  IntColumn get installmentMinor => integer()();
  IntColumn get tenureMonths => integer()();

  /// 'yyyy-MM-dd'.
  TextColumn get openDate => text()();

  /// Due date of installment 1; later ones follow monthly on the same day.
  TextColumn get firstDueDate => text()();

  /// Indicative annual profit rate in basis points.
  IntColumn get rateBp => integer()();

  /// Maturity value quoted by the bank (before tax); null = use the estimate.
  IntColumn get bankMaturityMinor => integer().nullable()();

  /// Tax deducted from profit, in basis points (1000 = 10 %).
  IntColumn get taxRateBp => integer().withDefault(const Constant(1000))();

  /// Late fee per installment paid after the grace period.
  IntColumn get lateFeeMinor => integer().withDefault(const Constant(0))();
  IntColumn get graceDays => integer().withDefault(const Constant(0))();

  /// Missed installments in a row after which the bank may close the account;
  /// 0 = no such rule.
  IntColumn get missedLimit => integer().withDefault(const Constant(3))();
  TextColumn get note => text().nullable()();

  /// Null while open: 'matured' | 'premature' | 'bank_closed'.
  TextColumn get closingType => text().nullable()();
  TextColumn get closedDate => text().nullable()();

  /// Closing figures as given by the bank (null while open).
  IntColumn get profitMinor => integer().nullable()();
  IntColumn get taxMinor => integer().nullable()();
  IntColumn get chargeMinor => integer().nullable()();
  IntColumn get netReceivedMinor => integer().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'CHECK (installment_minor > 0)',
    'CHECK (tenure_months >= 1 AND tenure_months <= 360)',
    'CHECK (length(open_date) = 10 AND length(first_due_date) = 10)',
    'CHECK (rate_bp >= 0 AND rate_bp <= 10000)',
    'CHECK (tax_rate_bp >= 0 AND tax_rate_bp <= 10000)',
    'CHECK (late_fee_minor >= 0)',
    'CHECK (grace_days >= 0 AND grace_days <= 60)',
    'CHECK (missed_limit >= 0 AND missed_limit <= 24)',
    "CHECK (closing_type IS NULL OR closing_type IN ('matured','premature','bank_closed'))",
  ];
}

/// A deposit of one or more whole installments. Voided rows stay for history.
@DataClassName('DpsPaymentRow')
class DpsPayments extends Table {
  @override
  String get tableName => 'dps_payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get dpsId => integer()();

  /// Number of installments this deposit covers (oldest unpaid first).
  IntColumn get installments => integer()();

  /// Late fee the bank charged with it (not part of the savings).
  IntColumn get lateFeeMinor => integer().withDefault(const Constant(0))();
  TextColumn get paymentDate => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id, dps_id) REFERENCES dps_accounts (profile_id, id)',
    'CHECK (installments >= 1)',
    'CHECK (late_fee_minor >= 0)',
    'CHECK (length(payment_date) = 10)',
  ];
}
