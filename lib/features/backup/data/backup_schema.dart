/// Describes the tables/columns that go into a backup file. Column names are
/// the SQLite column names. The order of [backupTables] is FK-safe (parents
/// first); deletion uses the reverse order.
enum ColKind { int_, text, bool_, dateTime }

class ColSpec {
  const ColSpec(
    this.name,
    this.kind, {
    this.nullable = false,
    this.defaultValue,
  });
  final String name;
  final ColKind kind;
  final bool nullable;

  /// JSON-level default used when an older backup lacks this column (v4
  /// columns). A column with a default may be absent from the file.
  final Object? defaultValue;
}

class TableSpec {
  const TableSpec(
    this.name,
    this.columns, {
    this.orderBy = 'id',
    this.optional = false,
  });
  final String name;
  final List<ColSpec> columns;

  /// Comma separated column names.
  final String orderBy;

  /// Tables added in schema v4/v5: absent from older backups (treated as empty).
  final bool optional;

  bool get hasId => columns.any((c) => c.name == 'id');

  String get orderBySql =>
      orderBy.split(',').map((c) => '"${c.trim()}"').join(',');
}

const _id = ColSpec('id', ColKind.int_);
const _pid = ColSpec('profile_id', ColKind.int_);
const _created = ColSpec('created_at', ColKind.dateTime);
const _updated = ColSpec('updated_at', ColKind.dateTime);
const _active = ColSpec('is_active', ColKind.bool_);

