import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

/// Pops a dialog to choose a month (and year). Returns a DateTime on day 1,
/// or null when dismissed. With [yearOnly] only the year is chosen (month = 1).
Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  required DateTime initial,
  bool yearOnly = false,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthYearDialog(initial: initial, yearOnly: yearOnly),
  );
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initial, required this.yearOnly});
  final DateTime initial;
  final bool yearOnly;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: context.l10n.ledgerPreviousYear,
            icon: const Icon(Icons.chevron_left),
            onPressed: _year > 1971 ? () => setState(() => _year--) : null,
          ),
          Text('$_year'),
          IconButton(
            tooltip: context.l10n.ledgerNextYear,
            icon: const Icon(Icons.chevron_right),
            onPressed: _year < 9998 ? () => setState(() => _year++) : null,
          ),
        ],
      ),
      content: widget.yearOnly
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  ChoiceChip(
                    label: Text(DateFormat.MMM().format(DateTime(2000, m))),
                    selected:
                        _year == widget.initial.year &&
                        m == widget.initial.month,
                    onSelected: (_) =>
                        Navigator.of(context).pop(DateTime(_year, m)),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        if (widget.yearOnly)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(DateTime(_year)),
            child: Text(context.l10n.ledgerSelect),
          ),
      ],
    );
  }
}

/// 'MMM yyyy' label for a month.
String monthLabel(DateTime m) => DateFormat('MMM yyyy').format(m);
