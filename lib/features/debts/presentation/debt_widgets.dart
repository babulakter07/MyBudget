import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../domain/debt.dart';

class DebtStatusChip extends StatelessWidget {
  const DebtStatusChip({super.key, required this.status});
  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      DebtStatus.open => scheme.primary,
      DebtStatus.overdue => AppColors.expense,
      DebtStatus.settled => scheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        debtStatusLabel(context.l10n, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Date picker field used by the debt sheets.
class DebtDateTile extends StatelessWidget {
  const DebtDateTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value ?? context.l10n.debtsNotSet),
    trailing: value != null && onClear != null
        ? IconButton(
            tooltip: context.l10n.debtsClearField(label),
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          )
        : const Icon(Icons.calendar_today),
    onTap: onTap,
  );
}
