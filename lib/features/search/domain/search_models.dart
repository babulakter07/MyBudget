import '../../../l10n/generated/app_localizations.dart';

enum SearchSort { dateDesc, dateAsc, amountDesc, amountAsc }

const searchTypes = ['expense', 'income', 'transfer'];

/// Immutable filter. Empty/null members mean "no restriction".
class SearchFilter {
  const SearchFilter({
    this.query = '',
    this.types = const {},
    this.minAmountMinor,
    this.maxAmountMinor,
    this.fromDate,
    this.toDate,
    this.accountIds = const {},
    this.categoryIds = const {},
    this.tagIds = const {},
    this.sort = SearchSort.dateDesc,
  });

  final String query;
  final Set<String> types;
  final int? minAmountMinor;
  final int? maxAmountMinor;

  /// 'yyyy-MM-dd', inclusive.
  final String? fromDate;
  final String? toDate;
  final Set<int> accountIds;
  final Set<int> categoryIds;
  final Set<int> tagIds;
  final SearchSort sort;

  /// True when any restriction (query or filter) is set.
  bool get hasCriteria => query.trim().isNotEmpty || hasFilters;

  /// Restrictions excluding the free-text query and sort order.
  bool get hasFilters =>
      types.isNotEmpty ||
      minAmountMinor != null ||
      maxAmountMinor != null ||
      fromDate != null ||
      toDate != null ||
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      tagIds.isNotEmpty;

  SearchFilter copyWith({
    String? query,
    Set<String>? types,
    int? minAmountMinor,
    bool clearMin = false,
    int? maxAmountMinor,
    bool clearMax = false,
    String? fromDate,
    bool clearFrom = false,
    String? toDate,
    bool clearTo = false,
    Set<int>? accountIds,
    Set<int>? categoryIds,
    Set<int>? tagIds,
    SearchSort? sort,
  }) => SearchFilter(
    query: query ?? this.query,
    types: types ?? this.types,
    minAmountMinor: clearMin ? null : (minAmountMinor ?? this.minAmountMinor),
    maxAmountMinor: clearMax ? null : (maxAmountMinor ?? this.maxAmountMinor),
    fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
    toDate: clearTo ? null : (toDate ?? this.toDate),
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    tagIds: tagIds ?? this.tagIds,
    sort: sort ?? this.sort,
  );

  /// Same sort and query, no filters.
  SearchFilter withoutFilters() => SearchFilter(query: query, sort: sort);
}

class SearchRow {
  const SearchRow({
    required this.id,
    required this.type,
    required this.date,
    required this.amountMinor,
    required this.title,
    required this.remarks,
    required this.accountName,
    required this.toAccountName,
    required this.categoryName,
    required this.subCategoryName,
    required this.costItemName,
    required this.incomeSource,
  });

  final int id;
  final String type;
  final String date;
  final int amountMinor;
  final String? title;
  final String? remarks;
  final String accountName;
  final String? toAccountName;
  final String? categoryName;
  final String? subCategoryName;
  final String? costItemName;
  final String? incomeSource;

  static String? _pick(String? s) => (s == null || s.trim().isEmpty) ? null : s;

  /// Best human label for the row.
  String get displayTitle =>
      _pick(title) ??
      switch (type) {
        'transfer' => 'Transfer',
        'income' => _pick(incomeSource) ?? 'Income',
        _ =>
          _pick(costItemName) ??
              _pick(subCategoryName) ??
              _pick(categoryName) ??
              'Expense',
      };

  /// Localized variant of [displayTitle] (user-entered text is never
  /// translated; only the fallback labels are).
  String localizedTitle(AppLocalizations l) =>
      _pick(title) ??
      switch (type) {
        'transfer' => l.searchTypeTransfer,
        'income' => _pick(incomeSource) ?? l.searchTypeIncome,
        _ =>
          _pick(costItemName) ??
              _pick(subCategoryName) ??
              _pick(categoryName) ??
              l.searchTypeExpense,
      };

  String get subtitle => type == 'transfer'
      ? '$accountName → ${toAccountName ?? '?'}'
      : [accountName, ?categoryName].join(' · ');
}

/// Totals over the WHOLE filtered set (not just the loaded page).
class SearchTotals {
  const SearchTotals({
    this.incomeMinor = 0,
    this.expenseMinor = 0,
    this.count = 0,
  });
  final int incomeMinor;
  final int expenseMinor;
  final int count;
}

class SearchPage {
  const SearchPage(this.rows, this.hasMore);
  final List<SearchRow> rows;
  final bool hasMore;
}

class SearchOption {
  const SearchOption(this.id, this.name);
  final int id;
  final String name;
}
