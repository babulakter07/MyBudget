import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../domain/loan_calculator.dart';

/// 1150 -> "11.5", 1000 -> "10", 125 -> "1.25".
String formatRateBp(int bp) {
  final s = (bp / 100).toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

String loanStatusLabel(AppLocalizations l, LoanStatus s) => switch (s) {
  LoanStatus.active => l.loansStatusActive,
  LoanStatus.overdue => l.loansStatusOverdue,
  LoanStatus.closed => l.loansStatusClosed,
};

String installmentStatusLabel(AppLocalizations l, InstallmentStatus s) =>
    switch (s) {
      InstallmentStatus.paid => l.loansInstPaid,
      InstallmentStatus.partial => l.loansInstPartial,
      InstallmentStatus.due => l.loansInstDue,
      InstallmentStatus.overdue => l.loansInstOverdue,
    };

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip({super.key, required this.status});
  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      LoanStatus.active => scheme.primary,
      LoanStatus.overdue => AppColors.expense,
      LoanStatus.closed => scheme.outline,
    };
    return _Chip(label: loanStatusLabel(context.l10n, status), color: color);
  }
}

/// Status chip that tells an early-settled or adjusted loan apart from a loan
/// that was simply paid off.
class LoanPositionChip extends StatelessWidget {
  const LoanPositionChip({super.key, required this.position});
  final LoanPosition position;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (position.isEarlyClosed) {
      return _Chip(
        label: l.loansClosedEarly,
        color: Theme.of(context).colorScheme.outline,
      );
    }
    if (position.isAdjusted) {
      return _Chip(
        label: l.loansAdjusted,
        color: Theme.of(context).colorScheme.tertiary,
      );
    }
    return LoanStatusChip(status: position.status);
  }
}

class InstallmentStatusChip extends StatelessWidget {
  const InstallmentStatusChip({super.key, required this.status});
  final InstallmentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      InstallmentStatus.paid => AppColors.income,
      InstallmentStatus.partial => Colors.orange.shade800,
      InstallmentStatus.due => scheme.primary,
      InstallmentStatus.overdue => AppColors.expense,
    };
    return _Chip(
      label: installmentStatusLabel(context.l10n, status),
      color: color,
    );
  }
}

/// Date picker field used by the loan sheets.
class LoanDateTile extends StatelessWidget {
  const LoanDateTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.calendar_today),
    onTap: onTap,
  );
}
