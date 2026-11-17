import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/ledger_models.dart';

/// Read-only ledger queries. Running balances are computed with SQL window
/// functions at query time and are never stored.
///
/// Account balance semantic: opening balance + every non-deleted movement
/// dated on/after the account's opening date (earlier rows are ignored).
class LedgerRepository {
  LedgerRepository(this._db);
  final AppDatabase _db;

  Stream<List<LedgerAccount>> watchAccounts(int profileId) {
    final q = _db.select(_db.accounts)
      ..where((a) => a.profileId.equals(profileId))
      ..orderBy([
        (a) => OrderingTerm.desc(a.isActive),
        (a) => OrderingTerm.asc(a.name),
      ]);
    return q.watch().map(
      (rows) => [
        for (final a in rows)
          LedgerAccount(
            id: a.id,
            name: a.name,
            type: a.type,
            isActive: a.isActive,
          ),
      ],
    );
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Reactive account ledger. [from]/[to] are 'yyyy-MM-dd' (inclusive) and
  /// default to unbounded. The running balance always carries in the opening
  /// balance plus everything dated before [from]. Throws [NotFoundException] /
  /// [ProfileMismatchException] for a missing or foreign account.
  Stream<AccountLedger> watchAccountLedger({
    required int profileId,
    required int accountId,
    String? from,
    String? to,
    String? search,
  }) async* {
    final acc = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (acc == null) throw NotFoundException('Account not found.');
    if (acc.profileId != profileId) {
      throw ProfileMismatchException('Account belongs to a different profile.');
    }
    final term = search?.trim().toLowerCase() ?? '';
    final pattern = term.isEmpty ? null : '%${_escapeLike(term)}%';

    yield* _db
        .customSelect(
          _accountSql,
          variables: [
            Variable<int>(profileId),
            Variable<int>(accountId),
            Variable<String>(from ?? '0000-00-00'),
            Variable<String>(to ?? '9999-12-31'),
            Variable<String>(pattern),
          ],
          readsFrom: {_db.financialTransactions, _db.accounts},
        )
        .watch()
        .map(
          (rows) => AccountLedger([
            for (final r in rows) _mapAccountRow(r, accountId),
          ]),
        );
  }

  AccountLedgerRow _mapAccountRow(QueryRow r, int accountId) {
    final isOpening = r.read<int>('kind') == 0;
    final balance = r.read<int>('balance');
    if (isOpening) {
      return AccountLedgerRow(
        id: 0,
        date: r.read<String>('txn_date'),
        description: 'Opening Balance',
        detail: '',
        incomeMinor: 0,
        expenseMinor: 0,
        transferInMinor: 0,
        transferOutMinor: 0,
        balanceMinor: balance,
        isOpening: true,
      );
    }
    final type = r.read<String>('type');
    final amount = r.read<int>('amount');
    final toId = r.readNullable<int>('to_account_id');
    final title = _clean(r.readNullable<String>('title'));
    final remarks = _clean(r.readNullable<String>('remarks'));
    final cat = _clean(r.readNullable<String>('cat'));
    final sub = _clean(r.readNullable<String>('sub'));
    final item = _clean(r.readNullable<String>('item'));
    final source = _clean(r.readNullable<String>('income_source'));
    final accName = r.read<String>('acc_name');
    final toName = _clean(r.readNullable<String>('to_acc_name'));

    var income = 0, expense = 0, tin = 0, tout = 0;
    String fallback;
    final parts = <String>[];
    switch (type) {
      case 'income':
        income = amount;
        fallback = source ?? 'Income';
        if (source != null && title != null) parts.add(source);
      case 'expense':
        expense = amount;
        fallback = item ?? cat ?? 'Expense';
        parts.addAll([?cat, ?sub, ?item]);
      default:
        if (toId == accountId) {
          tin = amount;
          fallback = 'Transfer from $accName';
        } else {
          tout = amount;
          fallback = 'Transfer to ${toName ?? 'account'}';
        }
    }
    if (remarks != null) parts.add(remarks);
    return AccountLedgerRow(
      id: r.read<int>('id'),
      date: r.read<String>('txn_date'),
      description: title ?? fallback,
      detail: parts.join(' · '),
      incomeMinor: income,
      expenseMinor: expense,
      transferInMinor: tin,
      transferOutMinor: tout,
      balanceMinor: balance,
      isOpening: false,
    );
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Reactive budget ledger for one month: expenses only, with remaining
  /// budget = monthly budget - cumulative expense (null when no budget set).
  Stream<BudgetLedger> watchBudgetLedger({
    required int profileId,
    required int year,
    required int month,
  }) {
    return _db
        .customSelect(
          _budgetSql,
          variables: [
            Variable<int>(profileId),
            Variable<int>(year),
            Variable<int>(month),
            Variable<String>(monthStartKey(year, month)),
            Variable<String>(monthEndKey(year, month)),
          ],
          readsFrom: {_db.financialTransactions, _db.monthlyBudgets},
        )
        .watch()
        .map((rows) {
          int? budget;
          final out = <BudgetLedgerRow>[];
          for (final r in rows) {
            if (r.read<int>('kind') == 0) {
              budget = r.readNullable<int>('budget');
              continue;
            }
            out.add(
              BudgetLedgerRow(
                id: r.read<int>('id'),
                date: r.read<String>('txn_date'),
                costItem:
                    _clean(r.readNullable<String>('item')) ??
                    _clean(r.readNullable<String>('title')) ??
                    '-',
                category: _clean(r.readNullable<String>('cat')) ?? '-',
                expenseMinor: r.read<int>('amount'),
                remainingMinor: r.readNullable<int>('remaining'),
              ),
            );
          }
          return BudgetLedger(budgetMinor: budget, rows: out);
        });
  }

  static const _accountSql = r'''
WITH acc AS (
  SELECT opening_balance_minor AS ob, opening_date AS od
  FROM accounts WHERE id = ?2 AND profile_id = ?1
), mv AS (
  SELECT t.id, t.txn_date, t.type, t.account_id, t.to_account_id, t.title,
         t.remarks, t.category_name_snapshot AS cat,
         t.sub_category_name_snapshot AS sub,
         t.cost_item_name_snapshot AS item, t.income_source,
         t.account_name_snapshot AS acc_name,
         t.to_account_name_snapshot AS to_acc_name,
         t.amount_minor AS amount,
         CASE WHEN t.type = 'income' THEN t.amount_minor
              WHEN t.type = 'expense' THEN -t.amount_minor
              WHEN t.to_account_id = ?2 THEN t.amount_minor
              ELSE -t.amount_minor END AS delta
  FROM financial_transactions t
  WHERE t.profile_id = ?1 AND t.is_deleted = 0
    AND t.txn_date >= (SELECT od FROM acc)
    AND (t.account_id = ?2 OR t.to_account_id = ?2)
), cum AS (
  SELECT mv.*,
         SUM(delta) OVER (ORDER BY txn_date, id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS run
  FROM mv
)
SELECT * FROM (
  SELECT 0 AS kind, 0 AS id,
         CASE WHEN ?3 > od THEN ?3 ELSE od END AS txn_date,
         NULL AS type, NULL AS account_id, NULL AS to_account_id,
         NULL AS title, NULL AS remarks, NULL AS cat, NULL AS sub,
         NULL AS item, NULL AS income_source, NULL AS acc_name,
         NULL AS to_acc_name, 0 AS amount,
         ob + COALESCE((SELECT SUM(delta) FROM mv WHERE txn_date < ?3), 0)
           AS balance
  FROM acc
  UNION ALL
  SELECT 1, id, txn_date, type, account_id, to_account_id, title, remarks,
         cat, sub, item, income_source, acc_name, to_acc_name, amount,
         (SELECT ob FROM acc) + run
  FROM cum
  WHERE txn_date >= ?3 AND txn_date <= ?4
    AND (?5 IS NULL OR lower(
      coalesce(title, '') || char(10) || coalesce(remarks, '') || char(10) ||
      coalesce(cat, '') || char(10) || coalesce(sub, '') || char(10) ||
      coalesce(item, '') || char(10) || coalesce(income_source, '')
    ) LIKE ?5 ESCAPE '\')
) ORDER BY kind, txn_date, id
''';

  static const _budgetSql = r'''
WITH b AS (
  SELECT total_budget_minor AS tb FROM monthly_budgets
  WHERE profile_id = ?1 AND year = ?2 AND month = ?3
), e AS (
  SELECT t.id, t.txn_date, t.title,
         t.cost_item_name_snapshot AS item,
         t.category_name_snapshot AS cat, t.amount_minor AS amount,
         SUM(t.amount_minor) OVER (ORDER BY t.txn_date, t.id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum
  FROM financial_transactions t
  WHERE t.profile_id = ?1 AND t.is_deleted = 0 AND t.type = 'expense'
    AND t.txn_date >= ?4 AND t.txn_date <= ?5
)
SELECT * FROM (
  SELECT 0 AS kind, 0 AS id, '' AS txn_date, NULL AS title, NULL AS item,
         NULL AS cat, 0 AS amount, (SELECT tb FROM b) AS budget,
         NULL AS remaining
  UNION ALL
  SELECT 1, id, txn_date, title, item, cat, amount, NULL,
         (SELECT tb FROM b) - cum
  FROM e
) ORDER BY kind, txn_date, id
''';
}
