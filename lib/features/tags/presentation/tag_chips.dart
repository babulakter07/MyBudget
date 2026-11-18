import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/tag_providers.dart';

/// Read-only chips of the tags on a transaction (empty when none).
class TagChips extends ConsumerWidget {
  const TagChips({super.key, required this.transactionId});
  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsForTransactionProvider(transactionId));
    return tags.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final t in list)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(t.name),
                avatar: t.color == null
                    ? null
                    : CircleAvatar(backgroundColor: Color(t.color!), radius: 6),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
