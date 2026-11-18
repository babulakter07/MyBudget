import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';

/// Hand-written schema-v3 fragments (only what the v4 step touches) with data.
AppDatabase _openV3() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
CREATE TABLE financial_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'BDT',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        raw.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL REFERENCES financial_profiles (id),
  name TEXT NOT NULL,
  description TEXT NULL,
  icon TEXT NULL,
  color INTEGER NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id)
)''');
        raw.execute('''
CREATE TABLE sub_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id)
)''');
        raw.execute('''
CREATE TABLE cost_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  sub_category_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT NULL,
  default_amount_minor INTEGER NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id)
)''');
        raw.execute('''
CREATE TABLE monthly_budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  total_budget_minor INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id),
  UNIQUE (profile_id, year, month)
)''');
        raw.execute('''
CREATE TABLE category_budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  monthly_budget_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  amount_minor INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id),
  UNIQUE (monthly_budget_id, category_id)
)''');
        raw.execute('''
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'cash',
  opening_balance_minor INTEGER NOT NULL DEFAULT 0,
  opening_date TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id)
)''');
        raw.execute('''
CREATE TABLE financial_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  account_id INTEGER NOT NULL,
  to_account_id INTEGER NULL,
  category_id INTEGER NULL,
  sub_category_id INTEGER NULL,
  cost_item_id INTEGER NULL,
  account_name_snapshot TEXT NOT NULL,
  to_account_name_snapshot TEXT NULL,
  category_name_snapshot TEXT NULL,
  sub_category_name_snapshot TEXT NULL,
  cost_item_name_snapshot TEXT NULL,
  income_source TEXT NULL,
  amount_minor INTEGER NOT NULL,
  txn_date TEXT NOT NULL,
  title TEXT NULL,
  remarks TEXT NULL,
  paid_by TEXT NULL,
  for_whom TEXT NULL,
  idempotency_key TEXT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (profile_id, id),
  UNIQUE (profile_id, idempotency_key)
)''');
        raw.execute('''
CREATE TABLE transaction_audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  transaction_id INTEGER NOT NULL,
  action TEXT NOT NULL,
  previous_json TEXT NULL,
  new_json TEXT NULL,
  created_at INTEGER NOT NULL
)''');
        raw.execute('''
CREATE TABLE application_settings (
  "key" TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
)''');
        raw.execute(
          "INSERT INTO financial_profiles (name, created_at, updated_at) VALUES ('Personal', 1700000000, 1700000000)",
        );
        raw.execute(
          "INSERT INTO categories (profile_id, name, created_at, updated_at) VALUES (1, 'Food', 1700000000, 1700000000)",
        );
        raw.execute(
          "INSERT INTO sub_categories (profile_id, category_id, name, created_at, updated_at) VALUES (1, 1, 'Meals', 1700000000, 1700000000)",
        );
        raw.execute(
          "INSERT INTO cost_items (profile_id, sub_category_id, name, created_at, updated_at) VALUES (1, 1, 'Lunch', 1700000000, 1700000000)",
        );
        raw.execute(
          "INSERT INTO monthly_budgets (profile_id, year, month, total_budget_minor, created_at, updated_at) VALUES (1, 2026, 11, 100000, 1700000000, 1700000000)",
        );
        raw.execute(
          "INSERT INTO category_budgets (profile_id, monthly_budget_id, category_id, amount_minor, created_at, updated_at) VALUES (1, 1, 1, 50000, 1700000000, 1700000000)",
        );
        raw.execute('PRAGMA user_version = 3');
      },
    ),
  );
}

void main() {
  test('v3 -> v4 keeps data, adds tables and new columns', () async {
    final db = _openV3();
    addTearDown(db.close);

    final item = await db.select(db.costItems).getSingle();
    expect(item.name, 'Lunch');
    expect(item.isFavorite, isFalse);

    final cb = await db.select(db.categoryBudgets).getSingle();
    expect(cb.amountMinor, 50000);
    expect(cb.rolloverEnabled, isFalse);

    final tables =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table'",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toSet();
    expect(
      tables,
      containsAll([
        'recurring_rules',
        'savings_goals',
        'debts',
        'debt_payments',
        'tags',
        'transaction_tags',
        'transaction_attachments',
        'exchange_rates',
      ]),
    );

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), AppDatabase.currentSchemaVersion);
  });

  test('v4 tables enforce constraints after migration', () async {
    final db = _openV3();
    addTearDown(db.close);
    final now = DateTime(2026, 11, 1);

    // Tag names are unique case-insensitively per profile.
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(profileId: 1, name: 'Eid', createdAt: now),
        );
    await expectLater(
      db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(profileId: 1, name: 'EID', createdAt: now),
          ),
      throwsA(anything),
    );

    // Debt principal must be positive; direction is constrained.
    await expectLater(
      db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              profileId: 1,
              direction: 'lent',
              personName: 'Rahim',
              principalMinor: 0,
              startDate: '2026-11-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
    await expectLater(
      db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              profileId: 1,
              direction: 'gift',
              personName: 'Rahim',
              principalMinor: 100,
              startDate: '2026-11-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('fresh install creates the v4 schema', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    expect(await db.select(db.recurringRules).get(), isEmpty);
    expect(await db.select(db.savingsGoals).get(), isEmpty);
    expect(await db.select(db.transactionAttachments).get(), isEmpty);
  });

  test('v3 -> v5 adds foreign-currency columns and exchange rates', () async {
    final db = _openV3();
    addTearDown(db.close);
    final now = DateTime(2026, 11, 1);

    // The migrated transactions table accepts the v5 columns.
    await db.customStatement(
      "INSERT INTO accounts (profile_id, name, opening_date, created_at, updated_at) VALUES (1, 'Cash', '2026-01-01', 1700000000, 1700000000)",
    );
    final id = await db
        .into(db.financialTransactions)
        .insert(
          FinancialTransactionsCompanion.insert(
            profileId: 1,
            type: 'income',
            accountId: 1,
            accountNameSnapshot: 'Cash',
            amountMinor: 245000,
            txnDate: '2026-11-01',
            createdAt: now,
            updatedAt: now,
            originalAmountMinor: const Value(2000),
            originalCurrency: const Value('USD'),
            rateMicro: const Value(122500000),
          ),
        );
    final row = await (db.select(
      db.financialTransactions,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.originalAmountMinor, 2000);
    expect(row.originalCurrency, 'USD');
    expect(row.rateMicro, 122500000);

    // Existing-style rows have no original amount.
    expect(await db.select(db.exchangeRates).get(), isEmpty);

    // Rates: one per (profile, currency); positive rate; 3-letter code.
    await db
        .into(db.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            profileId: 1,
            currencyCode: 'USD',
            rateMicro: 122500000,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await expectLater(
      db
          .into(db.exchangeRates)
          .insert(
            ExchangeRatesCompanion.insert(
              profileId: 1,
              currencyCode: 'USD',
              rateMicro: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
    await expectLater(
      db
          .into(db.exchangeRates)
          .insert(
            ExchangeRatesCompanion.insert(
              profileId: 1,
              currencyCode: 'EUR',
              rateMicro: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });
}
