import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/tag.dart';
import '../providers/tag_providers.dart';

/// Embeddable multi-select chip wrap with inline "create new tag".
class TagPicker extends ConsumerStatefulWidget {
  const TagPicker({
    super.key,
    required this.selectedIds,
    required this.onChanged,
  });

  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  ConsumerState<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends ConsumerState<TagPicker> {
  bool _creating = false;
  String? _error;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    final next = {...widget.selectedIds};
    if (!next.remove(id)) next.add(id);
    widget.onChanged(next);
  }

  Future<void> _create() async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    try {
      final tag = await ref
          .read(tagRepositoryProvider)
          .create(profileId: pid, name: _controller.text);
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = null;
        _controller.clear();
      });
      widget.onChanged({...widget.selectedIds, tag.id});
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(activeTagsProvider);
    return tags.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('$e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final t in list) _chip(t),
              if (!_creating)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(context.l10n.tagsNew),
                  onPressed: () => setState(() => _creating = true),
                ),
            ],
          ),
          if (_creating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: tagNameMaxLength,
                      decoration: InputDecoration(
                        labelText: context.l10n.tagsNewName,
                        errorText: _error,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _create(),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.tagsAdd,
                    icon: const Icon(Icons.check),
                    onPressed: _create,
                  ),
                  IconButton(
                    tooltip: context.l10n.commonCancel,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _creating = false;
                      _error = null;
                      _controller.clear();
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(Tag t) {
    final selected = widget.selectedIds.contains(t.id);
    return FilterChip(
      label: Text(t.name),
      selected: selected,
      avatar: t.color == null
          ? null
          : CircleAvatar(backgroundColor: Color(t.color!), radius: 6),
      onSelected: (_) => _toggle(t.id),
    );
  }
}
