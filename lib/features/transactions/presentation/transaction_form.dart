import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../attachments/domain/attachment.dart';
import '../../attachments/presentation/attachments_section.dart';
import '../../attachments/providers/attachment_providers.dart';
import '../../currency/domain/exchange_rate.dart';
import '../../currency/providers/currency_providers.dart';
import '../../profiles/data/profile_providers.dart';
import '../../tags/presentation/tag_picker.dart';
import '../../tags/providers/tag_providers.dart';
import '../domain/transaction_models.dart';
import '../providers/transaction_providers.dart';
import 'amount_keypad.dart';

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

  late String _type;
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  int? _subId;
  int? _itemId;
  late DateTime _date;
  String _idempotencyKey = _newIdempotencyKey();
  bool _saving = false;

  /// Selected foreign currency (null = base) and the rate it uses.
  String? _fxCode;
  int? _fxRate;
  String? _error;
  int _gen = 0;
  Set<int> _tagIds = <int>{};
  Set<int> _initialTagIds = <int>{};
  bool _tagsLoaded = true;
  final PendingAttachments _pending = PendingAttachments();

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
      if (e.isForeign && !e.isTransfer) {
        _fxCode = e.originalCurrency;
        _fxRate = e.rateMicro;
        _amount.text = formatMinor(e.originalAmountMinor!, symbol: '');
      } else {
        _amount.text = formatMinor(e.amountMinor, symbol: '');
      }
      _title.text = e.title ?? '';
      _remarks.text = e.remarks ?? '';
      _source.text = e.incomeSource ?? '';
      _tagsLoaded = false;
      _loadTags(e.id);
    }
  }

  Future<void> _loadTags(int id) async {
    try {
      final pid = ref.read(activeProfileIdProvider);
      if (pid == null) return;
      final tags = await ref
          .read(tagRepositoryProvider)
          .tagsForTransaction(pid, id)
          .first;
      if (!mounted) return;
      setState(() {
        _tagIds = {for (final t in tags) t.id};
        _initialTagIds = {..._tagIds};
        _tagsLoaded = true;
      });
    } on Object {
      // Leave tags untouched on failure (_tagsLoaded stays false so a save
      // never wipes them).
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _remarks.dispose();
    _source.dispose();
    _pending.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ save

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final typed = parseMajorToMinor(_amount.text);
    if (typed == null) return;
    final fxCode = _type == TransactionType.transfer ? null : _fxCode;
    final fxRate = fxCode == null ? null : _fxRate;
    var amount = typed;
    int? origMinor;
    if (fxCode != null) {
      final base = fxRate == null
          ? null
          : convertToBaseMinor(originalMinor: typed, rateMicro: fxRate);
      if (base == null) {
        setState(() => _error = context.l10n.transactionsCannotConvertSave);
        return;
      }
      amount = base;
      origMinor = typed;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(transactionRepositoryProvider);
    final date = dateKey(_date);
    try {
      final e = widget.existing;
      int? newId;
      if (e == null) {
        switch (_type) {
          case TransactionType.expense:
            newId = (await repo.createExpense(
              profileId: pid,
              accountId: _accountId!,
              categoryId: _categoryId!,
              subCategoryId: _subId,
              costItemId: _itemId,
              amountMinor: amount,
              originalAmountMinor: origMinor,
              originalCurrency: fxCode,
              rateMicro: fxRate,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
              idempotencyKey: _idempotencyKey,
            )).id;
          case TransactionType.income:
            newId = (await repo.createIncome(
              profileId: pid,
              accountId: _accountId!,
              incomeSource: _source.text,
              amountMinor: amount,
              originalAmountMinor: origMinor,
              originalCurrency: fxCode,
              rateMicro: fxRate,
              date: date,
              remarks: _remarks.text,
              idempotencyKey: _idempotencyKey,
            )).id;
          default:
            newId = (await repo.createTransfer(
              profileId: pid,
              fromAccountId: _accountId!,
              toAccountId: _toAccountId!,
              amountMinor: amount,
              date: date,
              remarks: _remarks.text,
              idempotencyKey: _idempotencyKey,
            )).id;
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
              originalAmountMinor: origMinor,
              originalCurrency: fxCode,
              rateMicro: fxRate,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
            );
          case TransactionType.income:
            await repo.updateIncome(
              profileId: pid,
              id: e.id,
              accountId: _accountId!,
              incomeSource: _source.text,
              amountMinor: amount,
              originalAmountMinor: origMinor,
              originalCurrency: fxCode,
              rateMicro: fxRate,
              date: date,
              title: _title.text,
              remarks: _remarks.text,
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
      // The transaction is saved; tag/receipt failures must never undo it.
      final warning = await _saveExtras(pid, e?.id ?? newId!);
      if (!mounted) return;
      if (_editing) {
        setState(() => _saving = false);
        if (warning != null) _snack(warning);
        widget.onSaved?.call();
        return;
      }
      _snack(
        warning == null
            ? context.l10n.transactionsSaved
            : context.l10n.transactionsSavedWithWarning(warning),
      );
      setState(() {
        _saving = false;
        _idempotencyKey = _newIdempotencyKey();
        _amount.clear();
        _title.clear();
        _remarks.clear();
        _source.clear();
        _categoryId = null;
        _subId = null;
        _itemId = null;
        _toAccountId = null;
        _fxCode = null;
        _fxRate = null;
        _date = DateTime.now();
        _tagIds = <int>{};
        _gen++;
      });
      _pending.clear();
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
          _error = context.l10n.transactionsSaveFailed('$e');
        });
      }
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(m)));

  /// Saves tags and (add mode) pending receipts for a saved transaction.
  /// Returns a warning message when something failed, else null.
  Future<String?> _saveExtras(int pid, int txnId) async {
    final l = context.l10n;
    final problems = <String>[];
    final tagsChanged = _editing
        ? (_tagsLoaded &&
              (_tagIds.length != _initialTagIds.length ||
                  !_tagIds.containsAll(_initialTagIds)))
        : _tagIds.isNotEmpty;
    if (tagsChanged) {
      try {
        await ref
            .read(tagRepositoryProvider)
            .setTagsForTransaction(pid, txnId, _tagIds);
      } on Object catch (err) {
        problems.add(l.transactionsTagsSaveFailed(_msg(err)));
      }
    }
    if (!_editing && !_pending.isEmpty) {
      try {
        await ref
            .read(attachmentRepositoryProvider)
            .commitPending(
              profileId: pid,
              transactionId: txnId,
              pending: _pending,
            );
      } on Object catch (err) {
        problems.add(l.transactionsReceiptsSaveFailed(_msg(err)));
      }
    }
    if (problems.isEmpty) return null;
    return l.transactionsExtrasWarning(problems.join(l.transactionsWarningAnd));
  }

  String _msg(Object err) => err is AppException ? err.message : '$err';

  Future<void> _openKeypad() async {
    final m = await showAmountKeypad(context, initial: _amount.text.trim());
    if (m != null && mounted) {
      setState(() => _amount.text = formatMinor(m, symbol: ''));
    }
  }

  /// Prefills the add form. Only called in add mode.
  void _prefill({
    required String type,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    int? subId,
    int? itemId,
    int? amountMinor,
    String? title,
    String? source,
  }) {
    setState(() {
      _type = type;
      _error = null;
      if (accountId != null) _accountId = accountId;
      _toAccountId = toAccountId;
      _categoryId = categoryId;
      _subId = subId;
      _itemId = itemId;
      _fxCode = null;
      _fxRate = null;
      if (amountMinor != null && amountMinor > 0) {
        _amount.text = formatMinor(amountMinor, symbol: '');
      }
      if (title != null) _title.text = title;
      if (source != null) _source.text = source;
      _date = DateTime.now();
      _idempotencyKey = _newIdempotencyKey();
      _gen++;
    });
  }

  void _repeatLast(TransactionView t, List<AccountRow> accounts) {
    bool active(int? id) => id != null && accounts.any((a) => a.id == id);
    _prefill(
      type: t.type,
      accountId: active(t.accountId) ? t.accountId : null,
      toAccountId: active(t.toAccountId) ? t.toAccountId : null,
      categoryId: t.categoryId,
      subId: t.subCategoryId,
      itemId: t.costItemId,
      amountMinor: t.amountMinor,
      title: t.type == TransactionType.income ? null : (t.title ?? ''),
      source: t.type == TransactionType.income ? (t.incomeSource ?? '') : null,
    );
  }

  Widget _quickAdd(List<AccountRow> accounts) {
    final last = ref.watch(recentTransactionsProvider(1)).value;
    final favs =
        ref.watch(favouriteCostItemsProvider).value ??
        const <FavouriteCostItem>[];
    final lastTxn = (last == null || last.isEmpty) ? null : last.first;
    if (lastTxn == null && favs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        key: const ValueKey('quick-add-row'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (lastTxn != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  key: const ValueKey('repeat-last'),
                  avatar: const Icon(Icons.replay, size: 18),
                  label: Text(context.l10n.transactionsRepeatLast),
                  onPressed: () => _repeatLast(lastTxn, accounts),
                ),
              ),
            for (final f in favs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  key: ValueKey('fav-chip-${f.costItemId}'),
                  avatar: const Icon(Icons.star, size: 18),
                  label: Text(f.name),
                  onPressed: () => _prefill(
                    type: TransactionType.expense,
                    categoryId: f.categoryId,
                    subId: f.subCategoryId,
                    itemId: f.costItemId,
                    amountMinor: f.defaultAmountMinor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: context.l10n.transactionsNoAccounts,
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
            _quickAdd(accounts),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(context.l10n.transactionsTypeExpense),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(context.l10n.transactionsTypeIncome),
                  icon: const Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text(context.l10n.transactionsTypeTransfer),
                  icon: const Icon(Icons.swap_horiz),
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
                ? context.l10n.transactionsFromAccount
                : context.l10n.transactionsAccount,
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
              label: context.l10n.transactionsToAccount,
              value: _toAccountId,
              existingId: widget.existing?.toAccountId,
              existingName: widget.existing?.toAccountName,
              excludeId: _accountId,
              keyName: 'to-account-field',
              onChanged: (v) => setState(() => _toAccountId = v),
              validatorExtra: (v) => v == _accountId
                  ? context.l10n.transactionsChooseDifferentAccount
                  : null,
            ),
          ],
          const SizedBox(height: 12),
          if (_type != TransactionType.transfer) _currencySelector(),
          TextFormField(
            key: const ValueKey('amount-field'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.transactionsAmount,
              prefixText:
                  '${_fxCode != null && _type != TransactionType.transfer ? currencySymbol(_fxCode!) : _baseSymbol} ',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const ValueKey('calc-button'),
                tooltip: context.l10n.transactionsCalculator,
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _openKeypad,
              ),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return context.l10n.transactionsEnterAmount;
              final m = parseMajorToMinor(t);
              if (m == null) {
                return context.l10n.transactionsInvalidAmount;
              }
              if (m <= 0) return context.l10n.transactionsAmountPositive;
              return null;
            },
          ),
          if (_type != TransactionType.transfer) _conversionLine(),
          const SizedBox(height: 12),
          InkWell(
            key: const ValueKey('date-field'),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.l10n.transactionsDate,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(dateKey(_date)),
            ),
          ),
          if (_type != TransactionType.income) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('title-field'),
              controller: _title,
              decoration: InputDecoration(
                labelText: context.l10n.transactionsTitleOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('remarks-field'),
            controller: _remarks,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.transactionsRemarksOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.transactionsTags,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          TagPicker(
            selectedIds: _tagIds,
            onChanged: (ids) => setState(() => _tagIds = ids),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.transactionsReceipts,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          if (_editing)
            AttachmentsSection(transactionId: widget.existing!.id)
          else
            AttachmentsSection(pending: _pending),
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
                : Text(
                    _editing
                        ? context.l10n.transactionsSaveChanges
                        : context.l10n.commonSave,
                  ),
          ),
        ],
      ),
    );
  }

  String get _baseCode =>
      ref.watch(activeProfileProvider).value?.currencyCode.toUpperCase() ??
      'BDT';

  String get _baseSymbol => currencySymbol(_baseCode);

  void _pickCurrency(String? code, List<ExchangeRate> rates) {
    setState(() {
      _error = null;
      if (code == null) {
        _fxCode = null;
        _fxRate = null;
        return;
      }
      final active = rates.where((r) => r.currencyCode == code).firstOrNull;
      _fxCode = code;
      _fxRate = active?.rateMicro ?? _fxRate;
    });
  }

  Widget _currencySelector() {
    final rates = ref.watch(exchangeRatesProvider).value ?? const [];
    final e = widget.existing;
    final savedCode = (e != null && e.isForeign) ? e.originalCurrency : null;
    final codes = <String>[
      for (final r in rates)
        if (r.currencyCode != _baseCode) r.currencyCode,
      if (savedCode != null && !rates.any((r) => r.currencyCode == savedCode))
        savedCode,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(
            key: ValueKey('currency-chip-$_baseCode'),
            label: Text(_baseCode),
            selected: _fxCode == null,
            onSelected: (_) => _pickCurrency(null, rates),
          ),
          for (final c in codes)
            ChoiceChip(
              key: ValueKey('currency-chip-$c'),
              label: Text(c),
              selected: _fxCode == c,
              onSelected: (_) => _pickCurrency(c, rates),
            ),
          if (codes.isEmpty)
            TextButton(
              key: const ValueKey('add-rates-link'),
              onPressed: () => context.push('/config/currencies'),
              child: Text(context.l10n.transactionsAddExchangeRates),
            ),
        ],
      ),
    );
  }

  Widget _conversionLine() {
    final code = _fxCode;
    if (code == null) return const SizedBox.shrink();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _amount,
      builder: (context, v, _) {
        final rate = _fxRate;
        final typed = parseMajorToMinor(v.text);
        final theme = Theme.of(context);
        String text;
        var bad = false;
        if (rate == null) {
          text = context.l10n.transactionsNoRate(code);
          bad = true;
        } else if (typed == null || typed <= 0) {
          text = context.l10n.transactionsRateLine(
            code,
            _baseSymbol,
            formatRate(rate),
          );
        } else {
          final base = convertToBaseMinor(
            originalMinor: typed,
            rateMicro: rate,
          );
          if (base == null) {
            text = context.l10n.transactionsConvertFail;
            bad = true;
          } else {
            text = context.l10n.transactionsConvertedLine(
              formatMinor(base, symbol: _baseSymbol),
              code,
              formatRate(rate),
            );
          }
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            text,
            key: const ValueKey('conversion-line'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: bad
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
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
          child: Text(
            context.l10n.transactionsInactiveSuffix(
              existingName ?? context.l10n.transactionsAccount,
            ),
          ),
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
      validator: (v) => v == null
          ? context.l10n.transactionsSelectAccount
          : validatorExtra?.call(v),
    );
  }

  List<Widget> _expenseFields(List<CategoryRow> cats) {
    final e = widget.existing;
    if (cats.isEmpty && !_editing) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(context.l10n.transactionsNoCategories),
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
          child: Text(
            context.l10n.transactionsInactiveSuffix(
              e.categoryName ?? context.l10n.transactionsCategory,
            ),
          ),
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
          child: Text(
            context.l10n.transactionsInactiveSuffix(
              e.subCategoryName ?? context.l10n.transactionsSubCategory,
            ),
          ),
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
          child: Text(
            context.l10n.transactionsInactiveSuffix(
              e.costItemName ?? context.l10n.transactionsCostItem,
            ),
          ),
        ),
    ];
    int? valid(int? v, List<DropdownMenuItem<int>> l) =>
        l.any((i) => i.value == v) ? v : null;

    return [
      DropdownButtonFormField<int>(
        key: ValueKey('cat-$_categoryId-${catItems.length}-$_gen'),
        initialValue: valid(_categoryId, catItems),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.transactionsCategory,
          border: const OutlineInputBorder(),
        ),
        items: catItems,
        onChanged: (v) => setState(() {
          _categoryId = v;
          _subId = null;
          _itemId = null;
        }),
        validator: (v) =>
            v == null ? context.l10n.transactionsSelectCategory : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey('sub-$_categoryId-$_subId-${subItems.length}-$_gen'),
        initialValue: valid(_subId, subItems),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.transactionsSubCategoryOptional,
          border: const OutlineInputBorder(),
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
        decoration: InputDecoration(
          labelText: context.l10n.transactionsCostItemOptional,
          border: const OutlineInputBorder(),
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
                if (def != null && def > 0 && _fxCode == null) {
                  _amount.text = formatMinor(def, symbol: '');
                }
              }),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _incomeFields() {
    final l = context.l10n;
    final sources = [
      l.transactionsSourceSalary,
      l.transactionsSourceFreelance,
      l.transactionsSourceBusiness,
      l.transactionsSourceOther,
    ];
    return [
      TextFormField(
        key: const ValueKey('source-field'),
        controller: _source,
        decoration: InputDecoration(
          labelText: context.l10n.transactionsIncomeSource,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? context.l10n.transactionsEnterIncomeSource
            : null,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final s in sources)
            ActionChip(label: Text(s), onPressed: () => _source.text = s),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }
}
