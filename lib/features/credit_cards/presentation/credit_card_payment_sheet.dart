import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/credit_card.dart';
import '../providers/credit_card_providers.dart';
import 'credit_card_widgets.dart';

Future<void> showCardPaymentSheet(BuildContext context, BillStatement bill) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CreditCardPaymentSheet(bill: bill),
  );
}

class CreditCardPaymentSheet extends ConsumerStatefulWidget {
  const CreditCardPaymentSheet({super.key, required this.bill});
  final BillStatement bill;

  @override
  ConsumerState<CreditCardPaymentSheet> createState() =>
      _CreditCardPaymentSheetState();
}

class _CreditCardPaymentSheetState
    extends ConsumerState<CreditCardPaymentSheet> {
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
    final stmt = widget.bill.bill.statementDate;
    _date = today.compareTo(stmt) < 0 ? stmt : today;
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
          .read(creditCardRepositoryProvider)
          .addPayment(
            profileId: profileId,
            billId: widget.bill.bill.id,
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
    final st = widget.bill;
    final max = st.remainingMinor;
    final minDue = st.minDueRemainingMinor;
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
                l.creditCardsPaymentTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(l.creditCardsRemainingNow(formatMinor(max))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (minDue > 0 && minDue < max)
                    ActionChip(
                      key: const ValueKey('pay-min'),
                      label: Text(
                        '${l.creditCardsPayMinimum}  ${formatMinor(minDue)}',
                      ),
                      onPressed: () =>
                          setState(() => _amount.text = minorToInput(minDue)),
                    ),
                  ActionChip(
                    key: const ValueKey('pay-full'),
                    label: Text('${l.creditCardsPayFull}  ${formatMinor(max)}'),
                    onPressed: () =>
                        setState(() => _amount.text = minorToInput(max)),
                  ),
                ],
              ),
              TextFormField(
                key: const ValueKey('pay-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.creditCardsFieldPayAmount,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  if (m == null) return l.creditCardsInvalidNumber;
                  if (m <= 0) return l.creditCardsAmountPositive;
                  if (m > max) return l.creditCardsMaxAmount(formatMinor(max));
                  return null;
                },
              ),
              CardDateTile(
                label: l.creditCardsFieldPayDate,
                value: _date,
                onTap: () async {
                  final d = await pickCardDate(
                    context,
                    _date,
                    first: st.bill.statementDate,
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              TextFormField(
                controller: _note,
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
                  key: const ValueKey('pay-save'),
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
