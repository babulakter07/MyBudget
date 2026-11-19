import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';
import '../providers/loan_providers.dart';
import 'loan_widgets.dart';

/// Opens the add / edit loan sheet. When [existing] has recorded payments the
/// financial terms are shown read-only (the repository enforces this too).
Future<void> showLoanForm(BuildContext context, {LoanPosition? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LoanFormSheet(existing: existing),
  );
}

String _majorText(int minor) => (minor / 100).toStringAsFixed(2);

class LoanFormSheet extends ConsumerStatefulWidget {
  const LoanFormSheet({super.key, this.existing});
  final LoanPosition? existing;

  @override
  ConsumerState<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<LoanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lender;
  late final TextEditingController _reference;
  late final TextEditingController _principal;
  late final TextEditingController _rate;
  late final TextEditingController _tenure;
  late final TextEditingController _installment;
  late final TextEditingController _fee;
  late final TextEditingController _note;
  late String _type;
  late String _method;
  late String _frequency;
  late String _start;
  late String _firstDue;
  bool _firstDueTouched = false;
  String? _error;
  bool _saving = false;

  bool get _locked => (widget.existing?.paidMinor ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing?.loan;
    _lender = TextEditingController(text: e?.lenderName ?? '');
    _reference = TextEditingController(text: e?.referenceNo ?? '');
    _principal = TextEditingController(
      text: e == null ? '' : _majorText(e.principalMinor),
    );
    _rate = TextEditingController(
      text: e == null ? '' : formatRateBp(e.interestRateBp),
    );
    _tenure = TextEditingController(text: e == null ? '' : '${e.tenureCount}');
    _installment = TextEditingController(
      text: e == null ? '' : _majorText(e.installmentMinor),
    );
    _fee = TextEditingController(
      text: e == null || e.processingFeeMinor == 0
          ? ''
          : _majorText(e.processingFeeMinor),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _type = e?.loanType ?? 'personal';
    _method = e?.interestMethod ?? 'reducing';
    _frequency = e?.frequency ?? 'monthly';
    _start = e?.startDate ?? dateKey(DateTime.now());
    _firstDue =
        e?.firstDueDate ?? LoanCalculator.dueDateAt(_start, 'monthly', 1);
    _firstDueTouched = e != null;
    for (final c in [_principal, _rate, _tenure, _installment]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _lender,
      _reference,
      _principal,
      _rate,
      _tenure,
      _installment,
      _fee,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- derived values ----

  int? get _principalMinor => parseMajorToMinor(_principal.text);

  /// Percent text -> basis points (11.5 -> 1150); null when invalid.
  int? get _rateBp {
    final t = _rate.text.trim();
    if (t.isEmpty) return null;
    final v = parseMajorToMinor(t);
    if (v == null || v > 10000) return null;
    return v;
  }

  int? get _count {
    final n = int.tryParse(_tenure.text.trim());
    return (n == null || n < 1 || n > 1200) ? null : n;
  }

  int? get _computedInstallment {
    final p = _principalMinor, r = _rateBp, n = _count;
    if (p == null || p <= 0 || r == null || n == null) return null;
    return LoanCalculator.computeInstallment(
      principalMinor: p,
      rateBp: r,
      method: _method,
      frequency: _frequency,
      count: n,
    );
  }

  /// The user's override, or the calculated figure.
  int? get _effectiveInstallment {
    final t = _installment.text.trim();
    if (t.isEmpty) return _computedInstallment;
    return parseMajorToMinor(t);
  }

  List<LoanInstallment>? get _previewSchedule {
    final p = _principalMinor, r = _rateBp, n = _count;
    final inst = _effectiveInstallment;
    if (p == null || p <= 0 || r == null || n == null) return null;
    if (inst == null || inst <= 0) return null;
    return LoanCalculator.buildSchedule(
      principalMinor: p,
      rateBp: r,
      method: _method,
      frequency: _frequency,
      count: n,
      installmentMinor: inst,
      firstDueDate: _firstDue,
    );
  }

  String _tenureHelper(AppLocalizations l) {
    final n = _count;
    if (n == null) return '';
    final months = (n * 12 / LoanCalculator.periodsPerYear(_frequency)).round();
    return l.loansTenureApprox(months ~/ 12, months % 12);
  }

  // ---- actions ----

  Future<String?> _pick(String current) async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    final principal = _principalMinor;
    final rateBp = _rateBp;
    final count = _count;
    if (profileId == null ||
        principal == null ||
        rateBp == null ||
        count == null) {
      return;
    }
    final installmentText = _installment.text.trim();
    final installment = installmentText.isEmpty
        ? null
        : parseMajorToMinor(installmentText);
    final fee = _fee.text.trim().isEmpty
        ? 0
        : (parseMajorToMinor(_fee.text) ?? 0);
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(loanRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          lenderName: _lender.text,
          loanType: _type,
          referenceNo: _reference.text,
          principalMinor: principal,
          interestRateBp: rateBp,
          interestMethod: _method,
          frequency: _frequency,
          tenureCount: count,
          installmentMinor: installment,
          processingFeeMinor: fee,
          startDate: _start,
          firstDueDate: _firstDue,
          note: _note.text,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.loan.id,
          lenderName: _lender.text,
          loanType: _type,
          referenceNo: _reference.text,
          principalMinor: principal,
          interestRateBp: rateBp,
          interestMethod: _method,
          frequency: _frequency,
          tenureCount: count,
          installmentMinor: installment,
          processingFeeMinor: fee,
          startDate: _start,
          firstDueDate: _firstDue,
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

  Widget _gap() => const SizedBox(height: 8);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final computed = _computedInstallment;
    final schedule = _previewSchedule;
    final enabled = !_locked;
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
                widget.existing == null ? l.loansAdd : l.loansEdit,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lender,
                maxLength: 80,
                decoration: InputDecoration(labelText: l.loansLender),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.loansLenderRequired
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l.loansType),
                items: [
                  for (final t in loanTypes)
                    DropdownMenuItem(
                      value: t,
                      child: Text(loanTypeLabel(l, t)),
                    ),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              _gap(),
              TextFormField(
                controller: _reference,
                decoration: InputDecoration(labelText: l.loansReferenceNo),
              ),
              if (_locked) ...[
                _gap(),
                Text(
                  l.loansTermsLocked,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              _gap(),
              TextFormField(
                controller: _principal,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansPrincipal,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return l.loansInvalidAmount;
                  if (m <= 0) return l.loansAmountPositive;
                  return null;
                },
              ),
              _gap(),
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansInterestRate,
                  hintText: '0.00',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty || _rateBp == null)
                    ? l.loansInvalidRate
                    : null,
              ),
              _gap(),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l.loansInterestMethod),
                items: [
                  for (final m in loanMethods)
                    DropdownMenuItem(
                      value: m,
                      child: Text(loanMethodLabel(l, m)),
                    ),
                ],
                onChanged: enabled
                    ? (v) => setState(() => _method = v ?? _method)
                    : null,
              ),
              _gap(),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: InputDecoration(labelText: l.loansFrequency),
                items: [
                  for (final f in loanFrequencies)
                    DropdownMenuItem(
                      value: f,
                      child: Text(loanFrequencyLabel(l, f)),
                    ),
                ],
                onChanged: enabled
                    ? (v) => setState(() {
                        _frequency = v ?? _frequency;
                        if (!_firstDueTouched) {
                          _firstDue = LoanCalculator.dueDateAt(
                            _start,
                            _frequency,
                            1,
                          );
                        }
                      })
                    : null,
              ),
              _gap(),
              TextFormField(
                controller: _tenure,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.loansTenure,
                  helperText: _tenureHelper(l),
                ),
                validator: (v) => _count == null ? l.loansInvalidTenure : null,
              ),
              _gap(),
              TextFormField(
                controller: _installment,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansInstallment,
                  hintText: computed == null ? '0.00' : _majorText(computed),
                  helperText: computed == null
                      ? null
                      : l.loansInstallmentHelper(formatMinor(computed)),
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final m = parseMajorToMinor(t);
                  if (m == null) return l.loansInvalidAmount;
                  if (m <= 0) return l.loansAmountPositive;
                  return null;
                },
              ),
              if (schedule != null && schedule.isNotEmpty) ...[
                _gap(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _previewRow(
                          l.loansTotalInterest,
                          formatMinor(
                            schedule.fold(0, (s, i) => s + i.interestMinor),
                          ),
                          theme,
                        ),
                        _previewRow(
                          l.loansTotalPayable,
                          formatMinor(
                            schedule.fold(0, (s, i) => s + i.installmentMinor),
                          ),
                          theme,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              _gap(),
              TextFormField(
                controller: _fee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansProcessingFee,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return parseMajorToMinor(t) == null
                      ? l.loansInvalidAmount
                      : null;
                },
              ),
              LoanDateTile(
                label: l.loansStartDate,
                value: _start,
                onTap: enabled
                    ? () async {
                        final d = await _pick(_start);
                        if (d == null) return;
                        setState(() {
                          _start = d;
                          if (!_firstDueTouched) {
                            _firstDue = LoanCalculator.dueDateAt(
                              d,
                              _frequency,
                              1,
                            );
                          }
                        });
                      }
                    : () {},
              ),
              LoanDateTile(
                label: l.loansFirstDueDate,
                value: _firstDue,
                onTap: enabled
                    ? () async {
                        final d = await _pick(_firstDue);
                        if (d != null) {
                          setState(() {
                            _firstDue = d;
                            _firstDueTouched = true;
                          });
                        }
                      }
                    : () {},
              ),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.loansNote),
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

  Widget _previewRow(
    String label,
    String value,
    ThemeData theme, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: bold
              ? theme.textTheme.titleMedium
              : theme.textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
