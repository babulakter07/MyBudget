import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_tables.dart';
import 'database_tables_v6.dart';
import 'database_tables_v7.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FinancialProfiles,
    Categories,
    SubCategories,
    CostItems,
    ApplicationSettings,
    MonthlyBudgets,
    CategoryBudgets,
    Accounts,
    FinancialTransactions,
    TransactionAuditLogs,
    RecurringRules,
    SavingsGoals,
    Debts,
    DebtPayments,
    Tags,
    TransactionTags,
    TransactionAttachments,
    ExchangeRates,
    Loans,
    LoanPayments,
    CreditCards,
    CreditCardBills,
    CreditCardPayments,
    FixedDeposits,
    FixedDepositTerms,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  static const int currentSchemaVersion = 7;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
      await _createV2Indexes();
      await _createV4Indexes();
      await _createV5Indexes();
      await _createV6Indexes();
      await _createV7Indexes();
    },
    onUpgrade: (m, from, to) async {
      // Stepwise migrations. Never rewrite earlier steps.
      if (from < 2) {
        await m.createTable(monthlyBudgets);
        await m.createTable(categoryBudgets);
        await m.createTable(accounts);
        await m.createTable(financialTransactions);
        await m.createTable(transactionAuditLogs);
        await _createV2Indexes();
      }
      // from < 2 already created the v2 tables from the current definitions
      // (which include the v3 shape), so v3 only applies to real v2 databases.
      if (from >= 2 && from < 3) {
        // Widen the accounts.type CHECK (rebuilds the table, keeps rows/ids).
        await m.alterTable(TableMigration(accounts));
        await m.addColumn(financialTransactions, financialTransactions.paidBy);
        await m.addColumn(financialTransactions, financialTransactions.forWhom);
        // Rebuilding a table drops its indexes; recreate them.
        await _createV2Indexes();
      }
      if (from < 4) {
        await m.createTable(recurringRules);
        await m.createTable(savingsGoals);
        await m.createTable(debts);
        await m.createTable(debtPayments);
        await m.createTable(tags);
        await m.createTable(transactionTags);
        await m.createTable(transactionAttachments);
        await m.addColumn(costItems, costItems.isFavorite);
        // Databases upgraded from v1 got category_budgets (already including
        // the column) from the v2 step above.
        if (from >= 2) {
          await m.addColumn(categoryBudgets, categoryBudgets.rolloverEnabled);
        }
        await _createV4Indexes();
      }
      if (from < 5) {
        await m.createTable(exchangeRates);
        // Databases created before v2 get the (already extended) table from
        // the v2 step above, so only add columns for real v2+ databases.
        if (from >= 2) {
          await m.addColumn(
            financialTransactions,
            financialTransactions.originalAmountMinor,
          );
          await m.addColumn(
            financialTransactions,
            financialTransactions.originalCurrency,
          );
          await m.addColumn(
            financialTransactions,
            financialTransactions.rateMicro,
          );
        }
        await _createV5Indexes();
      }
      if (from < 6) {
        await m.createTable(loans);
        await m.createTable(loanPayments);
        await m.createTable(creditCards);
        await m.createTable(creditCardBills);
        await m.createTable(creditCardPayments);
        await _createV6Indexes();
      }
      if (from < 7) {
        // Loans created by the v6 step above already have the v7 columns.
        if (from >= 6) {
          await m.addColumn(loans, loans.closingType);
          await m.addColumn(loans, loans.closedDate);
          await m.addColumn(loans, loans.closingRemarks);
          await m.addColumn(loans, loans.closingPaidMinor);
          await m.addColumn(loans, loans.parentLoanId);
        }
        await m.createTable(fixedDeposits);
        await m.createTable(fixedDepositTerms);
        await _createV7Indexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Case-insensitive uniqueness rules (names are unique per parent).
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX uq_profiles_name ON financial_profiles (name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_categories_profile_name ON categories (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_sub_categories_cat_name ON sub_categories (profile_id, category_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_cost_items_sub_name ON cost_items (profile_id, sub_category_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX idx_sub_categories_category ON sub_categories (profile_id, category_id)',
    );
    await customStatement(
      'CREATE INDEX idx_cost_items_sub ON cost_items (profile_id, sub_category_id)',
    );
  }

  /// v4 indexes (recurring, goals, debts, tags, attachments).
  Future<void> _createV4Indexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_tags_profile_name ON tags (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_goals_profile_name ON savings_goals (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_due ON recurring_rules (profile_id, is_active, next_due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments (profile_id, debt_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txn_tags_tag ON transaction_tags (profile_id, tag_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_txn ON transaction_attachments (profile_id, transaction_id)',
    );
  }

  /// v6 indexes (loans, credit cards).
  Future<void> _createV6Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments (profile_id, loan_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_cards_profile_name ON credit_cards (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_card_bills_month ON credit_card_bills (profile_id, card_id, bill_month) WHERE is_active = 1',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_card_bills_card ON credit_card_bills (profile_id, card_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_card_payments_bill ON credit_card_payments (profile_id, bill_id)',
    );
  }

  /// v7 indexes (fixed deposits).
  Future<void> _createV7Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fd_terms_deposit ON fixed_deposit_terms (profile_id, deposit_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_fd_terms_instrument ON fixed_deposit_terms (profile_id, instrument_number COLLATE NOCASE)',
    );
  }

  /// v5 indexes (exchange rates).
  Future<void> _createV5Indexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_rates_profile_code ON exchange_rates (profile_id, currency_code)',
    );
  }

  /// v2 indexes (accounts, transactions, audit).
  Future<void> _createV2Indexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_accounts_profile_name ON accounts (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txn_profile_date ON financial_transactions (profile_id, is_deleted, txn_date, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txn_account ON financial_transactions (profile_id, account_id, txn_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txn_to_account ON financial_transactions (profile_id, to_account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_txn_category ON financial_transactions (profile_id, category_id, txn_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_txn ON transaction_audit_logs (profile_id, transaction_id, id)',
    );
  }
}

/// Opens the app database in application-private storage.
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'mybudget.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
