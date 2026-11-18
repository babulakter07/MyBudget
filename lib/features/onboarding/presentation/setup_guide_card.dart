import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/setup_progress.dart';

/// Compact card for the top of the Home tab. Hidden once every step is done
/// or when the user dismisses it.
class SetupGuideCard extends ConsumerWidget {
  const SetupGuideCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(setupGuideDismissedProvider);
    final progress = ref.watch(setupProgressProvider).value;
    if (dismissed || progress == null || progress.complete) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Card(
      key: const ValueKey('setup-card'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ListTile(
        leading: const Icon(Icons.checklist_rtl),
        title: Text(l10n.setupCardTitle),
        subtitle: Text(
          l10n.setupProgress(progress.doneCount, SetupProgress.total),
        ),
        onTap: () => context.push('/setup'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => context.push('/setup'),
              child: Text(l10n.setupCardAction),
            ),
            IconButton(
              key: const ValueKey('setup-dismiss'),
              tooltip: l10n.setupDismiss,
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(setupGuideDismissedProvider.notifier).set(true),
            ),
          ],
        ),
      ),
    );
  }
}
