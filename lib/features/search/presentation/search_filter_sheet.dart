import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/search_models.dart';
import '../providers/search_providers.dart';

/// Opens the filter sheet; returns the edited filter on Apply, else null.
Future<SearchFilter?> showSearchFilterSheet(
  BuildContext context,
  SearchFilter initial,
) {
  return showModalBottomSheet<SearchFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final SearchFilter initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilter _f = widget.initial;
  late final TextEditingController _min = TextEditingController(
    text: _fmt(widget.initial.minAmountMinor),
  );
  late final TextEditingController _max = TextEditingController(
    text: _fmt(widget.initial.maxAmountMinor),
  );
  String? _error;

  static String _fmt(int? minor) {
    if (minor == null) return '';
    final frac = minor % 100;
    return frac == 0 ? '${minor ~/ 100}' : '${minor ~/ 100}.${two(frac)}';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final current = from ? _f.fromDate : _f.toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null ? DateTime.now() : parseDateKey(current),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _f = from
          ? _f.copyWith(fromDate: dateKey(picked))
          : _f.copyWith(toDate: dateKey(picked));
    });
  }

  void _apply() {
    int? min, max;
    if (_min.text.trim().isNotEmpty) {
      min = parseMajorToMinor(_min.text);
      if (min == null) {
        return setState(() => _error = context.l10n.searchErrInvalidMin);
      }
    }
    if (_max.text.trim().isNotEmpty) {
      max = parseMajorToMinor(_max.text);
      if (max == null) {
        return setState(() => _error = context.l10n.searchErrInvalidMax);
      }
    }
    if (min != null && max != null && min > max) {
      return setState(() => _error = context.l10n.searchErrMinGreater);
    }
    if (_f.fromDate != null &&
        _f.toDate != null &&
        _f.fromDate!.compareTo(_f.toDate!) > 0) {
      return setState(() => _error = context.l10n.searchErrDateOrder);
    }
    Navigator.of(context).pop(
      _f.copyWith(
        minAmountMinor: min,
        clearMin: min == null,
        maxAmountMinor: max,
        clearMax: max == null,
      ),
    );
  }

  void _reset() {
    _min.clear();
    _max.clear();
    setState(() {
      _error = null;
      _f = _f.withoutFilters();
    });
  }

  Set<T> _toggle<T>(Set<T> s, T v) {
    final n = {...s};
    n.contains(v) ? n.remove(v) : n.add(v);
    return n;
  }

  Widget _chips(
    AsyncValue<List<SearchOption>> options,
    Set<int> selected,
    void Function(int) onTap,
  ) {
    final list = options.value ?? const <SearchOption>[];
    if (list.isEmpty) {
      return Text(
        options.isLoading
            ? context.l10n.commonLoading
            : context.l10n.searchNoneAvailable,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final o in list)
          FilterChip(
            label: Text(o.name),
            selected: selected.contains(o.id),
            onSelected: (_) => onTap(o.id),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(t, style: theme.textTheme.titleSmall),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.searchFilters,
                style: theme.textTheme.titleLarge,
              ),
              section(context.l10n.searchSectionType),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in searchTypes)
                    FilterChip(
                      label: Text(searchTypeLabel(context.l10n, t)),
                      selected: _f.types.contains(t),
                      onSelected: (_) => setState(
                        () => _f = _f.copyWith(types: _toggle(_f.types, t)),
                      ),
                    ),
                ],
              ),
              section(context.l10n.searchSectionAmount),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.searchMin,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.searchMax,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              section(context.l10n.searchSectionDateRange),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(_f.fromDate ?? context.l10n.searchFrom),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(_f.toDate ?? context.l10n.searchTo),
                    ),
                  ),
                ],
              ),
              section(context.l10n.searchSectionAccounts),
              _chips(
                ref.watch(searchAccountOptionsProvider),
                _f.accountIds,
                (id) => setState(
                  () =>
                      _f = _f.copyWith(accountIds: _toggle(_f.accountIds, id)),
                ),
              ),
              section(context.l10n.searchSectionCategories),
              _chips(
                ref.watch(searchCategoryOptionsProvider),
                _f.categoryIds,
                (id) => setState(
                  () => _f = _f.copyWith(
                    categoryIds: _toggle(_f.categoryIds, id),
                  ),
                ),
              ),
              section(context.l10n.searchSectionTags),
              _chips(
                ref.watch(searchTagOptionsProvider),
                _f.tagIds,
                (id) => setState(
                  () => _f = _f.copyWith(tagIds: _toggle(_f.tagIds, id)),
                ),
              ),
              section(context.l10n.searchSectionSortBy),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in SearchSort.values)
                    ChoiceChip(
                      label: Text(sortLabel(context.l10n, s)),
                      selected: _f.sort == s,
                      onSelected: (_) =>
                          setState(() => _f = _f.copyWith(sort: s)),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: Text(context.l10n.searchReset),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _apply,
                    child: Text(context.l10n.commonApply),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String sortLabel(AppLocalizations l, SearchSort s) => switch (s) {
  SearchSort.dateDesc => l.searchSortNewest,
  SearchSort.dateAsc => l.searchSortOldest,
  SearchSort.amountDesc => l.searchSortHighest,
  SearchSort.amountAsc => l.searchSortLowest,
};

/// Display label for a stored transaction type (`expense|income|transfer`).
String searchTypeLabel(AppLocalizations l, String type) => switch (type) {
  'income' => l.searchTypeIncome,
  'transfer' => l.searchTypeTransfer,
  _ => l.searchTypeExpense,
};
