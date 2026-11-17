import 'package:drift/drift.dart';
import 'package:my_budget/core/database/app_database.dart';

final _now = DateTime(2026);

Future<int> addProfile(AppDatabase db, String name) => db
    .into(db.financialProfiles)
    .insert(
      FinancialProfilesCompanion.insert(
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addCategory(AppDatabase db, int p, String name) => db
    .into(db.categories)
    .insert(
      CategoriesCompanion.insert(
        profileId: p,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addSub(AppDatabase db, int p, int cat, String name) => db
    .into(db.subCategories)
    .insert(
      SubCategoriesCompanion.insert(
        profileId: p,
        categoryId: cat,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addItem(AppDatabase db, int p, int sub, String name) => db
    .into(db.costItems)
    .insert(
      CostItemsCompanion.insert(
        profileId: p,
        subCategoryId: sub,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addAccount(
  AppDatabase db,
  int p,
  String name, {
  int opening = 0,
  String openingDate = '2020-01-01',
}) => db
    .into(db.accounts)
    .insert(
      AccountsCompanion.insert(
        profileId: p,
        name: name,
        openingBalanceMinor: Value(opening),
        openingDate: openingDate,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<void> addBudget(AppDatabase db, int p, int year, int month, int minor) =>
    db
        .into(db.monthlyBudgets)
        .insert(
          MonthlyBudgetsCompanion.insert(
            profileId: p,
            year: year,
            month: month,
            totalBudgetMinor: minor,
            createdAt: _now,
            updatedAt: _now,
          ),
        );

Future<int> addExpense(
  AppDatabase db,
  int p, {
  required int account,
  required int category,
  int? sub,
  int? item,
  required int amount,
  required String date,
  String accountName = 'Cash',
  String categoryName = 'Food',
  String? subName,
  String? itemName,
  bool deleted = false,
}) => db
    .into(db.financialTransactions)
    .insert(
      FinancialTransactionsCompanion.insert(
        profileId: p,
        type: 'expense',
        accountId: account,
        categoryId: Value(category),
        subCategoryId: Value(sub),
        costItemId: Value(item),
        accountNameSnapshot: accountName,
        categoryNameSnapshot: Value(categoryName),
        subCategoryNameSnapshot: Value(subName),
        costItemNameSnapshot: Value(itemName),
        amountMinor: amount,
        txnDate: date,
        isDeleted: Value(deleted),
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addIncome(
  AppDatabase db,
  int p, {
  required int account,
  required int amount,
  required String date,
  bool deleted = false,
}) => db
    .into(db.financialTransactions)
    .insert(
      FinancialTransactionsCompanion.insert(
        profileId: p,
        type: 'income',
        accountId: account,
        accountNameSnapshot: 'Cash',
        incomeSource: const Value('Salary'),
        amountMinor: amount,
        txnDate: date,
        isDeleted: Value(deleted),
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addTransfer(
  AppDatabase db,
  int p, {
  required int from,
  required int to,
  required int amount,
  required String date,
}) => db
    .into(db.financialTransactions)
    .insert(
      FinancialTransactionsCompanion.insert(
        profileId: p,
        type: 'transfer',
        accountId: from,
        toAccountId: Value(to),
        accountNameSnapshot: 'from',
        toAccountNameSnapshot: const Value('to'),
        amountMinor: amount,
        txnDate: date,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
