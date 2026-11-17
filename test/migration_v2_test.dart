import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';

/// Builds a schema-v1 database (Sprint 1-2 tables only) with real data, then
/// opens it with the current AppDatabase to exercise the v1 -> v2 migration.
AppDatabase _openV1WithData() {
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
  UNIQUE (profile_id, id),
  FOREIGN KEY (profile_id) REFERENCES financial_profiles (id),
  FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)
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
  UNIQUE (profile_id, id),
  FOREIGN KEY (profile_id) REFERENCES financial_profiles (id),
  FOREIGN KEY (profile_id, sub_category_id) REFERENCES sub_categories (profile_id, id)
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
        raw.execute('PRAGMA user_version = 1');
      },
    ),
  );
}

void main() {
  test('v1 -> v2 keeps existing data and adds the new tables', () async {
    final db = _openV1WithData();
    addTearDown(db.close);

    // Opening triggers onUpgrade(1 -> 2).
    final profiles = await db.select(db.financialProfiles).get();
    expect(profiles.single.name, 'Personal');
    final cats = await db.select(db.categories).get();
    expect(cats.single.name, 'Food');

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
        'monthly_budgets',
        'category_budgets',
        'accounts',
        'financial_transactions',
        'transaction_audit_logs',
      ]),
    );

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), AppDatabase.currentSchemaVersion);
  });

  test('after migration the new tables enforce their constraints', () async {
    final db = _openV1WithData();
    addTearDown(db.close);
    final now = DateTime(2026, 11, 1);

    // Works against migrated data.
    final accountId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: 1,
            name: 'Cash',
            openingDate: '2026-01-01',
            createdAt: now,
            updatedAt: now,
          ),
        );
    expect(accountId, 1);

    // Case-insensitive unique account name (index created by the migration).
    await expectLater(
      db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              profileId: 1,
              name: 'CASH',
              openingDate: '2026-01-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );

    // Zero-amount transactions are rejected by the CHECK constraint.
    await expectLater(
      db
          .into(db.financialTransactions)
          .insert(
            FinancialTransactionsCompanion.insert(
              profileId: 1,
              type: 'income',
              accountId: 1,
              accountNameSnapshot: 'Cash',
              amountMinor: 0,
              txnDate: '2026-11-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );

    // Cross-profile account reference is rejected by the composite FK.
    await db.customStatement(
      "INSERT INTO financial_profiles (name, created_at, updated_at) VALUES ('Family', 1700000000, 1700000000)",
    );
    await expectLater(
      db
          .into(db.financialTransactions)
          .insert(
            FinancialTransactionsCompanion.insert(
              profileId: 2,
              type: 'income',
              accountId: 1,
              accountNameSnapshot: 'Cash',
              amountMinor: 100,
              txnDate: '2026-11-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('v3 accepts savings/credit_card accounts and member tags', () async {
    final db = _openV1WithData();
    addTearDown(db.close);
    final now = DateTime(2026, 11, 1);

    for (final type in ['savings', 'credit_card']) {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              profileId: 1,
              name: type,
              type: Value(type),
              openingDate: '2026-01-01',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await expectLater(
      db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              profileId: 1,
              name: 'bad',
              type: const Value('crypto'),
              openingDate: '2026-01-01',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );

    await db
        .into(db.financialTransactions)
        .insert(
          FinancialTransactionsCompanion.insert(
            profileId: 1,
            type: 'income',
            accountId: 1,
            accountNameSnapshot: 'savings',
            amountMinor: 500,
            txnDate: '2026-11-01',
            paidBy: const Value('Father'),
            forWhom: const Value('Mother'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await db.select(db.financialTransactions).getSingle();
    expect(row.paidBy, 'Father');
    expect(row.forWhom, 'Mother');
  });
}
