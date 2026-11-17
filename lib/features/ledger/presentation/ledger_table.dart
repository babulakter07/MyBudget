import 'package:material_ui/material_ui.dart';

class LedgerColumn {
  const LedgerColumn(this.label, this.width, {this.numeric = false});
  final String label;
  final double width;
  final bool numeric;
}

/// Horizontally scrollable table with a sticky header and footer and a
/// vertically scrolling body.
class LedgerTable extends StatelessWidget {
  const LedgerTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    required this.footer,
    this.onRowTap,
  });

  final List<LedgerColumn> columns;
  final int rowCount;

  /// Cells for the row at index (same length as [columns]).
  final List<Widget> Function(BuildContext context, int index) rowBuilder;
  final List<Widget> footer;
  final void Function(int index)? onRowTap;

  double get _width => columns.fold(0, (s, c) => s + c.width);

  Widget _cell(LedgerColumn c, Widget child) => SizedBox(
    width: c.width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Align(
        alignment: c.numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = _width < constraints.maxWidth ? constraints.maxWidth : _width;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            height: constraints.maxHeight,
            child: Column(
              children: [
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      for (final c in columns)
                        _cell(c, Text(c.label, style: headerStyle)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: rowCount,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final cells = rowBuilder(context, i);
                      final row = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var k = 0; k < columns.length; k++)
                            _cell(columns[k], cells[k]),
                        ],
                      );
                      return onRowTap == null
                          ? row
                          : InkWell(onTap: () => onRowTap!(i), child: row);
                    },
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      for (var k = 0; k < columns.length; k++)
                        _cell(columns[k], footer[k]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
