import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/amount_calculator.dart';

/// Shows the calculator keypad as a bottom sheet. Returns the evaluated
/// amount in minor units, or null when dismissed.
Future<int?> showAmountKeypad(BuildContext context, {String initial = ''}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AmountKeypad(initial: initial),
  );
}

class AmountKeypad extends StatefulWidget {
  const AmountKeypad({super.key, this.initial = ''});
  final String initial;

  @override
  State<AmountKeypad> createState() => _AmountKeypadState();
}

class _AmountKeypadState extends State<AmountKeypad> {
  late String _expr = widget.initial.replaceAll(',', '');
  String? _error;

  void _press(String k) => setState(() {
    _error = null;
    _expr += k;
  });

  void _back() => setState(() {
    _error = null;
    if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
  });

  int? _eval() {
    try {
      return AmountCalculator.evaluateToMinor(_expr);
    } on AppException catch (e) {
      setState(() => _error = e.message);
      return null;
    }
  }

  void _equals() {
    final m = _eval();
    if (m != null) {
      setState(() => _expr = formatMinor(m, symbol: '').replaceAll(',', ''));
    }
  }

  void _done() {
    final m = _eval();
    if (m == null) return;
    if (m <= 0) {
      setState(() => _error = context.l10n.transactionsKeypadAmountPositive);
      return;
    }
    Navigator.of(context).pop(m);
  }

  Widget _key(String label, VoidCallback onTap, {String? id, bool op = false}) {
    final child = Text(label, style: const TextStyle(fontSize: 20));
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: op
            ? FilledButton.tonal(
                key: ValueKey('key-${id ?? label}'),
                onPressed: onTap,
                child: child,
              )
            : OutlinedButton(
                key: ValueKey('key-${id ?? label}'),
                onPressed: onTap,
                child: child,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const ValueKey('keypad-display'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              alignment: Alignment.centerRight,
              child: Text(
                _expr.isEmpty ? '0' : _expr,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                key: const ValueKey('keypad-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            Row(
              children: [
                _key('7', () => _press('7')),
                _key('8', () => _press('8')),
                _key('9', () => _press('9')),
                _key('÷', () => _press('÷'), op: true),
              ],
            ),
            Row(
              children: [
                _key('4', () => _press('4')),
                _key('5', () => _press('5')),
                _key('6', () => _press('6')),
                _key('×', () => _press('×'), op: true),
              ],
            ),
            Row(
              children: [
                _key('1', () => _press('1')),
                _key('2', () => _press('2')),
                _key('3', () => _press('3')),
                _key('−', () => _press('−'), id: 'minus', op: true),
              ],
            ),
            Row(
              children: [
                _key('.', () => _press('.')),
                _key('0', () => _press('0')),
                _key('⌫', _back, id: 'back'),
                _key('+', () => _press('+'), op: true),
              ],
            ),
            Row(
              children: [
                _key('=', _equals, id: 'equals', op: true),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilledButton(
                      key: const ValueKey('keypad-done'),
                      onPressed: _done,
                      child: Text(context.l10n.transactionsKeypadUseAmount),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
