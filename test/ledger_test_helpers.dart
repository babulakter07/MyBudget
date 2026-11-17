import 'package:drift/drift.dart';
import 'package:my_budget/core/database/app_database.dart';

final _now = DateTime(2026);

Future<int> addProfile(AppDatabase db, [String name = 'P']) => db
    .into(db.financialProfiles)
    .insert(
      FinancialProfilesCompanion.insert(
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addAccount(
  AppDatabase db,
  int profileId,
  String name, {
  int opening = 0,
  String openingDate = '2026-01-01',
  bool active = true,
}) => db
    .into(db.accounts)
    .insert(
      AccountsCompanion.insert(
        profileId: profileId,
        name: name,
        openingBalanceMinor: Value(opening),
        openingDate: openingDate,
        isActive: Value(active),
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addCategory(AppDatabase db, int profileId, String name) => db
    .into(db.categories)
    .insert(
      CategoriesCompanion.insert(
        profileId: profileId,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addSubCategory(
  AppDatabase db,
  int profileId,
  int categoryId,
  String name,
) => db
    .into(db.subCategories)
    .insert(
      SubCategoriesCompanion.insert(
        profileId: profileId,
        categoryId: categoryId,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addCostItem(
  AppDatabase db,
  int profileId,
  int subCategoryId,
  String name,
) => db
    .into(db.costItems)
    .insert(
      CostItemsCompanion.insert(
        profileId: profileId,
        subCategoryId: subCategoryId,
        name: name,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<int> addBudget(
  AppDatabase db,
  int profileId,
  int year,
  int month,
  int totalMinor,
) => db
    .into(db.monthlyBudgets)
    .insert(
      MonthlyBudgetsCompanion.insert(
        profileId: profileId,
        year: year,
        month: month,
        totalBudgetMinor: totalMinor,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

/// Inserts a transaction row directly. Snapshot names are given as plain
/// strings; ids are optional but must satisfy the FK when provided.
Future<int> addTxn(
  AppDatabase db, {
  required int profileId,
  required String type,
  required int accountId,
  required int amount,
  required String date,
  int? toAccountId,
  int? categoryId,
  int? subCategoryId,
  int? costItemId,
  String accountName = 'Acc',
  String? toAccountName,
  String? category,
  String? subCategory,
  String? costItem,
  String? incomeSource,
  String? title,
  String? remarks,
  bool deleted = false,
}) => db
    .into(db.financialTransactions)
    .insert(
      FinancialTransactionsCompanion.insert(
        profileId: profileId,
        type: type,
        accountId: accountId,
        toAccountId: Value(toAccountId),
        categoryId: Value(categoryId),
        subCategoryId: Value(subCategoryId),
        costItemId: Value(costItemId),
        accountNameSnapshot: accountName,
        toAccountNameSnapshot: Value(toAccountName),
        categoryNameSnapshot: Value(category),
        subCategoryNameSnapshot: Value(subCategory),
        costItemNameSnapshot: Value(costItem),
        incomeSource: Value(incomeSource),
        amountMinor: amount,
        txnDate: date,
        title: Value(title),
        remarks: Value(remarks),
        isDeleted: Value(deleted),
        createdAt: _now,
        updatedAt: _now,
      ),
    );
