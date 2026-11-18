import 'package:drift/drift.dart';

/// All profile-owned tables carry `profile_id`. Child tables use composite
/// foreign keys (profile_id, parent_id) so a child can never reference a
/// parent belonging to another profile.

@DataClassName('ProfileRow')
class FinancialProfiles extends Table {
  @override
  String get tableName => 'financial_profiles';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get currencyCode => text().withDefault(const Constant('BDT'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(FinancialProfiles, #id)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
  ];
}

@DataClassName('SubCategoryRow')
class SubCategories extends Table {
  @override
  String get tableName => 'sub_categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get categoryId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
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
    'FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)',
  ];
}

@DataClassName('CostItemRow')
class CostItems extends Table {
  @override
  String get tableName => 'cost_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get subCategoryId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();

  /// Minor units (paisa). Never a floating-point value.
  IntColumn get defaultAmountMinor => integer().nullable()();

  /// v4: favourite cost items show up as one-tap quick-add templates.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
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
    'FOREIGN KEY (profile_id, sub_category_id) REFERENCES sub_categories (profile_id, id)',
    'CHECK (default_amount_minor IS NULL OR default_amount_minor >= 0)',
  ];
}

@DataClassName('SettingRow')
class ApplicationSettings extends Table {
  @override
  String get tableName => 'application_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('MonthlyBudgetRow')
class MonthlyBudgets extends Table {
  @override
  String get tableName => 'monthly_budgets';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();

  /// Minor units (paisa).
  IntColumn get totalBudgetMinor => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
    {profileId, year, month},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'CHECK (month BETWEEN 1 AND 12)',
    'CHECK (year BETWEEN 1970 AND 9999)',
    'CHECK (total_budget_minor >= 0)',
  ];
}

@DataClassName('CategoryBudgetRow')
class CategoryBudgets extends Table {
  @override
  String get tableName => 'category_budgets';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get monthlyBudgetId => integer()();
  IntColumn get categoryId => integer()();

  /// Allocation inside the monthly total (never added to it). Minor units.
  IntColumn get amountMinor => integer()();

  /// v4: when true, unspent budget from the previous month is carried into
  /// this category's allowance (default false = RESET each month).
  BoolColumn get rolloverEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
    {monthlyBudgetId, categoryId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, monthly_budget_id) REFERENCES monthly_budgets (profile_id, id)',
    'FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)',
    'CHECK (amount_minor >= 0)',
  ];
}

@DataClassName('AccountRow')
class Accounts extends Table {
  @override
  String get tableName => 'accounts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// 'cash' | 'bank' | 'mobile' | 'savings' | 'credit_card' | 'other'
  TextColumn get type => text().withDefault(const Constant('cash'))();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();

  /// Local date as 'yyyy-MM-dd'.
  TextColumn get openingDate => text()();
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
    "CHECK (type IN ('cash','bank','mobile','savings','credit_card','other'))",
    'CHECK (length(opening_date) = 10)',
  ];
}

/// Expense / income / transfer rows. One row per transfer (account_id = source,
/// to_account_id = destination). Snapshots keep history readable after renames.
@DataClassName('TransactionRow')
class FinancialTransactions extends Table {
  @override
  String get tableName => 'financial_transactions';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// 'expense' | 'income' | 'transfer'
  TextColumn get type => text()();
  IntColumn get accountId => integer()();
  IntColumn get toAccountId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get subCategoryId => integer().nullable()();
  IntColumn get costItemId => integer().nullable()();

  TextColumn get accountNameSnapshot => text()();
  TextColumn get toAccountNameSnapshot => text().nullable()();
  TextColumn get categoryNameSnapshot => text().nullable()();
  TextColumn get subCategoryNameSnapshot => text().nullable()();
  TextColumn get costItemNameSnapshot => text().nullable()();

  /// Income only (e.g. Salary, Freelance).
  TextColumn get incomeSource => text().nullable()();

  /// Strictly positive, minor units.
  IntColumn get amountMinor => integer()();

