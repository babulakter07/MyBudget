import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Schema v6: institutional loans and credit cards. Both are separate ledgers
// (like Debts): they never touch accounts, budgets or transactions.
// ---------------------------------------------------------------------------

/// A loan taken from a bank / lender. The repayment schedule is derived from
/// these parameters at query time (never stored); only the real settlements
/// are stored in [LoanPayments].
@DataClassName('LoanRow')
class Loans extends Table {
  @override
  String get tableName => 'loans';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// Bank / lender name.
  TextColumn get lenderName => text().withLength(min: 1, max: 80)();

  /// 'personal' | 'home' | 'vehicle' | 'education' | 'business' | 'other'
  TextColumn get loanType => text().withDefault(const Constant('personal'))();

  /// Loan account / reference number printed on the sanction letter.
  TextColumn get referenceNo => text().nullable()();

  /// Loan (principal) amount, minor units.
  IntColumn get principalMinor => integer()();

  /// Annual interest rate in basis points (1150 = 11.50 %).
  IntColumn get interestRateBp => integer()();

  /// 'reducing' (interest on the outstanding balance) | 'flat' (interest on
  /// the original principal for the whole tenure).
  TextColumn get interestMethod =>
      text().withDefault(const Constant('reducing'))();

  /// Repayment frequency: 'weekly' | 'monthly' | 'yearly'.
  TextColumn get frequency => text().withDefault(const Constant('monthly'))();

  /// Number of installments (tenure expressed in periods of [frequency]).
  IntColumn get tenureCount => integer()();

  /// Fixed installment amount (the last installment absorbs rounding).
  IntColumn get installmentMinor => integer()();

  /// One-off processing / documentation fee (informational, part of the
  /// total cost, not of the installments).
  IntColumn get processingFeeMinor =>
      integer().withDefault(const Constant(0))();

  /// Disbursement date 'yyyy-MM-dd'.
  TextColumn get startDate => text()();

  /// Due date of the first installment 'yyyy-MM-dd'.
  TextColumn get firstDueDate => text()();
  TextColumn get note => text().nullable()();

  /// Schema v7: how the loan was closed before its schedule ran out.
  /// 'early' (settled early) | 'adjusted' (rolled into a newer loan); null
  /// while the loan runs or when it was simply paid off.
  TextColumn get closingType => text().nullable()();

  /// Closing date 'yyyy-MM-dd' and the user's remarks (v7).
  TextColumn get closedDate => text().nullable()();
  TextColumn get closingRemarks => text().nullable()();

  /// Amount paid to settle an early closure (also recorded as a payment).
  IntColumn get closingPaidMinor => integer().nullable()();

  /// The loan this one replaced (adjustment / top-up), null otherwise (v7).
  IntColumn get parentLoanId => integer().nullable()();
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
    "CHECK (closing_type IS NULL OR closing_type IN ('early','adjusted'))",
    "CHECK (loan_type IN ('personal','home','vehicle','education','business','other'))",
    "CHECK (interest_method IN ('reducing','flat'))",
    "CHECK (frequency IN ('weekly','monthly','yearly'))",
    'CHECK (principal_minor > 0)',
    'CHECK (interest_rate_bp >= 0 AND interest_rate_bp <= 10000)',
    'CHECK (tenure_count >= 1 AND tenure_count <= 1200)',
    'CHECK (installment_minor > 0)',
    'CHECK (processing_fee_minor >= 0)',
    'CHECK (length(start_date) = 10)',
    'CHECK (length(first_due_date) = 10)',
  ];
}

/// A real settlement (installment or extra payment) of a [Loans] row.
/// Soft-deleted (is_deleted) when voided.
@DataClassName('LoanPaymentRow')
class LoanPayments extends Table {
  @override
  String get tableName => 'loan_payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get loanId => integer()();
  IntColumn get amountMinor => integer()();
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
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, loan_id) REFERENCES loans (profile_id, id)',
    'CHECK (amount_minor > 0)',
    'CHECK (length(payment_date) = 10)',
  ];
}

