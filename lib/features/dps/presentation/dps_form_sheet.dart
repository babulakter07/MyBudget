import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../fixed_deposits/presentation/fd_labels.dart';
import '../domain/dps.dart';
import '../providers/dps_providers.dart';

/// Adds a DPS, or edits [existing].
Future<void> showDpsForm(BuildContext context, {DpsPosition? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DpsFormSheet(existing: existing),
    );

class DpsFormSheet extends ConsumerStatefulWidget {
  const DpsFormSheet({super.key, this.existing});
  final DpsPosition? existing;

  @override
  ConsumerState<DpsFormSheet> createState() => _DpsFormSheetState();
}

class _DpsFormSheetState extends ConsumerState<DpsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final DpsTerms? _old = widget.existing?.terms;

  late final _bank = TextEditingController(text: _old?.bankName ?? '');
  late final _number = TextEditingController(text: _old?.accountNumber ?? '');
  late final _installment = TextEditingController(
    text: _old == null ? '' : fdMajorText(_old.installmentMinor),
  );
  late final _tenure = TextEditingController(
    text: _old == null ? '' : '${_old.tenureMonths}',
  );
  late final _rate = TextEditingController(
    text: _old == null ? '' : fdRateText(_old.rateBp),
  );
  late final _maturity = TextEditingController(
    text: _old?.bankMaturityMinor == null
        ? ''
        : fdMajorText(_old!.bankMaturityMinor!),
  );
  late final _taxRate = TextEditingController(
    text: fdRateText(_old?.taxRateBp ?? 1000),
  );
  late final _lateFee = TextEditingController(
    text: fdMajorText(_old?.lateFeeMinor ?? 0),
  );
  late final _grace = TextEditingController(text: '${_old?.graceDays ?? 0}');
  late final _missed = TextEditingController(text: '${_old?.missedLimit ?? 3}');
  final _paid = TextEditingController();
  late final _note = TextEditingController(text: _old?.note ?? '');

  late String _open = _old?.openDate ?? dateKey(DateTime.now());
  late String _firstDue = _old?.firstDueDate ?? _open;
  late bool _firstDueTouched = _old != null;
  String? _error;
  bool _saving = false;

  late final _all = [
    _bank,
    _number,
    _installment,
    _tenure,
    _rate,
    _maturity,
    _taxRate,
    _lateFee,
    _grace,
    _missed,
    _paid,
    _note,
  ];

  /// The schedule is fixed once money has been deposited against it.
  bool get _locked => (widget.existing?.paidCount ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    for (final c in [_installment, _tenure, _rate]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  static int? _intIn(String text, int low, int high) {
    final n = int.tryParse(text.trim());
    return n == null || n < low || n > high ? null : n;
  }

  int? get _installmentMinor => parseMajorToMinor(_installment.text);
  int? get _months => _intIn(_tenure.text, 1, 360);

  int? get _estimate {
    final amount = _installmentMinor;
    final months = _months;
    final rate = parseRateBp(_rate.text);
    if (amount == null || amount <= 0 || months == null || rate == null) {
      return null;
    }
    return DpsCalculator.estimatedMaturity(
      installmentMinor: amount,
      tenureMonths: months,
      rateBp: rate,
    );
  }

  /// Installments whose due date has passed, as a hint for a running DPS.
  int get _dueSoFar {
    final today = dateKey(DateTime.now());
    final months = _months ?? 0;
    var n = 0;
    while (n < months &&
        DpsCalculator.addMonths(_firstDue, n).compareTo(today) < 0) {
      n++;
    }
    return n;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final terms = DpsTerms(
      bankName: _bank.text,
      accountNumber: _number.text,
      installmentMinor: _installmentMinor!,
      tenureMonths: _months!,
      openDate: _open,
      firstDueDate: _firstDue,
      rateBp: parseRateBp(_rate.text)!,
      bankMaturityMinor: _maturity.text.trim().isEmpty
          ? null
          : parseMajorToMinor(_maturity.text),
      taxRateBp: parseRateBp(_taxRate.text)!,
      lateFeeMinor: parseMajorToMinor(_lateFee.text) ?? 0,
      graceDays: _intIn(_grace.text, 0, 60)!,
      missedLimit: _intIn(_missed.text, 0, 24)!,
      note: _note.text,
    );
    final repo = ref.read(dpsRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          terms: terms,
          paidInstallments: int.tryParse(_paid.text.trim()) ?? 0,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.account.id,
          terms: terms,
        );
      }
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    String? helper,
    bool number = false,
    bool enabled = true,
    String? Function(String text)? check,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      key: ValueKey('dps-$key'),
      controller: controller,
      enabled: enabled,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
      ),
      validator: check == null ? null : (v) => check(v ?? ''),
    ),
  );

  Widget _chips(
    TextEditingController controller,
    List<(String, String)> options, {
    bool enabled = true,
  }) => Wrap(
    spacing: 8,
    children: [
      for (final (value, label) in options)
        ActionChip(
          label: Text(label),
          onPressed: enabled
              ? () => setState(() => controller.text = value)
              : null,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final estimate = _estimate;
    String? invalid(bool ok) => ok ? null : l.dpsInvalid;
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
                widget.existing == null ? l.dpsAdd : l.dpsEdit,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_locked)
                Text(l.dpsLockedNote, style: theme.textTheme.bodySmall),
              _field(
                'bank',
                _bank,
                l.dpsBankName,
                check: (v) => v.trim().isEmpty || v.trim().length > 80
                    ? l.dpsBankRequired
                    : null,
              ),
              _field('number', _number, l.dpsAccountNumber),
              _field(
                'installment',
                _installment,
                l.dpsInstallment,
                number: true,
                enabled: !_locked,
                check: (v) => invalid((parseMajorToMinor(v) ?? 0) > 0),
              ),
              _field(
                'tenure',
                _tenure,
                l.dpsTenureMonths,
                number: true,
                enabled: !_locked,
                check: (v) => invalid(_intIn(v, 1, 360) != null),
              ),
              _chips(_tenure, [
                for (final years in const [3, 5, 8, 10])
                  ('${years * 12}', l.dpsYears(years)),
              ], enabled: !_locked),
              FdDateTile(
                label: l.dpsOpenDate,
                value: _open,
                onTap: () async {
                  if (_locked) return;
                  final d = await pickFdDate(context, _open);
                  if (d == null) return;
                  setState(() {
                    _open = d;
                    if (!_firstDueTouched) _firstDue = d;
                  });
                },
              ),
              FdDateTile(
                label: l.dpsFirstDueDate,
                value: _firstDue,
                onTap: () async {
                  if (_locked) return;
                  final d = await pickFdDate(context, _firstDue);
                  if (d == null) return;
                  setState(() {
                    _firstDue = d;
                    _firstDueTouched = true;
                  });
                },
              ),
              if (widget.existing == null)
                _field(
                  'paid',
                  _paid,
                  l.dpsAlreadyPaid,
                  helper: l.dpsAlreadyPaidHelper(_dueSoFar),
                  number: true,
                  check: (v) => invalid(
                    v.trim().isEmpty || _intIn(v, 0, _months ?? 360) != null,
                  ),
                ),
              _field(
                'rate',
                _rate,
                l.dpsRate,
                number: true,
                check: (v) => invalid(parseRateBp(v) != null),
              ),
              _field(
                'maturity',
                _maturity,
                l.dpsBankMaturity,
                helper: estimate == null
                    ? l.dpsBankMaturityHelper
                    : l.dpsEstimateHelper(formatMinor(estimate)),
                number: true,
                check: (v) =>
                    invalid(v.trim().isEmpty || parseMajorToMinor(v) != null),
              ),
              _field(
                'tax',
                _taxRate,
                l.dpsTaxRate,
                helper: l.dpsTaxHelper,
                number: true,
                check: (v) => invalid(parseRateBp(v) != null),
              ),
              _chips(_taxRate, const [('10', '10%'), ('15', '15%')]),
              const SizedBox(height: 12),
              Text(l.dpsBankRules, style: theme.textTheme.titleMedium),
              Text(l.dpsBankRulesNote, style: theme.textTheme.bodySmall),
              _field(
                'late-fee',
                _lateFee,
                l.dpsLateFee,
                number: true,
                check: (v) =>
                    invalid(v.trim().isEmpty || parseMajorToMinor(v) != null),
              ),
              _field(
                'grace',
                _grace,
                l.dpsGraceDays,
                number: true,
                check: (v) => invalid(_intIn(v, 0, 60) != null),
              ),
              _field(
                'missed',
                _missed,
                l.dpsMissedLimit,
                helper: l.dpsMissedLimitHelper,
                number: true,
                check: (v) => invalid(_intIn(v, 0, 24) != null),
              ),
              _field('note', _note, l.dpsNote),
              if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('dps-save'),
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
