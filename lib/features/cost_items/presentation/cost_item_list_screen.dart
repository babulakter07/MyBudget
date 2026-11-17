import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/cost_item.dart';
import '../providers/cost_item_providers.dart';

class CostItemListScreen extends ConsumerStatefulWidget {
  const CostItemListScreen({super.key});

  @override
  ConsumerState<CostItemListScreen> createState() => _CostItemListScreenState();
}

class _CostItemListScreenState extends ConsumerState<CostItemListScreen> {
  CostItemFilter _filter = const CostItemFilter();
  List<CategoryRow> _categories = const [];
  List<SubCategoryRow> _subCategories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final cats = await ref
        .read(costItemRepositoryProvider)
        .activeCategories(pid);
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _setCategory(int? id) async {
    final pid = ref.read(activeProfileIdProvider);
    var subs = <SubCategoryRow>[];
    if (id != null && pid != null) {
      subs = await ref
          .read(costItemRepositoryProvider)
          .subCategoriesOf(pid, id, onlyActive: false);
    }
    if (!mounted) return;
    setState(() {
      _subCategories = subs;
      _filter = CostItemFilter(
        categoryId: id,
        search: _filter.search,
        includeInactive: _filter.includeInactive,
      );
    });
  }

  void _update({
    int? subCategoryId,
    bool clearSub = false,
    String? search,
    bool? includeInactive,
  }) {
    setState(() {
      _filter = CostItemFilter(
        categoryId: _filter.categoryId,
        subCategoryId: clearSub
            ? null
            : (subCategoryId ?? _filter.subCategoryId),
        search: search ?? _filter.search,
        includeInactive: includeInactive ?? _filter.includeInactive,
      );
    });
  }

  Future<void> _toggleActive(CostItemView v, bool active) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(active ? 'Activate cost item?' : 'Deactivate cost item?'),
        content: Text(
          active
              ? '"${v.item.name}" will be available again.'
              : '"${v.item.name}" will be hidden from new entries. '
                    'Existing data is preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(active ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(costItemRepositoryProvider)
          .setActive(pid, v.item.id, active);
    } on AppException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _openForm([CostItemView? existing]) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _CostItemFormDialog(profileId: pid, existing: existing),
    );
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final pid = ref.watch(activeProfileIdProvider);
    final async = ref.watch(costItemsProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Items')),
      floatingActionButton: pid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add cost item'),
            ),
      body: pid == null
          ? const Center(child: Text('Select a profile first.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search name or description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (s) => _update(search: s),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          key: ValueKey('fc${_filter.categoryId}'),
                          initialValue: _filter.categoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All'),
                            ),
                            for (final c in _categories)
                              DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: _setCategory,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          key: ValueKey(
                            'fs${_filter.categoryId}${_filter.subCategoryId}',
                          ),
                          initialValue: _filter.subCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sub-category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All'),
                            ),
                            for (final s in _subCategories)
                              DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                          ],
                          onChanged: _filter.categoryId == null
                              ? null
                              : (v) => _update(
                                  subCategoryId: v,
                                  clearSub: v == null,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Show inactive'),
                  value: _filter.includeInactive,
                  onChanged: (v) => _update(includeInactive: v),
                ),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Could not load cost items: $e'),
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text('No cost items found.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => _tile(items[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(CostItemView v) {
    final it = v.item;
    final amount = it.defaultAmountMinor == null
        ? ''
        : ' · ${formatMinor(it.defaultAmountMinor!)}';
    return ListTile(
      enabled: it.isActive,
      title: Text(it.name),
      subtitle: Text(
        '${v.categoryName} › ${v.subCategoryName}$amount'
        '${it.isActive ? '' : ' · Inactive'}',
      ),
      onTap: () => _openForm(v),
      trailing: Switch(
        key: ValueKey('active-${it.id}'),
        value: it.isActive,
        onChanged: (a) => _toggleActive(v, a),
      ),
    );
  }
}

class _CostItemFormDialog extends ConsumerStatefulWidget {
  const _CostItemFormDialog({required this.profileId, this.existing});
  final int profileId;
  final CostItemView? existing;

  @override
  ConsumerState<_CostItemFormDialog> createState() => _FormState();
}

class _FormState extends ConsumerState<_CostItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  List<CategoryRow> _cats = const [];
  List<SubCategoryRow> _subs = const [];
  int? _catId;
  int? _subId;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.item.name ?? '');
    _desc = TextEditingController(text: e?.item.description ?? '');
    _amount = TextEditingController(
      text: e?.item.defaultAmountMinor == null
          ? ''
          : formatMinor(e!.item.defaultAmountMinor!, symbol: ''),
    );
    _catId = e?.categoryId;
    _subId = e?.item.subCategoryId;
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(costItemRepositoryProvider);
    final cats = await repo.activeCategories(widget.profileId);
    final subs = _catId == null
        ? <SubCategoryRow>[]
        : await repo.subCategoriesOf(widget.profileId, _catId!);
    if (!mounted) return;
    setState(() {
      _cats = cats;
      _subs = subs;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickCategory(int? id) async {
    final subs = id == null
        ? <SubCategoryRow>[]
        : await ref
              .read(costItemRepositoryProvider)
              .subCategoriesOf(widget.profileId, id);
    if (!mounted) return;
    setState(() {
      _catId = id;
      _subId = null;
      _subs = subs;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amountText = _amount.text.trim();
    final amount = amountText.isEmpty ? null : parseMajorToMinor(amountText);
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(costItemRepositoryProvider);
    try {
      final e = widget.existing;
      if (e == null) {
        await repo.create(
          profileId: widget.profileId,
          subCategoryId: _subId!,
          name: _name.text,
          description: _desc.text,
          defaultAmountMinor: amount,
        );
      } else {
        await repo.update(
          profileId: widget.profileId,
          id: e.item.id,
          subCategoryId: _subId!,
          name: _name.text,
          description: _desc.text,
          defaultAmountMinor: amount,
        );
      }
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    // Keep the current (possibly inactive) values visible when editing.
    final catItems = [
      for (final c in _cats)
        DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
      if (editing && _catId != null && !_cats.any((c) => c.id == _catId))
        DropdownMenuItem<int?>(
          value: _catId,
          child: Text(widget.existing!.categoryName),
        ),
    ];
    final subItems = [
      for (final s in _subs)
        DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
      if (editing &&
          _subId == widget.existing!.item.subCategoryId &&
          !_subs.any((s) => s.id == _subId))
        DropdownMenuItem<int?>(
          value: _subId,
          child: Text(widget.existing!.subCategoryName),
        ),
    ];
    return AlertDialog(
      title: Text(editing ? 'Edit cost item' : 'Add cost item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                key: ValueKey('cat$_catId${_cats.length}'),
                initialValue: _catId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: catItems,
                onChanged: _pickCategory,
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              DropdownButtonFormField<int?>(
                key: ValueKey('sub$_catId$_subId${_subs.length}'),
                initialValue: _subId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sub-category'),
                items: subItems,
                onChanged: (v) => setState(() => _subId = v),
                validator: (v) => v == null ? 'Select a sub-category' : null,
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Default amount (optional)',
                  prefixText: '৳ ',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  return parseMajorToMinor(t) == null
                      ? 'Enter a valid amount (max 2 decimals)'
                      : null;
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
