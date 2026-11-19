import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../help/presentation/help_button.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';
import '../providers/loan_providers.dart';
import 'loan_form_sheet.dart';
import 'loan_payment_sheet.dart';
import 'loan_widgets.dart';

/// Route: /loans/:id
class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final int loanId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  bool _showSchedule = true;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(loanProvider(widget.loanId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.loansTitle)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l.loansTitle)),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(loanProvider(widget.loanId)),
        ),
      ),
      data: (pos) {
        if (pos == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.loansTitle)),
            body: EmptyState(message: l.loansNotFound),
          );
        }
        return _build(context, pos);
      },
    );
  }

  Widget _build(BuildContext context, LoanPosition pos) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final loan = pos.loan;
    final profileId = ref.read(activeProfileIdProvider);
    final canPay = loan.isActive && pos.remainingMinor > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(loan.lenderName),
        actions: [
          const HelpButton(topicId: 'loans'),
          IconButton(
            tooltip: l.commonEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showLoanForm(context, existing: pos),
          ),
          IconButton(
            tooltip: loan.isActive ? l.commonArchive : l.loansUnarchive,
            icon: Icon(
              loan.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            onPressed: profileId == null
                ? null
                : () => _run(
                    () => ref
                        .read(loanRepositoryProvider)
                        .setArchived(profileId, loan.id, loan.isActive),
                  ),
          ),
        ],
      ),
      floatingActionButton: canPay
          ? FloatingActionButton.extended(
              onPressed: () => showLoanPaymentSheet(context, pos),
              icon: const Icon(Icons.add),
              label: Text(l.loansRecordPayment),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _overview(context, pos),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l.loansSchedule)),
                ButtonSegment(value: false, label: Text(l.loansPayments)),
              ],
              selected: {_showSchedule},
              onSelectionChanged: (s) =>
                  setState(() => _showSchedule = s.first),
            ),
          ),
          if (_showSchedule)
            ..._scheduleRows(context, pos)
          else
            _payments(context, profileId),
          const SizedBox(height: 4),
          if (!_showSchedule && pos.overdueCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.loansOverdueSummary(
                  pos.overdueCount,
                  formatMinor(pos.overdueMinor),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context, LoanPosition pos) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final loan = pos.loan;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loanTypeLabel(l, loan.loanType),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              LoanStatusChip(status: pos.status),
              if (!loan.isActive) ...[
                const SizedBox(width: 8),
                Text(l.loansArchived),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _row(
            l.loansPaidSoFar,
            formatMinor(pos.paidMinor),
            theme,
            color: AppColors.income,
          ),
          _row(
            l.loansRemaining,
            formatMinor(pos.remainingMinor),
            theme,
            bold: true,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pos.progress),
          const SizedBox(height: 2),
          Text(
            l.loansProgressPercent((pos.progress * 100).floor()),
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 24),
          _row(l.loansPrincipal, formatMinor(loan.principalMinor), theme),
          _row(
            l.loansInterestRate,
            l.loansRatePerYear(formatRateBp(loan.interestRateBp)),
            theme,
          ),
          _row(
            l.loansInterestMethod,
            loanMethodLabel(l, loan.interestMethod),
            theme,
          ),
          _row(
            l.loansTenure,
            l.loansTenureValue(
              loan.tenureCount,
              loanFrequencyLabel(l, loan.frequency),
            ),
            theme,
          ),
          _row(
            l.loansInstallment,
            loanPerPeriod(
              l,
              loan.frequency,
              formatMinor(loan.installmentMinor),
            ),
            theme,
          ),
          _row(
            l.loansTotalInterest,
            formatMinor(pos.totalInterestMinor),
            theme,
          ),
          _row(l.loansTotalPayable, formatMinor(pos.totalPayableMinor), theme),
          if (loan.processingFeeMinor > 0) ...[
            _row(
              l.loansProcessingFee,
              formatMinor(loan.processingFeeMinor),
              theme,
            ),
            _row(l.loansTotalCost, formatMinor(pos.totalCostMinor), theme),
          ],
          _row(l.loansStartDate, loan.startDate, theme),
          _row(l.loansFirstDueDate, loan.firstDueDate, theme),
          if (loan.referenceNo != null)
            _row(l.loansReferenceNo, loan.referenceNo!, theme),
          if (loan.note != null) _row(l.loansNote, loan.note!, theme),
        ],
      ),
    );
  }

  List<Widget> _scheduleRows(BuildContext context, LoanPosition pos) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return [
      for (final i in pos.schedule)
        ListTile(
          key: ValueKey('installment-${i.no}'),
          title: Row(
            children: [
              Expanded(
                child: Text('${l.loansInstallmentNo(i.no)}  •  ${i.dueDate}'),
              ),
              InstallmentStatusChip(status: i.status),
            ],
          ),
          subtitle: Text(
            [
              formatMinor(i.installmentMinor),
              '${l.loansPrincipalPart} ${formatMinor(i.principalMinor)}',
              '${l.loansInterestPart} ${formatMinor(i.interestMinor)}',
              if (i.status == InstallmentStatus.partial ||
                  (i.status == InstallmentStatus.overdue && i.paidMinor > 0))
                l.loansPaidOfAmount(
                  formatMinor(i.paidMinor),
                  formatMinor(i.installmentMinor),
                ),
              if (i.paidDate != null) l.loansPaidOn(i.paidDate!),
              l.loansBalanceAfter(formatMinor(i.balanceAfterMinor)),
            ].join('  •  '),
            style: theme.textTheme.bodySmall,
          ),
          trailing:
              (!pos.isClosed && pos.loan.isActive && identical(i, pos.nextDue))
              ? TextButton(
                  key: ValueKey('mark-paid-${i.no}'),
                  onPressed: () =>
                      showLoanPaymentSheet(context, pos, installment: i),
                  child: Text(l.loansMarkPaid),
                )
              : null,
        ),
    ];
  }

  Widget _payments(BuildContext context, int? profileId) {
    final l = context.l10n;
    final payments = ref.watch(loanPaymentsProvider(widget.loanId));
    return payments.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
      error: (e, _) => ErrorState(error: e),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(l.loansNoPayments)),
          );
        }
        return Column(
          children: [
            for (final p in list)
              ListTile(
                title: Text(
                  formatMinor(p.amountMinor),
                  style: p.isDeleted
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: Text(
                  [
                    p.paymentDate,
                    if (p.note != null) p.note!,
                    if (p.isDeleted) l.loansVoided,
                  ].join('  •  '),
                ),
                trailing: p.isDeleted
                    ? null
                    : IconButton(
                        tooltip: l.loansVoidPayment,
                        icon: const Icon(Icons.undo),
                        onPressed: profileId == null
                            ? null
                            : () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: l.loansVoidPayment,
                                  message: l.loansVoidMessage(
                                    formatMinor(p.amountMinor),
                                  ),
                                  confirmLabel: l.loansVoid,
                                  cancelLabel: l.commonCancel,
                                );
                                if (!ok || !mounted) return;
                                await _run(
                                  () => ref
                                      .read(loanRepositoryProvider)
                                      .voidPayment(profileId, p.id),
                                );
                              },
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _row(
    String label,
    String value,
    ThemeData theme, {
    bool bold = false,
    Color? color,
  }) {
    final style =
        (bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
            ?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
