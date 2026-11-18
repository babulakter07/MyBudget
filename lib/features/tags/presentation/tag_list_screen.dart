import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/tag.dart';
import '../providers/tag_providers.dart';

/// Manage tags: create, rename, recolor, archive/restore.
class TagListScreen extends ConsumerStatefulWidget {
  const TagListScreen({super.key});

  @override
  ConsumerState<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends ConsumerState<TagListScreen> {
  bool _showArchived = false;

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() fn) async {
    try {
      await fn();
    } on AppException catch (e) {
      if (mounted) _msg(e.message);
    }
  }

  Future<void> _edit(Tag? tag) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final repo = ref.read(tagRepositoryProvider);
    final result = await showDialog<({String name, int? color})>(
      context: context,
      builder: (_) => _TagEditDialog(tag: tag),
    );
    if (result == null) return;
    await _run(() async {
      if (tag == null) {
        await repo.create(
          profileId: pid,
          name: result.name,
          color: result.color,
        );
      } else {
        if (result.name != tag.name) {
          await repo.rename(pid, tag.id, result.name);
        }
        if (result.color != tag.color) {
          await repo.recolor(pid, tag.id, result.color);
        }
      }
    });
  }

  Future<void> _toggle(Tag tag) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final repo = ref.read(tagRepositoryProvider);
    if (tag.isActive) {
      final ok = await showConfirmDialog(
        context,
        title: context.l10n.tagsArchiveTitle,
        message: context.l10n.tagsArchiveMessage(tag.name),
        confirmLabel: context.l10n.commonArchive,
      );
      if (!ok) return;
    }
    await _run(() => repo.setActive(pid, tag.id, !tag.isActive));
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(allTagsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tagsTitle),
        actions: [
          IconButton(
            tooltip: _showArchived
                ? context.l10n.tagsHideArchived
                : context.l10n.tagsShowArchived,
            icon: Icon(
              _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: context.l10n.tagsAdd,
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: tags.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(allTagsProvider),
        ),
        data: (all) {
          final items = all.where((t) => _showArchived || t.isActive).toList();
          if (items.isEmpty) {
            return EmptyState(
              message: context.l10n.tagsEmpty,
              icon: Icons.sell_outlined,
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: t.color == null
                      ? Theme.of(context).colorScheme.primary
                      : Color(t.color!),
                ),
                title: Text(
                  t.name,
                  style: t.isActive
                      ? null
                      : const TextStyle(fontStyle: FontStyle.italic),
                ),
                subtitle: t.isActive ? null : Text(context.l10n.tagsArchived),
                onTap: () => _edit(t),
                trailing: IconButton(
                  tooltip: t.isActive
                      ? context.l10n.commonArchive
                      : context.l10n.commonRestore,
                  icon: Icon(
                    t.isActive
                        ? Icons.archive_outlined
                        : Icons.unarchive_outlined,
                  ),
                  onPressed: () => _toggle(t),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TagEditDialog extends StatefulWidget {
  const _TagEditDialog({this.tag});
  final Tag? tag;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.tag?.name ?? '',
  );
  int? _color;
  String? _error;

  @override
  void initState() {
    super.initState();
    _color = widget.tag?.color;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = context.l10n.tagsNameRequired);
      return;
    }
    Navigator.of(context).pop((name: n, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.tag == null ? context.l10n.tagsNew : context.l10n.tagsEdit,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: tagNameMaxLength,
            decoration: InputDecoration(
              labelText: context.l10n.tagsName,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in tagPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = _color == c ? null : c),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(c),
                    child: _color == c
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(context.l10n.commonSave)),
      ],
    );
  }
}
