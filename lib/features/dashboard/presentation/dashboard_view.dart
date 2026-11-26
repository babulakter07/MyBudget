import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../debts/presentation/debt_summary_card.dart';
import '../../goals/presentation/goals_summary_card.dart';
import '../../insights/presentation/insights_highlights_card.dart';
import '../../ledger/presentation/period_pickers.dart';
import '../../profiles/data/profile_providers.dart';
import '../../upcoming/presentation/upcoming_payments_card.dart';
import '../providers/dashboard_providers.dart';
import 'analytics_section.dart';
import 'overview_section.dart';
import 'yearly_section.dart';

/// Dashboard tab body (no Scaffold of its own).
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProfileProvider);
    return active.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorState(error: e),
      data: (profile) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(profile?.name ?? context.l10n.dashboardNoProfile),
              subtitle: Text(profile?.currencyCode ?? ''),
              trailing: TextButton.icon(
                onPressed: () => context.go('/profiles'),
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.l10n.dashboardSwitch),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const UpcomingPaymentsCard(),
          const _PeriodFilter(),
          const SizedBox(height: 12),
          const OverviewSection(),
          const SizedBox(height: 12),
          const InsightsHighlightsCard(),
          const GoalsSummaryCard(),
          const DebtSummaryCard(),
          const AnalyticsSection(),
          const YearlySection(),
        ],
      ),
    );
  }
}

class _PeriodFilter extends ConsumerWidget {
  const _PeriodFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);
    final notifier = ref.read(dashboardFilterProvider.notifier);
    final month = ref.watch(dashboardMonthProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: Text(context.l10n.dashboardCurrentMonth),
          selected: filter.mode == DashboardPeriodMode.current,
          onSelected: (_) => notifier.setCurrent(),
        ),
        ChoiceChip(
          label: Text(context.l10n.dashboardPreviousMonth),
          selected: filter.mode == DashboardPeriodMode.previous,
          onSelected: (_) => notifier.setPrevious(),
        ),
        ChoiceChip(
          label: Text(
            filter.mode == DashboardPeriodMode.selected
                ? monthLabel(month)
                : context.l10n.dashboardSelectMonth,
          ),
          selected: filter.mode == DashboardPeriodMode.selected,
          onSelected: (_) async {
            final picked = await showMonthYearPicker(context, initial: month);
            if (picked != null) notifier.selectMonth(picked);
          },
        ),
        Text(monthLabel(month), style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
