import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
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
    final ok = await showConfirmDialog(
      context,
      title: 'Delete transaction?',
      message: t.isTransfer
          ? 'This transfer will be removed from both accounts. '
                'You can undo this.'
          : 'This transaction will be removed from balances, budgets and '
                'reports. You can undo this.',
      confirmLabel: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await repo.softDelete(pid, t.id);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'Undo',
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
    try {
      await ref.read(transactionRepositoryProvider).restore(pid, t.id);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Transaction restored')),
      );
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
        title: const Text('Transaction'),
        actions: [
          if (t != null && !t.isDeleted) ...[
            IconButton(
              key: const ValueKey('edit-button'),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/transactions/${t.id}/edit'),
            ),
            IconButton(
              key: const ValueKey('delete-button'),
              tooltip: 'Delete',
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
            return const EmptyState(message: 'Transaction not found.');
          }
          return _Body(
            t: t,
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
    required this.onRestore,
    required this.auditAsync,
  });
  final TransactionView t;
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
    final typeLabel = t.isExpense
        ? 'Expense'
        : t.isIncome
        ? 'Income'
        : 'Transfer';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (t.isDeleted)
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('This transaction is deleted'),
              subtitle: const Text(
                'It is excluded from balances, budgets and reports.',
              ),
              trailing: FilledButton(
                key: const ValueKey('restore-button'),
                onPressed: onRestore,
                child: const Text('Restore'),
              ),
            ),
          ),
        Text(
          formatMinor(t.amountMinor),
          key: const ValueKey('detail-amount'),
          style: theme.textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text(typeLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _row('Description', t.description),
        _row('Date', t.date),
        if (t.isTransfer) ...[
          _row('From account', t.accountName),
          _row('To account', t.toAccountName),
        ] else
          _row('Account', t.accountName),
        if (t.isExpense) ...[
          _row('Category', t.categoryName),
          _row('Sub-category', t.subCategoryName),
          _row('Cost item', t.costItemName),
        ],
        if (t.isIncome) _row('Source', t.incomeSource),
        if (!t.isTransfer) ...[
          _row(t.isIncome ? 'Received by' : 'Paid by', t.paidBy),
          _row('For whom', t.forWhom),
        ],
        _row('Title', t.title),
        _row('Remarks', t.remarks),
        const Divider(height: 32),
        Text('History', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        auditAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load history: $e'),
          data: (entries) => entries.isEmpty
              ? const Text('No history yet.')
              : Column(children: [for (final e in entries) _auditTile(e)]),
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

  static const _labels = {
    'create': 'Created',
    'update': 'Edited',
    'delete': 'Deleted',
    'restore': 'Restored',
  };

  static const _skip = {'updatedAt', 'deletedAt', 'isDeleted'};

  String _changes(TransactionAuditEntry e) {
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
            'amount: ${formatMinor(p[k] as int)} → ${formatMinor(n[k] as int)}',
          );
        } else if (k.endsWith('Id')) {
          continue;
        } else {
          out.add('$k: ${p[k] ?? '-'} → ${n[k] ?? '-'}');
        }
      }
      return out.join('\n');
    } on Object {
      return '';
    }
  }

  Widget _auditTile(TransactionAuditEntry e) {
    final d = e.createdAt;
    final stamp =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    final changes = _changes(e);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, size: 20),
      title: Text(_labels[e.action] ?? e.action),
      subtitle: Text(changes.isEmpty ? stamp : '$stamp\n$changes'),
    );
  }
}
