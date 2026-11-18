import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/insights_repository.dart';
import '../domain/insights_models.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(ref.watch(appDatabaseProvider)),
);

/// Injectable clock ("today").
final insightsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Month selected on the insights screen (day is always 1). Resets when the
/// active profile changes.
class InsightsMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(activeProfileIdProvider);
    final now = ref.read(insightsClockProvider)();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  /// No-op once the current month is reached.
  void next() {
    final now = ref.read(insightsClockProvider)();
    final cap = DateTime(now.year, now.month);
    final n = DateTime(state.year, state.month + 1);
    if (!n.isAfter(cap)) state = n;
  }

  void setMonth(DateTime m) => state = DateTime(m.year, m.month);
}

final insightsMonthProvider = NotifierProvider<InsightsMonthNotifier, DateTime>(
  InsightsMonthNotifier.new,
);

typedef InsightsKey = ({int year, int month});

/// Insights for any month of the active profile (reactive).
final insightsForMonthProvider = StreamProvider.family<Insights?, InsightsKey>((
  ref,
  key,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  final now = ref.read(insightsClockProvider)();
  return ref
      .watch(insightsRepositoryProvider)
      .watchInsights(profileId, key.year, key.month, now: now);
});

/// Insights for the month chosen on the screen.
final selectedInsightsProvider = Provider<AsyncValue<Insights?>>((ref) {
  final m = ref.watch(insightsMonthProvider);
  return ref.watch(insightsForMonthProvider((year: m.year, month: m.month)));
});

/// Insights for the current month (dashboard card).
final currentInsightsProvider = Provider<AsyncValue<Insights?>>((ref) {
  final now = ref.watch(insightsClockProvider)();
  return ref.watch(
    insightsForMonthProvider((year: now.year, month: now.month)),
  );
});
