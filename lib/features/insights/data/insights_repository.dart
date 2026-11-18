import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/insights_calculations.dart';
import '../domain/insights_models.dart';

/// Read-only spending insights. Every query filters `profile_id` and
/// (for transactions) `is_deleted = 0`. Only `expense` rows feed the spending
/// insights; income is used solely for the savings rate.
class InsightsRepository {
  InsightsRepository(this._db);
  final AppDatabase _db;

  static const _uncategorized = 'Uncategorized';

  /// Re-emits whenever transactions, budgets, recurring rules or categories
  /// change.
  Stream<Insights> watchInsights(
    int profileId,
    int year,
    int month, {
    required DateTime now,
  }) {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.financialTransactions,
            _db.monthlyBudgets,
            _db.recurringRules,
            _db.categories,
          },
        )
        .watch()
        .asyncMap((_) => compute(profileId, year, month, now: now));
  }

  /// Computes the insights for [year]/[month]; [now] supplies "today".
  Future<Insights> compute(
    int profileId,
    int year,
    int month, {
    required DateTime now,
  }) async {
    final start = monthStartKey(year, month);
    final end = monthEndKey(year, month);
    final prev = DateTime(year, month - 1);
    final prevStart = monthStartKey(prev.year, prev.month);
    final prevEnd = monthEndKey(prev.year, prev.month);
    final isCurrent = now.year == year && now.month == month;
    final today = DateTime(now.year, now.month, now.day);

    final cur = await _categoryTotals(profileId, start, end);
    final prv = await _categoryTotals(profileId, prevStart, prevEnd);
    final comparison = MonthComparison(
      currentMinor: cur.values.fold(0, (a, b) => a + b.minor),
      previousMinor: prv.values.fold(0, (a, b) => a + b.minor),
      categories: InsightsCalculations.categoryDeltas(cur, prv),
    );

    final income = await _sum(profileId, 'income', start, end);

    return Insights(
      year: year,
      month: month,
      isCurrentMonth: isCurrent,
      comparison: comparison,
      unusual: await _unusual(profileId, year, month, start, end),
      forecast: isCurrent
          ? await _forecast(profileId, year, month, start, end, today)
          : null,
      weekdays: await _weekdays(profileId, year, month, end, today, isCurrent),
      topItems: await _topItems(profileId, start, end),
      savings: SavingsRate(
        incomeMinor: income,
        expenseMinor: comparison.currentMinor,
      ),
    );
  }

  Future<int> _sum(int profileId, String type, String from, String to) async {
    final r = await _db
        .customSelect(
          r'''
SELECT COALESCE(SUM(amount_minor), 0) AS s FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = ?2
  AND txn_date >= ?3 AND txn_date <= ?4
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(type),
            Variable<String>(from),
            Variable<String>(to),
          ],
        )
        .getSingle();
    return r.read<int>('s');
  }

  Future<Map<int?, ({String name, int minor})>> _categoryTotals(
    int profileId,
    String from,
    String to,
  ) async {
    final rows = await _db
        .customSelect(
          r'''
SELECT t.category_id AS cid,
       COALESCE(c.name, MAX(t.category_name_snapshot), ?4) AS name,
       SUM(t.amount_minor) AS total
FROM financial_transactions t
LEFT JOIN categories c ON c.id = t.category_id AND c.profile_id = t.profile_id
WHERE t.profile_id = ?1 AND t.is_deleted = 0 AND t.type = 'expense'
  AND t.txn_date >= ?2 AND t.txn_date <= ?3
GROUP BY t.category_id
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(from),
            Variable<String>(to),
            const Variable<String>(_uncategorized),
          ],
        )
        .get();
    return {
      for (final r in rows)
        r.readNullable<int>('cid'): (
          name: r.read<String>('name'),
          minor: r.read<int>('total'),
        ),
    };
  }

  /// Transactions this month above mean + 2*stddev (population) of the same
  /// category's expenses over the previous 6 full months; categories need at
  /// least [InsightsCalculations.minOutlierSamples] historical samples.
  /// Top 5 by excess over the mean.
  Future<List<UnusualTransaction>> _unusual(
    int profileId,
    int year,
    int month,
    String start,
    String end,
  ) async {
    final histStart = monthStartKey(
      DateTime(year, month - 6).year,
      DateTime(year, month - 6).month,
    );
    final histEndD = DateTime(year, month, 0);
    final histEnd = dateKey(histEndD);

    final hist = await _db
        .customSelect(
          r'''
SELECT category_id AS cid, COUNT(*) AS n, SUM(amount_minor) AS s,
       SUM(amount_minor * amount_minor) AS sq
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY category_id
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(histStart),
            Variable<String>(histEnd),
          ],
        )
        .get();
    final stats = {
      for (final r in hist)
        r.readNullable<int>('cid'): (
          n: r.read<int>('n'),
          sum: r.read<int>('s'),
          sq: r.read<int>('sq'),
        ),
    };
    if (stats.isEmpty) return const [];

    final rows = await _db
        .customSelect(
          r'''
SELECT t.id AS id, t.txn_date AS d, t.title AS title, t.amount_minor AS amt,
       t.category_id AS cid,
       COALESCE(c.name, t.category_name_snapshot, ?4) AS cname
FROM financial_transactions t
LEFT JOIN categories c ON c.id = t.category_id AND c.profile_id = t.profile_id
WHERE t.profile_id = ?1 AND t.is_deleted = 0 AND t.type = 'expense'
  AND t.txn_date >= ?2 AND t.txn_date <= ?3
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(start),
            Variable<String>(end),
            const Variable<String>(_uncategorized),
          ],
        )
        .get();

    final out = <UnusualTransaction>[];
    for (final r in rows) {
      final st = stats[r.readNullable<int>('cid')];
      if (st == null) continue;
      final amt = r.read<int>('amt');
      if (!InsightsCalculations.isOutlier(amt, st.n, st.sum, st.sq)) continue;
      out.add(
        UnusualTransaction(
          transactionId: r.read<int>('id'),
          date: r.read<String>('d'),
          title: r.readNullable<String>('title'),
          categoryName: r.read<String>('cname'),
          amountMinor: amt,
          usualMinor: InsightsCalculations.mean(st.n, st.sum),
        ),
      );
    }
    out.sort((a, b) {
      final c = b.excessMinor.compareTo(a.excessMinor);
      return c != 0 ? c : b.transactionId.compareTo(a.transactionId);
    });
    return out.take(5).toList();
  }

  Future<Forecast> _forecast(
    int profileId,
    int year,
    int month,
    String start,
    String end,
    DateTime today,
  ) async {
    final todayKey = dateKey(today);
    final spent = await _sum(profileId, 'expense', start, todayKey);
    final last14 = await _sum(
      profileId,
      'expense',
      dateKey(DateTime(today.year, today.month, today.day - 13)),
      todayKey,
    );
    final budgetRow = await _db
        .customSelect(
          r'''
SELECT COALESCE(SUM(total_budget_minor), 0) AS b FROM monthly_budgets
WHERE profile_id = ?1 AND year = ?2 AND month = ?3
''',
          variables: [
            Variable<int>(profileId),
            Variable<int>(year),
            Variable<int>(month),
          ],
        )
        .getSingle();

    final rules = await _db
        .customSelect(
          r'''
SELECT amount_minor, frequency, interval_count, start_date, end_date,
       next_due_date
FROM recurring_rules
WHERE profile_id = ?1 AND is_active = 1 AND type = 'expense'
''',
          variables: [Variable<int>(profileId)],
        )
        .get();
    var recurring = 0;
    for (final r in rules) {
      final n = InsightsCalculations.occurrencesInMonth(
        frequency: r.read<String>('frequency'),
        interval: r.read<int>('interval_count'),
        startDate: r.read<String>('start_date'),
        nextDue: r.read<String>('next_due_date'),
        endDate: r.readNullable<String>('end_date'),
        monthStart: start,
        monthEnd: end,
      );
      recurring += n * r.read<int>('amount_minor');
    }

    return InsightsCalculations.forecast(
      spentSoFarMinor: spent,
      last14Minor: last14,
      daysElapsed: today.day,
      daysInThisMonth: daysInMonth(year, month),
      recurringRemainingMinor: recurring,
      budgetMinor: budgetRow.read<int>('b'),
    );
  }

  /// Expense totals per weekday over the 90 days ending at today (current
  /// month) or at the month end (other months, capped at today).
  Future<List<WeekdayBucket>> _weekdays(
    int profileId,
    int year,
    int month,
    String monthEnd,
    DateTime today,
    bool isCurrent,
  ) async {
    var anchor = parseDateKey(monthEnd);
    if (isCurrent || anchor.isAfter(today)) anchor = today;
    final from = DateTime(anchor.year, anchor.month, anchor.day - 89);
    final rows = await _db
        .customSelect(
          r'''
SELECT CAST(strftime('%w', txn_date) AS INTEGER) AS dow,
       SUM(amount_minor) AS total
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY dow
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(dateKey(from)),
            Variable<String>(dateKey(anchor)),
          ],
        )
        .get();
    final totals = List<int>.filled(8, 0);
    for (final r in rows) {
      final dow = r.read<int>('dow');
      totals[dow == 0 ? 7 : dow] = r.read<int>('total');
    }
    return [
      for (var w = 1; w <= 7; w++)
        WeekdayBucket(weekday: w, totalMinor: totals[w]),
    ];
  }

  /// Top 5 cost items (falling back to title, then category) by total.
  Future<List<TopItem>> _topItems(
    int profileId,
    String start,
    String end,
  ) async {
    final rows = await _db
        .customSelect(
          r'''
SELECT COALESCE(NULLIF(TRIM(cost_item_name_snapshot), ''),
                NULLIF(TRIM(title), ''),
                category_name_snapshot, ?4) AS name,
       SUM(amount_minor) AS total
FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND txn_date >= ?2 AND txn_date <= ?3
GROUP BY name
ORDER BY total DESC, name ASC
LIMIT 5
''',
          variables: [
            Variable<int>(profileId),
            Variable<String>(start),
            Variable<String>(end),
            const Variable<String>(_uncategorized),
          ],
        )
        .get();
    return [
      for (final r in rows)
        TopItem(name: r.read<String>('name'), totalMinor: r.read<int>('total')),
    ];
  }
}
