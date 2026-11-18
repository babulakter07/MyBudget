import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/debt_repository.dart';
import '../domain/debt.dart';

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DebtRepository(ref.watch(appDatabaseProvider)),
);

/// Active debts of the active profile for a direction ('lent'|'borrowed').
final debtsByDirectionProvider = StreamProvider.family<List<Debt>, String>((
  ref,
  direction,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <Debt>[]);
  return ref
      .watch(debtRepositoryProvider)
      .watchAll(profileId, direction: direction);
});

final debtProvider = StreamProvider.family<Debt?, int>((ref, debtId) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref.watch(debtRepositoryProvider).watchById(profileId, debtId);
});

final debtPaymentsProvider = StreamProvider.family<List<DebtPayment>, int>((
  ref,
  debtId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <DebtPayment>[]);
  return ref.watch(debtRepositoryProvider).watchPayments(profileId, debtId);
});

final debtSummaryProvider = StreamProvider<DebtSummary>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(DebtSummary.empty);
  return ref.watch(debtRepositoryProvider).watchSummary(profileId);
});
