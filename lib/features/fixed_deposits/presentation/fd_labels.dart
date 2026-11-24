import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/fixed_deposit.dart';
import '../domain/fixed_deposit_calculator.dart';

/// Canonical scheme codes stored in the database (chips write these; the
/// labels shown are localized).
const fdSchemeFdr = 'FDR';
const fdSchemeDps = 'DPS';
const fdSchemeSanchaypatra = 'Sanchaypatra';

/// Localized label for a stored scheme type; free text is shown as typed.
String fdSchemeLabel(AppLocalizations l, String type) =>
    switch (type.toLowerCase()) {
      'fdr' => l.fixedDepositsSchemeFdr,
      'dps' => l.fixedDepositsSchemeDps,
      'sanchaypatra' => l.fixedDepositsSchemeSanchaypatra,
      _ => type,
    };

/// 1150 -> "11.5", 1000 -> "10", 125 -> "1.25".
String fdRateText(int bp) {
  final s = (bp / 100).toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Minor units as editable major text ("1000.00").
String fdMajorText(int minor) => (minor / 100).toStringAsFixed(2);

/// "12.2" / "6" (30 days = 1 month).
String fdMonthsText(int days) {
  final s = FixedDepositCalculator.tenureMonths(days).toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String fdStatusLabel(AppLocalizations l, FdStatus s) => switch (s) {
  FdStatus.active => l.fixedDepositsStatusActive,
  FdStatus.matured => l.fixedDepositsStatusMatured,
  FdStatus.closed => l.fixedDepositsStatusClosed,
};

String fdOutcomeLabel(AppLocalizations l, String outcome) => switch (outcome) {
  fdOutcomeEncashed => l.fixedDepositsOutcomeEncashed,
  fdOutcomeReissued => l.fixedDepositsOutcomeReissued,
  _ => l.fixedDepositsOutcomeRunning,
};

/// "12 days left" / "Matures today" / "Matured 3 days ago"; null when closed.
String? fdDueText(AppLocalizations l, FixedDepositPosition p) {
  final d = p.daysToMaturity;
  if (d == null) return null;
  if (d == 0) return l.fixedDepositsMaturesToday;
  return d > 0 ? l.fixedDepositsDaysLeft(d) : l.fixedDepositsMaturedAgo(-d);
}

/// Days from the issue date to [closing], clamped to the tenure (interest is
/// suggested for the days actually run, never for more than the tenure).
int fdInterestDays(FixedDepositTerm t, String closing) {
  final d = FixedDepositCalculator.daysBetween(t.startDate, closing);
  if (d < 0) return 0;
  return d > t.tenureDays ? t.tenureDays : d;
}

class FdChip extends StatelessWidget {
  const FdChip({super.key, required this.label, required this.color});
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

class FdStatusChip extends StatelessWidget {
  const FdStatusChip({super.key, required this.status});
  final FdStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      FdStatus.active => scheme.primary,
      FdStatus.matured => AppColors.income,
      FdStatus.closed => scheme.outline,
    };
    return FdChip(label: fdStatusLabel(context.l10n, status), color: color);
  }
}

/// Date picker row used by the deposit sheets.
class FdDateTile extends StatelessWidget {
  const FdDateTile({
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

Future<String?> pickFdDate(BuildContext context, String current) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: isValidDateKey(current)
        ? parseDateKey(current)
        : DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  return picked == null ? null : dateKey(picked);
}

/// Percent text -> basis points (11.5 -> 1150); null when invalid or > 100 %.
int? parseRateBp(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final v = parseMajorToMinor(t);
  if (v == null || v < 0 || v > 10000) return null;
  return v;
}

/// Label/value row used on the detail screen.
class FdRow extends StatelessWidget {
  const FdRow(
    this.label,
    this.value, {
    super.key,
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
