import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/sub_category_providers.dart';
import '../domain/sub_category.dart';

class SubCategoryListScreen extends ConsumerStatefulWidget {
  const SubCategoryListScreen({super.key});

  @override
  ConsumerState<SubCategoryListScreen> createState() =>
      _SubCategoryListScreenState();
}

class _SubCategoryListScreenState extends ConsumerState<SubCategoryListScreen> {
  int? _categoryId;
  String _search = '';
  bool _showInactive = false;

  SubCategoryFilter get _filter => SubCategoryFilter(
    categoryId: _categoryId,
    search: _search,
    includeInactive: _showInactive,
  );

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggle(SubCategoryView v, bool value) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          value ? 'Activate sub-category?' : 'Deactivate sub-category?',
        ),
        content: Text(
          value
              ? '"${v.name}" will be available again.'
              : '"${v.name}" will be hidden from new entries. Existing data is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(subCategoryRepositoryProvider)
          .setActive(profileId: profileId, id: v.id, isActive: value);
    } on AppException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _openForm([SubCategoryView? existing]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SubCategoryFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(activeProfileIdProvider);
    final categories =
        ref.watch(subCategoryCategoryOptionsProvider).value ?? const [];
    final list = ref.watch(subCategoriesProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Sub-categories')),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add sub-category',
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? const Center(child: Text('Select a profile first.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search sub-categories',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                      ),
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: _categoryId == c.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = c.id),
                          ),
                        ),
                    ],
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Show inactive'),
                  value: _showInactive,
                  onChanged: (v) => setState(() => _showInactive = v),
                ),
                Expanded(
                  child: list.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Could not load sub-categories: $e'),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text('No sub-categories found.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final v = items[i];
                          return ListTile(
                            title: Text(v.name),
                            subtitle: Text(
                              v.categoryName +
                                  (v.isActive ? '' : ' - inactive'),
                            ),
                            onTap: () => _openForm(v),
                            trailing: Switch(
                              value: v.isActive,
                              onChanged: (val) => _toggle(v, val),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SubCategoryFormDialog extends ConsumerStatefulWidget {
  const _SubCategoryFormDialog({this.existing});
  final SubCategoryView? existing;

  @override
  ConsumerState<_SubCategoryFormDialog> createState() =>
      _SubCategoryFormDialogState();
}

class _SubCategoryFormDialogState
    extends ConsumerState<_SubCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late int? _categoryId = widget.existing?.categoryId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(subCategoryRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          categoryId: _categoryId!,
          name: _name.text,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.id,
          name: _name.text,
          categoryId: _categoryId,
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
    final all = ref.watch(subCategoryCategoryOptionsProvider).value ?? const [];
    final options = all
        .where((c) => c.isActive || c.id == widget.existing?.categoryId)
        .toList();
    final value = options.any((c) => c.id == _categoryId) ? _categoryId : null;
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add sub-category' : 'Edit sub-category',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: value,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in options)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            TextFormField(
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
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
