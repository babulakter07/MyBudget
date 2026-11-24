import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/fixed_deposit.dart';
import '../domain/fixed_deposit_calculator.dart';
import '../providers/fixed_deposit_providers.dart';
import 'fd_close_sheet.dart';
import 'fd_form_sheet.dart';
import 'fd_labels.dart';

/// Route: /fd/:id
class FdDetailScreen extends ConsumerStatefulWidget {
  const FdDetailScreen({super.key, required this.depositId});
  final int depositId;

  @override
  ConsumerState<FdDetailScreen> createState() => _FdDetailScreenState();
}

class _FdDetailScreenState extends ConsumerState<FdDetailScreen> {
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(fixedDepositProvider(widget.depositId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.fixedDepositsTitle)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l.fixedDepositsTitle)),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(fixedDepositProvider(widget.depositId)),
        ),
      ),
      data: (pos) {
        if (pos == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.fixedDepositsTitle)),
            body: EmptyState(message: l.fixedDepositsNotFound),
          );
        }
        return _build(context, pos);
      },
    );
  }

  Widget _build(BuildContext context, FixedDepositPosition pos) {
    final l = context.l10n;
    final deposit = pos.deposit;
    final profileId = ref.read(activeProfileIdProvider);
    final canClose = deposit.isActive && pos.current.isActive;
    final matured = pos.status == FdStatus.matured;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${fdSchemeLabel(l, deposit.schemeType)} • ${deposit.bankName}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const HelpButton(topicId: 'fixed_deposits'),
          IconButton(
            tooltip: l.fixedDepositsEditDetails,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showFdForm(
              context,
              mode: FdFormMode.editDetails,
              existing: pos,
            ),
          ),
          IconButton(
            tooltip: deposit.isActive ? l.commonArchive : l.commonRestore,
            icon: Icon(
              deposit.isActive
                  ? Icons.archive_outlined
                  : Icons.unarchive_outlined,
            ),
            onPressed: profileId == null
                ? null
                : () => _run(
                    () => ref
                        .read(fixedDepositRepositoryProvider)
                        .setArchived(
                          profileId: profileId,
                          depositId: deposit.id,
                          archived: deposit.isActive,
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: canClose && matured
          ? FloatingActionButton.extended(
              key: const ValueKey('fab-reissue'),
              onPressed: () => showFdCloseSheet(context, pos, reissue: true),
              icon: const Icon(Icons.autorenew),
              label: Text(l.fixedDepositsReissue),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _overview(context, pos),
          if (canClose) _actions(context, pos, matured),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l.fixedDepositsHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final t in pos.terms.reversed) _termCard(context, t),
        ],
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    FixedDepositPosition pos,
    bool matured,
  ) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!matured)
            OutlinedButton.icon(
              key: const ValueKey('btn-reissue'),
              onPressed: () => showFdCloseSheet(context, pos, reissue: true),
              icon: const Icon(Icons.autorenew),
              label: Text(l.fixedDepositsReissue),
            ),
          FilledButton.icon(
            key: const ValueKey('btn-encash'),
            onPressed: () => showFdCloseSheet(context, pos, reissue: false),
            icon: const Icon(Icons.payments_outlined),
            label: Text(l.fixedDepositsEncash),
          ),
          OutlinedButton.icon(
            key: const ValueKey('btn-edit-instrument'),
            onPressed: () => showFdForm(
              context,
              mode: FdFormMode.editInstrument,
              existing: pos,
            ),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(l.fixedDepositsEditInstrument),
          ),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context, FixedDepositPosition pos) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final d = pos.deposit;
    final t = pos.current;
    final due = fdDueText(l, pos);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FdStatusChip(status: pos.status),
              if (t.isReissue && t.isActive) ...[
                const SizedBox(width: 8),
                FdChip(
                  label: l.fixedDepositsBadgeReissued,
                  color: theme.colorScheme.tertiary,
                ),
              ],
              if (!d.isActive) ...[
                const SizedBox(width: 8),
                Text(l.fixedDepositsArchived),
              ],
            ],
          ),
          if (pos.status == FdStatus.matured) ...[
            const SizedBox(height: 8),
            Card(
              color: AppColors.income.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.fixedDepositsMaturedBanner),
              ),
            ),
          ],
          if (pos.status == FdStatus.closed) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.fixedDepositsClosedBanner),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FdRow(
            l.fixedDepositsPrincipal,
            formatMinor(t.principalMinor),
            bold: true,
          ),
          if (due != null)
            FdRow(l.fixedDepositsMaturityDate, '${pos.maturityDate}  •  $due'),
          if (due == null) FdRow(l.fixedDepositsMaturityDate, pos.maturityDate),
          FdRow(l.fixedDepositsInstrumentNumber, t.instrumentNumber),
          FdRow(l.fixedDepositsIssueDate, t.startDate),
          FdRow(
            l.fixedDepositsTenureDays,
            l.fixedDepositsTenureValue(
              t.tenureDays,
              fdMonthsText(t.tenureDays),
            ),
          ),
          FdRow(
            l.fixedDepositsInterestRate,
            l.fixedDepositsRatePerYear(fdRateText(t.rateBp)),
          ),
          if (t.isActive) ...[
            FdRow(
              l.fixedDepositsExpectedInterest,
              formatMinor(pos.expectedInterestMinor),
              color: AppColors.income,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l.fixedDepositsExpectedNote,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (d.beneficiaryName != null)
            FdRow(l.fixedDepositsBeneficiary, d.beneficiaryName!),
          if (d.note != null) FdRow(l.fixedDepositsNote, d.note!),
        ],
      ),
    );
  }

  Widget _termCard(BuildContext context, FixedDepositTerm t) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final maturity = FixedDepositCalculator.maturityDate(
      t.startDate,
      t.tenureDays,
    );
    return Card(
      key: ValueKey('term-${t.termNo}'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.fixedDepositsInstrumentNo(t.termNo)}  •  ${t.instrumentNumber}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                FdChip(
                  label: fdOutcomeLabel(l, t.outcome),
                  color: switch (t.outcome) {
                    fdOutcomeActive => theme.colorScheme.primary,
                    fdOutcomeReissued => theme.colorScheme.tertiary,
                    _ => theme.colorScheme.outline,
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${t.startDate} → $maturity',
              style: theme.textTheme.bodySmall,
            ),
            if (t.isReissue)
              Text(
                l.fixedDepositsReissuedFrom(t.termNo - 1),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            FdRow(l.fixedDepositsPrincipal, formatMinor(t.principalMinor)),
            FdRow(
              l.fixedDepositsInterestRate,
              l.fixedDepositsRatePerYear(fdRateText(t.rateBp)),
            ),
            FdRow(
              l.fixedDepositsTenureDays,
              l.fixedDepositsTenureValue(
                t.tenureDays,
                fdMonthsText(t.tenureDays),
              ),
            ),
            if (!t.isActive) ...[
              const Divider(height: 16),
              Text(
                l.fixedDepositsClosedOn(t.settledDate ?? ''),
                style: theme.textTheme.bodySmall,
              ),
              FdRow(
                l.fixedDepositsClosingInterest,
                formatMinor(t.interestMinor ?? 0),
              ),
              FdRow(l.fixedDepositsClosingTax, formatMinor(t.taxMinor ?? 0)),
              FdRow(
                l.fixedDepositsClosingCharge,
                formatMinor(t.bankChargeMinor ?? 0),
              ),
              FdRow(
                l.fixedDepositsNetReceived,
                formatMinor(t.netReceivedMinor ?? 0),
                bold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
