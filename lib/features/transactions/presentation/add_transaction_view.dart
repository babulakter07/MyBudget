import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import 'transaction_form.dart';

/// Bottom-nav "Add" tab body (no Scaffold of its own).
class AddTransactionView extends ConsumerWidget {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = ref.watch(activeProfileIdProvider);
    if (pid == null) {
      return const EmptyState(message: 'Select a profile first.');
    }
    // Rebuild the form (and its idempotency key) when the profile changes.
    return TransactionForm(key: ValueKey('add-form-$pid'));
  }
}
