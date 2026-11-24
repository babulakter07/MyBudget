import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/fixed_deposit_calculator.dart';
import '../providers/fixed_deposit_providers.dart';
import 'fd_labels.dart';

enum FdFormMode {
  /// New deposit together with its first instrument.
  create,

  /// Scheme type, bank, beneficiary and note of an existing deposit.
  editDetails,

  /// Instrument number, dates, tenure, rate and principal of the RUNNING
  /// instrument.
  editInstrument,
}

/// Opens the add / edit deposit sheet.
Future<void> showFdForm(
  BuildContext context, {
  FdFormMode mode = FdFormMode.create,
  FixedDepositPosition? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FdFormSheet(mode: mode, existing: existing),
  );
}

class FdFormSheet extends ConsumerStatefulWidget {
  const FdFormSheet({super.key, this.mode = FdFormMode.create, this.existing});
  final FdFormMode mode;
  final FixedDepositPosition? existing;

  @override
  ConsumerState<FdFormSheet> createState() => _FdFormSheetState();
}

class _FdFormSheetState extends ConsumerState<FdFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scheme;
  late final TextEditingController _bank;
  late final TextEditingController _beneficiary;
  late final TextEditingController _number;
  late final TextEditingController _tenure;
  late final TextEditingController _rate;
  late final TextEditingController _principal;
  late final TextEditingController _note;
  late String _issue;
  String? _error;
  bool _saving = false;

  bool get _showDetails => widget.mode != FdFormMode.editInstrument;
  bool get _showInstrument => widget.mode != FdFormMode.editDetails;

  @override
  void initState() {
    super.initState();
    final d = widget.existing?.deposit;
    final t = widget.existing?.current;
    _scheme = TextEditingController(text: d?.schemeType ?? fdSchemeFdr);
    _bank = TextEditingController(text: d?.bankName ?? '');
    _beneficiary = TextEditingController(text: d?.beneficiaryName ?? '');
    _number = TextEditingController(text: t?.instrumentNumber ?? '');
    _tenure = TextEditingController(text: t == null ? '' : '${t.tenureDays}');
    _rate = TextEditingController(text: t == null ? '' : fdRateText(t.rateBp));
    _principal = TextEditingController(
      text: t == null ? '' : fdMajorText(t.principalMinor),
    );
    _note = TextEditingController(text: d?.note ?? '');
    _issue = t?.startDate ?? dateKey(DateTime.now());
    _tenure.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _scheme,
      _bank,
      _beneficiary,
      _number,
      _tenure,
      _rate,
      _principal,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _days {
    final n = int.tryParse(_tenure.text.trim());
    return (n == null || n < 1 || n > 36500) ? null : n;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(fixedDepositRepositoryProvider);
    try {
      switch (widget.mode) {
        case FdFormMode.create:
          await repo.create(
            profileId: profileId,
            schemeType: _scheme.text,
            bankName: _bank.text,
            beneficiaryName: _beneficiary.text,
            note: _note.text,
            instrumentNumber: _number.text,
            startDate: _issue,
            tenureDays: _days!,
            rateBp: parseRateBp(_rate.text)!,
            principalMinor: parseMajorToMinor(_principal.text)!,
          );
        case FdFormMode.editDetails:
          await repo.updateDeposit(
            profileId: profileId,
            depositId: widget.existing!.deposit.id,
            schemeType: _scheme.text,
            bankName: _bank.text,
            beneficiaryName: _beneficiary.text,
            note: _note.text,
          );
        case FdFormMode.editInstrument:
          await repo.updateActiveTerm(
            profileId: profileId,
            termId: widget.existing!.current.id,
            instrumentNumber: _number.text,
            startDate: _issue,
            tenureDays: _days!,
            rateBp: parseRateBp(_rate.text)!,
            principalMinor: parseMajorToMinor(_principal.text)!,
          );
      }
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _gap() => const SizedBox(height: 8);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final days = _days;
    final title = widget.mode == FdFormMode.create
        ? l.fixedDepositsAdd
        : widget.mode == FdFormMode.editDetails
        ? l.fixedDepositsEditDetails
        : l.fixedDepositsEditInstrument;
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
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (_showDetails) ...[
                TextFormField(
                  controller: _scheme,
                  maxLength: 40,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsSchemeType,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fixedDepositsSchemeRequired
                      : null,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (code, label) in [
                      (fdSchemeFdr, l.fixedDepositsSchemeFdr),
                      (fdSchemeDps, l.fixedDepositsSchemeDps),
                      (fdSchemeSanchaypatra, l.fixedDepositsSchemeSanchaypatra),
                    ])
                      ActionChip(
                        key: ValueKey('scheme-$code'),
                        label: Text(label),
                        onPressed: () => setState(() => _scheme.text = code),
                      ),
                  ],
                ),
                _gap(),
                TextFormField(
                  controller: _bank,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l.fixedDepositsBank),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fixedDepositsBankRequired
                      : null,
                ),
                TextFormField(
                  controller: _beneficiary,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsBeneficiary,
                  ),
                ),
                _gap(),
              ],
              if (_showInstrument) ...[
                TextFormField(
                  controller: _number,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsInstrumentNumber,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fixedDepositsInstrumentRequired
                      : null,
                ),
                FdDateTile(
                  label: l.fixedDepositsIssueDate,
                  value: _issue,
                  onTap: () async {
                    final d = await pickFdDate(context, _issue);
                    if (d != null) setState(() => _issue = d);
                  },
                ),
                TextFormField(
                  controller: _tenure,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsTenureDays,
                    helperText: days == null
                        ? null
                        : '${l.fixedDepositsTenureHelper(fdMonthsText(days))}  •  '
                              '${l.fixedDepositsMaturityDate}: '
                              '${FixedDepositCalculator.maturityDate(_issue, days)}',
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      _days == null ? l.fixedDepositsInvalidTenure : null,
                ),
                _gap(),
                TextFormField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsInterestRate,
                    hintText: '0.00',
                  ),
                  validator: (v) => parseRateBp(v ?? '') == null
                      ? l.fixedDepositsInvalidRate
                      : null,
                ),
                _gap(),
                TextFormField(
                  controller: _principal,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsPrincipal,
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    final m = parseMajorToMinor(v ?? '');
                    if (m == null) return l.fixedDepositsInvalidAmount;
                    if (m <= 0) return l.fixedDepositsAmountPositive;
                    return null;
                  },
                ),
              ],
              if (_showDetails)
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.fixedDepositsNote),
                ),
              if (_error != null) ...[
                _gap(),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
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
