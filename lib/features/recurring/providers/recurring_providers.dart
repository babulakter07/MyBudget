import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../data/recurring_repository.dart';
import '../data/recurring_service.dart';
import '../domain/recurring_models.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(appDatabaseProvider)),
);

final recurringServiceProvider = Provider<RecurringService>(
  (ref) => RecurringService(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

/// All rules (active first, then paused/ended) of the active profile.
final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const <RecurringRule>[]);
  return ref.watch(recurringRepositoryProvider).watchAll(pid);
});

/// Rules due within the next N days (overdue included) for dashboards.
final upcomingRecurringProvider =
    FutureProvider.family<List<RecurringRule>, int>((ref, days) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return const <RecurringRule>[];
      // Re-evaluate whenever rules change.
      ref.watch(recurringRulesProvider);
      return ref.watch(recurringRepositoryProvider).upcoming(pid, days);
    });

/// Generates due occurrences for the active profile. Reading/watching
/// `recurringGenerationProvider` (or `.future`) at app start runs one pass;
/// call `ref.read(recurringGenerationProvider.notifier).run()` on resume.
final recurringGenerationProvider =
    AsyncNotifierProvider<RecurringGenerationNotifier, GenerationResult?>(
      RecurringGenerationNotifier.new,
    );

class RecurringGenerationNotifier extends AsyncNotifier<GenerationResult?> {
  @override
  Future<GenerationResult?> build() async {
    final pid = ref.watch(activeProfileIdProvider);
    if (pid == null) return null;
    return ref.read(recurringServiceProvider).generateDue(profileId: pid);
  }

  /// Runs a generation pass now (idempotent; safe to call repeatedly).
  Future<GenerationResult?> run({DateTime? today}) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return null;
    final result = await ref
        .read(recurringServiceProvider)
        .generateDue(profileId: pid, today: today);
    state = AsyncData(result);
    return result;
  }
}
