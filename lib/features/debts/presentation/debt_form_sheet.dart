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

Future<void> showDebtForm(
  BuildContext context, {
  Debt? existing,
  String direction = 'lent',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DebtFormSheet(existing: existing, direction: direction),
  );
}

class DebtFormSheet extends ConsumerStatefulWidget {
  const DebtFormSheet({super.key, this.existing, this.direction = 'lent'});
  final Debt? existing;
  final String direction;

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _direction;
  late String _start;
  String? _due;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _person = TextEditingController(text: e?.personName ?? '');
    _amount = TextEditingController(
      text: e == null ? '' : (e.principalMinor / 100).toStringAsFixed(2),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _direction = e?.direction ?? widget.direction;
    _start = e?.startDate ?? dateKey(DateTime.now());
    _due = e?.dueDate;
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<String?> _pick(String? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && isValidDateKey(current)
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
    if (profileId == null) return;
    final minor = parseMajorToMinor(_amount.text);
    if (minor == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(debtRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          direction: _direction,
          personName: _person.text,
          principalMinor: minor,
          startDate: _start,
          dueDate: _due,
          note: _note.text,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.id,
          direction: _direction,
          personName: _person.text,
          principalMinor: minor,
          startDate: _start,
          dueDate: _due,
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

  @override
  Widget build(BuildContext context) {
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
                widget.existing == null
                    ? context.l10n.debtsAddDebt
                    : context.l10n.debtsEditDebt,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'lent',
                    label: Text(context.l10n.debtsILent),
                  ),
                  ButtonSegment(
                    value: 'borrowed',
                    label: Text(context.l10n.debtsIBorrowed),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() => _direction = s.first),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _person,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: context.l10n.debtsPerson,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.debtsPersonRequired
                    : null,
              ),
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
                  return null;
                },
              ),
              DebtDateTile(
                label: context.l10n.debtsStartDate,
                value: _start,
                onTap: () async {
                  final d = await _pick(_start);
                  if (d != null) setState(() => _start = d);
                },
              ),
              DebtDateTile(
                label: context.l10n.debtsDueDate,
                value: _due,
                onTap: () async {
                  final d = await _pick(_due ?? _start);
                  if (d != null) setState(() => _due = d);
                },
                onClear: () => setState(() => _due = null),
              ),
              TextFormField(
                controller: _note,
                maxLines: 2,
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