  /// Local date as 'yyyy-MM-dd' (sorts and groups correctly as text).
  TextColumn get txnDate => text()();
  TextColumn get title => text().nullable()();
  TextColumn get remarks => text().nullable()();

  /// Optional free-text household member tags (v3). Labels only; no
  /// permissions or separate ledgers hang off them.
  TextColumn get paidBy => text().nullable()();
  TextColumn get forWhom => text().nullable()();

  /// v5 multi-currency. When a transaction was entered in a foreign
  /// currency, [amountMinor] is ALREADY the converted base-currency amount
  /// (so every balance/budget/report stays in base currency) and these three
  /// columns keep what the user typed: all NULL or all set (enforced by the
  /// repository and backup validator).
  IntColumn get originalAmountMinor => integer().nullable()();
  TextColumn get originalCurrency => text().nullable()();

  /// Base major units per 1 foreign major unit, times 1,000,000.
  IntColumn get rateMicro => integer().nullable()();

  /// Client-generated key so a retried save cannot create a duplicate.
  TextColumn get idempotencyKey => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
    {profileId, idempotencyKey},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, account_id) REFERENCES accounts (profile_id, id)',
    'FOREIGN KEY (profile_id, to_account_id) REFERENCES accounts (profile_id, id)',
    'FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)',
    'FOREIGN KEY (profile_id, sub_category_id) REFERENCES sub_categories (profile_id, id)',
    'FOREIGN KEY (profile_id, cost_item_id) REFERENCES cost_items (profile_id, id)',
    "CHECK (type IN ('expense','income','transfer'))",
    'CHECK (amount_minor > 0)',
    'CHECK (length(txn_date) = 10)',
    "CHECK (type <> 'transfer' OR (to_account_id IS NOT NULL AND to_account_id <> account_id))",
    "CHECK (type = 'transfer' OR to_account_id IS NULL)",
    "CHECK (type <> 'expense' OR category_id IS NOT NULL)",
  ];
}

@DataClassName('AuditLogRow')
class TransactionAuditLogs extends Table {
  @override
  String get tableName => 'transaction_audit_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get transactionId => integer()();

  /// 'create' | 'update' | 'delete' | 'restore'
  TextColumn get action => text()();

  /// JSON snapshots of the row before/after the action (null when n/a).
  TextColumn get previousJson => text().nullable()();
  TextColumn get newJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, transaction_id) REFERENCES financial_transactions (profile_id, id)',
    "CHECK (action IN ('create','update','delete','restore'))",
  ];
}

// ---------------------------------------------------------------------------
// v4 tables
// ---------------------------------------------------------------------------

/// Template for transactions that repeat (rent, salary, bills, EMI).
/// Generated transactions use idempotency key `rec:<ruleId>:<yyyy-MM-dd>` so a
/// due date can never be posted twice.
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  @override
  String get tableName => 'recurring_rules';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// 'expense' | 'income' | 'transfer'
  TextColumn get type => text()();
  IntColumn get accountId => integer()();
  IntColumn get toAccountId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get subCategoryId => integer().nullable()();
  IntColumn get costItemId => integer().nullable()();
  TextColumn get incomeSource => text().nullable()();
  IntColumn get amountMinor => integer()();
  TextColumn get title => text()();
  TextColumn get remarks => text().nullable()();

  /// 'daily' | 'weekly' | 'monthly' | 'yearly'
  TextColumn get frequency => text()();

  /// Every N units of [frequency] (>= 1).
  IntColumn get intervalCount => integer().withDefault(const Constant(1))();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();

  /// Next date a transaction is due ('yyyy-MM-dd'); advanced as it is posted.
  TextColumn get nextDueDate => text()();

  /// Reminder lead time in days; null = no reminder.
  IntColumn get remindDaysBefore => integer().nullable()();
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
    'FOREIGN KEY (profile_id, account_id) REFERENCES accounts (profile_id, id)',
    'FOREIGN KEY (profile_id, to_account_id) REFERENCES accounts (profile_id, id)',
    'FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)',
    'FOREIGN KEY (profile_id, sub_category_id) REFERENCES sub_categories (profile_id, id)',
    'FOREIGN KEY (profile_id, cost_item_id) REFERENCES cost_items (profile_id, id)',
    "CHECK (type IN ('expense','income','transfer'))",
    "CHECK (frequency IN ('daily','weekly','monthly','yearly'))",
    'CHECK (amount_minor > 0)',
    'CHECK (interval_count >= 1)',
    'CHECK (length(start_date) = 10 AND length(next_due_date) = 10)',
    "CHECK (type <> 'transfer' OR (to_account_id IS NOT NULL AND to_account_id <> account_id))",
    "CHECK (type = 'transfer' OR to_account_id IS NULL)",
    "CHECK (type <> 'expense' OR category_id IS NOT NULL)",
  ];
}

