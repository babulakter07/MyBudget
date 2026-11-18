import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/transaction_models.dart';
import '../providers/transaction_providers.dart';

const _incomeSources = ['Salary', 'Freelance', 'Business', 'Other'];

String _newIdempotencyKey() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';

/// Shared add/edit form. With [existing] it edits (type fixed, prefilled,
/// pops via [onSaved]); without it, it adds and resets after each save.
class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.existing, this.onSaved});

  final TransactionView? existing;
  final VoidCallback? onSaved;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _remarks = TextEditingController();
  final _source = TextEditingController();
  final _paidBy = TextEditingController();
  final _forWhom = TextEditingController();

  late String _type;
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  int? _subId;
  int? _itemId;
  late DateTime _date;
  String _idempotencyKey = _newIdempotencyKey();
  bool _saving = false;
  String? _error;
  int _gen = 0;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) {
      _type = TransactionType.expense;
      _date = DateTime.now();
    } else {
      _type = e.type;
      _accountId = e.accountId;
      _toAccountId = e.toAccountId;
      _categoryId = e.categoryId;
      _subId = e.subCategoryId;
      _itemId = e.costItemId;
      _date = parseDateKey(e.date);
      _amount.text = formatMinor(e.amountMinor, symbol: '');
      _title.text = e.title ?? '';
      _remarks.text = e.remarks ?? '';
      _source.text = e.incomeSource ?? '';
      _paidBy.text = e.paidBy ?? '';
      _forWhom.text = e.forWhom ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _remarks.dispose();
    _source.dispose();
    _paidBy.dispose();
    _forWhom.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ save

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final amount = parseMajorToMinor(_amount.text);
    if (amount == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(transactionRepositoryProvider);
    final date = dateKey(_date);
    try {
      final e = widget.existing;
      if (e == null) {
        switch (_type) {
          case TransactionType.expense:
            await repo.createExpense(
              profileId: pid,
              accountId: _accountId!,
              categoryId: _categoryId!,
              subCategoryId: _subId,
              costItemId: _itemId,
              amountMinor: amount,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
              paidBy: _paidBy.text,
              forWhom: _forWhom.text,
              idempotencyKey: _idempotencyKey,
            );
          case TransactionType.income:
            await repo.createIncome(
              profileId: pid,
              accountId: _accountId!,
              incomeSource: _source.text,
              amountMinor: amount,
              date: date,
              remarks: _remarks.text,
              paidBy: _paidBy.text,
              forWhom: _forWhom.text,
              idempotencyKey: _idempotencyKey,
            );
          default:
            await repo.createTransfer(
              profileId: pid,
              fromAccountId: _accountId!,
              toAccountId: _toAccountId!,
              amountMinor: amount,
              date: date,
              remarks: _remarks.text,
              idempotencyKey: _idempotencyKey,
            );
        }
      } else {
        switch (_type) {
          case TransactionType.expense:
            await repo.updateExpense(
              profileId: pid,
              id: e.id,
              accountId: _accountId!,
              categoryId: _categoryId!,
              subCategoryId: _subId,
              costItemId: _itemId,
              amountMinor: amount,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
              paidBy: _paidBy.text,
              forWhom: _forWhom.text,
            );
          case TransactionType.income:
            await repo.updateIncome(
              profileId: pid,
              id: e.id,
              accountId: _accountId!,
              incomeSource: _source.text,
              amountMinor: amount,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
              paidBy: _paidBy.text,
              forWhom: _forWhom.text,
            );
          default:
            await repo.updateTransfer(
              profileId: pid,
              id: e.id,
              fromAccountId: _accountId!,
              toAccountId: _toAccountId!,
              amountMinor: amount,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
            );
        }
      }
      if (!mounted) return;
      if (_editing) {
        setState(() => _saving = false);
        widget.onSaved?.call();
        return;
      }
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('Transaction saved')));
      setState(() {
        _saving = false;
        _idempotencyKey = _newIdempotencyKey();
        _amount.clear();
        _title.clear();
        _remarks.clear();
        _source.clear();
        _paidBy.clear();
        _forWhom.clear();
        _categoryId = null;
        _subId = null;
        _itemId = null;
        _toAccountId = null;
        _date = DateTime.now();
        _gen++;
      });
      widget.onSaved?.call();
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save the transaction: $e';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(txnActiveAccountsProvider);
    final catsAsync = ref.watch(txnActiveCategoriesProvider);
    if (accountsAsync.isLoading || catsAsync.isLoading) {
      if (!accountsAsync.hasValue || !catsAsync.hasValue) {
        return const LoadingView();
      }
    }
    if (accountsAsync.hasError) {
      return ErrorState(error: accountsAsync.error!);
    }
    if (catsAsync.hasError) return ErrorState(error: catsAsync.error!);
    final accounts = accountsAsync.value ?? const <AccountRow>[];
    final cats = catsAsync.value ?? const <CategoryRow>[];

    if (accounts.isEmpty && !_editing) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message:
            'No accounts yet.\nCreate an account in Settings > Accounts '
            'before adding transactions.',
      );
    }
    if (!_editing && _accountId == null && accounts.length == 1) {
      _accountId = accounts.first.id;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_editing) ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
          ],
          if (_type == TransactionType.expense) ..._expenseFields(cats),
          if (_type == TransactionType.income) ..._incomeFields(),
          _accountDropdown(
            accounts: accounts,
            label: _type == TransactionType.transfer
                ? 'From account'
                : 'Account',
            value: _accountId,
            existingId: widget.existing?.accountId,
            existingName: widget.existing?.accountName,
            keyName: 'account-field',
            onChanged: (v) => setState(() {
              _accountId = v;
              if (_toAccountId == v) _toAccountId = null;
            }),
          ),
          if (_type == TransactionType.transfer) ...[
            const SizedBox(height: 12),
            _accountDropdown(
              accounts: accounts,
              label: 'To account',
              value: _toAccountId,
              existingId: widget.existing?.toAccountId,
              existingName: widget.existing?.toAccountName,
              excludeId: _accountId,
              keyName: 'to-account-field',
              onChanged: (v) => setState(() => _toAccountId = v),
              validatorExtra: (v) =>
                  v == _accountId ? 'Choose a different account' : null,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('amount-field'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Enter an amount';
              final m = parseMajorToMinor(t);
              if (m == null) {
                return 'Enter a valid amount, like 1250 or 1250.50 '
                    '(max 2 decimals)';
              }
              if (m <= 0) return 'Amount must be greater than zero';
              return null;
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            key: const ValueKey('date-field'),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(dateKey(_date)),
            ),
          ),
          if (_type != TransactionType.transfer) ..._memberFields(),
          if (_type != TransactionType.income) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('title-field'),
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('remarks-field'),
            controller: _remarks,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-button'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editing ? 'Save changes' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown({
    required List<AccountRow> accounts,
    required String label,
    required int? value,
    required int? existingId,
    required String? existingName,
    required String keyName,
    required ValueChanged<int?> onChanged,
    int? excludeId,
    String? Function(int?)? validatorExtra,
  }) {
    final items = [
      for (final a in accounts)
        if (a.id != excludeId)
          DropdownMenuItem<int>(value: a.id, child: Text(a.name)),
      if (existingId != null &&
          existingId != excludeId &&
          !accounts.any((a) => a.id == existingId))
        DropdownMenuItem<int>(
          value: existingId,
          child: Text('${existingName ?? 'Account'} (inactive)'),
        ),
    ];
    final current = items.any((i) => i.value == value) ? value : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('$keyName-$current-${items.length}-$_gen'),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) =>
          v == null ? 'Select an account' : validatorExtra?.call(v),
    );
  }

  List<Widget> _expenseFields(List<CategoryRow> cats) {
    final e = widget.existing;
    if (cats.isEmpty && !_editing) {
      return const [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'No categories yet. Create a category in Settings > Categories '
            'to record expenses.',
          ),
        ),
      ];
    }
    final subs = _categoryId == null
        ? const <SubCategoryRow>[]
        : (ref.watch(txnActiveSubCategoriesProvider(_categoryId!)).value ??
              const <SubCategoryRow>[]);
    final items = _subId == null
        ? const <CostItemRow>[]
        : (ref.watch(txnActiveCostItemsProvider(_subId!)).value ??
              const <CostItemRow>[]);

    final catItems = [
      for (final c in cats)
        DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
      if (e?.categoryId != null && !cats.any((c) => c.id == e!.categoryId))
        DropdownMenuItem<int>(
          value: e!.categoryId,
          child: Text('${e.categoryName ?? 'Category'} (inactive)'),
        ),
    ];
    final subItems = [
      for (final s in subs)
        DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
      if (e?.subCategoryId != null &&
          _categoryId == e!.categoryId &&
          !subs.any((s) => s.id == e.subCategoryId))
        DropdownMenuItem<int>(
          value: e.subCategoryId,
          child: Text('${e.subCategoryName ?? 'Sub-category'} (inactive)'),
        ),
    ];
    final costItems = [
      for (final i in items)
        DropdownMenuItem<int>(value: i.id, child: Text(i.name)),
      if (e?.costItemId != null &&
          _subId == e!.subCategoryId &&
          !items.any((i) => i.id == e.costItemId))
        DropdownMenuItem<int>(
          value: e.costItemId,
          child: Text('${e.costItemName ?? 'Cost item'} (inactive)'),
        ),
    ];
    int? valid(int? v, List<DropdownMenuItem<int>> l) =>
        l.any((i) => i.value == v) ? v : null;

    return [
      DropdownButtonFormField<int>(
        key: ValueKey('cat-$_categoryId-${catItems.length}-$_gen'),
        initialValue: valid(_categoryId, catItems),
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        items: catItems,
        onChanged: (v) => setState(() {
          _categoryId = v;
          _subId = null;
          _itemId = null;
        }),
        validator: (v) => v == null ? 'Select a category' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey('sub-$_categoryId-$_subId-${subItems.length}-$_gen'),
        initialValue: valid(_subId, subItems),
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Sub-category (optional)',
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
        key: ValueKey('item-$_subId-$_itemId-${costItems.length}-$_gen'),
        initialValue: valid(_itemId, costItems),
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Cost item (optional)',
          border: OutlineInputBorder(),
        ),
        items: costItems,
        onChanged: _subId == null
            ? null
            : (v) => setState(() {
                _itemId = v;
                final def = items
                    .where((i) => i.id == v)
                    .map((i) => i.defaultAmountMinor)
                    .firstOrNull;
                if (def != null && def > 0) {
                  _amount.text = formatMinor(def, symbol: '');
                }
              }),
      ),
      const SizedBox(height: 12),
    ];
  }

  /// Optional household tags: who paid / received, and who it was for.
  List<Widget> _memberFields() {
    final names = ref.watch(txnMemberNamesProvider).value ?? const <String>[];
    final income = _type == TransactionType.income;
    return [
      const SizedBox(height: 12),
      _memberField(
        controller: _paidBy,
        keyName: 'paid-by-field',
        label: income ? 'Received by (optional)' : 'Paid by (optional)',
        names: names,
      ),
      const SizedBox(height: 12),
      _memberField(
        controller: _forWhom,
        keyName: 'for-whom-field',
        label: 'For whom (optional)',
        names: names,
      ),
    ];
  }

  Widget _memberField({
    required TextEditingController controller,
    required String keyName,
    required String label,
    required List<String> names,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey(keyName),
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'e.g. Father, Mother, Self',
            border: const OutlineInputBorder(),
            counterText: '',
          ),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final n in names.take(8))
                ActionChip(
                  label: Text(n),
                  onPressed: () => setState(() => controller.text = n),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _incomeFields() => [
    TextFormField(
      key: const ValueKey('source-field'),
      controller: _source,
      decoration: const InputDecoration(
        labelText: 'Income source',
        border: OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Enter an income source' : null,
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: [
        for (final s in _incomeSources)
          ActionChip(label: Text(s), onPressed: () => _source.text = s),
      ],
    ),
    const SizedBox(height: 12),
  ];
}
