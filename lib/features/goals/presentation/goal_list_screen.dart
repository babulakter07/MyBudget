import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/goal.dart';
import '../providers/goal_providers.dart';
import 'goal_form_sheet.dart';
import 'goal_widgets.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final showArchived = ref.watch(goalShowArchivedProvider);
    final async = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.goalsTitle)),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: context.l10n.goalsAddGoal,
              onPressed: () => showGoalForm(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(context.l10n.goalsShowArchived),
            value: showArchived,
            onChanged: ref.read(goalShowArchivedProvider.notifier).set,
          ),
          Expanded(
            child: profileId == null
                ? EmptyState(
                    icon: Icons.person_off,
                    message: context.l10n.goalsSelectProfile,
                  )
                : async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(
                      error: e,
                      onRetry: () => ref.invalidate(goalsProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? EmptyState(
                            icon: Icons.savings_outlined,
                            message: context.l10n.goalsEmpty,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _GoalCard(item: items[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.item});
  final GoalWithProgress item;

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    bool active,
  ) async {
    final g = item.goal;
    if (!active) {
      final ok = await showConfirmDialog(
        context,
        title: context.l10n.goalsArchiveTitle,
        message: context.l10n.goalsArchiveMessage(g.name),
        confirmLabel: context.l10n.commonConfirm,
        cancelLabel: context.l10n.commonCancel,
      );
      if (!ok) return;
    }
    try {
      await ref
          .read(goalRepositoryProvider)
          .setActive(g.profileId, g.id, active);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final g = item.goal;
    final p = item.progress;
    return Opacity(
      opacity: g.isActive ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showGoalForm(context, existing: g),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoalProgressBody(item: item),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: p.displayPercent / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        g.isActive
                            ? context.l10n.goalsAccountLine(item.accountName)
                            : context.l10n.goalsAccountLineArchived(
                                item.accountName,
                              ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (p.achieved) const AchievedBadge(),
                    if (g.isActive)
                      IconButton(
                        tooltip: context.l10n.goalsArchiveGoal,
                        icon: const Icon(Icons.archive_outlined),
                        onPressed: () => _setActive(context, ref, false),
                      )
                    else
                      IconButton(
                        tooltip: context.l10n.goalsRestoreGoal,
                        icon: const Icon(Icons.unarchive_outlined),
                        onPressed: () => _setActive(context, ref, true),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
