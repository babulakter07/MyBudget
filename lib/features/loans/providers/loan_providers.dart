import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/loan_repository.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(ref.watch(appDatabaseProvider)),
);

/// Whether archived loans are listed.
class LoanShowArchivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final loanShowArchivedProvider =
    NotifierProvider<LoanShowArchivedNotifier, bool>(
      LoanShowArchivedNotifier.new,
    );

final loansProvider = StreamProvider<List<LoanPosition>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final archived = ref.watch(loanShowArchivedProvider);
  if (profileId == null) return Stream.value(const <LoanPosition>[]);
  return ref
      .watch(loanRepositoryProvider)
      .watchAll(profileId, includeArchived: archived);
});

final loanProvider = StreamProvider.family<LoanPosition?, int>((ref, loanId) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref.watch(loanRepositoryProvider).watchById(profileId, loanId);
});

final loanPaymentsProvider = StreamProvider.family<List<LoanPayment>, int>((
  ref,
  loanId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <LoanPayment>[]);
  return ref.watch(loanRepositoryProvider).watchPayments(profileId, loanId);
});

final loanSummaryProvider = StreamProvider<LoanSummary>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(LoanSummary.empty);
  return ref.watch(loanRepositoryProvider).watchSummary(profileId);
});
