import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

import '../domain/insights_calculations.dart';
import '../providers/insights_providers.dart';

/// Embeddable dashboard card (no Scaffold): top 2-3 insight messages for the
/// current month, forecast first. Tapping opens `/insights`. Renders nothing
/// while loading, on error, or when there is no data.
class InsightsHighlightsCard extends ConsumerWidget {
  const InsightsHighlightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(currentInsightsProvider).value;
    if (insights == null || !insights.hasData) return const SizedBox.shrink();
    final messages = InsightMessages.all(
      context.l10n,
      insights,
    ).take(3).toList();
    if (messages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/insights'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.insightsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              for (final m in messages)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(m.text, style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
