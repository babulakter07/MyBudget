import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/credit_card.dart';
import '../domain/credit_card_calculator.dart';
import '../providers/credit_card_providers.dart';
import 'credit_card_widgets.dart';

Future<void> showCreditCardForm(BuildContext context, {CreditCard? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CreditCardFormSheet(existing: existing),
  );
}

class CreditCardFormSheet extends ConsumerStatefulWidget {
  const CreditCardFormSheet({super.key, this.existing});
  final CreditCard? existing;

  @override
  ConsumerState<CreditCardFormSheet> createState() =>
      _CreditCardFormSheetState();
}

class _CreditCardFormSheetState extends ConsumerState<CreditCardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bank;
  late final TextEditingController _last4;
  late final TextEditingController _limit;
  late final TextEditingController _stmtDay;
  late final TextEditingController _dueDays;
  late final TextEditingController _apr;
  late final TextEditingController _minPct;
  late final TextEditingController _minFloor;
  late final TextEditingController _feePct;
  late final TextEditingController _feeFloor;
  late bool _fromStatement;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _bank = TextEditingController(text: e?.bankName ?? '');
    _last4 = TextEditingController(text: e?.lastFour ?? '');
    _limit = TextEditingController(
      text: e == null ? '' : minorToInput(e.creditLimitMinor),
    );
    _stmtDay = TextEditingController(text: '${e?.statementDay ?? 1}');
    _dueDays = TextEditingController(text: '${e?.dueDays ?? 20}');
    _apr = TextEditingController(text: e == null ? '' : bpToInput(e.aprBp));
    _minPct = TextEditingController(
      text: e == null ? '5' : bpToInput(e.minPaymentBp),
    );
    _minFloor = TextEditingController(
      text: e == null || e.minPaymentFloorMinor == 0
          ? ''
          : minorToInput(e.minPaymentFloorMinor),
    );
    _feePct = TextEditingController(
      text: e == null || e.lateFeeBp == 0 ? '' : bpToInput(e.lateFeeBp),
    );
    _feeFloor = TextEditingController(
      text: e == null || e.lateFeeFloorMinor == 0
          ? ''
          : minorToInput(e.lateFeeFloorMinor),
    );
    _fromStatement = e?.interestFromStatement ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _bank,
      _last4,
      _limit,
      _stmtDay,
      _dueDays,
      _apr,
      _minPct,
      _minFloor,
      _feePct,
      _feeFloor,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _intIn(String? v, int min, int max) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < min || n > max) {
      return context.l10n.creditCardsRangeInt(min, max);
    }
    return null;
  }

  String? _pctIn(String? v, {bool optional = false}) {
    if (optional && (v == null || v.trim().isEmpty)) return null;
    final bp = parsePercentToBp(v ?? '');
    if (bp == null) return context.l10n.creditCardsInvalidNumber;
    if (bp > 10000) return context.l10n.creditCardsInvalidPercent;
    return null;
  }

  String? _moneyIn(String? v, {bool optional = false, bool positive = false}) {
    if (optional && (v == null || v.trim().isEmpty)) return null;
    final m = parseMajorToMinor(v ?? '');
    if (m == null) return context.l10n.creditCardsInvalidNumber;
    if (positive && m <= 0) return context.l10n.creditCardsAmountPositive;
    return null;
  }

  int _bp(TextEditingController c) => parsePercentToBp(c.text) ?? 0;
  int _money(TextEditingController c) => parseMajorToMinor(c.text) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(creditCardRepositoryProvider);
    try {
      final l4 = _last4.text.trim().isEmpty ? null : _last4.text.trim();
      if (widget.existing == null) {
        await repo.createCard(
          profileId: profileId,
          name: _name.text,
          bankName: _bank.text,
          lastFour: l4,
          creditLimitMinor: _money(_limit),
          statementDay: int.parse(_stmtDay.text.trim()),
          dueDays: int.parse(_dueDays.text.trim()),
          aprBp: _bp(_apr),
          minPaymentBp: _bp(_minPct),
          minPaymentFloorMinor: _money(_minFloor),
          lateFeeBp: _bp(_feePct),
          lateFeeFloorMinor: _money(_feeFloor),
          interestFromStatement: _fromStatement,
        );
      } else {
        await repo.updateCard(
          profileId: profileId,
          id: widget.existing!.id,
          name: _name.text,
          bankName: _bank.text,
          lastFour: l4,
          creditLimitMinor: _money(_limit),
          statementDay: int.parse(_stmtDay.text.trim()),
          dueDays: int.parse(_dueDays.text.trim()),
          aprBp: _bp(_apr),
          minPaymentBp: _bp(_minPct),
          minPaymentFloorMinor: _money(_minFloor),
          lateFeeBp: _bp(_feePct),
          lateFeeFloorMinor: _money(_feeFloor),
          interestFromStatement: _fromStatement,
        );
      }
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _num(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    String? help,
    bool decimal = true,
    Key? key,
  }) => TextFormField(
    key: key,
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(
      labelText: label,
      helperText: help,
      helperMaxLines: 3,
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
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
                widget.existing == null ? l.creditCardsAdd : l.creditCardsEdit,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('cc-name'),
                controller: _name,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.creditCardsFieldName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.commonRequired : null,
              ),
              TextFormField(
                key: const ValueKey('cc-bank'),
                controller: _bank,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.creditCardsFieldBank),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.commonRequired : null,
              ),
              TextFormField(
                key: const ValueKey('cc-last4'),
                controller: _last4,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.creditCardsFieldLastFour,
                  counterText: '',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return RegExp(r'^\d{4}$').hasMatch(t)
                      ? null
                      : l.creditCardsLastFourInvalid;
                },
              ),
              _num(
                _limit,
                l.creditCardsFieldLimit,
                (v) => _moneyIn(v, positive: true),
                key: const ValueKey('cc-limit'),
              ),
              _num(
                _stmtDay,
                l.creditCardsFieldStatementDay,
                (v) => _intIn(v, 1, 28),
                help: l.creditCardsHelpStatementDay,
                decimal: false,
                key: const ValueKey('cc-stmt-day'),
              ),
              _num(
                _dueDays,
                l.creditCardsFieldDueDays,
                (v) => _intIn(v, 1, 60),
                help: l.creditCardsHelpDueDays,
                decimal: false,
                key: const ValueKey('cc-due-days'),
              ),
              _num(
                _apr,
                l.creditCardsFieldApr,
                _pctIn,
                help: l.creditCardsHelpApr,
                key: const ValueKey('cc-apr'),
              ),
              _num(
                _minPct,
                l.creditCardsFieldMinPct,
                _pctIn,
                key: const ValueKey('cc-min-pct'),
              ),
              _num(
                _minFloor,
                l.creditCardsFieldMinFloor,
                (v) => _moneyIn(v, optional: true),
                help: l.creditCardsHelpMin,
                key: const ValueKey('cc-min-floor'),
              ),
              _num(
                _feePct,
                l.creditCardsFieldLateFeePct,
                (v) => _pctIn(v, optional: true),
                key: const ValueKey('cc-fee-pct'),
              ),
              _num(
                _feeFloor,
                l.creditCardsFieldLateFeeFloor,
                (v) => _moneyIn(v, optional: true),
                help: l.creditCardsHelpLateFee,
                key: const ValueKey('cc-fee-floor'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.creditCardsInterestFromStatement),
                subtitle: Text(l.creditCardsHelpInterestFromStatement),
                value: _fromStatement,
                onChanged: (v) => setState(() => _fromStatement = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('cc-save'),
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
