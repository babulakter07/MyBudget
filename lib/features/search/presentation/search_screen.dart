import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/search_models.dart';
import '../providers/search_providers.dart';
import 'search_filter_sheet.dart';

/// Global transaction search (route /search). Has its own Scaffold.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchFilterProvider).query;
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        ref.read(searchResultsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(searchFilterProvider.notifier).setQuery(v);
    });
    setState(() {});
  }

  void _commit(String v) {
    _debounce?.cancel();
    ref.read(searchFilterProvider.notifier).setQuery(v);
    ref.read(recentSearchesProvider.notifier).add(v);
  }

  void _useQuery(String q) {
    _controller.text = q;
    _commit(q);
    setState(() {});
  }

  Future<void> _openFilters() async {
    final result = await showSearchFilterSheet(
      context,
      ref.read(searchFilterProvider),
    );
    if (result != null) {
      ref.read(searchFilterProvider.notifier).set(result);
    }
  }

  void _clearAll() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchFilterProvider.notifier).set(const SearchFilter());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final recents = ref.watch(recentSearchesProvider);
    final showRecents = _controller.text.trim().isEmpty && !filter.hasFilters;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.searchClearText,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _commit('');
                      setState(() {});
                    },
                  ),
          ),
          onChanged: _onChanged,
          onSubmitted: _commit,
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.searchFilters,
            icon: Badge(
              isLabelVisible: filter.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          if (filter.hasFilters || filter.sort != SearchSort.dateDesc)
            _ActiveChips(filter: filter, onClear: _clearAll),
          Expanded(
            child: showRecents
                ? _Recents(
                    recents: recents,
                    onTap: _useQuery,
                    onRemove: (q) =>
                        ref.read(recentSearchesProvider.notifier).remove(q),
                    onClear: () =>
                        ref.read(recentSearchesProvider.notifier).clear(),
                  )
                : _Results(
                    controller: _scroll,
                    onClear: _clearAll,
                    onOpen: (id) {
                      ref
                          .read(recentSearchesProvider.notifier)
                          .add(_controller.text);
                      context.push('/transactions/$id');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChips extends ConsumerWidget {
  const _ActiveChips({required this.filter, required this.onClear});
  final SearchFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(searchFilterProvider.notifier);
    final accounts = {
      for (final o in ref.watch(searchAccountOptionsProvider).value ?? const [])
        o.id: o.name,
    };
    final cats = {
      for (final o
          in ref.watch(searchCategoryOptionsProvider).value ??
              const <SearchOption>[])
        o.id: o.name,
    };
    final tags = {
      for (final o
          in ref.watch(searchTagOptionsProvider).value ??
              const <SearchOption>[])
        o.id: o.name,
    };
    Widget chip(String label, VoidCallback onDelete) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(label: Text(label), onDeleted: onDelete),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final t in filter.types)
            chip(
              searchTypeLabel(context.l10n, t),
              () => n.set(filter.copyWith(types: {...filter.types}..remove(t))),
            ),
          if (filter.minAmountMinor != null)
            chip(
              '≥ ${formatMinor(filter.minAmountMinor!)}',
              () => n.set(filter.copyWith(clearMin: true)),
            ),
          if (filter.maxAmountMinor != null)
            chip(
              '≤ ${formatMinor(filter.maxAmountMinor!)}',
              () => n.set(filter.copyWith(clearMax: true)),
            ),
          if (filter.fromDate != null)
            chip(
              context.l10n.searchChipFrom(filter.fromDate!),
              () => n.set(filter.copyWith(clearFrom: true)),
            ),
          if (filter.toDate != null)
            chip(
              context.l10n.searchChipTo(filter.toDate!),
              () => n.set(filter.copyWith(clearTo: true)),
            ),
          for (final id in filter.accountIds)
            chip(
              accounts[id] ?? context.l10n.searchChipAccount,
              () => n.set(
                filter.copyWith(accountIds: {...filter.accountIds}..remove(id)),
              ),
            ),
          for (final id in filter.categoryIds)
            chip(
              cats[id] ?? context.l10n.searchChipCategory,
              () => n.set(
                filter.copyWith(
                  categoryIds: {...filter.categoryIds}..remove(id),
                ),
              ),
            ),
          for (final id in filter.tagIds)
            chip(
              context.l10n.searchChipTag(
                tags[id] ?? context.l10n.searchTagFallback,
              ),
              () => n.set(
                filter.copyWith(tagIds: {...filter.tagIds}..remove(id)),
              ),
            ),
          if (filter.sort != SearchSort.dateDesc)
            chip(
              sortLabel(context.l10n, filter.sort),
              () => n.set(filter.copyWith(sort: SearchSort.dateDesc)),
            ),
          TextButton(
            onPressed: onClear,
            child: Text(context.l10n.searchClearFilters),
          ),
        ],
      ),
    );
  }
}

class _Recents extends StatelessWidget {
  const _Recents({
    required this.recents,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });
  final List<String> recents;
  final void Function(String) onTap;
  final void Function(String) onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (recents.isEmpty) {
      return EmptyState(
        message: context.l10n.searchEmptyHint,
        icon: Icons.search,
      );
    }
    return ListView(
      children: [
        ListTile(
          title: Text(
            context.l10n.searchRecent,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: TextButton(
            onPressed: onClear,
            child: Text(context.l10n.searchClearAll),
          ),
        ),
        for (final q in recents)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () => onTap(q),
            trailing: IconButton(
              tooltip: context.l10n.searchRemove,
              icon: const Icon(Icons.close),
              onPressed: () => onRemove(q),
            ),
          ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.controller,
    required this.onOpen,
    required this.onClear,
  });
  final ScrollController controller;
  final void Function(int id) onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchResultsProvider);
    // Keep showing the previous data while a new query loads.
    final data = async.value;
    if (data == null) {
      if (async.hasError) {
        return ErrorState(
          error: async.error!,
          onRetry: () => ref.invalidate(searchResultsProvider),
        );
      }
      return const LoadingView();
    }
    if (data.rows.isEmpty) {
      return EmptyState(
        message: context.l10n.searchNoResults,
        icon: Icons.search_off,
        action: TextButton(
          onPressed: onClear,
          child: Text(context.l10n.searchClearFilters),
        ),
      );
    }

    final items = <Object>[];
    String? last;
    for (final r in data.rows) {
      if (r.date != last) {
        items.add(r.date);
        last = r.date;
      }
      items.add(r);
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        if (async.isLoading) const LinearProgressIndicator(minHeight: 2),
        _TotalsHeader(totals: data.totals),
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount: items.length + (data.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = items[i];
              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    item,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }
              return _ResultTile(row: item as SearchRow, onOpen: onOpen);
            },
          ),
        ),
      ],
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  const _TotalsHeader({required this.totals});
  final SearchTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, String value, Color? color) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            cell(context.l10n.searchResults, '${totals.count}', null),
            cell(
              context.l10n.searchTypeIncome,
              formatMinor(totals.incomeMinor),
              AppColors.income,
            ),
            cell(
              context.l10n.searchTypeExpense,
              formatMinor(totals.expenseMinor),
              AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.row, required this.onOpen});
  final SearchRow row;
  final void Function(int id) onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (row.type) {
      'income' => AppColors.income,
      'expense' => AppColors.expense,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final sign = switch (row.type) {
      'income' => '+',
      'expense' => '-',
      _ => '',
    };
    return ListTile(
      title: Text(
        row.localizedTitle(context.l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        row.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign${formatMinor(row.amountMinor)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: () => onOpen(row.id),
    );
  }
}
