import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

/// Search/inactive filter for the list screen.
class CategoryFilter {
  const CategoryFilter({this.search = '', this.includeInactive = false});
  final String search;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is CategoryFilter &&
      other.search == search &&
      other.includeInactive == includeInactive;
  @override
  int get hashCode => Object.hash(search, includeInactive);
}

class CategoryFilterNotifier extends Notifier<CategoryFilter> {
  @override
  CategoryFilter build() => const CategoryFilter();
  void setSearch(String s) =>
      state = CategoryFilter(search: s, includeInactive: state.includeInactive);
  void setIncludeInactive(bool v) =>
      state = CategoryFilter(search: state.search, includeInactive: v);
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryFilter>(
      CategoryFilterNotifier.new,
    );

/// Categories of the active profile; refreshes on profile switch.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  final filter = ref.watch(categoryFilterProvider);
  if (profileId == null) return Stream.value(const <Category>[]);
  return ref
      .watch(categoryRepositoryProvider)
      .watchAll(
        profileId,
        search: filter.search,
        includeInactive: filter.includeInactive,
      );
});
