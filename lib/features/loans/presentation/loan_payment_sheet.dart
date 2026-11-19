import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/loan_calculator.dart';
import '../providers/loan_providers.dart';
import 'loan_widgets.dart';

/// Records a payment. With [installment] the sheet is the "mark this
/// installment as paid" flow: the amount is that installment's unpaid part and
/// the user picks the real settlement date (it may differ from the due date).
Future<void> showLoanPaymentSheet(
  BuildContext context,
  LoanPosition pos, {
  LoanInstallment? installment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LoanPaymentSheet(position: pos, installment: installment),
  );
}

class LoanPaymentSheet extends ConsumerStatefulWidget {
  const LoanPaymentSheet({super.key, required this.position, this.installment});
  final LoanPosition position;
  final LoanInstallment? installment;

  @override
  ConsumerState<LoanPaymentSheet> createState() => _LoanPaymentSheetState();
}

class _LoanPaymentSheetState extends ConsumerState<LoanPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _note = TextEditingController();
  late String _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pos = widget.position;
    final next = widget.installment ?? pos.nextDue;
    final suggested = next == null
        ? ''
        : (next.unpaidMinor / 100).toStringAsFixed(2);
    _amount = TextEditingController(text: suggested);
    final today = dateKey(DateTime.now());
    _date = today.compareTo(pos.loan.startDate) < 0
        ? pos.loan.startDate
        : today;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    final minor = parseMajorToMinor(_amount.text);
    if (profileId == null || minor == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(loanRepositoryProvider)
          .addPayment(
            profileId: profileId,
            loanId: widget.position.loan.id,
            amountMinor: minor,
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
    final max = widget.position.remainingMinor;
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
                widget.installment == null
                    ? l.loansRecordPayment
                    : l.loansMarkInstallmentPaid(widget.installment!.no),
                style: theme.textTheme.titleLarge,
              ),
              if (widget.installment != null)
                Text(
                  l.loansDueOn(widget.installment!.dueDate),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Text(
                l.loansRemainingAmount(formatMinor(max)),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansAmount,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return l.loansInvalidAmount;
                  if (m <= 0) return l.loansAmountPositive;
                  if (m > max) return l.loansMaxAmount(formatMinor(max));
                  return null;
                },
              ),
              LoanDateTile(
                label: l.loansPaymentDate,
                value: _date,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: parseDateKey(_date),
                    firstDate: parseDateKey(widget.position.loan.startDate),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = dateKey(picked));
                },
              ),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(labelText: l.loansNote),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
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
