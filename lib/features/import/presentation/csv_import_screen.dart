import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../data/csv_parsing.dart';
import '../domain/csv_import_models.dart';
import '../providers/import_providers.dart';

/// Number of rows shown in the preview.
const int csvPreviewRows = 20;

const int _none = -1;

/// Import transactions from a bank/e-wallet CSV export. Route `/settings/import`.
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  PickedCsv? _file;
  bool _hasHeader = true;
  CsvTable? _table;
  ColumnMapping _mapping = const ColumnMapping();
  int? _accountId;
  int? _defaultCategoryId;
  ImportPlan? _plan;
  CsvImportResult? _result;
  String? _error;
  bool _busy = false;
  int _planToken = 0;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ref.read(csvFileGatewayProvider).pick();
      if (picked == null) return;
      _file = picked;
      await _parse(guess: true);
      final accounts = await ref.read(txnActiveAccountsProvider.future);
      if (_accountId == null && accounts.isNotEmpty) {
        _accountId = accounts.first.id;
      }
      await _replan();
    } on AppException catch (e) {
      _error = e.message;
      _table = null;
      _plan = null;
    } catch (e) {
      _error = mounted ? context.l10n.importCouldNotRead('$e') : '$e';
      _table = null;
      _plan = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _parse({required bool guess}) async {
    final f = _file;
    if (f == null) return;
    try {
      final t = parseCsv(f.text, hasHeader: _hasHeader);
      _table = t;
      _result = null;
      if (guess) {
        _mapping = _hasHeader ? guessMapping(t) : const ColumnMapping();
      }
      _error = null;
    } on AppException catch (e) {
      _table = null;
      _plan = null;
      _error = e.message;
    }
  }

  Future<void> _replan() async {
    final token = ++_planToken;
    final table = _table;
    final pid = ref.read(activeProfileIdProvider);
    if (table == null ||
        pid == null ||
        _accountId == null ||
        !_mapping.isComplete) {
      if (mounted) setState(() => _plan = null);
      return;
    }
    try {
      final plan = await ref
          .read(csvImportServiceProvider)
          .plan(
            profileId: pid,
            table: table,
            settings: ImportSettings(
              accountId: _accountId!,
              defaultCategoryId: _defaultCategoryId,
              mapping: _mapping,
            ),
          );
      if (!mounted || token != _planToken) return;
      setState(() {
        _plan = plan;
        _error = null;
      });
    } on AppException catch (e) {
      if (!mounted || token != _planToken) return;
      setState(() {
        _plan = null;
        _error = e.message;
      });
    }
  }

  void _change(VoidCallback f) {
    setState(() {
      f();
      _result = null;
    });
    _replan();
  }

  Future<void> _import() async {
    final table = _table;
    final pid = ref.read(activeProfileIdProvider);
    if (table == null || pid == null || _accountId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(csvImportServiceProvider)
          .import(
            profileId: pid,
            table: table,
            settings: ImportSettings(
              accountId: _accountId!,
              defaultCategoryId: _defaultCategoryId,
              mapping: _mapping,
            ),
          );
      _result = res;
      await _replan();
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = mounted ? context.l10n.importImportFailed('$e') : '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final accounts = ref.watch(txnActiveAccountsProvider).value ?? const [];
    final categories =
        ref.watch(txnActiveCategoriesProvider).value ?? const <CategoryRow>[];
    final table = _table;
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(title: Text(l.importTitle)),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.importStep1, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l.importIntro, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.upload_file),
                      label: Text(l.importChooseFile),
                    ),
                    if (_file != null) Text(_file!.name),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.importFirstRowHeader),
                  value: _hasHeader,
                  onChanged: _busy
                      ? null
                      : (v) async {
                          _hasHeader = v;
                          await _parse(guess: true);
                          setState(() {});
                          await _replan();
                        },
                ),
                if (_error != null)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        key: const Key('import-error'),
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                if (table != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l.importStep2(
                      table.rows.length,
                      table.delimiter == '\t'
                          ? l.importDelimiterTab
                          : table.delimiter,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _colDrop(
                    'map-date',
                    l.importColDate,
                    table,
                    _mapping.date,
                    (v) => _change(
                      () => _mapping = _mapping.copyWith(date: () => v),
                    ),
                  ),
                  _formatDrop(),
                  _colDrop(
                    'map-amount',
                    l.importColAmount,
                    table,
                    _mapping.amount,
                    (v) => _change(
                      () => _mapping = _mapping.copyWith(amount: () => v),
                    ),
                  ),
                  _colDrop(
                    'map-description',
                    l.importColDescription,
                    table,
                    _mapping.description,
                    (v) => _change(
                      () => _mapping = _mapping.copyWith(description: () => v),
                    ),
                    optional: true,
                  ),
                  _colDrop(
                    'map-type',
                    l.importColType,
                    table,
                    _mapping.type,
                    (v) => _change(
                      () => _mapping = _mapping.copyWith(type: () => v),
                    ),
                    optional: true,
                    noneLabel: l.importColTypeNone,
                  ),
                  _colDrop(
                    'map-category',
                    l.importColCategory,
                    table,
                    _mapping.category,
                    (v) => _change(
                      () => _mapping = _mapping.copyWith(category: () => v),
                    ),
                    optional: true,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey('account-$_accountId-${accounts.length}'),
                    initialValue: accounts.any((a) => a.id == _accountId)
                        ? _accountId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.importIntoAccount),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => _change(() => _accountId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                      'defcat-$_defaultCategoryId-${categories.length}',
                    ),
                    initialValue:
                        categories.any((c) => c.id == _defaultCategoryId)
                        ? _defaultCategoryId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.importDefaultCategory,
                      helperText: l.importDefaultCategoryHelp,
                      helperMaxLines: 3,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _none,
                        child: Text(l.importDefaultCategoryNone),
                      ),
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => _change(
                      () => _defaultCategoryId = v == _none ? null : v,
                    ),
                  ),
                ],
                if (table != null && plan != null) ...[
                  const SizedBox(height: 20),
                  Text(l.importStep3, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l.importSummary(
                      plan.validCount,
                      plan.duplicateCount,
                      plan.invalidCount,
                      plan.rows.length < csvPreviewRows
                          ? plan.rows.length
                          : csvPreviewRows,
                    ),
                    key: const Key('import-summary'),
                  ),
                  const SizedBox(height: 8),
                  for (final r in plan.rows.take(csvPreviewRows))
                    _PreviewTile(row: r),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_busy || plan.validCount == 0) ? null : _import,
                    icon: const Icon(Icons.download_done),
                    label: Text(l.importImportRows(plan.validCount)),
                  ),
                  if (plan.invalidCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.importInvalidNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    key: const Key('import-result'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.importFinished,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(l.importImported(_result!.imported)),
                          Text(
                            l.importSkippedDuplicates(
                              _result!.skippedDuplicates,
                            ),
                          ),
                          Text(l.importInvalidRows(_result!.invalid)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colDrop(
    String keyName,
    String label,
    CsvTable table,
    int? value,
    ValueChanged<int?> onChanged, {
    bool optional = false,
    String? noneLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey('$keyName-$value-${table.headers.length}'),
        initialValue: value ?? (optional ? _none : null),
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          if (optional)
            DropdownMenuItem(
              value: _none,
              child: Text(noneLabel ?? context.l10n.importNotMapped),
            ),
          for (var i = 0; i < table.headers.length; i++)
            DropdownMenuItem(
              value: i,
              child: Text(table.headers[i], overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) => onChanged(v == null || v == _none ? null : v),
      ),
    );
  }

  Widget _formatDrop() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<CsvDateFormat>(
      key: ValueKey('format-${_mapping.dateFormat.name}'),
      initialValue: _mapping.dateFormat,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.l10n.importDateFormat),
      items: [
        for (final f in CsvDateFormat.values)
          DropdownMenuItem(value: f, child: Text(f.label)),
      ],
      onChanged: (v) => v == null
          ? null
          : _change(() => _mapping = _mapping.copyWith(dateFormat: v)),
    ),
  );
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.row});
  final ImportRowPlan row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final (icon, color) = switch (row.status) {
      ImportRowStatus.valid => (Icons.check_circle_outline, scheme.primary),
      ImportRowStatus.duplicate => (Icons.copy_all, scheme.outline),
      ImportRowStatus.invalid => (Icons.error_outline, scheme.error),
    };
    final String title;
    String? subtitle;
    switch (row.status) {
      case ImportRowStatus.invalid:
        title = l.importRowInvalid(row.number, row.cells.join(' | '));
        subtitle = row.errors.join('\n');
      case ImportRowStatus.duplicate:
        title = l.importRowDuplicate(row.number);
        subtitle = '${row.date} · ${formatMinor(row.amountMinor!)}';
      case ImportRowStatus.valid:
        title = l.importRowValid(
          row.number,
          row.isExpense! ? l.importKindExpense : l.importKindIncome,
          formatMinor(row.amountMinor!),
        );
        subtitle =
            '${row.date} · ${row.description ?? l.importNoDescription}'
            '${row.categoryName != null ? ' · ${row.categoryName}' : ''}';
    }
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
