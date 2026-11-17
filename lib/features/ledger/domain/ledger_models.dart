/// Account owned by the active profile, as needed by the ledger picker.
class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
  });

  final int id;
  final String name;
  final String type;
  final bool isActive;
}

/// One line of an account ledger. Exactly one of the four amount fields is
/// non-zero for a movement row; the opening row has all four at zero.
class AccountLedgerRow {
  const AccountLedgerRow({
    required this.id,
    required this.date,
    required this.description,
    required this.detail,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.transferInMinor,
    required this.transferOutMinor,
    required this.balanceMinor,
    required this.isOpening,
  });

  /// Transaction id (0 for the opening-balance row).
  final int id;

  /// 'yyyy-MM-dd'.
  final String date;
  final String description;

  /// Secondary line (category path / remarks); may be empty.
  final String detail;
  final int incomeMinor;
  final int expenseMinor;
  final int transferInMinor;
  final int transferOutMinor;

  /// Running balance after this row (computed in SQL, never stored).
  final int balanceMinor;
  final bool isOpening;
}

/// Ledger for one account over a date range. `rows.first` is always the
/// opening row whose balance already includes everything before the range.
class AccountLedger {
  const AccountLedger(this.rows);

  final List<AccountLedgerRow> rows;

  bool get hasMovements => rows.length > 1;
  int get openingBalanceMinor => rows.isEmpty ? 0 : rows.first.balanceMinor;
  int get closingBalanceMinor => rows.isEmpty ? 0 : rows.last.balanceMinor;
  int get totalIncomeMinor => rows.fold(0, (s, r) => s + r.incomeMinor);
  int get totalExpenseMinor => rows.fold(0, (s, r) => s + r.expenseMinor);
  int get totalTransferInMinor => rows.fold(0, (s, r) => s + r.transferInMinor);
  int get totalTransferOutMinor =>
      rows.fold(0, (s, r) => s + r.transferOutMinor);
}

class BudgetLedgerRow {
  const BudgetLedgerRow({
    required this.id,
    required this.date,
    required this.costItem,
    required this.category,
    required this.expenseMinor,
    required this.remainingMinor,
  });

  final int id;
  final String date;
  final String costItem;
  final String category;
  final int expenseMinor;

  /// Monthly budget minus cumulative expense; null when no budget is set.
  final int? remainingMinor;
}

class BudgetLedger {
  const BudgetLedger({required this.budgetMinor, required this.rows});

  /// Null when no budget exists for the month.
  final int? budgetMinor;
  final List<BudgetLedgerRow> rows;

  int get totalExpenseMinor => rows.fold(0, (s, r) => s + r.expenseMinor);
  int? get remainingMinor =>
      budgetMinor == null ? null : budgetMinor! - totalExpenseMinor;
}
