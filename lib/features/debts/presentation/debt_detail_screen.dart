import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../l10n/l10n.dart';
import '../domain/debt.dart';
import '../providers/debt_providers.dart';
import 'debt_form_sheet.dart';
import 'debt_widgets.dart';
import 'payment_sheet.dart';

/// Route: /debts/:id
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});
  final int debtId;

  void _snack(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _shareText(AppLocalizations l, Debt d) {
    final person = d.personName;
    final outstanding = formatMinor(d.outstandingMinor);
    final principal = formatMinor(d.principalMinor);
    final date = d.dueDate;
    if (d.isLent) {
      return date == null
          ? l.debtsReminderLent(person, outstanding, principal)
          : l.debtsReminderLentDue(person, outstanding, principal, date);
    }
    return date == null
        ? l.debtsReminderBorrowed(person, outstanding, principal)
        : l.debtsReminderBorrowedDue(person, outstanding, principal, date);
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on AppException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debtProvider(debtId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.l10n.debtsTitle)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.debtsTitle)),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(debtProvider(debtId)),
        ),
      ),
      data: (debt) {
        if (debt == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.debtsTitle)),
            body: EmptyState(message: context.l10n.debtsNotFound),
          );
        }
        return _build(context, ref, debt);
      },
    );
  }

  Widget _build(BuildContext context, WidgetRef ref, Debt debt) {
    final theme = Theme.of(context);
    final payments = ref.watch(debtPaymentsProvider(debtId));
    final profileId = ref.read(activeProfileIdProvider);
    final canPay = debt.isActive && debt.outstandingMinor > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(debt.personName),
        actions: [
          if (debt.outstandingMinor > 0)
            IconButton(
              tooltip: context.l10n.debtsShareReminder,
              icon: const Icon(Icons.share),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: _shareText(context.l10n, debt)),
              ),
            ),
          IconButton(
            tooltip: context.l10n.commonEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDebtForm(context, existing: debt),
          ),
          IconButton(
            tooltip: debt.isActive
                ? context.l10n.commonArchive
                : context.l10n.debtsUnarchive,
            icon: Icon(
              debt.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            onPressed: profileId == null
                ? null
                : () => _run(
                    context,
                    () => ref
                        .read(debtRepositoryProvider)
                        .setArchived(profileId, debt.id, debt.isActive),
                  ),
          ),
        ],
      ),
      floatingActionButton: canPay
          ? FloatingActionButton.extended(
              onPressed: () => showPaymentSheet(context, debt),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.debtsAddPayment),
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
                Row(
                  children: [
                    Text(
                      debt.isLent
                          ? context.l10n.debtsLent
                          : context.l10n.debtsBorrowed,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    DebtStatusChip(status: debt.status),
                    if (!debt.isActive) ...[
                      const SizedBox(width: 8),
                      Text(context.l10n.debtsArchived),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _row(
                  context.l10n.debtsPrincipal,
                  formatMinor(debt.principalMinor),
                  theme,
                ),
                _row(
                  context.l10n.debtsPaid,
                  formatMinor(debt.paidMinor),
                  theme,
                ),
                _row(
                  context.l10n.debtsOutstanding,
                  formatMinor(debt.outstandingMinor),
                  theme,
                  bold: true,
                ),
                _row(context.l10n.debtsStartDate, debt.startDate, theme),
                _row(context.l10n.debtsDueDate, debt.dueDate ?? '-', theme),
                if (debt.note != null)
                  _row(context.l10n.debtsNote, debt.note!, theme),
                if (canPay) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: context.l10n.debtsMarkSettled,
                        message: context.l10n.debtsSettleMessage(
                          formatMinor(debt.outstandingMinor),
                        ),
                        confirmLabel: context.l10n.debtsSettle,
                        cancelLabel: context.l10n.commonCancel,
                      );
                      if (!ok || profileId == null || !context.mounted) return;
                      await _run(
                        context,
                        () => ref
                            .read(debtRepositoryProvider)
                            .settle(
                              profileId: profileId,
                              debtId: debt.id,
                              paymentDate: _settleDate(debt),
                            ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(context.l10n.debtsMarkSettled),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              context.l10n.debtsPayments,
              style: theme.textTheme.titleMedium,
            ),
          ),
          payments.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorState(error: e),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(context.l10n.debtsNoPayments)),
                );
              }
              return Column(
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
                          if (p.isDeleted) context.l10n.debtsVoided,
                        ].join('  •  '),
                      ),
                      trailing: p.isDeleted
                          ? null
                          : IconButton(
                              tooltip: context.l10n.debtsVoidPayment,
                              icon: const Icon(Icons.undo),
                              onPressed: profileId == null
                                  ? null
                                  : () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: context.l10n.debtsVoidPayment,
                                        message: context.l10n.debtsVoidMessage(
                                          formatMinor(p.amountMinor),
                                        ),
                                        confirmLabel: context.l10n.debtsVoid,
                                        cancelLabel: context.l10n.commonCancel,
                                      );
                                      if (!ok || !context.mounted) return;
                                      await _run(
                                        context,
                                        () => ref
                                            .read(debtRepositoryProvider)
                                            .voidPayment(profileId, p.id),
                                      );
                                    },
                            ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _settleDate(Debt d) {
    final today = dateKey(DateTime.now());
    return today.compareTo(d.startDate) < 0 ? d.startDate : today;
  }

  Widget _row(
    String label,
    String value,
    ThemeData theme, {
    bool bold = false,
  }) {
    final style = bold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Flexible(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
