import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../domain/dashboard_calculations.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_widgets.dart';

class OverviewSection extends ConsumerWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = Theme.of(context).colorScheme.error;
    final cash = ref.watch(cashBalanceProvider);
    return AsyncSection(
      value: ref.watch(monthOverviewProvider),
      builder: (o) {
        final pct = DashboardCalculations.utilizationPercent(
          o.budgetMinor,
          o.expenseMinor,
        );
        final over = o.expenseMinor > o.budgetMinor && o.hasBudget;
        return StatGrid(
          children: [
            StatCard(
              label: 'Monthly budget',
              value: formatMinor(o.budgetMinor),
            ),
            StatCard(
              label: 'Month expense',
              value: formatMinor(o.expenseMinor),
              color: AppColors.expense,
            ),
            StatCard(
              label: 'Remaining budget',
              value: formatMinor(o.remainingMinor),
              color: o.remainingMinor < 0 ? error : null,
            ),
            StatCard(
              label: 'Budget utilization',
              value: '${pct.toStringAsFixed(1)}%',
              color: over ? error : null,
              footer: LinearProgressIndicator(
                value: DashboardCalculations.utilizationProgress(
                  o.budgetMinor,
                  o.expenseMinor,
                ),
                color: over ? error : null,
              ),
            ),
            StatCard(
              label: 'Cash balance (active accounts)',
              value: cash.when(
                data: formatMinor,
                loading: () => '...',
                error: (_, _) => '-',
              ),
            ),
            StatCard(
              label: 'Month income',
              value: formatMinor(o.incomeMinor),
              color: AppColors.income,
            ),
          ],
        );
      },
    );
  }
}
