import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/transaction_models.dart';
import '../providers/transaction_providers.dart';

class _Line {
  int? categoryId;
  int? subCategoryId;
  int? costItemId;
  final amount = TextEditingController();
}

/// Records one bill (for example a shop receipt) as several expenses, one per
/// category/item line, saved together or not at all.
class SplitExpenseScreen extends ConsumerStatefulWidget {
  const SplitExpenseScreen({super.key});

  @override
  ConsumerState<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends ConsumerState<SplitExpenseScreen> {
  final _title = TextEditingController();
  final _remarks = TextEditingController();
  final _lines = [_Line(), _Line()];
  int? _accountId;
  DateTime _date = DateTime.now();
  String? _error;
  bool _busy = false;
  // One key per screen visit so a double tap or retry cannot duplicate rows.
  final _keyPrefix = 'split-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _title.dispose();
    _remarks.dispose();
    for (final l in _lines) {
      l.amount.dispose();
    }
    super.dispose();
  }

  int get _totalMinor =>
      _lines.fold(0, (sum, l) => sum + (parseMajorToMinor(l.amount.text) ?? 0));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    if (_accountId == null) {
      setState(() => _error = l10n.splitErrAccount);
      return;
    }
    final lines = <SplitExpenseLine>[];
    for (final l in _lines) {
      final minor = parseMajorToMinor(l.amount.text);
      if (l.categoryId == null || minor == null || minor <= 0) {
        setState(() => _error = l10n.splitErrLine);
        return;
      }
      lines.add(
        SplitExpenseLine(
          categoryId: l.categoryId!,
          subCategoryId: l.subCategoryId,
          costItemId: l.costItemId,
          amountMinor: minor,
        ),
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(transactionRepositoryProvider)
          .createSplitExpense(
            profileId: pid,
            accountId: _accountId!,
            date: dateKey(_date),
            lines: lines,
            title: _title.text,
            remarks: _remarks.text,
            keyPrefix: _keyPrefix,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.splitSaved(lines.length))));
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts =
        ref.watch(txnActiveAccountsProvider).value ?? const <AccountRow>[];
    final cats =
        ref.watch(txnActiveCategoriesProvider).value ?? const <CategoryRow>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.splitIntro),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const ValueKey('split-account'),
            initialValue: _accountId,
            decoration: InputDecoration(
              labelText: l10n.splitAccount,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final a in accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(dateKey(_date)),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('split-title'),
            controller: _title,
            decoration: InputDecoration(
              labelText: l10n.splitBillTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _lines.length; i++)
            _LineCard(
              index: i,
              line: _lines[i],
              cats: cats,
              canRemove: _lines.length > 2,
              onRemove: () => setState(() => _lines.removeAt(i)),
              onChanged: () => setState(() {}),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('split-add-line'),
              icon: const Icon(Icons.add),
              label: Text(l10n.splitAddLine),
              onPressed: () => setState(() => _lines.add(_Line())),
            ),
          ),
          const Divider(),
          Text(
            l10n.splitTotal(formatMinor(_totalMinor)),
            key: const ValueKey('split-total'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                key: const ValueKey('split-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('split-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.splitSave),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends ConsumerWidget {
  const _LineCard({
    required this.index,
    required this.line,
    required this.cats,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _Line line;
  final List<CategoryRow> cats;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subs = line.categoryId == null
        ? const <SubCategoryRow>[]
        : ref.watch(txnActiveSubCategoriesProvider(line.categoryId!)).value ??
              const <SubCategoryRow>[];
    final items = line.subCategoryId == null
        ? const <CostItemRow>[]
        : ref.watch(txnActiveCostItemsProvider(line.subCategoryId!)).value ??
              const <CostItemRow>[];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.splitLine(index + 1),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    key: ValueKey('split-remove-$index'),
                    tooltip: l10n.splitRemoveLine,
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
              ],
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('split-cat-$index'),
              initialValue: line.categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.splitCategory),
              items: [
                for (final c in cats)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) {
                line
                  ..categoryId = v
                  ..subCategoryId = null
                  ..costItemId = null;
                onChanged();
              },
            ),
            if (subs.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('split-sub-$index'),
                initialValue: line.subCategoryId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.splitSubCategory),
                items: [
                  for (final s in subs)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) {
                  line
                    ..subCategoryId = v
                    ..costItemId = null;
                  onChanged();
                },
              ),
            if (items.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('split-item-$index'),
                initialValue: line.costItemId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.splitCostItem),
                items: [
                  for (final i in items)
                    DropdownMenuItem(value: i.id, child: Text(i.name)),
                ],
                onChanged: (v) {
                  line.costItemId = v;
                  onChanged();
                },
              ),
            TextField(
              key: ValueKey('split-amount-$index'),
              controller: line.amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.splitAmount),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
