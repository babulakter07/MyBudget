import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Schema v7: deposit schemes (FDR, DPS, Sanchaypatra, ...), modelled on the
// MegaFeed "Deposit Scheme" business. A separate ledger like loans/debts: it
// never touches accounts, budgets or transactions. A deposit owns a chain of
// INSTRUMENTS (terms): an instrument is either encashed or REISSUED (its net
// received amount becomes the principal of a new, linked instrument).
// ---------------------------------------------------------------------------

/// The scheme at a bank. The money terms live in [FixedDepositTerms] (one row
/// per instrument); status is derived from the latest instrument.
@DataClassName('FixedDepositRow')
class FixedDeposits extends Table {
  @override
  String get tableName => 'fixed_deposits';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// Scheme type label: 'FDR', 'DPS', 'Sanchaypatra', ... (free text).
  TextColumn get schemeType => text().withDefault(const Constant('FDR'))();

  /// Bank / institution name.
  TextColumn get bankName => text().withLength(min: 1, max: 80)();

  /// Name on the instrument.
  TextColumn get beneficiaryName => text().nullable()();
  TextColumn get note => text().nullable()();
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
    'CHECK (length(scheme_type) >= 1 AND length(scheme_type) <= 40)',
  ];
}

/// One instrument (issue or reissue) of a [FixedDeposits] row. Maturity =
/// start date + tenure days (30 days = 1 month). Interest, tax and bank charge
/// are entered by the user when the instrument is closed (the app only
/// suggests the interest); the net received amount may be overridden.
@DataClassName('FixedDepositTermRow')
class FixedDepositTerms extends Table {
  @override
  String get tableName => 'fixed_deposit_terms';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get depositId => integer()();

  /// 1 for the first issue, 2 for the first reissue, ...
  IntColumn get termNo => integer()();

  /// Certificate / instrument number, unique per profile (case-insensitive).
  TextColumn get instrumentNumber => text().withLength(min: 1, max: 100)();
  TextColumn get startDate => text()();
  IntColumn get tenureDays => integer()();

  /// Annual rate in basis points (1050 = 10.50 %).
  IntColumn get rateBp => integer()();
  IntColumn get principalMinor => integer()();

  /// 'active' | 'encashed' | 'reissued'. Closed instruments are history.
  TextColumn get outcome => text().withDefault(const Constant('active'))();

  /// Closing date, null while active.
  TextColumn get settledDate => text().nullable()();

  /// Closing figures (null while active): interest earned, tax deducted at
  /// source, bank charge, and net received = principal + interest - tax -
  /// charge (or the user's final figure).
  IntColumn get interestMinor => integer().nullable()();
  IntColumn get taxMinor => integer().nullable()();
  IntColumn get bankChargeMinor => integer().nullable()();
  IntColumn get netReceivedMinor => integer().nullable()();

  /// The instrument this one reissued, null for the first issue.
  IntColumn get renewedFromTermId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
    {depositId, termNo},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id, deposit_id) REFERENCES fixed_deposits (profile_id, id)',
    "CHECK (outcome IN ('active','encashed','reissued'))",
    'CHECK (term_no >= 1)',
    'CHECK (length(start_date) = 10)',
    'CHECK (tenure_days >= 1 AND tenure_days <= 36500)',
    'CHECK (rate_bp >= 0 AND rate_bp <= 10000)',
    'CHECK (principal_minor > 0)',
  ];
}
