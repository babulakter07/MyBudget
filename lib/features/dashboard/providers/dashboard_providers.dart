import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(appDatabaseProvider)),
);

/// Injectable clock (current/previous month, days elapsed).
final dashboardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

enum DashboardPeriodMode { current, previous, selected }

class DashboardFilter {
  const DashboardFilter({
    this.mode = DashboardPeriodMode.current,
    required this.selectedMonth,
    required this.year,
  });

  final DashboardPeriodMode mode;

  /// Used when [mode] is `selected` (day is always 1).
  final DateTime selectedMonth;

  /// Year of the yearly section.
  final int year;

  DashboardFilter copyWith({
    DashboardPeriodMode? mode,
    DateTime? selectedMonth,
    int? year,
  }) => DashboardFilter(
    mode: mode ?? this.mode,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    year: year ?? this.year,
  );

  /// The month the overview/analytics sections show.
  DateTime resolveMonth(DateTime now) => switch (mode) {
    DashboardPeriodMode.current => DateTime(now.year, now.month),
    DashboardPeriodMode.previous => DateTime(now.year, now.month - 1),
    DashboardPeriodMode.selected => selectedMonth,
  };
}

class DashboardFilterNotifier extends Notifier<DashboardFilter> {
  @override
  DashboardFilter build() {
    ref.watch(activeProfileIdProvider); // reset when the profile switches
    final now = ref.read(dashboardClockProvider)();
    return DashboardFilter(
      selectedMonth: DateTime(now.year, now.month),
      year: now.year,
    );
  }

  void setCurrent() =>
      state = state.copyWith(mode: DashboardPeriodMode.current);
  void setPrevious() =>
      state = state.copyWith(mode: DashboardPeriodMode.previous);
  void selectMonth(DateTime m) => state = state.copyWith(
    mode: DashboardPeriodMode.selected,
    selectedMonth: DateTime(m.year, m.month),
  );
  void selectYear(int year) => state = state.copyWith(year: year);
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilter>(
      DashboardFilterNotifier.new,
    );

/// Resolved (year, month) of the monthly sections.
final dashboardMonthProvider = Provider<DateTime>((ref) {
  final now = ref.watch(dashboardClockProvider)();
  return ref.watch(dashboardFilterProvider).resolveMonth(now);
});

/// Builds a profile+month scoped stream provider.
StreamProvider<T> _monthly<T>(
  Stream<T> Function(DashboardRepository repo, int profileId, int y, int m) q,
  T empty,
) => StreamProvider<T>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final month = ref.watch(dashboardMonthProvider);
  if (profileId == null) return Stream.value(empty);
  return q(
    ref.watch(dashboardRepositoryProvider),
    profileId,
    month.year,
    month.month,
  );
});

final monthOverviewProvider = _monthly<MonthOverview>(
  (r, p, y, m) => r.watchMonthOverview(p, y, m),
  const MonthOverview(budgetMinor: 0, expenseMinor: 0, incomeMinor: 0),
);

final topCostItemsProvider = _monthly<List<RankedAmount>>(
  (r, p, y, m) => r.watchTopCostItems(p, y, m),
  const [],
);

final categoryTotalsProvider = _monthly<List<RankedAmount>>(
  (r, p, y, m) => r.watchCategoryTotals(p, y, m),
  const [],
);

final dailyExpensesProvider = _monthly<List<DayAmount>>(
  (r, p, y, m) => r.watchDailyExpenses(p, y, m),
  const [],
);

final cashBalanceProvider = StreamProvider<int>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(0);
  return ref.watch(dashboardRepositoryProvider).watchCashBalance(profileId);
});

final yearlyTotalsProvider = StreamProvider<YearlyTotals>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final year = ref.watch(dashboardFilterProvider.select((f) => f.year));
  if (profileId == null) {
    return Stream.value(
      YearlyTotals(
        year: year,
        expenseByMonth: List.filled(12, 0),
        incomeByMonth: List.filled(12, 0),
      ),
    );
  }
  return ref
      .watch(dashboardRepositoryProvider)
      .watchYearlyTotals(profileId, year);
});
