import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../fixed_deposits/presentation/fd_labels.dart';
import '../domain/dps.dart';
import '../providers/dps_providers.dart';
import 'dps_labels.dart';

Future<void> _sheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );

Future<void> showDpsDepositSheet(BuildContext context, DpsPosition position) =>
    _sheet(context, _DepositForm(position: position));

Future<void> showDpsCloseSheet(BuildContext context, DpsPosition position) =>
    _sheet(context, _CloseForm(position: position));

const _decimal = TextInputType.numberWithOptions(decimal: true);

class _DepositForm extends ConsumerStatefulWidget {
  const _DepositForm({required this.position});
  final DpsPosition position;

  @override
  ConsumerState<_DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends ConsumerState<_DepositForm> {
  DpsPosition get _p => widget.position;

  late final _count = TextEditingController(
    text: '${_p.overdueCount.clamp(1, _p.remainingCount)}',
  );
  final _lateFee = TextEditingController();
  final _note = TextEditingController();
  String _date = dateKey(DateTime.now());
  bool _feeTouched = false;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _suggestFee();
  }

  @override
  void dispose() {
    _count.dispose();
    _lateFee.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _installments {
    final n = int.tryParse(_count.text.trim());
    return n == null || n < 1 || n > _p.remainingCount ? null : n;
  }

  int? get _fee =>
      _lateFee.text.trim().isEmpty ? 0 : parseMajorToMinor(_lateFee.text);

  void _suggestFee() {
    if (_feeTouched) return;
    _lateFee.text = fdMajorText(_p.suggestedLateFee(_installments ?? 0, _date));
  }

  Future<void> _save() async {
    final l = context.l10n;
    final installments = _installments;
    final fee = _fee;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    if (installments == null || fee == null) {
      setState(() => _error = l.dpsInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(dpsRepositoryProvider)
          .addPayment(
            profileId: profileId,
            dpsId: _p.account.id,
            installments: installments,
            lateFeeMinor: fee,
            paymentDate: _date,
            note: _note.text,
          );
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
    final total =
        (_installments ?? 0) * _p.terms.installmentMinor + (_fee ?? 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.dpsRecordDeposit, style: theme.textTheme.titleLarge),
        Text(
          '${_p.terms.bankName} • '
          '${l.dpsPerMonth(formatMinor(_p.terms.installmentMinor))}',
          style: theme.textTheme.bodySmall,
        ),
        TextField(
          key: const ValueKey('dps-count'),
          controller: _count,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.dpsInstallmentCount,
            helperText: l.dpsInstallmentCountHelper(
              _p.remainingCount,
              _p.overdueCount,
            ),
            helperMaxLines: 2,
          ),
          onChanged: (_) => setState(_suggestFee),
        ),
        FdDateTile(
          label: l.dpsDepositDate,
          value: _date,
          onTap: () async {
            final d = await pickFdDate(context, _date);
            if (d == null) return;
            setState(() {
              _date = d;
              _suggestFee();
            });
          },
        ),
        TextField(
          key: const ValueKey('dps-fee'),
          controller: _lateFee,
          keyboardType: _decimal,
          decoration: InputDecoration(labelText: l.dpsLateFeeCharged),
          onChanged: (_) => setState(() => _feeTouched = true),
        ),
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: l.dpsNote),
        ),
        const SizedBox(height: 12),
        Text(
          l.dpsDepositTotal(formatMinor(total)),
          style: theme.textTheme.titleMedium,
        ),
        Text(l.dpsSeparateLedgerNote, style: theme.textTheme.bodySmall),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const ValueKey('dps-deposit-save'),
            onPressed: _saving ? null : _save,
            child: Text(l.commonSave),
          ),
        ),
      ],
    );
  }
}

class _CloseForm extends ConsumerStatefulWidget {
  const _CloseForm({required this.position});
  final DpsPosition position;

  @override
  ConsumerState<_CloseForm> createState() => _CloseFormState();
}

class _CloseFormState extends ConsumerState<_CloseForm> {
  DpsPosition get _p => widget.position;

