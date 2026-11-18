import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/tag_repository.dart';
import '../domain/tag.dart';

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(ref.watch(appDatabaseProvider)),
);

/// Active tags of the active profile.
final activeTagsProvider = StreamProvider<List<Tag>>((ref) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const []);
  return ref.watch(tagRepositoryProvider).watchTags(pid);
});

/// All tags including archived.
final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const []);
  return ref.watch(tagRepositoryProvider).watchTags(pid, includeArchived: true);
});

final tagsForTransactionProvider = StreamProvider.family<List<Tag>, int>((
  ref,
  txnId,
) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const []);
  return ref.watch(tagRepositoryProvider).tagsForTransaction(pid, txnId);
});

typedef TagRange = ({DateTime from, DateTime to});

final tagTotalsProvider = StreamProvider.family<List<TagTotal>, TagRange>((
  ref,
  range,
) {
  final pid = ref.watch(activeProfileIdProvider);
  if (pid == null) return Stream.value(const []);
  return ref
      .watch(tagRepositoryProvider)
      .watchTagTotals(pid, range.from, range.to);
});
