import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/dps_repository.dart';
import '../domain/dps.dart';

final dpsRepositoryProvider = Provider<DpsRepository>(
  (ref) => DpsRepository(ref.watch(appDatabaseProvider)),
);

/// Whether archived accounts are listed.
class DpsShowArchivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final dpsShowArchivedProvider = NotifierProvider<DpsShowArchivedNotifier, bool>(
  DpsShowArchivedNotifier.new,
);

final dpsListProvider = StreamProvider<List<DpsPosition>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final archived = ref.watch(dpsShowArchivedProvider);
  if (profileId == null) return Stream.value(const <DpsPosition>[]);
  return ref
      .watch(dpsRepositoryProvider)
      .watchAll(profileId, includeArchived: archived);
});

final dpsProvider = StreamProvider.family<DpsPosition?, int>((ref, id) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  return ref.watch(dpsRepositoryProvider).watchById(profileId, id);
});

final dpsPaymentsProvider = StreamProvider.family<List<DpsPayment>, int>((
  ref,
  id,
) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(const <DpsPayment>[]);
  return ref.watch(dpsRepositoryProvider).watchPayments(profileId, id);
});
