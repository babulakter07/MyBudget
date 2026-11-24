import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';
import '../providers/loan_providers.dart';
import 'loan_form_sheet.dart';
import 'loan_widgets.dart';

/// Route: /loans
class LoanListScreen extends ConsumerWidget {
  const LoanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profileId = ref.watch(activeProfileIdProvider);
    final showArchived = ref.watch(loanShowArchivedProvider);
    final async = ref.watch(loansProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.loansListTitle),
        actions: const [HelpButton(topicId: 'loans')],
      ),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: l.loansAdd,
              onPressed: () => showLoanForm(context),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(icon: Icons.person_off, message: l.commonSelectProfile)
          : Column(
              children: [
                const _SummaryCard(),
                SwitchListTile(
                  title: Text(l.loansShowArchived),
                  value: showArchived,
                  onChanged: ref.read(loanShowArchivedProvider.notifier).set,
                ),
                Expanded(
                  child: async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(
                      error: e,
                      onRetry: () => ref.invalidate(loansProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? EmptyState(
                            icon: Icons.account_balance_outlined,
                            message: l.loansEmpty,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: items.length,
                            itemBuilder: (_, i) => LoanTile(position: items[i]),
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
    final s = ref.watch(loanSummaryProvider).value ?? LoanSummary.empty;
    final theme = Theme.of(context);
    Widget cell(String label, String value, Color? color) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
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
                cell(
                  l.loansTotalRemaining,
                  formatMinor(s.remainingMinor),
                  null,
                ),
                cell(
                  l.loansOverdue,
                  formatMinor(s.overdueMinor),
                  s.overdueMinor > 0 ? AppColors.expense : null,
                ),
                cell(
                  l.loansMonthlyCommitment,
                  formatMinor(s.monthlyCommitmentMinor),
                  null,
                ),
              ],
            ),
            if (s.nextDueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                l.loansNextDueRow(s.nextDueDate!, formatMinor(s.nextDueMinor)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoanTile extends StatelessWidget {
  const LoanTile({super.key, required this.position});
  final LoanPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final loan = position.loan;
    final theme = Theme.of(context);
    final next = position.nextDue;
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(loan.lenderName, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          LoanPositionChip(position: position),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                loanTypeLabel(l, loan.loanType),
                loanPerPeriod(
                  l,
                  loan.frequency,
                  formatMinor(loan.installmentMinor),
                ),
                if (!loan.isActive) l.loansArchived,
              ].join('  •  '),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: position.progress),
            const SizedBox(height: 4),
            Text(
              position.isEarlyClosed
                  ? l.loansBannerEarly(loan.closedDate ?? '')
                  : position.isAdjusted
                  ? l.loansBannerAdjusted(loan.closedDate ?? '')
                  : next == null
                  ? l.loansClosedMessage
                  : l.loansNextDueRow(
                      next.dueDate,
                      formatMinor(next.unpaidMinor),
                    ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(l.loansRemaining, style: theme.textTheme.labelSmall),
          Text(
            formatMinor(loan.isClosedByUser ? 0 : position.remainingMinor),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
      onTap: () => context.push('/loans/${loan.id}'),
    );
  }
}
