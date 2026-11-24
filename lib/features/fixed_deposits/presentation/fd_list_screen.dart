import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/fixed_deposit_calculator.dart';
import '../providers/fixed_deposit_providers.dart';
import 'fd_form_sheet.dart';
import 'fd_labels.dart';

/// Route: /fd
class FdListScreen extends ConsumerWidget {
  const FdListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profileId = ref.watch(activeProfileIdProvider);
    final showArchived = ref.watch(fdShowArchivedProvider);
    final async = ref.watch(fixedDepositsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.fixedDepositsListTitle),
        actions: const [HelpButton(topicId: 'fixed_deposits')],
      ),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: l.fixedDepositsAdd,
              onPressed: () => showFdForm(context),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(icon: Icons.person_off, message: l.commonSelectProfile)
          : Column(
              children: [
                const _SummaryCard(),
                SwitchListTile(
                  title: Text(l.fixedDepositsShowArchived),
                  value: showArchived,
                  onChanged: ref.read(fdShowArchivedProvider.notifier).set,
                ),
                Expanded(
                  child: async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(
                      error: e,
                      onRetry: () => ref.invalidate(fixedDepositsProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? EmptyState(
                            icon: Icons.savings_outlined,
                            message: l.fixedDepositsEmpty,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: items.length,
                            itemBuilder: (_, i) => FdTile(position: items[i]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s =
        ref.watch(fixedDepositSummaryProvider).value ??
        FixedDepositSummary.empty;
    final theme = Theme.of(context);
    Widget cell(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Row(
              children: [
                cell(l.fixedDepositsSummaryOpen, '${s.openCount}'),
                cell(l.fixedDepositsSummaryPlaced, formatMinor(s.placedMinor)),
                cell(
                  l.fixedDepositsSummaryInterest,
                  formatMinor(s.expectedInterestMinor),
                ),
              ],
            ),
            if (s.nextMaturityDate != null) ...[
              const SizedBox(height: 8),
              Text(
                l.fixedDepositsNextMaturity(
                  s.nextMaturityDate!,
                  formatMinor(s.nextMaturityPrincipalMinor),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (s.maturedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                l.fixedDepositsMaturedAlert(s.maturedCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.income,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FdTile extends StatelessWidget {
  const FdTile({super.key, required this.position});
  final FixedDepositPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = position;
    final t = p.current;
    final due = fdDueText(l, p);
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${fdSchemeLabel(l, p.deposit.schemeType)} • ${p.deposit.bankName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (t.isReissue && t.isActive) ...[
            FdChip(
              label: l.fixedDepositsBadgeReissued,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
          ],
          FdStatusChip(status: p.status),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                l.fixedDepositsInstrumentRow(t.instrumentNumber),
                l.fixedDepositsRatePerYear(fdRateText(t.rateBp)),
                if (!p.deposit.isActive) l.fixedDepositsArchived,
              ].join('  •  '),
            ),
            const SizedBox(height: 2),
            Text(
              [p.maturityDate, ?due].join('  •  '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMinor(t.principalMinor),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
      onTap: () => context.push('/fd/${p.deposit.id}'),
    );
  }
}
