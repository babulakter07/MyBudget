import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../providers/debt_providers.dart';

/// Embeddable dashboard card (no Scaffold). Hidden when there are no debts.
class DebtSummaryCard extends ConsumerWidget {
  const DebtSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(debtSummaryProvider).value;
    if (s == null || s.activeCount == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    Widget cell(String label, String value, Color? color) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/debts'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.handshake_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.debtsListTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  cell(
                    context.l10n.debtsOwedToMe,
                    formatMinor(s.owedToMeMinor),
                    AppColors.income,
                  ),
                  cell(
                    context.l10n.debtsIOwe,
                    formatMinor(s.iOweMinor),
                    AppColors.expense,
                  ),
                  cell(
                    context.l10n.debtsOverdue,
                    '${s.overdueCount}',
                    s.overdueCount > 0 ? AppColors.expense : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
