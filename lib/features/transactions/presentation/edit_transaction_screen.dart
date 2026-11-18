import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../providers/transaction_providers.dart';
import 'transaction_form.dart';

class EditTransactionScreen extends ConsumerWidget {
  const EditTransactionScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.transactionsEditTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(error: e),
        data: (t) {
          if (t == null) {
            return EmptyState(message: context.l10n.transactionsNotFound);
          }
          if (t.isDeleted) {
            return EmptyState(
              message: context.l10n.transactionsDeletedCannotEdit,
            );
          }
          return TransactionForm(
            key: ValueKey('edit-${t.id}'),
            existing: t,
            onSaved: () {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(content: Text(context.l10n.transactionsUpdated)),
              );
              if (context.canPop()) context.pop();
            },
          );
        },
      ),
    );
  }
}
