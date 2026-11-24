import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/fixed_deposit.dart';
import '../domain/fixed_deposit_calculator.dart';
import '../providers/fixed_deposit_providers.dart';
import 'fd_labels.dart';

/// Opens the encash ([reissue] false) or reissue sheet for the running
/// instrument of [position].
Future<void> showFdCloseSheet(
  BuildContext context,
  FixedDepositPosition position, {
  required bool reissue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FdCloseSheet(position: position, reissue: reissue),
  );
}

class FdCloseSheet extends ConsumerStatefulWidget {
  const FdCloseSheet({
    super.key,
    required this.position,
    required this.reissue,
  });
  final FixedDepositPosition position;
  final bool reissue;

  @override
  ConsumerState<FdCloseSheet> createState() => _FdCloseSheetState();
}

class _FdCloseSheetState extends ConsumerState<FdCloseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _interest;
  final _tax = TextEditingController(text: '0');
  final _charge = TextEditingController(text: '0');
  final _finalNet = TextEditingController();
  final _newNumber = TextEditingController();
  late final TextEditingController _newTenure;
  late final TextEditingController _newRate;
  late String _closing;
  late String _reissueDate;
  bool _interestTouched = false;
  bool _reissueDateTouched = false;
  String? _error;
  bool _saving = false;

  FixedDepositTerm get _term => widget.position.current;

  @override
  void initState() {
    super.initState();
    final t = _term;
    final today = dateKey(DateTime.now());
    _closing = today.compareTo(t.startDate) < 0 ? t.startDate : today;
    _reissueDate = _closing;
    _interest = TextEditingController(text: fdMajorText(_suggested()));
    _newTenure = TextEditingController(text: '${t.tenureDays}');
    _newRate = TextEditingController(text: fdRateText(t.rateBp));
    for (final c in [
      _interest,
      _tax,
      _charge,
      _finalNet,
      _newTenure,
      _newRate,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _interest,
      _tax,
      _charge,
      _finalNet,
      _newNumber,
      _newTenure,
      _newRate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _suggested() => FixedDepositCalculator.suggestedInterest(
    principalMinor: _term.principalMinor,
    rateBp: _term.rateBp,
    days: fdInterestDays(_term, _closing),
  );

  int _money(TextEditingController c) =>
      c.text.trim().isEmpty ? 0 : (parseMajorToMinor(c.text) ?? 0);

  int get _calculatedNet => FixedDepositCalculator.calculatedNet(
    principalMinor: _term.principalMinor,
    interestMinor: _money(_interest),
    taxMinor: _money(_tax),
    bankChargeMinor: _money(_charge),
  );

  int? get _override =>
      _finalNet.text.trim().isEmpty ? null : parseMajorToMinor(_finalNet.text);

  int get _net => _override ?? _calculatedNet;

  int? get _newDays {
    final n = int.tryParse(_newTenure.text.trim());
    return (n == null || n < 1 || n > 36500) ? null : n;
  }

  String? _optionalMoney(String? v, String invalid) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return parseMajorToMinor(t) == null ? invalid : null;
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
      if (widget.reissue) {
        await repo.reissue(
          profileId: profileId,
          termId: _term.id,
          settledDate: _closing,
          interestMinor: _money(_interest),
          taxMinor: _money(_tax),
          bankChargeMinor: _money(_charge),
          netReceivedMinor: _override,
          newInstrumentNumber: _newNumber.text,
          newStartDate: _reissueDate,
          newTenureDays: _newDays!,
          newRateBp: parseRateBp(_newRate.text)!,
        );
      } else {
        await repo.encash(
          profileId: profileId,
          termId: _term.id,
          settledDate: _closing,
          interestMinor: _money(_interest),
          taxMinor: _money(_tax),
          bankChargeMinor: _money(_charge),
          netReceivedMinor: _override,
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
    final days = fdInterestDays(_term, _closing);
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
                widget.reissue
                    ? l.fixedDepositsReissueTitle
                    : l.fixedDepositsEncashTitle,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                '${fdSchemeLabel(l, widget.position.deposit.schemeType)} '
                '${_term.instrumentNumber} • '
                '${formatMinor(_term.principalMinor)}',
                style: theme.textTheme.bodySmall,
              ),
              if (!widget.reissue) ...[
                const SizedBox(height: 4),
                Text(
                  l.fixedDepositsEncashNote,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              FdDateTile(
                label: l.fixedDepositsClosingDate,
                value: _closing,
                onTap: () async {
                  final d = await pickFdDate(context, _closing);
                  if (d == null) return;
                  setState(() {
                    _closing = d;
                    if (!_interestTouched) {
                      _interest.text = fdMajorText(_suggested());
                    }
                    if (!_reissueDateTouched) _reissueDate = d;
                  });
                },
              ),
              TextFormField(
                key: const ValueKey('close-interest'),
                controller: _interest,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.fixedDepositsClosingInterest,
                  helperText: l.fixedDepositsInterestHelper(days),
                  helperMaxLines: 2,
                ),
                onChanged: (_) => _interestTouched = true,
                validator: (v) =>
                    _optionalMoney(v, l.fixedDepositsInvalidAmount),
              ),
              _gap(),
              TextFormField(
                key: const ValueKey('close-tax'),
                controller: _tax,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.fixedDepositsClosingTax,
                ),
                validator: (v) =>
                    _optionalMoney(v, l.fixedDepositsInvalidAmount),
              ),
              _gap(),
              TextFormField(
                key: const ValueKey('close-charge'),
                controller: _charge,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.fixedDepositsClosingCharge,
                ),
                validator: (v) =>
                    _optionalMoney(v, l.fixedDepositsInvalidAmount),
              ),
              _gap(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l.fixedDepositsCalculatedNet(formatMinor(_calculatedNet)),
                    key: const ValueKey('calculated-net'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
              TextFormField(
                key: const ValueKey('close-final-net'),
                controller: _finalNet,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.fixedDepositsFinalNet,
                  helperText: l.fixedDepositsFinalNetHelper,
                ),
                validator: (v) =>
                    _optionalMoney(v, l.fixedDepositsInvalidAmount),
              ),
              if (widget.reissue) ...[
                const Divider(height: 24),
                Text(
                  l.fixedDepositsNewInstrument,
                  style: theme.textTheme.titleMedium,
                ),
                TextFormField(
                  key: const ValueKey('new-number'),
                  controller: _newNumber,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsNewInstrumentNumber,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fixedDepositsInstrumentRequired
                      : null,
                ),
                FdDateTile(
                  label: l.fixedDepositsReissueDate,
                  value: _reissueDate,
                  onTap: () async {
                    final d = await pickFdDate(context, _reissueDate);
                    if (d != null) {
                      setState(() {
                        _reissueDate = d;
                        _reissueDateTouched = true;
                      });
                    }
                  },
                ),
                TextFormField(
                  key: const ValueKey('new-tenure'),
                  controller: _newTenure,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsTenureDays,
                    helperText: _newDays == null
                        ? null
                        : '${l.fixedDepositsTenureHelper(fdMonthsText(_newDays!))}  •  '
                              '${l.fixedDepositsMaturityDate}: '
                              '${FixedDepositCalculator.maturityDate(_reissueDate, _newDays!)}',
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      _newDays == null ? l.fixedDepositsInvalidTenure : null,
                ),
                _gap(),
                TextFormField(
                  key: const ValueKey('new-rate'),
                  controller: _newRate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l.fixedDepositsInterestRate,
                  ),
                  validator: (v) => parseRateBp(v ?? '') == null
                      ? l.fixedDepositsInvalidRate
                      : null,
                ),
                _gap(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _net > 0
                          ? l.fixedDepositsNewPrincipal(formatMinor(_net))
                          : l.fixedDepositsNetMustBePositive,
                      key: const ValueKey('new-principal'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _net > 0 ? null : theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                _gap(),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('close-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    widget.reissue
                        ? l.fixedDepositsReissue
                        : l.fixedDepositsEncash,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