/// A credit card and the bank's billing policy for it.
@DataClassName('CreditCardRow')
class CreditCards extends Table {
  @override
  String get tableName => 'credit_cards';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// Card nickname, unique per profile (case-insensitive).
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get bankName => text().withLength(min: 1, max: 80)();

  /// Last four digits (optional, never the full number).
  TextColumn get lastFour => text().nullable()();
  IntColumn get creditLimitMinor => integer()();

  /// Day of month (1-28) the statement is generated.
  IntColumn get statementDay => integer()();

  /// Payment due date = statement date + this many days (1-60).
  IntColumn get dueDays => integer()();

  /// Annual interest rate (APR) in basis points on unpaid bills.
  IntColumn get aprBp => integer()();

  /// Minimum payment = max(floor, this % of the bill), in basis points.
  IntColumn get minPaymentBp => integer()();
  IntColumn get minPaymentFloorMinor =>
      integer().withDefault(const Constant(0))();

  /// Late-payment fee when the minimum is not paid by the due date:
  /// max(floor, this % of the unpaid minimum), basis points.
  IntColumn get lateFeeBp => integer().withDefault(const Constant(0))();
  IntColumn get lateFeeFloorMinor => integer().withDefault(const Constant(0))();

  /// false: interest runs from the due date on the unpaid balance.
  /// true: when a bill is not paid in full by the due date, the grace period
  /// is lost and interest runs from the statement date.
  BoolColumn get interestFromStatement =>
      boolean().withDefault(const Constant(false))();
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
    'CHECK (credit_limit_minor > 0)',
    'CHECK (statement_day >= 1 AND statement_day <= 28)',
    'CHECK (due_days >= 1 AND due_days <= 60)',
    'CHECK (apr_bp >= 0 AND apr_bp <= 10000)',
    'CHECK (min_payment_bp >= 0 AND min_payment_bp <= 10000)',
    'CHECK (min_payment_floor_minor >= 0)',
    'CHECK (late_fee_bp >= 0 AND late_fee_bp <= 10000)',
    'CHECK (late_fee_floor_minor >= 0)',
    'CHECK (last_four IS NULL OR length(last_four) = 4)',
  ];
}

/// One monthly statement of a card: the NEW charges of that cycle (never
/// including the previous unpaid bill). Interest and late fees are computed
/// from the bill, the policy of the card and the payments.
@DataClassName('CreditCardBillRow')
class CreditCardBills extends Table {
  @override
  String get tableName => 'credit_card_bills';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get cardId => integer()();

  /// Statement month 'yyyy-MM'; unique per card among active bills.
  TextColumn get billMonth => text()();
  TextColumn get statementDate => text()();
  TextColumn get dueDate => text()();
  IntColumn get amountMinor => integer()();

  /// Minimum payment snapshot (card policy at creation, editable).
  IntColumn get minPaymentMinor => integer()();
  TextColumn get note => text().nullable()();

  /// false = voided/archived (kept for history).
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
    'FOREIGN KEY (profile_id, card_id) REFERENCES credit_cards (profile_id, id)',
    'CHECK (length(bill_month) = 7)',
    'CHECK (length(statement_date) = 10)',
    'CHECK (length(due_date) = 10)',
    'CHECK (amount_minor > 0)',
    'CHECK (min_payment_minor >= 0 AND min_payment_minor <= amount_minor)',
  ];
}

/// A payment against one card bill. Soft-deleted when voided.
@DataClassName('CreditCardPaymentRow')
class CreditCardPayments extends Table {
  @override
  String get tableName => 'credit_card_payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get billId => integer()();
  IntColumn get amountMinor => integer()();
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
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, bill_id) REFERENCES credit_card_bills (profile_id, id)',
    'CHECK (amount_minor > 0)',
    'CHECK (length(payment_date) = 10)',
  ];
}
