import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../fixed_deposits/presentation/fd_labels.dart';
import '../../help/presentation/help_button.dart';
import '../domain/dps.dart';
import '../providers/dps_providers.dart';
import 'dps_action_sheets.dart';
import 'dps_form_sheet.dart';
import 'dps_labels.dart';

/// Route: /dps/:id
class DpsDetailScreen extends ConsumerWidget {
  const DpsDetailScreen({super.key, required this.dpsId});
  final int dpsId;

  Future<void> _run(BuildContext context, Future<void> Function() body) async {
    try {
      await body();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(dpsProvider(dpsId));
    final p = async.value;
    final profileId = ref.watch(activeProfileIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.terms.bankName ?? l.dpsTitle),
        actions: [
          const HelpButton(topicId: 'dps'),
          if (p != null && !p.isClosed)
            IconButton(
              tooltip: l.dpsEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showDpsForm(context, existing: p),
            ),
          if (p != null && profileId != null)
            IconButton(
              tooltip: p.account.isActive ? l.dpsArchive : l.dpsUnarchive,
              icon: Icon(
                p.account.isActive
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined,
              ),
              onPressed: () => _run(
                context,
                () => ref
                    .read(dpsRepositoryProvider)
                    .setArchived(profileId, dpsId, p.account.isActive),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(dpsProvider(dpsId)),
        ),
        data: (position) {
          if (position == null) {
            return EmptyState(
              icon: Icons.savings_outlined,
              message: l.dpsNotFound,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _Overview(position: position),
              if (!position.isClosed && position.account.isActive)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (position.remainingCount > 0)
                        FilledButton.icon(
                          onPressed: () =>
                              showDpsDepositSheet(context, position),
                          icon: const Icon(Icons.add),
                          label: Text(l.dpsRecordDeposit),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => showDpsCloseSheet(context, position),
                        icon: const Icon(Icons.task_alt),
                        label: Text(l.dpsCloseTitle),
                      ),
                    ],
                  ),
                ),
              _Deposits(position: position, onError: _run),
              _Schedule(position: position),
            ],
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.position});
  final DpsPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = position;
    final t = p.terms;
    final a = p.account;
    final next = p.nextDue;
    final warning = p.status == DpsStatus.atRisk
        ? l.dpsAtRiskWarning(p.overdueCount)
        : p.isOneMissFromLimit
        ? l.dpsOneMoreWarning(t.missedLimit)
        : p.overdueCount > 0
        ? l.dpsOverdueWarning(p.overdueCount, formatMinor(p.overdueMinor))
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.dpsPerMonth(formatMinor(t.installmentMinor)),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                DpsStatusChip(status: p.status),
              ],
            ),
            if (a.terms.accountNumber != null)
              Text(l.dpsAccountNumberValue(a.terms.accountNumber!)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: p.progress),
            const SizedBox(height: 4),
            Text(l.dpsPaidOf(p.paidCount, t.tenureMonths)),
            if (warning != null) ...[
              const SizedBox(height: 8),
              Text(
                warning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Divider(),
            FdRow(l.dpsSummaryDeposited, formatMinor(p.depositedMinor)),
            if (p.lateFeesPaidMinor > 0)
              FdRow(l.dpsLateFeesPaid, formatMinor(p.lateFeesPaidMinor)),
            FdRow(l.dpsRate, '${fdRateText(t.rateBp)}%'),
            if (p.isClosed) ...[
              FdRow(dpsClosingLabel(l, a.closingType!), a.closedDate ?? ''),
              FdRow(l.dpsProfit, formatMinor(a.profitMinor ?? 0)),
              FdRow(l.dpsTax, formatMinor(a.taxMinor ?? 0)),
              FdRow(l.dpsCharges, formatMinor(a.chargeMinor ?? 0)),
              FdRow(
                l.dpsNetReceived,
                formatMinor(a.netReceivedMinor ?? 0),
                bold: true,
              ),
            ] else ...[
              if (next != null)
                FdRow(
                  l.dpsNextInstallment,
                  '${next.dueDate} (${dpsInstallmentLabel(l, next.status)})',
                ),
              FdRow(l.dpsMaturityDate, p.maturityDate),
              FdRow(
                t.bankMaturityMinor == null
                    ? l.dpsMaturityEstimate
                    : l.dpsMaturityFromBank,
                formatMinor(p.maturityMinor),
              ),
              FdRow(
                l.dpsExpectedTax(fdRateText(t.taxRateBp)),
                formatMinor(p.expectedTaxMinor),
              ),
              FdRow(
                l.dpsExpectedNet,
                formatMinor(p.expectedNetMinor),
                bold: true,
              ),
              Text(l.dpsMaturityNote, style: theme.textTheme.bodySmall),
            ],
            if (t.note != null) ...[const SizedBox(height: 8), Text(t.note!)],
          ],
        ),
      ),
    );
  }
}

class _Deposits extends ConsumerWidget {
  const _Deposits({required this.position, required this.onError});
  final DpsPosition position;
  final Future<void> Function(BuildContext, Future<void> Function()) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final id = position.account.id;
    final payments = ref.watch(dpsPaymentsProvider(id)).value ?? const [];
    return Card(
      child: ExpansionTile(
        title: Text(l.dpsDeposits),
        initiallyExpanded: true,
        children: [
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.dpsNoDeposits),
            ),
          for (final x in payments)
            ListTile(
              dense: true,
              title: Text(
                formatMinor(x.installments * position.terms.installmentMinor),
                style: x.isDeleted
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              subtitle: Text(
                [
                  x.paymentDate,
                  l.dpsInstallmentsCount(x.installments),
                  if (x.lateFeeMinor > 0)
                    l.dpsLateFeeValue(formatMinor(x.lateFeeMinor)),
                  if (x.isDeleted) l.dpsVoided,
                  ?x.note,
                ].join('  •  '),
                style: theme.textTheme.bodySmall,
              ),
              trailing: x.isDeleted || position.isClosed
                  ? null
                  : IconButton(
                      tooltip: l.dpsVoid,
                      icon: const Icon(Icons.undo),
                      onPressed: () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: l.dpsVoidTitle,
                          message: l.dpsVoidMessage,
                          confirmLabel: l.dpsVoid,
                        );
                        final profileId = ref.read(activeProfileIdProvider);
                        if (!ok || profileId == null || !context.mounted) {
                          return;
                        }
                        await onError(
                          context,
                          () => ref
                              .read(dpsRepositoryProvider)
                              .voidPayment(profileId, x.id),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule({required this.position});
  final DpsPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: ExpansionTile(
        title: Text(l.dpsSchedule),
        children: [
          for (final i in position.schedule)
            ListTile(
              dense: true,
              leading: Text('${i.no}'),
              title: Text(i.dueDate),
              subtitle: i.paidDate == null
                  ? null
                  : Text(l.dpsPaidOn(i.paidDate!)),
              trailing: Text(
                dpsInstallmentLabel(l, i.status),
                style: i.status == DpsInstallmentStatus.overdue
                    ? const TextStyle(color: AppColors.expense)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
