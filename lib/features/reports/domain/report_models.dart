/// Pure report models. All money is integer minor units (paisa).
library;

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.amountMinor,
  });

  /// Null for expenses without a category (legacy/uncategorised).
  final int? categoryId;

  /// Latest name snapshot recorded on the transactions.
  final String name;
  final int amountMinor;
}

class SubCategoryTotal {
  const SubCategoryTotal({
    required this.categoryId,
    required this.subCategoryId,
    required this.categoryName,
    required this.name,
    required this.amountMinor,
  });

  final int? categoryId;
  final int? subCategoryId;
  final String categoryName;
  final String name;
  final int amountMinor;
}

class ItemTotal {
  const ItemTotal({
    required this.categoryId,
    required this.subCategoryId,
    required this.costItemId,
    required this.categoryName,
    required this.subCategoryName,
    required this.name,
    required this.amountMinor,
  });

  final int? categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final String categoryName;
  final String subCategoryName;
  final String name;
  final int amountMinor;
}

class DailyTotal {
  const DailyTotal({required this.date, required this.amountMinor});

  /// 'yyyy-MM-dd'
  final String date;
  final int amountMinor;
}

class AccountMovement {
  const AccountMovement({
    required this.accountId,
    required this.accountName,
    required this.openingMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.transferInMinor,
    required this.transferOutMinor,
  });

  final int accountId;
  final String accountName;

  /// Balance carried in at the start of the period (or the account's opening
  /// balance when it was opened during the period).
  final int openingMinor;
  final int incomeMinor;
  final int expenseMinor;
  final int transferInMinor;
  final int transferOutMinor;

  int get closingMinor =>
      openingMinor +
      incomeMinor -
      expenseMinor +
      transferInMinor -
      transferOutMinor;

  bool get hasActivity =>
      incomeMinor != 0 ||
      expenseMinor != 0 ||
      transferInMinor != 0 ||
      transferOutMinor != 0;
}

/// Integer per-mille of [part] over [whole], rounded half up. Null when
/// [whole] is not positive. Avoids floating point.
int? permille(int part, int whole) {
  if (whole <= 0) return null;
  return (part * 1000 + whole ~/ 2) ~/ whole;
}

class MonthlyReport {
  const MonthlyReport({
    required this.profileId,
    required this.profileName,
    required this.currencyCode,
    required this.year,
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.budgetMinor,
    required this.categories,
    required this.subCategories,
    required this.items,
    required this.daily,
    required this.accounts,
  });

  final int profileId;
  final String profileName;
  final String currencyCode;
  final int year;
  final int month;
  final int incomeMinor;
  final int expenseMinor;

  /// Null when no budget is set for the month.
  final int? budgetMinor;
  final List<CategoryTotal> categories;
  final List<SubCategoryTotal> subCategories;
  final List<ItemTotal> items;

  /// One entry per calendar day of the month (zeros included).
  final List<DailyTotal> daily;
  final List<AccountMovement> accounts;

  int get netMinor => incomeMinor - expenseMinor;

  /// Budget - expense (may be negative). Null without a budget.
  int? get remainingMinor =>
      budgetMinor == null ? null : budgetMinor! - expenseMinor;

  /// Expense / budget in per-mille; null when budget is missing or zero.
  int? get utilizationPermille =>
      budgetMinor == null ? null : permille(expenseMinor, budgetMinor!);

  bool get isEmpty =>
      incomeMinor == 0 &&
      expenseMinor == 0 &&
      budgetMinor == null &&
      accounts.every((a) => !a.hasActivity);
}

class YearlyMonthRow {
  const YearlyMonthRow({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.budgetMinor,
  });

  /// 1..12
  final int month;
  final int incomeMinor;
  final int expenseMinor;

  /// Null when no budget exists for this month.
  final int? budgetMinor;

  int? get remainingMinor =>
      budgetMinor == null ? null : budgetMinor! - expenseMinor;
}

class CategoryYearRow {
  const CategoryYearRow({
    required this.categoryId,
    required this.name,
    required this.monthlyMinor,
  });

  final int? categoryId;
  final String name;

  /// Exactly 12 entries, January first.
  final List<int> monthlyMinor;

  int get totalMinor => monthlyMinor.fold(0, (a, b) => a + b);
}

class YearlyReport {
  const YearlyReport({
    required this.profileId,
    required this.profileName,
    required this.currencyCode,
    required this.year,
    required this.months,
    required this.categories,
  });

  final int profileId;
  final String profileName;
  final String currencyCode;
  final int year;

  /// Always exactly 12 rows (empty months are zero).
  final List<YearlyMonthRow> months;

  /// Category x 12 months matrix, sorted by total descending.
  final List<CategoryYearRow> categories;

  int get incomeMinor => months.fold(0, (a, m) => a + m.incomeMinor);
  int get expenseMinor => months.fold(0, (a, m) => a + m.expenseMinor);

  /// Sum of the monthly budgets; null when no month has a budget.
  int? get budgetMinor {
    final withBudget = months.where((m) => m.budgetMinor != null);
    if (withBudget.isEmpty) return null;
    return withBudget.fold<int>(0, (a, m) => a + m.budgetMinor!);
  }

  int? get remainingMinor =>
      budgetMinor == null ? null : budgetMinor! - expenseMinor;

  /// Average over all 12 months (empty months count as zero), rounded half
  /// up to the nearest minor unit.
  int get averageMonthlyExpenseMinor => (expenseMinor + 6) ~/ 12;

  /// Month with the highest expense; earliest wins ties. Null when the year
  /// has no expense at all.
  YearlyMonthRow? get highestSpendingMonth {
    YearlyMonthRow? best;
    for (final m in months) {
      if (m.expenseMinor <= 0) continue;
      if (best == null || m.expenseMinor > best.expenseMinor) best = m;
    }
    return best;
  }

  /// Month with the lowest expense AMONG months that have expense (an empty
  /// month is not "lowest spending"). Earliest wins ties. Null if none.
  YearlyMonthRow? get lowestSpendingMonth {
    YearlyMonthRow? best;
    for (final m in months) {
      if (m.expenseMinor <= 0) continue;
      if (best == null || m.expenseMinor < best.expenseMinor) best = m;
    }
    return best;
  }

  bool get isEmpty =>
      incomeMinor == 0 && expenseMinor == 0 && budgetMinor == null;
}

class RangeReport {
  const RangeReport({
    required this.profileId,
    required this.profileName,
    required this.currencyCode,
    required this.from,
    required this.to,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.categories,
    required this.subCategories,
    required this.items,
    required this.daily,
  });

  final int profileId;
  final String profileName;
  final String currencyCode;

  /// Inclusive 'yyyy-MM-dd'.
  final String from;
  final String to;
  final int incomeMinor;
  final int expenseMinor;
  final List<CategoryTotal> categories;
  final List<SubCategoryTotal> subCategories;
  final List<ItemTotal> items;

  /// Expense per day for every day in the range (zeros included).
  final List<DailyTotal> daily;

  int get netMinor => incomeMinor - expenseMinor;
  bool get isEmpty => incomeMinor == 0 && expenseMinor == 0;
}
