import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../providers/goal_providers.dart';
import 'goal_widgets.dart';

/// Embeddable dashboard card: top 3 active goals. Hidden when there are none
/// (and while loading / on error, so the dashboard never shows a broken tile).
class GoalsSummaryCard extends ConsumerWidget {
  const GoalsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeGoalsProvider);
    final items = async.asData?.value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final top = items.take(3).toList();
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/goals'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.goalsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              for (final g in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: GoalProgressBody(item: g, compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
