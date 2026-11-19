import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../l10n/l10n.dart';
import '../domain/credit_card.dart';
import '../domain/credit_card_calculator.dart';

/// Minor units as an editable decimal string ("1500.50"), integer maths only.
String minorToInput(int minor) => '${minor ~/ 100}.${two(minor % 100)}';

Color billStatusColor(BuildContext context, BillStatus s) {
  final scheme = Theme.of(context).colorScheme;
  return switch (s) {
    BillStatus.paid => AppColors.income,
    BillStatus.overdue => AppColors.expense,
    BillStatus.minPaid => scheme.tertiary,
    BillStatus.partial => scheme.primary,
    BillStatus.unpaid => scheme.outline,
  };
}

class BillStatusChip extends StatelessWidget {
  const BillStatusChip({super.key, required this.status});
  final BillStatus status;

  @override
  Widget build(BuildContext context) {
    final color = billStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        billStatusLabel(context.l10n, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Credit utilisation bar; turns red above 80 %.
class UtilisationBar extends StatelessWidget {
  const UtilisationBar({super.key, required this.bp});
  final int bp;

  @override
  Widget build(BuildContext context) {
    final value = (bp / 10000).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        color: bp > 8000 ? AppColors.expense : null,
      ),
    );
  }
}

/// Tappable date field used by the credit card sheets.
class CardDateTile extends StatelessWidget {
  const CardDateTile({
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

Future<String?> pickCardDate(
  BuildContext context,
  String current, {
  String? first,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: isValidDateKey(current)
        ? parseDateKey(current)
        : DateTime.now(),
    firstDate: first != null && isValidDateKey(first)
        ? parseDateKey(first)
        : DateTime(2000),
    lastDate: DateTime(2100),
  );
  return picked == null ? null : dateKey(picked);
}

/// Label on the left, value on the right.
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        (bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
            ?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Percent formatter for UI text, e.g. 1250 -> "12.5%".
String pct(int bp) => formatBp(bp);
