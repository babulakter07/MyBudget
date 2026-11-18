import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../attachments/presentation/attachments_section.dart';
import '../../profiles/data/profile_providers.dart';
import '../../tags/presentation/tag_chips.dart';
import '../domain/transaction_models.dart';
import '../providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});
  final int transactionId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionView t,
  ) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.transactionsDeleteTitle,
      message: t.isTransfer
          ? l.transactionsDeleteTransferMessage
          : l.transactionsDeleteMessage,
      confirmLabel: l.commonDelete,
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await repo.softDelete(pid, t.id);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.transactionsDeleted),
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () => repo.restore(pid, t.id),
          ),
        ),
      );
    } on AppException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TransactionView t,
  ) async {
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final restoredText = context.l10n.transactionsRestored;
    try {
      await ref.read(transactionRepositoryProvider).restore(pid, t.id);
      messenger?.showSnackBar(SnackBar(content: Text(restoredText)));
    } on AppException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionProvider(transactionId));
    final t = async.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.transactionsDetailTitle),
        actions: [
          if (t != null && !t.isDeleted) ...[
            IconButton(
              key: const ValueKey('edit-button'),
              tooltip: context.l10n.commonEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/transactions/${t.id}/edit'),
            ),
            IconButton(
              key: const ValueKey('delete-button'),
              tooltip: context.l10n.commonDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, t),
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(error: e),
        data: (t) {
          if (t == null) {
            return EmptyState(message: context.l10n.transactionsNotFound);
          }
          return _Body(
            t: t,
            baseSymbol: currencySymbol(
              ref.watch(activeProfileProvider).value?.currencyCode ?? 'BDT',
            ),
            onRestore: () => _restore(context, ref, t),
            auditAsync: ref.watch(transactionAuditProvider(transactionId)),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.t,
    required this.baseSymbol,
    required this.onRestore,
    required this.auditAsync,
  });
  final TransactionView t;
  final String baseSymbol;
  final VoidCallback onRestore;
  final AsyncValue<List<TransactionAuditEntry>> auditAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = t.isIncome
        ? AppColors.income
        : t.isExpense
        ? AppColors.expense
        : theme.colorScheme.primary;
    final l = context.l10n;
    final typeLabel = t.isExpense
        ? l.transactionsTypeExpense
        : t.isIncome
        ? l.transactionsTypeIncome
        : l.transactionsTypeTransfer;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (t.isDeleted)
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.transactionsIsDeleted),
              subtitle: Text(l.transactionsExcludedNote),
              trailing: FilledButton(
                key: const ValueKey('restore-button'),
                onPressed: onRestore,
                child: Text(l.commonRestore),
              ),
            ),
          ),
        Text(
          formatMinor(t.amountMinor),
          key: const ValueKey('detail-amount'),
          style: theme.textTheme.headlineMedium?.copyWith(color: color),
        ),
        if (t.isForeign)
          Text(
            l.transactionsOriginalLine(
              formatOriginal(t.originalAmountMinor!, t.originalCurrency!),
              t.originalCurrency!,
              baseSymbol,
              formatRate(t.rateMicro!),
            ),
            key: const ValueKey('detail-original'),
            style: theme.textTheme.bodyMedium,
          ),
        Text(typeLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _row(l.transactionsDescription, t.description),
        _row(l.transactionsDate, t.date),
        if (t.isTransfer) ...[
          _row(l.transactionsFromAccount, t.accountName),
          _row(l.transactionsToAccount, t.toAccountName),
        ] else
          _row(l.transactionsAccount, t.accountName),
        if (t.isExpense) ...[
          _row(l.transactionsCategory, t.categoryName),
          _row(l.transactionsSubCategory, t.subCategoryName),
          _row(l.transactionsCostItem, t.costItemName),
        ],
        if (t.isIncome) _row(l.transactionsSource, t.incomeSource),
        _row(l.transactionsTitle, t.title),
        _row(l.transactionsRemarks, t.remarks),
        const SizedBox(height: 12),
        TagChips(transactionId: t.id),
        const SizedBox(height: 12),
        Text(l.transactionsReceipts, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        AttachmentsSection(transactionId: t.id),
        const Divider(height: 32),
        Text(l.transactionsHistory, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        auditAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(l.transactionsHistoryLoadFailed('$e')),
          data: (entries) => entries.isEmpty
              ? Text(l.transactionsNoHistory)
              : Column(
                  children: [for (final e in entries) _auditTile(context, e)],
                ),
        ),
      ],
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static String _actionLabel(AppLocalizations l, String action) =>
      switch (action) {
        'create' => l.transactionsAuditCreated,
        'update' => l.transactionsAuditEdited,
        'delete' => l.transactionsAuditDeleted,
        'restore' => l.transactionsAuditRestored,
        _ => action,
      };

  static String _fieldLabel(AppLocalizations l, String key) => switch (key) {
    'title' => l.transactionsFieldTitle,
    'remarks' => l.transactionsFieldRemarks,
    'incomeSource' => l.transactionsFieldIncomeSource,
    'txnDate' => l.transactionsFieldDate,
    'type' => l.transactionsFieldType,
    _ => key,
  };

  static const _skip = {'updatedAt', 'deletedAt', 'isDeleted'};

  String _changes(AppLocalizations l, TransactionAuditEntry e) {
    if (e.action != 'update' || e.previousJson == null || e.newJson == null) {
      return '';
    }
    try {
      final p = jsonDecode(e.previousJson!) as Map<String, dynamic>;
      final n = jsonDecode(e.newJson!) as Map<String, dynamic>;
      final out = <String>[];
      for (final k in n.keys) {
        if (_skip.contains(k) || p[k] == n[k]) continue;
        if (k == 'amountMinor') {
          out.add(
            l.transactionsChangeAmount(
              formatMinor(p[k] as int),
              formatMinor(n[k] as int),
            ),
          );
        } else if (k == 'originalAmountMinor') {
          out.add(
            l.transactionsChangeOriginalAmount(
              p[k] == null ? '-' : formatMinor(p[k] as int, symbol: ''),
              n[k] == null ? '-' : formatMinor(n[k] as int, symbol: ''),
            ),
          );
        } else if (k == 'originalCurrency') {
          out.add(
            l.transactionsChangeOriginalCurrency(
              '${p[k] ?? '-'}',
              '${n[k] ?? '-'}',
            ),
          );
        } else if (k == 'rateMicro') {
          out.add(
            l.transactionsChangeRate(
              p[k] == null ? '-' : formatRate(p[k] as int),
              n[k] == null ? '-' : formatRate(n[k] as int),
            ),
          );
        } else if (k.endsWith('Id')) {
          continue;
        } else {
          out.add(
            l.transactionsChangeGeneric(
              _fieldLabel(l, k),
              '${p[k] ?? '-'}',
              '${n[k] ?? '-'}',
            ),
          );
        }
      }
      return out.join('\n');
    } on Object {
      return '';
    }
  }

  Widget _auditTile(BuildContext context, TransactionAuditEntry e) {
    final l = context.l10n;
    final d = e.createdAt;
    final stamp =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    final changes = _changes(l, e);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, size: 20),
      title: Text(_actionLabel(l, e.action)),
      subtitle: Text(changes.isEmpty ? stamp : '$stamp\n$changes'),
    );
  }
}
