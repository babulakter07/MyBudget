import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/credit_card.dart';
import '../domain/credit_card_calculator.dart';
import '../providers/credit_card_providers.dart';
import 'credit_card_widgets.dart';

/// Add a bill ([existing] null) or edit one.
Future<void> showCreditCardBillSheet(
  BuildContext context, {
  required CreditCard card,
  CreditCardBill? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CreditCardBillSheet(card: card, existing: existing),
  );
}

class CreditCardBillSheet extends ConsumerStatefulWidget {
  const CreditCardBillSheet({super.key, required this.card, this.existing});
  final CreditCard card;
  final CreditCardBill? existing;

  @override
  ConsumerState<CreditCardBillSheet> createState() =>
      _CreditCardBillSheetState();
}

class _CreditCardBillSheetState extends ConsumerState<CreditCardBillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _month;
  late final TextEditingController _amount;
  late final TextEditingController _min;
  late final TextEditingController _note;
  late String _statement;
  late String _due;
  bool _minTouched = false;
  bool _datesTouched = false;
  String? _error;
  bool _saving = false;

  static final _monthRe = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _month = TextEditingController(
      text: e?.billMonth ?? monthKey(now.year, now.month),
    );
    _amount = TextEditingController(
      text: e == null ? '' : minorToInput(e.amountMinor),
    );
    _min = TextEditingController(
      text: e == null ? '' : minorToInput(e.minPaymentMinor),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _minTouched = e != null;
    _datesTouched = e != null;
    _statement = e?.statementDate ?? _defaultStatement();
    _due = e?.dueDate ?? dueDateFor(_statement, widget.card.dueDays);
  }

  @override
  void dispose() {
    _month.dispose();
    _amount.dispose();
    _min.dispose();
    _note.dispose();
    super.dispose();
  }

  String _defaultStatement() => _monthRe.hasMatch(_month.text.trim())
      ? statementDateFor(_month.text.trim(), widget.card.statementDay)
      : dateKey(DateTime.now());

  void _recompute() {
    setState(() {
      if (!_datesTouched && _monthRe.hasMatch(_month.text.trim())) {
        _statement = _defaultStatement();
        _due = dueDateFor(_statement, widget.card.dueDays);
      }
      final a = parseMajorToMinor(_amount.text);
      if (!_minTouched && a != null && a > 0) {
        _min.text = minorToInput(
          minimumPayment(
            billMinor: a,
            minPaymentBp: widget.card.minPaymentBp,
            floorMinor: widget.card.minPaymentFloorMinor,
          ),
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    final amount = parseMajorToMinor(_amount.text);
    final min = parseMajorToMinor(_min.text);
    if (profileId == null || amount == null || min == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(creditCardRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.createBill(
          profileId: profileId,
          cardId: widget.card.id,
          billMonth: _month.text.trim(),
          amountMinor: amount,
          statementDate: _statement,
          dueDate: _due,
          minPaymentMinor: min,
          note: _note.text,
        );
      } else {
        await repo.updateBill(
          profileId: profileId,
          billId: widget.existing!.id,
          amountMinor: amount,
          statementDate: _statement,
          dueDate: _due,
          minPaymentMinor: min,
          note: _note.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? l.creditCardsEditBill : l.creditCardsAddBill,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('bill-month'),
                controller: _month,
                enabled: !editing,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: l.creditCardsFieldMonth,
                  hintText: '2026-06',
                ),
                onChanged: (_) => _recompute(),
                validator: (v) => _monthRe.hasMatch((v ?? '').trim())
                    ? null
                    : l.creditCardsInvalidMonth,
              ),
              TextFormField(
                key: const ValueKey('bill-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.creditCardsFieldBillAmount,
                  helperText: l.creditCardsHelpBillAmount,
                  helperMaxLines: 3,
                  hintText: '0.00',
                ),
                onChanged: (_) => _recompute(),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return l.creditCardsInvalidNumber;
                  if (m <= 0) return l.creditCardsAmountPositive;
                  return null;
                },
              ),
              CardDateTile(
                label: l.creditCardsFieldStatementDate,
                value: _statement,
                onTap: () async {
                  final d = await pickCardDate(context, _statement);
                  if (d != null) {
                    setState(() {
                      _statement = d;
                      _datesTouched = true;
                    });
                  }
                },
              ),
              CardDateTile(
                label: l.creditCardsFieldDueDate,
                value: _due,
                onTap: () async {
                  final d = await pickCardDate(
                    context,
                    _due,
                    first: _statement,
                  );
                  if (d != null) {
                    setState(() {
                      _due = d;
                      _datesTouched = true;
                    });
                  }
                },
              ),
              TextFormField(
                key: const ValueKey('bill-min'),
                controller: _min,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.creditCardsFieldMinDue,
                  helperText: l.creditCardsHelpMinDue,
                  helperMaxLines: 3,
                ),
                onChanged: (_) => _minTouched = true,
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return l.creditCardsInvalidNumber;
                  final a = parseMajorToMinor(_amount.text);
                  if (a != null && m > a) {
                    return l.creditCardsMaxAmount(formatMinor(a));
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.creditCardsFieldNote),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('bill-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(l.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
