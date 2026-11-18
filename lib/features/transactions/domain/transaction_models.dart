class TransactionType {
  TransactionType._();
  static const expense = 'expense';
  static const income = 'income';
  static const transfer = 'transfer';
}

/// A ledger transaction with names taken from the stored snapshots, so history
/// stays readable after masters are renamed.
class TransactionView {
  const TransactionView({
    required this.id,
    required this.profileId,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.subCategoryId,
    this.costItemId,
    required this.accountName,
    this.toAccountName,
    this.categoryName,
    this.subCategoryName,
    this.costItemName,
    this.incomeSource,
    required this.amountMinor,
    this.originalAmountMinor,
    this.originalCurrency,
    this.rateMicro,
    required this.date,
    this.title,
    this.remarks,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String type;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final String accountName;
  final String? toAccountName;
  final String? categoryName;
  final String? subCategoryName;
  final String? costItemName;
  final String? incomeSource;
  final int amountMinor;

  /// Foreign-currency entry (all three set, or all null). [amountMinor] is
  /// always the converted base-currency amount.
  final int? originalAmountMinor;
  final String? originalCurrency;
  final int? rateMicro;

  bool get isForeign =>
      originalAmountMinor != null &&
      originalCurrency != null &&
      rateMicro != null;

  /// 'yyyy-MM-dd'
  final String date;
  final String? title;
  final String? remarks;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;

  /// Short human description used in lists.
  String get description {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    switch (type) {
      case TransactionType.expense:
        return costItemName ?? subCategoryName ?? categoryName ?? 'Expense';
      case TransactionType.income:
        return incomeSource ?? 'Income';
      default:
        return 'Transfer $accountName → ${toAccountName ?? ''}';
    }
  }
}

class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.fromDate,
    this.toDate,
    this.search = '',
    this.includeDeleted = false,
    this.limit,
  });

  final String? type;
  final String? fromDate;
  final String? toDate;
  final String search;
  final bool includeDeleted;
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.fromDate == fromDate &&
      other.toDate == toDate &&
      other.search == search &&
      other.includeDeleted == includeDeleted &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(type, fromDate, toDate, search, includeDeleted, limit);
}

class TransactionAuditEntry {
  const TransactionAuditEntry({
    required this.id,
    required this.transactionId,
    required this.action,
    this.previousJson,
    this.newJson,
    required this.createdAt,
  });

  final int id;
  final int transactionId;

  /// create | update | delete | restore
  final String action;
  final String? previousJson;
  final String? newJson;
  final DateTime createdAt;
}

/// A favourite cost item with its active parents, for the quick-add chips.
class FavouriteCostItem {
  const FavouriteCostItem({
    required this.costItemId,
    required this.name,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.categoryId,
    required this.categoryName,
    this.defaultAmountMinor,
  });

  final int costItemId;
  final String name;
  final int subCategoryId;
  final String subCategoryName;
  final int categoryId;
  final String categoryName;
  final int? defaultAmountMinor;
}

/// One category/item/amount line of a split bill.
class SplitExpenseLine {
  const SplitExpenseLine({
    required this.categoryId,
    this.subCategoryId,
    this.costItemId,
    required this.amountMinor,
  });

  final int categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final int amountMinor;
}
