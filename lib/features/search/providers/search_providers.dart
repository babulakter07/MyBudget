import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/search_repository.dart';
import '../domain/search_models.dart';

const searchPageSize = 50;
const recentSearchesKey = 'search_recent_queries';
const maxRecentSearches = 8;

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(appDatabaseProvider)),
);

class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() {
    ref.watch(activeProfileIdProvider); // reset when the profile switches
    return const SearchFilter();
  }

  void set(SearchFilter f) => state = f;
  void setQuery(String q) => state = state.copyWith(query: q);
  void clearFilters() => state = state.withoutFilters();
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilter>(
      SearchFilterNotifier.new,
    );

class SearchResults {
  const SearchResults({
    required this.rows,
    required this.totals,
    required this.hasMore,
    this.loadingMore = false,
  });
  final List<SearchRow> rows;
  final SearchTotals totals;
  final bool hasMore;
  final bool loadingMore;
}

class SearchResultsNotifier extends AsyncNotifier<SearchResults> {
  @override
  Future<SearchResults> build() async {
    final profileId = ref.watch(activeProfileIdProvider);
    final filter = ref.watch(searchFilterProvider);
    if (profileId == null) {
      return const SearchResults(
        rows: [],
        totals: SearchTotals(),
        hasMore: false,
      );
    }
    final repo = ref.read(searchRepositoryProvider);
    final page = await repo.search(profileId, filter, limit: searchPageSize);
    final totals = await repo.totals(profileId, filter);
    return SearchResults(
      rows: page.rows,
      totals: totals,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final cur = state.value;
    final profileId = ref.read(activeProfileIdProvider);
    if (cur == null || !cur.hasMore || cur.loadingMore || profileId == null) {
      return;
    }
    final filter = ref.read(searchFilterProvider);
    state = AsyncData(
      SearchResults(
        rows: cur.rows,
        totals: cur.totals,
        hasMore: cur.hasMore,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(searchRepositoryProvider)
          .search(
            profileId,
            filter,
            limit: searchPageSize,
            offset: cur.rows.length,
          );
      state = AsyncData(
        SearchResults(
          rows: [...cur.rows, ...page.rows],
          totals: cur.totals,
          hasMore: page.hasMore,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, SearchResults>(
      SearchResultsNotifier.new,
    );

final searchAccountOptionsProvider = FutureProvider<List<SearchOption>>((ref) {
  final p = ref.watch(activeProfileIdProvider);
  if (p == null) return const <SearchOption>[];
  return ref.watch(searchRepositoryProvider).accounts(p);
});

final searchCategoryOptionsProvider = FutureProvider<List<SearchOption>>((ref) {
  final p = ref.watch(activeProfileIdProvider);
  if (p == null) return const <SearchOption>[];
  return ref.watch(searchRepositoryProvider).categories(p);
});

final searchTagOptionsProvider = FutureProvider<List<SearchOption>>((ref) {
  final p = ref.watch(activeProfileIdProvider);
  if (p == null) return const <SearchOption>[];
  return ref.watch(searchRepositoryProvider).tags(p);
});

/// Last [maxRecentSearches] queries, newest first (SharedPreferences).
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(recentSearchesKey) ??
      const [];

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [
      q,
      ...state.where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(maxRecentSearches).toList();
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(recentSearchesKey, next);
  }

  Future<void> remove(String query) async {
    final next = state.where((e) => e != query).toList();
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(recentSearchesKey, next);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(recentSearchesKey);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );
