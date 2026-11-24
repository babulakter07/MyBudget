import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/fixed_deposit_repository.dart';
import '../domain/fixed_deposit_calculator.dart';

final fixedDepositRepositoryProvider = Provider<FixedDepositRepository>(
  (ref) => FixedDepositRepository(ref.watch(appDatabaseProvider)),
);

/// Whether archived deposits are listed.
class FdShowArchivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final fdShowArchivedProvider = NotifierProvider<FdShowArchivedNotifier, bool>(
  FdShowArchivedNotifier.new,
);

final fixedDepositsProvider = StreamProvider<List<FixedDepositPosition>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final archived = ref.watch(fdShowArchivedProvider);
  if (profileId == null) {
    return Stream.value(const <FixedDepositPosition>[]);
  }
  return ref
      .watch(fixedDepositRepositoryProvider)
      .watchAll(profileId, includeArchived: archived);
});

final fixedDepositProvider = StreamProvider.family<FixedDepositPosition?, int>((
  ref,
  depositId,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref
      .watch(fixedDepositRepositoryProvider)
      .watchById(profileId, depositId);
});

final fixedDepositSummaryProvider = StreamProvider<FixedDepositSummary>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(FixedDepositSummary.empty);
  return ref.watch(fixedDepositRepositoryProvider).watchSummary(profileId);
});
