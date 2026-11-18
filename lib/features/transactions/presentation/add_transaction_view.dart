import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import 'transaction_form.dart';

/// Bottom-nav "Add" tab body (no Scaffold of its own).
class AddTransactionView extends ConsumerWidget {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = ref.watch(activeProfileIdProvider);
    if (pid == null) {
      return EmptyState(message: context.l10n.transactionsSelectProfileFirst);
    }
    // Rebuild the form (and its idempotency key) when the profile changes.
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: TextButton.icon(
              key: const ValueKey('open-split'),
              icon: const Icon(Icons.call_split),
              label: Text(context.l10n.splitOpen),
              onPressed: () => context.push('/transactions/split'),
            ),
          ),
        ),
        Expanded(child: TransactionForm(key: ValueKey('add-form-$pid'))),
      ],
    );
  }
}
