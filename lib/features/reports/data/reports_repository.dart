import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/report_models.dart';

const String uncategorisedLabel = 'Uncategorised';
const String noSubCategoryLabel = 'No sub-category';
const String noItemLabel = 'No item';

/// Read-only report queries computed from source transactions. Every query
/// filters by profile and excludes soft-deleted rows.
class ReportsRepository {
  ReportsRepository(this._db);
  final AppDatabase _db;

  Future<ProfileRow> _profile(int profileId) async {
    final p = await (_db.select(
      _db.financialProfiles,
    )..where((t) => t.id.equals(profileId))).getSingleOrNull();
    if (p == null) throw NotFoundException('Profile not found.');
    return p;
  }

  Future<List<TransactionRow>> _txns(
    int profileId, {
    String from = '0000-01-01',
    required String to,
  }) {
    final q = _db.select(_db.financialTransactions)
      ..where(
        (t) =>
            t.profileId.equals(profileId) &
            t.isDeleted.equals(false) &
            t.txnDate.isBiggerOrEqualValue(from) &
            t.txnDate.isSmallerOrEqualValue(to),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.txnDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return q.get();
  }

  void _checkMonth(int year, int month) {
    if (year < 1970 || year > 9999) {
      throw ValidationException('Year must be between 1970 and 9999.');
    }
    if (month < 1 || month > 12) {
      throw ValidationException('Month must be between 1 and 12.');
    }
  }

  // ---------------------------------------------------------------- monthly

  Future<MonthlyReport> monthly(int profileId, int year, int month) async {
    _checkMonth(year, month);
    final profile = await _profile(profileId);
    final start = monthStartKey(year, month);
    final end = monthEndKey(year, month);

    final rows = await _txns(profileId, to: end);

    var income = 0, expense = 0;
    final expenses = <TransactionRow>[];
    for (final r in rows) {
      if (r.txnDate.compareTo(start) < 0) continue;
      if (r.type == 'income') income += r.amountMinor;
      if (r.type == 'expense') {
        expense += r.amountMinor;
        expenses.add(r);
      }
    }

    final budgetRow =
        await (_db.select(_db.monthlyBudgets)..where(
              (b) =>
                  b.profileId.equals(profileId) &
                  b.year.equals(year) &
                  b.month.equals(month),
            ))
            .getSingleOrNull();

    final agg = _Breakdown.from(expenses);
    final accounts = await _accountMovements(profileId, rows, start, end);

    return MonthlyReport(
      profileId: profileId,
      profileName: profile.name,
      currencyCode: profile.currencyCode,
      year: year,
      month: month,
      incomeMinor: income,
      expenseMinor: expense,
      budgetMinor: budgetRow?.totalBudgetMinor,
      categories: agg.categories,
      subCategories: agg.subCategories,
      items: agg.items,
      daily: _dailySeries(expenses, start, end),
      accounts: accounts,
    );
  }

  /// [rows] are all non-deleted rows with txnDate <= [end].
  /// Rows dated before an account's opening date are never counted.
  Future<List<AccountMovement>> _accountMovements(
    int profileId,
    List<TransactionRow> rows,
    String start,
    String end,
  ) async {
    final accounts =
        await (_db.select(_db.accounts)
              ..where((a) => a.profileId.equals(profileId))
              ..orderBy([(a) => OrderingTerm.asc(a.id)]))
            .get();
    final result = <AccountMovement>[];
    for (final a in accounts) {
      // Account does not exist yet in this period.
      if (a.openingDate.compareTo(end) > 0) continue;
      var opening = a.openingBalanceMinor;
      var inc = 0, exp = 0, tin = 0, tout = 0;
      for (final r in rows) {
        if (r.txnDate.compareTo(a.openingDate) < 0) continue;
        final before = r.txnDate.compareTo(start) < 0;
        if (r.accountId == a.id) {
          switch (r.type) {
            case 'income':
              if (before) {
                opening += r.amountMinor;
              } else {
                inc += r.amountMinor;
              }
            case 'expense':
              if (before) {
                opening -= r.amountMinor;
              } else {
                exp += r.amountMinor;
              }
            case 'transfer':
              if (before) {
                opening -= r.amountMinor;
              } else {
                tout += r.amountMinor;
              }
          }
        }
        if (r.type == 'transfer' && r.toAccountId == a.id) {
          if (before) {
            opening += r.amountMinor;
          } else {
            tin += r.amountMinor;
          }
        }
      }
      result.add(
        AccountMovement(
          accountId: a.id,
          accountName: a.name,
          openingMinor: opening,
          incomeMinor: inc,
          expenseMinor: exp,
          transferInMinor: tin,
          transferOutMinor: tout,
        ),
      );
    }
    return result;
  }

  // ----------------------------------------------------------------- yearly

  Future<YearlyReport> yearly(int profileId, int year) async {
    _checkMonth(year, 1);
    final profile = await _profile(profileId);
    final rows = await _txns(
      profileId,
      from: monthStartKey(year, 1),
      to: monthEndKey(year, 12),
    );
    final income = List<int>.filled(12, 0);
    final expense = List<int>.filled(12, 0);
    final names = <int?, String>{};
    final matrix = <int?, List<int>>{};
    for (final r in rows) {
      final m = int.parse(r.txnDate.substring(5, 7)) - 1;
      if (r.type == 'income') income[m] += r.amountMinor;
      if (r.type == 'expense') {
        expense[m] += r.amountMinor;
        final list = matrix.putIfAbsent(r.categoryId, () => List.filled(12, 0));
        list[m] += r.amountMinor;
        names[r.categoryId] = _categoryName(r);
      }
    }
    final budgets = await (_db.select(
      _db.monthlyBudgets,
    )..where((b) => b.profileId.equals(profileId) & b.year.equals(year))).get();
    final budgetByMonth = {
      for (final b in budgets) b.month: b.totalBudgetMinor,
    };

    final cats = [
      for (final e in matrix.entries)
        CategoryYearRow(
          categoryId: e.key,
          name: names[e.key]!,
          monthlyMinor: e.value,
        ),
    ]..sort(_byTotalThenName);

    return YearlyReport(
      profileId: profileId,
      profileName: profile.name,
      currencyCode: profile.currencyCode,
      year: year,
      months: [
        for (var m = 1; m <= 12; m++)
          YearlyMonthRow(
            month: m,
            incomeMinor: income[m - 1],
            expenseMinor: expense[m - 1],
            budgetMinor: budgetByMonth[m],
          ),
      ],
      categories: cats,
    );
  }

  static int _byTotalThenName(CategoryYearRow a, CategoryYearRow b) {
    final c = b.totalMinor.compareTo(a.totalMinor);
    return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  // ------------------------------------------------------------ custom range

  /// Validates 'yyyy-MM-dd' bounds with from <= to.
  void validateRange(String from, String to) {
    if (!isValidDateKey(from) || !isValidDateKey(to)) {
      throw ValidationException('Enter valid dates (yyyy-MM-dd).');
    }
    if (from.compareTo(to) > 0) {
      throw ValidationException(
        'The start date must not be after the end date.',
      );
    }
  }

  Future<RangeReport> range(int profileId, String from, String to) async {
    validateRange(from, to);
    final profile = await _profile(profileId);
    final rows = await _txns(profileId, from: from, to: to);
    var income = 0, expense = 0;
    final expenses = <TransactionRow>[];
    for (final r in rows) {
      if (r.type == 'income') income += r.amountMinor;
      if (r.type == 'expense') {
        expense += r.amountMinor;
        expenses.add(r);
      }
    }
    final agg = _Breakdown.from(expenses);
    return RangeReport(
      profileId: profileId,
      profileName: profile.name,
      currencyCode: profile.currencyCode,
      from: from,
      to: to,
      incomeMinor: income,
      expenseMinor: expense,
      categories: agg.categories,
      subCategories: agg.subCategories,
      items: agg.items,
      daily: _dailySeries(expenses, from, to),
    );
  }

  List<DailyTotal> _dailySeries(
    List<TransactionRow> expenses,
    String from,
    String to,
  ) {
    final byDay = <String, int>{};
    for (final r in expenses) {
      byDay[r.txnDate] = (byDay[r.txnDate] ?? 0) + r.amountMinor;
    }
    final a = parseDateKey(from), b = parseDateKey(to);
    final out = <DailyTotal>[];
    for (var i = 0; ; i++) {
      final d = DateTime(a.year, a.month, a.day + i);
      if (d.isAfter(b)) break;
      final k = dateKey(d);
      out.add(DailyTotal(date: k, amountMinor: byDay[k] ?? 0));
    }
    return out;
  }
}

String _categoryName(TransactionRow r) => r.categoryId == null
    ? uncategorisedLabel
    : (r.categoryNameSnapshot ?? 'Unknown category');

/// Groups expense rows by ids but displays the latest name snapshot.
class _Breakdown {
  _Breakdown(this.categories, this.subCategories, this.items);

  final List<CategoryTotal> categories;
  final List<SubCategoryTotal> subCategories;
  final List<ItemTotal> items;

  factory _Breakdown.from(List<TransactionRow> expenses) {
    final cat = <int?, int>{};
    final catName = <int?, String>{};
    final sub = <(int?, int?), int>{};
    final subName = <(int?, int?), String>{};
    final item = <(int?, int?, int?), int>{};
    final itemName = <(int?, int?, int?), String>{};

    for (final r in expenses) {
      final sn = r.subCategoryId == null
          ? noSubCategoryLabel
          : (r.subCategoryNameSnapshot ?? 'Unknown sub-category');
      final inm = r.costItemId == null
          ? noItemLabel
          : (r.costItemNameSnapshot ?? 'Unknown item');
      final ck = r.categoryId;
      final sk = (r.categoryId, r.subCategoryId);
      final ik = (r.categoryId, r.subCategoryId, r.costItemId);
      cat[ck] = (cat[ck] ?? 0) + r.amountMinor;
      catName[ck] = _categoryName(r);
      sub[sk] = (sub[sk] ?? 0) + r.amountMinor;
      subName[sk] = sn;
      item[ik] = (item[ik] ?? 0) + r.amountMinor;
      itemName[ik] = inm;
    }

    final cats = [
      for (final e in cat.entries)
        CategoryTotal(
          categoryId: e.key,
          name: catName[e.key]!,
          amountMinor: e.value,
        ),
    ]..sort((a, b) => _cmp(a.amountMinor, a.name, b.amountMinor, b.name));
    final subs = [
      for (final e in sub.entries)
        SubCategoryTotal(
          categoryId: e.key.$1,
          subCategoryId: e.key.$2,
          categoryName: catName[e.key.$1]!,
          name: subName[e.key]!,
          amountMinor: e.value,
        ),
    ]..sort((a, b) => _cmp(a.amountMinor, a.name, b.amountMinor, b.name));
    final items = [
      for (final e in item.entries)
        ItemTotal(
          categoryId: e.key.$1,
          subCategoryId: e.key.$2,
          costItemId: e.key.$3,
          categoryName: catName[e.key.$1]!,
          subCategoryName: subName[(e.key.$1, e.key.$2)]!,
          name: itemName[e.key]!,
          amountMinor: e.value,
        ),
    ]..sort((a, b) => _cmp(a.amountMinor, a.name, b.amountMinor, b.name));
    return _Breakdown(cats, subs, items);
  }

  static int _cmp(int a, String an, int b, String bn) {
    final c = b.compareTo(a);
    return c != 0 ? c : an.toLowerCase().compareTo(bn.toLowerCase());
  }
}