/// Savings goal tied to one account. Progress = that account's computed
/// balance (never stored), so contributions are ordinary transfers/income.
@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table {
  @override
  String get tableName => 'savings_goals';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get accountId => integer()();
  IntColumn get targetMinor => integer()();
  TextColumn get targetDate => text().nullable()();
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
    'FOREIGN KEY (profile_id, account_id) REFERENCES accounts (profile_id, id)',
    'CHECK (target_minor > 0)',
  ];
}

/// Money lent to / borrowed from a person. Separate from income/expense: it
/// never touches account balances or budgets.
@DataClassName('DebtRow')
class Debts extends Table {
  @override
  String get tableName => 'debts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// 'lent' (they owe me) | 'borrowed' (I owe them)
  TextColumn get direction => text()();
  TextColumn get personName => text().withLength(min: 1, max: 80)();
  IntColumn get principalMinor => integer()();
  TextColumn get startDate => text()();
  TextColumn get dueDate => text().nullable()();
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
    "CHECK (direction IN ('lent','borrowed'))",
    'CHECK (principal_minor > 0)',
    'CHECK (length(start_date) = 10)',
  ];
}

/// Repayments against a [Debts] row. Soft-deleted (is_deleted) when voided.
@DataClassName('DebtPaymentRow')
class DebtPayments extends Table {
  @override
  String get tableName => 'debt_payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get debtId => integer()();
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
    'FOREIGN KEY (profile_id, debt_id) REFERENCES debts (profile_id, id)',
    'CHECK (amount_minor > 0)',
    'CHECK (length(payment_date) = 10)',
  ];
}

/// Free-form labels that cut across categories ("Eid", "Trip 2026").
@DataClassName('TagRow')
class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get color => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
  ];
}

@DataClassName('TransactionTagRow')
class TransactionTags extends Table {
  @override
  String get tableName => 'transaction_tags';

  IntColumn get profileId => integer()();
  IntColumn get transactionId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, transaction_id) REFERENCES financial_transactions (profile_id, id)',
    'FOREIGN KEY (profile_id, tag_id) REFERENCES tags (profile_id, id)',
  ];
}

/// Receipt photos. [relativePath] is relative to the attachments directory
/// so backups and reinstalls stay portable.
@DataClassName('AttachmentRow')
class TransactionAttachments extends Table {
  @override
  String get tableName => 'transaction_attachments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get transactionId => integer()();
  TextColumn get relativePath => text()();
  TextColumn get mimeType => text().withDefault(const Constant('image/jpeg'))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
    'FOREIGN KEY (profile_id, transaction_id) REFERENCES financial_transactions (profile_id, id)',
  ];
}

/// Manual exchange rates (per profile) used to enter transactions in a
/// foreign currency. Rates are never fetched online.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  @override
  String get tableName => 'exchange_rates';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();

  /// ISO-4217 style code, 3 upper-case letters (e.g. USD).
  TextColumn get currencyCode => text()();

  /// Base major units per 1 foreign major unit, times 1,000,000.
  IntColumn get rateMicro => integer()();
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
    'CHECK (length(currency_code) = 3)',
    'CHECK (rate_micro > 0)',
  ];
}
