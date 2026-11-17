import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/widgets.dart';
import '../providers/transaction_providers.dart';
import 'transaction_form.dart';

class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit transaction')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(error: e),
        data: (t) {
          if (t == null) {
            return const EmptyState(message: 'Transaction not found.');
          }
          if (t.isDeleted) {
            return const EmptyState(
              message: 'This transaction is deleted. Restore it to edit.',
            );
          }
          return TransactionForm(
            key: ValueKey('edit-${t.id}'),
            existing: t,
            onSaved: () {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('Transaction updated')),
              );
              if (context.canPop()) context.pop();
            },
          );
        },
      ),
    );
  }
}
