import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'credit_card_payment_sheet.dart';
import 'credit_card_widgets.dart';

/// Route: /cards/:id/bills/:billId
class CreditCardBillScreen extends ConsumerWidget {
  const CreditCardBillScreen({
    super.key,
    required this.cardId,
    required this.billId,
  });
  final int cardId;
  final int billId;

  void _snack(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(BuildContext context, Future<void> Function() a) async {
    try {
      await a();
    } on AppException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(cardBillProvider(billId));
    final card = ref.watch(creditCardProvider(cardId)).value?.card;
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.creditCardsTitle)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l.creditCardsTitle)),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(cardBillProvider(billId)),
        ),
      ),
      data: (st) {
        if (st == null || card == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.creditCardsTitle)),
            body: EmptyState(message: l.creditCardsBillNotFound),
          );
        }
        return _build(context, ref, st, card);
      },
    );
  }

  Widget _build(
    BuildContext context,
    WidgetRef ref,
    BillStatement st,
    CreditCard card,
  ) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final bill = st.bill;
    final profileId = ref.read(activeProfileIdProvider);
    final payments = ref.watch(cardPaymentsProvider(billId));
    final projection = ref.watch(billProjectionProvider(billId)).value;
    final canPay = bill.isActive && st.remainingMinor > 0;
    final bad = AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.creditCardsBillTitle(bill.billMonth)),
        actions: [
          const HelpButton(topicId: 'cards'),
          if (bill.isActive) ...[
            IconButton(
              tooltip: l.commonEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showCreditCardBillSheet(context, card: card, existing: bill),
            ),
            IconButton(
              tooltip: l.creditCardsVoidBill,
              icon: const Icon(Icons.block),
              onPressed: profileId == null
                  ? null
                  : () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: l.creditCardsVoidBill,
                        message: l.creditCardsVoidBillMessage,
                        confirmLabel: l.creditCardsVoid,
                        cancelLabel: l.commonCancel,
                      );
                      if (!ok || !context.mounted) return;
                      await _run(
                        context,
                        () => ref
                            .read(creditCardRepositoryProvider)
                            .voidBill(profileId, bill.id),
                      );
                    },
            ),
          ],
        ],
      ),
      floatingActionButton: canPay
          ? FloatingActionButton.extended(
              onPressed: () => showCardPaymentSheet(context, st),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l.creditCardsPay),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    BillStatusChip(status: st.status),
                    Text(l.creditCardsDueOn(bill.dueDate)),
                    if (st.daysOverdue > 0)
                      Text(
                        l.creditCardsDaysOverdue(st.daysOverdue),
                        style: TextStyle(color: bad),
                      ),
                  ],
                ),
                if (!bill.isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l.creditCardsVoidedBanner),
                  ),
                const SizedBox(height: 12),
                Text(
                  l.creditCardsBreakdown,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                CardRow(
                  label: l.creditCardsBillAmountLabel,
                  value: formatMinor(st.amountMinor),
                ),
                CardRow(
                  label: l.creditCardsMinimumDue,
                  value: formatMinor(st.minPaymentMinor),
                ),
                CardRow(
                  label: l.creditCardsInterest(pct(card.aprBp)),
                  value: formatMinor(st.interestMinor),
                  color: st.interestMinor > 0 ? bad : null,
                ),
                CardRow(
                  label: l.creditCardsLateFee(pct(card.lateFeeBp)),
                  value: formatMinor(st.lateFeeMinor),
                  color: st.lateFeeMinor > 0 ? bad : null,
                ),
                CardRow(
                  label: l.creditCardsExtraCharges,
                  value: l.creditCardsExtraValue(
                    formatMinor(st.totalChargesMinor),
                    pct(st.extraBp),
                  ),
                  color: st.totalChargesMinor > 0 ? bad : null,
                ),
                const Divider(),
                CardRow(
                  label: l.creditCardsTotalPayable,
                  value: formatMinor(st.totalPayableMinor),
                ),
                CardRow(
                  label: l.creditCardsPaidSoFar,
                  value: formatMinor(st.paidMinor),
                ),
                CardRow(
                  label: l.creditCardsRemaining,
                  value: formatMinor(st.remainingMinor),
                  bold: true,
                ),
                if (st.effectiveAnnualBp > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l.creditCardsEffectiveAnnual(pct(st.effectiveAnnualBp)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (bill.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(bill.note!, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          if (projection != null && canPay)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.creditCardsProjectionTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l.creditCardsProjectionIntro(projection.horizon)),
                    const SizedBox(height: 8),
                    if (projection.minimumMinor > 0)
                      Text(
                        l.creditCardsProjectionMin(
                          formatMinor(projection.minimumMinor),
                          formatMinor(projection.chargesIfMinimumMinor),
                        ),
                      ),
                    Text(
                      l.creditCardsProjectionNothing(
                        formatMinor(projection.chargesIfNothingMinor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l.creditCardsPayments,
              style: theme.textTheme.titleMedium,
            ),
          ),
          payments.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorState(error: e),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l.creditCardsNoPayments)),
                  )
                : Column(
                    children: [
                      for (final p in list)
                        ListTile(
                          title: Text(
                            formatMinor(p.amountMinor),
                            style: p.isDeleted
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            [
                              p.paymentDate,
                              if (p.note != null) p.note!,
                              if (p.isDeleted) l.creditCardsVoided,
                            ].join('  •  '),
                          ),
                          trailing: p.isDeleted || profileId == null
                              ? null
                              : IconButton(
                                  tooltip: l.creditCardsVoidPayment,
                                  icon: const Icon(Icons.undo),
                                  onPressed: () async {
                                    final ok = await showConfirmDialog(
                                      context,
                                      title: l.creditCardsVoidPayment,
                                      message: l.creditCardsVoidPaymentMessage(
                                        formatMinor(p.amountMinor),
                                      ),
                                      confirmLabel: l.creditCardsVoid,
                                      cancelLabel: l.commonCancel,
                                    );
                                    if (!ok || !context.mounted) return;
                                    await _run(
                                      context,
                                      () => ref
                                          .read(creditCardRepositoryProvider)
                                          .voidPayment(profileId, p.id),
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
