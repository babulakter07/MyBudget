import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/cost_item_repository.dart';
import '../domain/cost_item.dart';

final costItemRepositoryProvider = Provider<CostItemRepository>(
  (ref) => CostItemRepository(ref.watch(appDatabaseProvider)),
);

final costItemsProvider =
    StreamProvider.family<List<CostItemView>, CostItemFilter>((ref, filter) {
      final profileId = ref.watch(activeProfileIdProvider);
      if (profileId == null) return Stream.value(const <CostItemView>[]);
      return ref
          .watch(costItemRepositoryProvider)
          .watchAll(
            profileId,
            categoryId: filter.categoryId,
            subCategoryId: filter.subCategoryId,
            search: filter.search,
            includeInactive: filter.includeInactive,
          );
    });