  final _profit = TextEditingController();
  final _tax = TextEditingController();
  final _charge = TextEditingController(text: '0');
  final _finalNet = TextEditingController();
  final String _today = dateKey(DateTime.now());
  late String _date = _today;
  late DpsClosingType _type = _p.status == DpsStatus.matured
      ? DpsClosingType.matured
      : DpsClosingType.premature;
  bool _profitTouched = false;
  bool _taxTouched = false;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  @override
  void dispose() {
    for (final c in [_profit, _tax, _charge, _finalNet]) {
      c.dispose();
    }
    super.dispose();
  }

  static int? _money(TextEditingController c) =>
      c.text.trim().isEmpty ? 0 : parseMajorToMinor(c.text);

  /// Only a matured DPS has a profit the app can suggest: banks work out early
  /// closure in their own ways, so that figure comes from the statement.
  void _suggest() {
    if (!_profitTouched) {
      _profit.text = fdMajorText(
        _type == DpsClosingType.matured ? _p.expectedProfitMinor : 0,
      );
    }
    if (!_taxTouched) {
      _tax.text = fdMajorText(
        DpsCalculator.taxOn(_money(_profit) ?? 0, _p.terms.taxRateBp),
      );
    }
  }

  int get _calculatedNet =>
      _p.depositedMinor +
      (_money(_profit) ?? 0) -
      (_money(_tax) ?? 0) -
      (_money(_charge) ?? 0);

  Future<void> _save() async {
    final l = context.l10n;
    final profit = _money(_profit);
    final tax = _money(_tax);
    final charge = _money(_charge);
    final override = _finalNet.text.trim().isEmpty
        ? null
        : parseMajorToMinor(_finalNet.text);
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    if (profit == null ||
        tax == null ||
        charge == null ||
        (override == null && _finalNet.text.trim().isNotEmpty)) {
      setState(() => _error = l.dpsInvalid);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l.dpsCloseTitle,
      message: l.dpsCloseConfirm(formatMinor(override ?? _calculatedNet)),
      confirmLabel: l.dpsClose,
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(dpsRepositoryProvider)
          .close(
            profileId: profileId,
            id: _p.account.id,
            type: _type,
            closedDate: _date,
            profitMinor: profit,
            taxMinor: tax,
            chargeMinor: charge,
            netReceivedMinor: override,
          );
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _amount(
    String key,
    TextEditingController c,
    String label, {
    String? helper,
    VoidCallback? onTyped,
  }) => TextField(
    key: ValueKey('dps-$key'),
    controller: c,
    keyboardType: _decimal,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
    ),
    onChanged: (_) => setState(() {
      onTyped?.call();
      _suggest();
    }),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.dpsCloseTitle, style: theme.textTheme.titleLarge),
        Text(
          '${_p.terms.bankName} • '
          '${l.dpsDepositedAmount(formatMinor(_p.depositedMinor))}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in DpsClosingType.values)
              ChoiceChip(
                label: Text(dpsClosingLabel(l, t)),
                selected: _type == t,
                onSelected: (_) => setState(() {
                  _type = t;
                  _suggest();
                }),
              ),
          ],
        ),
        if (_type != DpsClosingType.matured)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.dpsEarlyNote, style: theme.textTheme.bodySmall),
          ),
        FdDateTile(
          label: l.dpsClosingDate,
          value: _date,
          onTap: () async {
            final d = await pickFdDate(context, _date);
            if (d != null) setState(() => _date = d);
          },
        ),
        _amount(
          'profit',
          _profit,
          l.dpsProfit,
          helper: l.dpsProfitHelper,
          onTyped: () => _profitTouched = true,
        ),
        _amount('close-tax', _tax, l.dpsTax, onTyped: () => _taxTouched = true),
        _amount('charge', _charge, l.dpsCharges, helper: l.dpsChargesHelper),
        const SizedBox(height: 12),
        Text(
          l.dpsCalculatedNet(formatMinor(_calculatedNet)),
          key: const ValueKey('dps-net'),
          style: theme.textTheme.titleMedium,
        ),
        _amount(
          'final-net',
          _finalNet,
          l.dpsFinalNet,
          helper: l.dpsFinalNetHelper,
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const ValueKey('dps-close-save'),
            onPressed: _saving ? null : _save,
            child: Text(l.dpsClose),
          ),
        ),
      ],
    );
  }
}
