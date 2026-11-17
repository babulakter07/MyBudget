import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/dashboard_calculations.dart';
import '../domain/dashboard_models.dart';

/// Read-only reactive dashboard queries. Every query filters `profile_id` and
/// `is_deleted = 0`; each stream re-emits when the tables it reads change.
class DashboardRepository {
  DashboardRepository(this._db);
  final AppDatabase _db;

  Set<ResultSetImplementation> get _txnTables => {_db.financialTransactions};

  /// Monthly budget, month expense and month income.
  Stream<MonthOverview> watchMonthOverview(int profileId, int year, int month) {
    return _db
        .customSelect(
          r'''
SELECT
  COALESCE((SELECT total_budget_minor FROM monthly_budgets
            WHERE profile_id = ?1 AND year = ?2 AND month = ?3), 0) AS budget,
  COALESCE((SELECT SUM(amount_minor) FROM financial_transactions
            WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
              AND txn_date >= ?4 AND txn_date <= ?5), 0) AS expense,
  COALESCE((SELECT SUM(amount_minor) FROM financial_transactions
            WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'income'
              AND txn_date >= ?4 AND txn_date <= ?5), 0) AS income
''',
          variables: [
            Variable<int>(profileId),
            Variable<int>(year),
            Variable<int>(month),
            Variable<String>(monthStartKey(year, month)),
            Variable<String>(monthEndKey(year, month)),
          ],
          readsFrom: {..._txnTables, _db.monthlyBudgets},
        )
        .watchSingle()
        .map(
          (r) => MonthOverview(
            budgetMinor: r.read<int>('budget'),
            expenseMinor: r.read<int>('expense'),
            incomeMinor: r.read<int>('income'),
          ),
        );
  }

  /// Actual cash across ACTIVE accounts:
  /// opening + income - expense + transfers in - transfers out (rows dated on
  /// or after each account's opening date). Independent of any budget.
  Stream<int> watchCashBalance(int profileId) {
    return _db
        .customSelect(
          r'''
SELECT COALESCE(SUM(
  a.opening_balance_minor + COALESCE((
    SELECT SUM(CASE
        WHEN t.type = 'income' THEN t.amount_minor
        WHEN t.type = 'expense' THEN -t.amount_minor
        WHEN t.to_account_id = a.id THEN t.amount_minor
        ELSE -t.amount_minor END)
    FROM financial_transactions t
    WHERE t.profile_id = a.profile_id AND t.is_deleted = 0
      AND t.txn_date >= a.opening_date
      AND (t.account_id = a.id OR t.to_account_id = a.id)), 0)
), 0) AS cash
FROM accounts a
WHERE a.profile_id = ?1 AND a.is_active = 1
''',
          variables: [Variable<int>(profileId)],
          readsFrom: {..._txnTables, _db.accounts},
        )
        .watchSingle()
        .map((r) => r.read<int>('cash'));
  }

  Stream<List<RankedAmount>> _watchGrouped(
    int profileId,
    int year,
    int month,
    String idCol,
    String nameCol,
  ) {
    return _db
        .customSelect(
          '''
SELECT $idCol AS gid, $nameCol AS gname, SUM(amount_minor) AS total,
       MAX(id) AS last_id
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND $idCol IS NOT NULL AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY $idCol
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(monthStartKey(year, month)),
            Variable<String>(monthEndKey(year, month)),
          ],
          readsFrom: _txnTables,
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              RankedAmount(
                id: r.read<int>('gid'),
                name: r.readNullable<String>('gname') ?? 'Unknown',
                amountMinor: r.read<int>('total'),
              ),
          ],
        );
  }

  /// Top [limit] cost items by expense in the month (ids + latest snapshots).
  Stream<List<RankedAmount>> watchTopCostItems(
    int profileId,
    int year,
    int month, {
    int limit = 5,
  }) => _watchGrouped(
    profileId,
    year,
    month,
    'cost_item_id',
    'cost_item_name_snapshot',
  ).map((l) => DashboardCalculations.topN(l, limit: limit));

  /// Every category with expense in the month, largest first (pie chart).
  Stream<List<RankedAmount>> watchCategoryTotals(
    int profileId,
    int year,
    int month,
  ) => _watchGrouped(
    profileId,
    year,
    month,
    'category_id',
    'category_name_snapshot',
  ).map((l) => DashboardCalculations.topN(l, limit: l.length));

  /// Top [limit] categories by expense in the month.
  Stream<List<RankedAmount>> watchTopCategories(
    int profileId,
    int year,
    int month, {
    int limit = 5,
  }) => watchCategoryTotals(
    profileId,
    year,
    month,
  ).map((l) => l.take(limit).toList());

  /// Expense per day in the month (days with spending only), ascending.
  Stream<List<DayAmount>> watchDailyExpenses(
    int profileId,
    int year,
    int month,
  ) {
    return _db
        .customSelect(
          r'''
SELECT txn_date, SUM(amount_minor) AS total
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY txn_date ORDER BY txn_date
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(monthStartKey(year, month)),
            Variable<String>(monthEndKey(year, month)),
          ],
          readsFrom: _txnTables,
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              DayAmount(r.read<String>('txn_date'), r.read<int>('total')),
          ],
        );
  }

  /// Income/expense for each of the 12 months of [year] (zeros included).
  Stream<YearlyTotals> watchYearlyTotals(int profileId, int year) {
    return _db
        .customSelect(
          r'''
SELECT CAST(substr(txn_date, 6, 2) AS INTEGER) AS m, type,
       SUM(amount_minor) AS total
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type IN ('expense', 'income')
  AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY m, type
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(monthStartKey(year, 1)),
            Variable<String>(monthEndKey(year, 12)),
          ],
          readsFrom: _txnTables,
        )
        .watch()
        .map((rows) {
          final exp = List<int>.filled(12, 0);
          final inc = List<int>.filled(12, 0);
          for (final r in rows) {
            final m = r.read<int>('m');
            if (m < 1 || m > 12) continue;
            final total = r.read<int>('total');
            if (r.read<String>('type') == 'expense') {
              exp[m - 1] = total;
            } else {
              inc[m - 1] = total;
            }
          }
          return YearlyTotals(
            year: year,
            expenseByMonth: exp,
            incomeByMonth: inc,
          );
        });
  }
}
