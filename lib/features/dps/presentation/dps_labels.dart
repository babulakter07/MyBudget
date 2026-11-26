import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../fixed_deposits/presentation/fd_labels.dart' show FdChip;
import '../domain/dps.dart';

String dpsStatusLabel(AppLocalizations l, DpsStatus s) => switch (s) {
  DpsStatus.active => l.dpsStatusActive,
  DpsStatus.overdue => l.dpsStatusOverdue,
  DpsStatus.atRisk => l.dpsStatusAtRisk,
  DpsStatus.matured => l.dpsStatusMatured,
  DpsStatus.closed => l.dpsStatusClosed,
};

String dpsClosingLabel(AppLocalizations l, DpsClosingType t) => switch (t) {
  DpsClosingType.matured => l.dpsCloseMatured,
  DpsClosingType.premature => l.dpsClosePremature,
  DpsClosingType.bankClosed => l.dpsCloseBank,
};

String dpsInstallmentLabel(AppLocalizations l, DpsInstallmentStatus s) =>
    switch (s) {
      DpsInstallmentStatus.paid => l.dpsInstallmentPaid,
      DpsInstallmentStatus.overdue => l.dpsStatusOverdue,
      DpsInstallmentStatus.due => l.dpsInstallmentDue,
      DpsInstallmentStatus.upcoming => l.dpsInstallmentUpcoming,
    };

class DpsStatusChip extends StatelessWidget {
  const DpsStatusChip({super.key, required this.status});
  final DpsStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      DpsStatus.active => scheme.primary,
      DpsStatus.overdue || DpsStatus.atRisk => AppColors.expense,
      DpsStatus.matured => AppColors.income,
      DpsStatus.closed => scheme.outline,
    };
    return FdChip(label: dpsStatusLabel(context.l10n, status), color: color);
  }
}
