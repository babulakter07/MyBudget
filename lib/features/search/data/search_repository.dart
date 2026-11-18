import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/search_models.dart';

String _escapeLike(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

/// Read-only global transaction search. All SQL is profile-scoped and always
/// excludes soft-deleted rows.
class SearchRepository {
  SearchRepository(this._db);
  final AppDatabase _db;

  static const _textColumns = [
    't.title',
    't.remarks',
    't.income_source',
    't.account_name_snapshot',
    't.to_account_name_snapshot',
    't.category_name_snapshot',
    't.sub_category_name_snapshot',
    't.cost_item_name_snapshot',
    't.paid_by',
    't.for_whom',
  ];

  ({String where, List<Variable> vars}) _where(int profileId, SearchFilter f) {
    final sql = StringBuffer('t.profile_id = ? AND t.is_deleted = 0');
    final vars = <Variable>[Variable<int>(profileId)];

    // Each whitespace-separated term must match at least one text field
    // (or a tag name of the transaction).
    for (final term in f.query.trim().toLowerCase().split(RegExp(r'\s+'))) {
      if (term.isEmpty) continue;
      final p = '%${_escapeLike(term)}%';
      final ors = [
        for (final c in _textColumns)
          "lower(coalesce($c, '')) LIKE ? ESCAPE '\\'",
        'EXISTS (SELECT 1 FROM transaction_tags tt '
            'JOIN tags g ON g.profile_id = tt.profile_id AND g.id = tt.tag_id '
            'WHERE tt.profile_id = t.profile_id AND tt.transaction_id = t.id '
            "AND lower(g.name) LIKE ? ESCAPE '\\')",
      ];
      sql.write(' AND (${ors.join(' OR ')})');
      vars.addAll(List.generate(ors.length, (_) => Variable<String>(p)));
    }

    String marks(int n) => List.filled(n, '?').join(',');
    if (f.types.isNotEmpty) {
      sql.write(' AND t.type IN (${marks(f.types.length)})');
      vars.addAll(f.types.map((e) => Variable<String>(e)));
    }
    if (f.minAmountMinor != null) {
      sql.write(' AND t.amount_minor >= ?');
      vars.add(Variable<int>(f.minAmountMinor));
    }
    if (f.maxAmountMinor != null) {
      sql.write(' AND t.amount_minor <= ?');
      vars.add(Variable<int>(f.maxAmountMinor));
    }
    if (f.fromDate != null) {
      sql.write(' AND t.txn_date >= ?');
      vars.add(Variable<String>(f.fromDate));
    }
    if (f.toDate != null) {
      sql.write(' AND t.txn_date <= ?');
      vars.add(Variable<String>(f.toDate));
    }
    if (f.accountIds.isNotEmpty) {
      final m = marks(f.accountIds.length);
      sql.write(' AND (t.account_id IN ($m) OR t.to_account_id IN ($m))');
      for (var i = 0; i < 2; i++) {
        vars.addAll(f.accountIds.map((e) => Variable<int>(e)));
      }
    }
    if (f.categoryIds.isNotEmpty) {
      sql.write(' AND t.category_id IN (${marks(f.categoryIds.length)})');
      vars.addAll(f.categoryIds.map((e) => Variable<int>(e)));
    }
    if (f.tagIds.isNotEmpty) {
      sql.write(
        ' AND EXISTS (SELECT 1 FROM transaction_tags tt '
        'WHERE tt.profile_id = t.profile_id AND tt.transaction_id = t.id '
        'AND tt.tag_id IN (${marks(f.tagIds.length)}))',
      );
      vars.addAll(f.tagIds.map((e) => Variable<int>(e)));
    }
    return (where: sql.toString(), vars: vars);
  }

  static String _orderBy(SearchSort s) => switch (s) {
    SearchSort.dateDesc => 't.txn_date DESC, t.id DESC',
    SearchSort.dateAsc => 't.txn_date ASC, t.id ASC',
    SearchSort.amountDesc => 't.amount_minor DESC, t.id DESC',
    SearchSort.amountAsc => 't.amount_minor ASC, t.id ASC',
  };

  /// One page of results. Fetches limit+1 rows to compute [SearchPage.hasMore].
  Future<SearchPage> search(
    int profileId,
    SearchFilter filter, {
    int limit = 50,
    int offset = 0,
  }) async {
    final w = _where(profileId, filter);
    final rows = await _db
        .customSelect(
          'SELECT t.id, t.type, t.txn_date, t.amount_minor, t.title, '
          't.remarks, t.account_name_snapshot, t.to_account_name_snapshot, '
          't.category_name_snapshot, t.sub_category_name_snapshot, '
          't.cost_item_name_snapshot, t.income_source '
          'FROM financial_transactions t WHERE ${w.where} '
          'ORDER BY ${_orderBy(filter.sort)} LIMIT ? OFFSET ?',
          variables: [
            ...w.vars,
            Variable<int>(limit + 1),
            Variable<int>(offset),
          ],
          readsFrom: {_db.financialTransactions},
        )
        .get();
    final mapped = [
      for (final r in rows.take(limit))
        SearchRow(
          id: r.read<int>('id'),
          type: r.read<String>('type'),
          date: r.read<String>('txn_date'),
          amountMinor: r.read<int>('amount_minor'),
          title: r.readNullable<String>('title'),
          remarks: r.readNullable<String>('remarks'),
          accountName: r.read<String>('account_name_snapshot'),
          toAccountName: r.readNullable<String>('to_account_name_snapshot'),
          categoryName: r.readNullable<String>('category_name_snapshot'),
          subCategoryName: r.readNullable<String>('sub_category_name_snapshot'),
          costItemName: r.readNullable<String>('cost_item_name_snapshot'),
          incomeSource: r.readNullable<String>('income_source'),
        ),
    ];
    return SearchPage(mapped, rows.length > limit);
  }

  /// Income/expense totals and row count over the whole filtered set.
  Future<SearchTotals> totals(int profileId, SearchFilter filter) async {
    final w = _where(profileId, filter);
    final r = await _db
        .customSelect(
          "SELECT COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount_minor "
          'ELSE 0 END), 0) AS inc, '
          "COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount_minor "
          'ELSE 0 END), 0) AS exp, COUNT(*) AS cnt '
          'FROM financial_transactions t WHERE ${w.where}',
          variables: w.vars,
          readsFrom: {_db.financialTransactions},
        )
        .getSingle();
    return SearchTotals(
      incomeMinor: r.read<int>('inc'),
      expenseMinor: r.read<int>('exp'),
      count: r.read<int>('cnt'),
    );
  }

  Future<List<SearchOption>> accounts(int profileId) => _options(
    'SELECT id, name FROM accounts WHERE profile_id = ? '
    'ORDER BY name COLLATE NOCASE',
    profileId,
    {_db.accounts},
  );

  Future<List<SearchOption>> categories(int profileId) => _options(
    'SELECT id, name FROM categories WHERE profile_id = ? '
    'ORDER BY name COLLATE NOCASE',
    profileId,
    {_db.categories},
  );

  Future<List<SearchOption>> tags(int profileId) => _options(
    'SELECT id, name FROM tags WHERE profile_id = ? AND is_active = 1 '
    'ORDER BY name COLLATE NOCASE',
    profileId,
    {_db.tags},
  );

  Future<List<SearchOption>> _options(
    String sql,
    int profileId,
    Set<TableInfo> reads,
  ) async {
    final rows = await _db
        .customSelect(
          sql,
          variables: [Variable<int>(profileId)],
          readsFrom: reads,
        )
        .get();
    return [
      for (final r in rows)
        SearchOption(r.read<int>('id'), r.read<String>('name')),
    ];
  }
}
