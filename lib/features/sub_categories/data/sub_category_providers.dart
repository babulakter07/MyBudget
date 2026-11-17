import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../domain/sub_category.dart';
import 'sub_category_repository.dart';

final subCategoryRepositoryProvider = Provider<SubCategoryRepository>(
  (ref) => SubCategoryRepository(ref.watch(appDatabaseProvider)),
);

final subCategoriesProvider =
    StreamProvider.family<List<SubCategoryView>, SubCategoryFilter>((
      ref,
      filter,
    ) {
      final profileId = ref.watch(activeProfileIdProvider);
      if (profileId == null) return Stream.value(const []);
      return ref
          .watch(subCategoryRepositoryProvider)
          .watchAll(
            profileId,
            categoryId: filter.categoryId,
            search: filter.search,
            includeInactive: filter.includeInactive,
          );
    });

typedef CategoryOption = ({int id, String name, bool isActive});

/// All categories (active and inactive) of the active profile.
final subCategoryCategoryOptionsProvider = StreamProvider<List<CategoryOption>>(
  (ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    if (profileId == null) return Stream.value(const []);
    return ref
        .watch(subCategoryRepositoryProvider)
        .watchCategoryOptions(profileId);
  },
);
