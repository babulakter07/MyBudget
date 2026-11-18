import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/goal_repository.dart';
import '../domain/goal.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(appDatabaseProvider)),
);

class GoalArchivedFilterNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

/// Whether the goal list also shows archived goals.
final goalShowArchivedProvider =
    NotifierProvider<GoalArchivedFilterNotifier, bool>(
      GoalArchivedFilterNotifier.new,
    );

/// Goals of the active profile with computed progress (live).
final goalsProvider = StreamProvider<List<GoalWithProgress>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final archived = ref.watch(goalShowArchivedProvider);
  if (profileId == null) return Stream.value(const <GoalWithProgress>[]);
  return ref
      .watch(goalRepositoryProvider)
      .watchGoals(profileId, includeArchived: archived);
});

/// Active goals only, for the dashboard summary card.
final activeGoalsProvider = StreamProvider<List<GoalWithProgress>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <GoalWithProgress>[]);
  return ref.watch(goalRepositoryProvider).watchGoals(profileId);
});

/// Active accounts selectable as a goal's account.
final goalAccountOptionsProvider = StreamProvider<List<GoalAccountOption>>((
  ref,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <GoalAccountOption>[]);
  return ref.watch(goalRepositoryProvider).watchAccountOptions(profileId);
});