const List<TableSpec> backupTables = [
  TableSpec('financial_profiles', [
    _id,
    ColSpec('name', ColKind.text),
    ColSpec('currency_code', ColKind.text),
    _active,
    _created,
    _updated,
  ]),
  TableSpec('exchange_rates', [
    _id,
    _pid,
    ColSpec('currency_code', ColKind.text),
    ColSpec('rate_micro', ColKind.int_),
    _active,
    _created,
    _updated,
  ], optional: true),
  TableSpec('categories', [
    _id,
    _pid,
    ColSpec('name', ColKind.text),
    ColSpec('description', ColKind.text, nullable: true),
    ColSpec('icon', ColKind.text, nullable: true),
    ColSpec('color', ColKind.int_, nullable: true),
    _active,
    _created,
    _updated,
  ]),
  TableSpec('sub_categories', [
    _id,
    _pid,
    ColSpec('category_id', ColKind.int_),
    ColSpec('name', ColKind.text),
    _active,
    _created,
    _updated,
  ]),
  TableSpec('cost_items', [
    _id,
    _pid,
    ColSpec('sub_category_id', ColKind.int_),
    ColSpec('name', ColKind.text),
    ColSpec('description', ColKind.text, nullable: true),
    ColSpec('default_amount_minor', ColKind.int_, nullable: true),
    ColSpec('is_favorite', ColKind.bool_, defaultValue: false),
    _active,
    _created,
    _updated,
  ]),
  TableSpec('monthly_budgets', [
    _id,
    _pid,
    ColSpec('year', ColKind.int_),
    ColSpec('month', ColKind.int_),
    ColSpec('total_budget_minor', ColKind.int_),
    _created,
    _updated,
  ]),
  TableSpec('category_budgets', [
    _id,
    _pid,
    ColSpec('monthly_budget_id', ColKind.int_),
    ColSpec('category_id', ColKind.int_),
    ColSpec('amount_minor', ColKind.int_),
    ColSpec('rollover_enabled', ColKind.bool_, defaultValue: false),
    _created,
    _updated,
  ]),
  TableSpec('accounts', [
    _id,
    _pid,
    ColSpec('name', ColKind.text),
    ColSpec('type', ColKind.text),
    ColSpec('opening_balance_minor', ColKind.int_),
    ColSpec('opening_date', ColKind.text),
    _active,
    _created,
    _updated,
  ]),
  TableSpec('recurring_rules', [
    _id,
    _pid,
    ColSpec('type', ColKind.text),
    ColSpec('account_id', ColKind.int_),
    ColSpec('to_account_id', ColKind.int_, nullable: true),
    ColSpec('category_id', ColKind.int_, nullable: true),
    ColSpec('sub_category_id', ColKind.int_, nullable: true),
    ColSpec('cost_item_id', ColKind.int_, nullable: true),
    ColSpec('income_source', ColKind.text, nullable: true),
    ColSpec('amount_minor', ColKind.int_),
    ColSpec('title', ColKind.text),
    ColSpec('remarks', ColKind.text, nullable: true),
    ColSpec('frequency', ColKind.text),
    ColSpec('interval_count', ColKind.int_),
    ColSpec('start_date', ColKind.text),
    ColSpec('end_date', ColKind.text, nullable: true),
    ColSpec('next_due_date', ColKind.text),
    ColSpec('remind_days_before', ColKind.int_, nullable: true),
    _active,
    _created,
    _updated,
  ], optional: true),
  TableSpec('savings_goals', [
    _id,
    _pid,
    ColSpec('name', ColKind.text),
    ColSpec('account_id', ColKind.int_),
    ColSpec('target_minor', ColKind.int_),
    ColSpec('target_date', ColKind.text, nullable: true),
    ColSpec('note', ColKind.text, nullable: true),
    _active,
    _created,
    _updated,
  ], optional: true),
  TableSpec('debts', [
    _id,
    _pid,
    ColSpec('direction', ColKind.text),
    ColSpec('person_name', ColKind.text),
    ColSpec('principal_minor', ColKind.int_),
    ColSpec('start_date', ColKind.text),
    ColSpec('due_date', ColKind.text, nullable: true),
    ColSpec('note', ColKind.text, nullable: true),
    _active,
    _created,
    _updated,
  ], optional: true),
  TableSpec('debt_payments', [
    _id,
    _pid,
    ColSpec('debt_id', ColKind.int_),
    ColSpec('amount_minor', ColKind.int_),
    ColSpec('payment_date', ColKind.text),
    ColSpec('note', ColKind.text, nullable: true),
    ColSpec('is_deleted', ColKind.bool_),
    _created,
  ], optional: true),
  TableSpec('financial_transactions', [
    _id,
    _pid,
    ColSpec('type', ColKind.text),
    ColSpec('account_id', ColKind.int_),
    ColSpec('to_account_id', ColKind.int_, nullable: true),
    ColSpec('category_id', ColKind.int_, nullable: true),
    ColSpec('sub_category_id', ColKind.int_, nullable: true),
    ColSpec('cost_item_id', ColKind.int_, nullable: true),
    ColSpec('account_name_snapshot', ColKind.text),
    ColSpec('to_account_name_snapshot', ColKind.text, nullable: true),
    ColSpec('category_name_snapshot', ColKind.text, nullable: true),
    ColSpec('sub_category_name_snapshot', ColKind.text, nullable: true),
    ColSpec('cost_item_name_snapshot', ColKind.text, nullable: true),
    ColSpec('income_source', ColKind.text, nullable: true),
    ColSpec('amount_minor', ColKind.int_),
    ColSpec('original_amount_minor', ColKind.int_, nullable: true),
    ColSpec('original_currency', ColKind.text, nullable: true),
    ColSpec('rate_micro', ColKind.int_, nullable: true),
    ColSpec('txn_date', ColKind.text),
    ColSpec('title', ColKind.text, nullable: true),
    ColSpec('remarks', ColKind.text, nullable: true),
    ColSpec('paid_by', ColKind.text, nullable: true),
    ColSpec('for_whom', ColKind.text, nullable: true),
    ColSpec('idempotency_key', ColKind.text, nullable: true),
    ColSpec('is_deleted', ColKind.bool_),
    ColSpec('deleted_at', ColKind.dateTime, nullable: true),
    _created,
    _updated,
  ]),
  TableSpec('transaction_audit_logs', [
    _id,
    _pid,
    ColSpec('transaction_id', ColKind.int_),
    ColSpec('action', ColKind.text),
    ColSpec('previous_json', ColKind.text, nullable: true),
    ColSpec('new_json', ColKind.text, nullable: true),
    _created,
  ]),
  TableSpec('tags', [
    _id,
    _pid,
    ColSpec('name', ColKind.text),
    ColSpec('color', ColKind.int_, nullable: true),
    _active,
    _created,
  ], optional: true),
  TableSpec(
    'transaction_tags',
    [
      _pid,
      ColSpec('transaction_id', ColKind.int_),
      ColSpec('tag_id', ColKind.int_),
    ],
    orderBy: 'transaction_id,tag_id',
    optional: true,
  ),
  TableSpec('transaction_attachments', [
    _id,
    _pid,
    ColSpec('transaction_id', ColKind.int_),
    ColSpec('relative_path', ColKind.text),
    ColSpec('mime_type', ColKind.text),
    ColSpec('size_bytes', ColKind.int_),
    ColSpec('is_deleted', ColKind.bool_),
    _created,
  ], optional: true),
  TableSpec('application_settings', [
    ColSpec('key', ColKind.text),
    ColSpec('value', ColKind.text),
  ], orderBy: 'key'),
];

/// Tables with an AUTOINCREMENT id (they have sqlite_sequence entries).
Set<String> get autoIncrementTables => {
  for (final t in backupTables)
    if (t.hasId) t.name,
};

const String settingFrequency = 'backup.frequency';
const String settingRetention = 'backup.retention';
const String settingLastAt = 'backup.last_at';
const String settingLastStatus = 'backup.last_status';
const String settingLastMessage = 'backup.last_message';

/// Transient backup-status keys: never exported, never overwritten or deleted
/// by a restore.
const Set<String> transientSettingKeys = {
  settingLastAt,
  settingLastStatus,
  settingLastMessage,
};
