import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/goal.dart';
import '../providers/goal_providers.dart';

Future<void> showGoalForm(BuildContext context, {Goal? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => GoalFormSheet(existing: existing),
  );
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing});
  final Goal? existing;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _note;
  int? _accountId;
  String? _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(
      text: e == null ? '' : (e.targetMinor / 100).toStringAsFixed(2),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _accountId = e?.accountId;
    _date = e?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date != null && isValidDateKey(_date!)
        ? parseDateKey(_date!)
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: initial.isBefore(now) ? initial : now,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateKey(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    if (_accountId == null) {
      setState(() => _error = context.l10n.goalsChooseAccount);
      return;
    }
    final minor = parseMajorToMinor(_target.text.trim());
    if (minor == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(goalRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          name: _name.text,
          accountId: _accountId!,
          targetMinor: minor,
          targetDate: _date,
          note: _note.text,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.id,
          name: _name.text,
          accountId: _accountId!,
          targetMinor: minor,
          targetDate: _date,
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
    final accounts = ref.watch(goalAccountOptionsProvider);
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
                    ? context.l10n.goalsAddGoal
                    : context.l10n.goalsEditGoal,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: context.l10n.goalsGoalName,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.goalsNameRequired
                    : null,
              ),
              TextFormField(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.goalsTargetAmount,
                  hintText: '0.00',
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v?.trim() ?? '');
                  if (m == null) return context.l10n.goalsInvalidAmount;
                  if (m <= 0) return context.l10n.goalsTargetPositive;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.goalsSavingsAccount,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              accounts.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (list) => list.isEmpty
                    ? Text(context.l10n.goalsNoAccounts)
                    : Wrap(
                        spacing: 8,
                        children: [
                          for (final a in list)
                            ChoiceChip(
                              label: Text(a.name),
                              selected: _accountId == a.id,
                              onSelected: (_) =>
                                  setState(() => _accountId = a.id),
                            ),
                        ],
                      ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.goalsTargetDateOptional),
                subtitle: Text(_date ?? context.l10n.goalsNoDeadline),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_date != null)
                      IconButton(
                        tooltip: context.l10n.goalsClearDate,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _date = null),
                      ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.goalsNoteOptional,
                ),
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
