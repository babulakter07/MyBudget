import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/category.dart';
import '../providers/category_providers.dart';
import 'category_form_sheet.dart';
import 'category_visuals.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final filter = ref.watch(categoryFilterProvider);
    final async = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add category',
              onPressed: () => showCategoryForm(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search categories',
                border: OutlineInputBorder(),
              ),
              onChanged: ref.read(categoryFilterProvider.notifier).setSearch,
            ),
          ),
          SwitchListTile(
            title: const Text('Show inactive'),
            value: filter.includeInactive,
            onChanged: ref
                .read(categoryFilterProvider.notifier)
                .setIncludeInactive,
          ),
          Expanded(
            child: profileId == null
                ? const _Message(
                    icon: Icons.person_off,
                    text: 'Select a profile to manage categories.',
                  )
                : async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _Message(
                      icon: Icons.error_outline,
                      text: 'Something went wrong: $e',
                    ),
                    data: (items) => items.isEmpty
                        ? const _Message(
                            icon: Icons.category_outlined,
                            text: 'No categories yet. Tap + to add one.',
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) =>
                                _CategoryTile(category: items[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});
  final Category category;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(value ? 'Activate category?' : 'Deactivate category?'),
        content: Text(
          value
              ? '"${category.name}" will be available again.'
              : '"${category.name}" will be hidden from new entries. Existing data is kept.',
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
          .read(categoryRepositoryProvider)
          .setActive(category.profileId, category.id, value);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category.color == null ? null : Color(category.color!);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: Icon(iconForKey(category.icon)),
      ),
      title: Text(
        category.name,
        style: category.isActive
            ? null
            : TextStyle(color: Theme.of(context).disabledColor),
      ),
      subtitle: category.description == null
          ? null
          : Text(category.description!),
      onTap: () => showCategoryForm(context, existing: category),
      trailing: Switch(
        value: category.isActive,
        onChanged: (v) => _toggle(context, ref, v),
      ),
    );
  }
}
