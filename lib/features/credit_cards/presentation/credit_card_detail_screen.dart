import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/credit_card.dart';
import '../providers/credit_card_providers.dart';
import 'credit_card_bill_sheet.dart';
import 'credit_card_form_sheet.dart';
import 'credit_card_widgets.dart';

/// Route: /cards/:id
class CreditCardDetailScreen extends ConsumerWidget {
  const CreditCardDetailScreen({super.key, required this.cardId});
  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(creditCardProvider(cardId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.creditCardsTitle)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l.creditCardsTitle)),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(creditCardProvider(cardId)),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.creditCardsTitle)),
            body: EmptyState(message: l.creditCardsNotFound),
          );
        }
        return _Body(summary: summary);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});
  final CardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final card = summary.card;
    final bills = ref.watch(cardBillsProvider(card.id));
    final profileId = ref.read(activeProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          const HelpButton(topicId: 'cards'),
          IconButton(
            tooltip: l.commonEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showCreditCardForm(context, existing: card),
          ),
          IconButton(
            tooltip: card.isActive
                ? l.creditCardsDeactivate
                : l.creditCardsActivate,
            icon: Icon(
              card.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            onPressed: profileId == null
                ? null
                : () async {
                    try {
                      await ref
                          .read(creditCardRepositoryProvider)
                          .setActive(profileId, card.id, !card.isActive);
                    } on AppException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
          ),
        ],
      ),
      floatingActionButton: card.isActive
          ? FloatingActionButton.extended(
              onPressed: () => showCreditCardBillSheet(context, card: card),
              icon: const Icon(Icons.add),
              label: Text(l.creditCardsAddBill),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!card.isActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l.creditCardsInactiveBanner),
                  ),
                Text(
                  card.lastFour == null
                      ? card.bankName
                      : '${card.bankName}  •••• ${card.lastFour}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                CardRow(
                  label: l.creditCardsLimit,
                  value: formatMinor(card.creditLimitMinor),
                ),
                CardRow(
                  label: l.creditCardsOutstanding,
                  value: formatMinor(summary.outstandingMinor),
                  bold: true,
                ),
                CardRow(
                  label: l.creditCardsAvailable,
                  value: formatMinor(summary.availableMinor),
                  color: summary.availableMinor < 0 ? AppColors.expense : null,
                ),
                if (summary.chargesMinor > 0)
                  CardRow(
                    label: l.creditCardsChargesAdded,
                    value: formatMinor(summary.chargesMinor),
                    color: AppColors.expense,
                  ),
                const SizedBox(height: 8),
                UtilisationBar(bp: summary.utilisationBp),
                const SizedBox(height: 4),
                Text(
                  l.creditCardsUsed(pct(summary.utilisationBp ~/ 100 * 100)),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(l.creditCardsPolicy, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(label: Text(l.creditCardsChipApr(pct(card.aprBp)))),
                    Chip(
                      label: Text(l.creditCardsChipMin(pct(card.minPaymentBp))),
                    ),
                    Chip(
                      label: Text(
                        l.creditCardsChipLateFee(
                          card.lateFeeFloorMinor > 0 && card.lateFeeBp == 0
                              ? formatMinor(card.lateFeeFloorMinor)
                              : pct(card.lateFeeBp),
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        l.creditCardsChipStatementDay(card.statementDay),
                      ),
                    ),
                    Chip(label: Text(l.creditCardsChipDueDays(card.dueDays))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l.creditCardsBills, style: theme.textTheme.titleMedium),
          ),
          bills.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorState(error: e),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l.creditCardsNoBills)),
                  )
                : Column(
                    children: [
                      for (final s in list)
                        _BillTile(cardId: card.id, statement: s),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.cardId, required this.statement});
  final int cardId;
  final BillStatement statement;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final b = statement.bill;
    return ListTile(
      title: Row(
        children: [
          Text(b.billMonth, style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
          BillStatusChip(status: statement.status),
        ],
      ),
      subtitle: Text(
        [
          l.creditCardsBillAmount(formatMinor(b.amountMinor)),
          l.creditCardsDueOn(b.dueDate),
          if (statement.totalChargesMinor > 0)
            l.creditCardsExtraPct(pct(statement.extraBp)),
        ].join('  •  '),
      ),
      trailing: Text(
        l.creditCardsRemainingAmount(formatMinor(statement.remainingMinor)),
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => context.push('/cards/$cardId/bills/${b.id}'),
    );
  }
}
