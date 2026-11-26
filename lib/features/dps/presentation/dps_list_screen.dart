import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/dps.dart';
import '../providers/dps_providers.dart';
import 'dps_form_sheet.dart';
import 'dps_labels.dart';

/// Route: /dps
class DpsListScreen extends ConsumerWidget {
  const DpsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profileId = ref.watch(activeProfileIdProvider);
    final async = ref.watch(dpsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.dpsTitle),
        actions: const [HelpButton(topicId: 'dps')],
      ),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: l.dpsAdd,
              onPressed: () => showDpsForm(context),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(icon: Icons.person_off, message: l.commonSelectProfile)
          : async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(dpsListProvider),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  if (items.isNotEmpty) _Summary(items: items),
                  SwitchListTile(
                    title: Text(l.dpsShowArchived),
                    value: ref.watch(dpsShowArchivedProvider),
                    onChanged: ref.read(dpsShowArchivedProvider.notifier).set,
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyState(
                        icon: Icons.savings_outlined,
                        message: l.dpsEmpty,
                      ),
                    ),
                  for (final p in items) _DpsTile(position: p),
                ],
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.items});
  final List<DpsPosition> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    var open = 0, deposited = 0, monthly = 0, overdue = 0;
    for (final p in items) {
      if (p.isClosed || !p.account.isActive) continue;
      open++;
      deposited += p.depositedMinor;
      if (p.remainingCount > 0) monthly += p.terms.installmentMinor;
      overdue += p.overdueMinor;
    }
    Widget cell(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
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
                cell(l.dpsSummaryOpen, '$open'),
                cell(l.dpsSummaryDeposited, formatMinor(deposited)),
                cell(l.dpsSummaryMonthly, formatMinor(monthly)),
              ],
            ),
            if (overdue > 0) ...[
              const SizedBox(height: 8),
              Text(
                l.dpsSummaryOverdue(formatMinor(overdue)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.expense,
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

class _DpsTile extends StatelessWidget {
  const _DpsTile({required this.position});
  final DpsPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = position;
    final next = p.nextDue;
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(p.terms.bankName, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          DpsStatusChip(status: p.status),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            [
              l.dpsPerMonth(formatMinor(p.terms.installmentMinor)),
              l.dpsPaidOf(p.paidCount, p.terms.tenureMonths),
              if (!p.account.isActive) l.dpsArchived,
            ].join('  •  '),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: p.progress),
          if (!p.isClosed) ...[
            const SizedBox(height: 4),
            Text(
              next == null
                  ? l.dpsMaturesOn(p.maturityDate)
                  : l.dpsNextDue(next.dueDate),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      onTap: () => context.push('/dps/${p.account.id}'),
    );
  }
}
