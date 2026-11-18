import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/debt.dart';
import '../providers/debt_providers.dart';
import 'debt_widgets.dart';

Future<void> showPaymentSheet(BuildContext context, Debt debt) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PaymentSheet(debt: debt),
  );
}

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key, required this.debt});
  final Debt debt;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = dateKey(DateTime.now());
    _date = today.compareTo(widget.debt.startDate) < 0
        ? widget.debt.startDate
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
          .read(debtRepositoryProvider)
          .addPayment(
            profileId: profileId,
            debtId: widget.debt.id,
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
    final theme = Theme.of(context);
    final max = widget.debt.outstandingMinor;
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
                context.l10n.debtsAddPayment,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.debtsOutstandingAmount(formatMinor(max)),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.debtsAmount,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return context.l10n.debtsInvalidAmount;
                  if (m <= 0) return context.l10n.debtsAmountPositive;
                  if (m > max) {
                    return context.l10n.debtsMaxAmount(formatMinor(max));
                  }
                  return null;
                },
              ),
              DebtDateTile(
                label: context.l10n.debtsPaymentDate,
                value: _date,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: parseDateKey(_date),
                    firstDate: parseDateKey(widget.debt.startDate),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = dateKey(picked));
                },
              ),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(labelText: context.l10n.debtsNote),
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
                  child: Text(context.l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
