import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/credit_card.dart';
import '../providers/credit_card_providers.dart';
import 'credit_card_form_sheet.dart';
import 'credit_card_widgets.dart';

/// Route: /cards
class CreditCardListScreen extends ConsumerWidget {
  const CreditCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profileId = ref.watch(activeProfileIdProvider);
    final async = ref.watch(creditCardSummariesProvider);
    final overall = ref.watch(overallCardSummaryProvider);
    final showInactive = ref.watch(showInactiveCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.creditCardsTitle),
        actions: const [HelpButton(topicId: 'cards')],
      ),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: l.creditCardsAdd,
              onPressed: () => showCreditCardForm(context),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(icon: Icons.person_off, message: l.commonSelectProfile)
          : async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(creditCardSummariesProvider),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  if (overall.value != null && overall.value!.cardCount > 0)
                    _OverallCard(summary: overall.value!),
                  SwitchListTile(
                    title: Text(l.creditCardsShowInactive),
                    value: showInactive,
                    onChanged: ref.read(showInactiveCardsProvider.notifier).set,
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyState(
                        icon: Icons.credit_card,
                        message: l.creditCardsEmpty,
                      ),
                    )
                  else
                    for (final s in items) _CardTile(summary: s),
                ],
              ),
            ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.summary});
  final OverallCardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final next = summary.nextDue;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.creditCardsTotalOutstanding,
              style: theme.textTheme.labelLarge,
            ),
            Text(
              formatMinor(summary.totalOutstandingMinor),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            UtilisationBar(bp: summary.utilisationBp),
            const SizedBox(height: 4),
            Text(
              '${l.creditCardsUsed(pct(summary.utilisationBp ~/ 100 * 100))}'
              '  •  ${l.creditCardsAvailable}: ${formatMinor(summary.availableMinor)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${l.creditCardsTotalLimit}: ${formatMinor(summary.totalLimitMinor)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (summary.overdueCount > 0)
              Text(
                l.creditCardsOverdueBills(summary.overdueCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.expense,
                ),
              ),
            Text(
              next == null
                  ? l.creditCardsNothingDue
                  : l.creditCardsNextDue(
                      next.cardName,
                      next.statement.bill.dueDate,
                    ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.summary});
  final CardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final card = summary.card;
    final next = summary.nextDue;
    final overdue = summary.overdueCount > 0;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/cards/${card.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: card.isActive ? null : theme.disabledColor,
                          ),
                        ),
                        Text(
                          card.lastFour == null
                              ? card.bankName
                              : '${card.bankName}  •••• ${card.lastFour}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.creditCardsOutstanding,
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        formatMinor(summary.outstandingMinor),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              UtilisationBar(bp: summary.utilisationBp),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l.creditCardsAvailableShort}: ${formatMinor(summary.availableMinor)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (overdue)
                    Text(
                      l.creditCardsOverdueBadge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.expense,
                      ),
                    )
                  else if (next != null)
                    Text(
                      l.creditCardsDueOn(next.bill.dueDate),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              if (!card.isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.commonInactive,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
