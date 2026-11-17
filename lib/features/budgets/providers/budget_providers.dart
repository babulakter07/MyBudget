import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(appDatabaseProvider)),
);

class SelectedMonth {
  const SelectedMonth(this.year, this.month);
  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is SelectedMonth && other.year == year && other.month == month;
  @override
  int get hashCode => Object.hash(year, month);
}

class SelectedMonthNotifier extends Notifier<SelectedMonth> {
  @override
  SelectedMonth build() {
    final now = DateTime.now();
    return SelectedMonth(now.year, now.month);
  }

  void set(int year, int month) {
    final d = DateTime(year, month);
    state = SelectedMonth(d.year, d.month);
  }

  void previous() => set(state.year, state.month - 1);
  void next() => set(state.year, state.month + 1);
}

final selectedBudgetMonthProvider =
    NotifierProvider<SelectedMonthNotifier, SelectedMonth>(
      SelectedMonthNotifier.new,
    );

/// Budget + spending for the selected month of the active profile.
final budgetSummaryProvider = StreamProvider<MonthBudget>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final m = ref.watch(selectedBudgetMonthProvider);
  if (profileId == null) {
    return Stream.value(
      MonthBudget(
        year: m.year,
        month: m.month,
        hasBudget: false,
        summary: const BudgetSummary(budgetMinor: 0, expenseMinor: 0),
        categories: const [],
      ),
    );
  }
  return ref
      .watch(budgetRepositoryProvider)
      .watchMonth(profileId, m.year, m.month);
});
