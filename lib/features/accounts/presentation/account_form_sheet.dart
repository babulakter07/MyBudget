import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/account.dart';
import '../providers/account_providers.dart';

Future<void> showAccountForm(BuildContext context, {Account? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccountFormSheet(existing: existing),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.existing});
  final Account? existing;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late String _type;
  late String _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _opening = TextEditingController(
      text: e == null ? '' : (e.openingBalanceMinor / 100).toStringAsFixed(2),
    );
    _type = e?.type ?? 'cash';
    _date = e?.openingDate ?? dateKey(DateTime.now());
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = isValidDateKey(_date)
        ? parseDateKey(_date)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateKey(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    final text = _opening.text.trim();
    final minor = text.isEmpty ? 0 : parseMajorToMinor(text);
    if (minor == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(accountRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          profileId: profileId,
          name: _name.text,
          type: _type,
          openingBalanceMinor: minor,
          openingDate: _date,
        );
      } else {
        await repo.update(
          profileId: profileId,
          id: widget.existing!.id,
          name: _name.text,
          type: _type,
          openingBalanceMinor: minor,
          openingDate: _date,
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
                widget.existing == null ? 'Add account' : 'Edit account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in accountTypes)
                    ChoiceChip(
                      label: Text(accountTypeLabel(t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Opening balance',
                  hintText: '0.00',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  return parseMajorToMinor(t) == null
                      ? 'Enter a valid amount (max 2 decimals)'
                      : null;
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Opening date'),
                subtitle: Text(_date),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
