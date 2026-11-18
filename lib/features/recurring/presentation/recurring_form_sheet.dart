import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_models.dart';
import '../providers/recurring_providers.dart';
import 'recurring_list_screen.dart' show recurrenceFrequencyLabel;

Future<void> showRecurringForm(
  BuildContext context, {
  RecurringRule? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RecurringFormSheet(existing: existing),
  );
}

class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({super.key, this.existing});
  final RecurringRule? existing;

  @override
  ConsumerState<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _interval;
  late final TextEditingController _source;
  late final TextEditingController _remarks;
  late String _type;
  late String _frequency;
  int? _accountId, _toAccountId, _categoryId, _subId, _itemId, _remind;
  late String _start;
  String? _end;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(
      text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(2),
    );
    _interval = TextEditingController(text: '${e?.intervalCount ?? 1}');
    _source = TextEditingController(text: e?.incomeSource ?? '');
    _remarks = TextEditingController(text: e?.remarks ?? '');
    _type = e?.type ?? 'expense';
    _frequency = e?.frequency ?? RecurrenceFrequency.monthly;
    _accountId = e?.accountId;
    _toAccountId = e?.toAccountId;
    _categoryId = e?.categoryId;
    _subId = e?.subCategoryId;
    _itemId = e?.costItemId;
    _remind = e?.remindDaysBefore;
    _start = e?.startDate ?? dateKey(DateTime.now());
    _end = e?.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _interval.dispose();
    _source.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final current = start ? _start : (_end ?? _start);
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidDateKey(current)
          ? parseDateKey(current)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _start = dateKey(picked) : _end = dateKey(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final amount = parseMajorToMinor(_amount.text)!;
    final input = RecurringInput(
      type: _type,
      accountId: _accountId!,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
      categoryId: _type == 'expense' ? _categoryId : null,
      subCategoryId: _type == 'expense' ? _subId : null,
      costItemId: _type == 'expense' ? _itemId : null,
      incomeSource: _type == 'income' ? _source.text : null,
      amountMinor: amount,
      title: _title.text,
      remarks: _remarks.text,
      frequency: _frequency,
      intervalCount: int.parse(_interval.text.trim()),
      startDate: _start,
      endDate: _end,
      remindDaysBefore: _remind,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(recurringRepositoryProvider);
      final e = widget.existing;
      if (e == null) {
        await repo.create(pid, input);
      } else {
        await repo.update(pid, e.id, input);
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  List<DropdownMenuItem<int>> _items<T>(
    List<T> rows,
    int Function(T) id,
    String Function(T) name,
  ) => [
    for (final r in rows) DropdownMenuItem(value: id(r), child: Text(name(r))),
  ];

  int? _valid(int? v, List<DropdownMenuItem<int>> items) =>
      items.any((i) => i.value == v) ? v : null;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(txnActiveAccountsProvider).value ?? const [];
    final cats = ref.watch(txnActiveCategoriesProvider).value ?? const [];
    final subs = _categoryId == null
        ? const []
        : (ref.watch(txnActiveSubCategoriesProvider(_categoryId!)).value ??
              const []);
    final costItems = _subId == null
        ? const []
        : (ref.watch(txnActiveCostItemsProvider(_subId!)).value ?? const []);
    final accItems = _items(accounts, (a) => a.id, (a) => a.name);
    final catItems = _items(cats, (c) => c.id, (c) => c.name);
    final subItems = _items(subs, (s) => s.id, (s) => s.name);
    final itemItems = _items(costItems, (c) => c.id, (c) => c.name);
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing
                    ? context.l10n.recurringFormEdit
                    : context.l10n.recurringFormNew,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'expense',
                    label: Text(context.l10n.recurringTypeExpense),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text(context.l10n.recurringTypeIncome),
                  ),
                  ButtonSegment(
                    value: 'transfer',
                    label: Text(context.l10n.recurringTypeTransfer),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFieldTitle,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.recurringEnterTitle
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFieldAmount,
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final m = parseMajorToMinor(v ?? '');
                  return (m == null || m <= 0)
                      ? context.l10n.recurringEnterAmount
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('acc-$_accountId-${accItems.length}'),
                initialValue: _valid(_accountId, accItems),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _type == 'transfer'
                      ? context.l10n.recurringFieldFromAccount
                      : context.l10n.recurringFieldAccount,
                  border: const OutlineInputBorder(),
                ),
                items: accItems,
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) =>
                    v == null ? context.l10n.recurringSelectAccount : null,
              ),
              if (_type == 'transfer') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('to-$_toAccountId-${accItems.length}'),
                  initialValue: _valid(_toAccountId, accItems),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringFieldToAccount,
                    border: OutlineInputBorder(),
                  ),
                  items: accItems,
                  onChanged: (v) => setState(() => _toAccountId = v),
                  validator: (v) => v == null
                      ? context.l10n.recurringSelectDestination
                      : (v == _accountId
                            ? context.l10n.recurringDifferentAccount
                            : null),
                ),
              ],
              if (_type == 'income') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _source,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringFieldIncomeSource,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.l10n.recurringEnterIncomeSource
                      : null,
                ),
              ],
              if (_type == 'expense') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('cat-$_categoryId-${catItems.length}'),
                  initialValue: _valid(_categoryId, catItems),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringFieldCategory,
                    border: OutlineInputBorder(),
                  ),
                  items: catItems,
                  onChanged: (v) => setState(() {
                    _categoryId = v;
                    _subId = null;
                    _itemId = null;
                  }),
                  validator: (v) =>
                      v == null ? context.l10n.recurringSelectCategory : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('sub-$_categoryId-$_subId-${subItems.length}'),
                  initialValue: _valid(_subId, subItems),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringFieldSubCategory,
                    border: OutlineInputBorder(),
                  ),
                  items: subItems,
                  onChanged: _categoryId == null
                      ? null
                      : (v) => setState(() {
                          _subId = v;
                          _itemId = null;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('item-$_subId-$_itemId-${itemItems.length}'),
                  initialValue: _valid(_itemId, itemItems),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringFieldCostItem,
                    border: OutlineInputBorder(),
                  ),
                  items: itemItems,
                  onChanged: _subId == null
                      ? null
                      : (v) => setState(() => _itemId = v),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('freq-$_frequency'),
                      initialValue: _frequency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.recurringFieldFrequency,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final f in RecurrenceFrequency.all)
                          DropdownMenuItem(
                            value: f,
                            child: Text(
                              recurrenceFrequencyLabel(context.l10n, f),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _frequency = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _interval,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.recurringFieldEveryN,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return (n == null || n < 1)
                            ? context.l10n.recurringMin1
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.recurringFieldStartDate),
                subtitle: Text(_start),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pick(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.recurringFieldEndDate),
                subtitle: Text(_end ?? context.l10n.recurringNoEnd),
                trailing: _end == null
                    ? const Icon(Icons.calendar_today)
                    : IconButton(
                        tooltip: context.l10n.recurringClearEndDate,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _end = null),
                      ),
                onTap: () => _pick(false),
              ),
              DropdownButtonFormField<int?>(
                key: ValueKey('remind-$_remind'),
                initialValue: _remind,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFieldReminder,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final d in recurringReminderChoices)
                    DropdownMenuItem<int?>(
                      value: d,
                      child: Text(
                        d == null
                            ? context.l10n.recurringNoReminder
                            : d == 0
                            ? context.l10n.recurringOnTheDay
                            : context.l10n.recurringDaysBefore(d),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _remind = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarks,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFieldRemarks,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  editing
                      ? context.l10n.recurringSaveChanges
                      : context.l10n.recurringCreateRule,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
