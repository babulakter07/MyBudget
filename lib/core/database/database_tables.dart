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

  /// 'cash' | 'bank' | 'mobile' | 'other'
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
    "CHECK (type IN ('cash','bank','mobile','other'))",
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
