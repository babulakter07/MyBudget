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

/// Early-settlement sheet: shows what is still owed (principal, interest,
/// installments) and closes the loan, optionally recording the amount paid.
Future<void> showLoanCloseSheet(BuildContext context, LoanPosition pos) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LoanCloseSheet(position: pos),
  );
}

class LoanCloseSheet extends ConsumerStatefulWidget {
  const LoanCloseSheet({super.key, required this.position});
  final LoanPosition position;

  @override
  ConsumerState<LoanCloseSheet> createState() => _LoanCloseSheetState();
}

class _LoanCloseSheetState extends ConsumerState<LoanCloseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _paid = TextEditingController();
  final _remarks = TextEditingController();
  late String _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final today = dateKey(DateTime.now());
    final start = widget.position.loan.startDate;
    _date = today.compareTo(start) < 0 ? start : today;
  }

  @override
  void dispose() {
    _paid.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    final paid = _paid.text.trim().isEmpty
        ? 0
        : (parseMajorToMinor(_paid.text) ?? 0);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(loanRepositoryProvider)
          .closeEarly(
            profileId: profileId,
            loanId: widget.position.loan.id,
            closedDate: _date,
            remarks: _remarks.text,
            paidMinor: paid,
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
    final pos = widget.position;
    final max = pos.remainingMinor;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
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
              Text(l.loansCloseEarlyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l.loansCloseEarlyNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      row(
                        l.loansRemainingPrincipal,
                        formatMinor(pos.remainingPrincipalMinor),
                      ),
                      row(
                        l.loansRemainingInterest,
                        formatMinor(pos.remainingInterestMinor),
                      ),
                      row(
                        l.loansRemainingInstallments,
                        '${pos.remainingInstallments}',
                      ),
                      row(l.loansRemaining, formatMinor(max)),
                    ],
                  ),
                ),
              ),
              LoanDateTile(
                label: l.loansClosingDate,
                value: _date,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: parseDateKey(_date),
                    firstDate: parseDateKey(pos.loan.startDate),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = dateKey(picked));
                },
              ),
              TextFormField(
                key: const ValueKey('close-paid'),
                controller: _paid,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.loansAmountPaidToClose,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final m = parseMajorToMinor(t);
                  if (m == null) return l.loansInvalidAmount;
                  if (m > max) return l.loansMaxAmount(formatMinor(max));
                  return null;
                },
              ),
              TextFormField(
                key: const ValueKey('close-remarks'),
                controller: _remarks,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.loansClosingRemarks),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('close-confirm'),
                  onPressed: _saving ? null : _save,
                  child: Text(l.loansCloseEarly),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
