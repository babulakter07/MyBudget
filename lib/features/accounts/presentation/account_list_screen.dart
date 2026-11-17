import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/account.dart';
import '../providers/account_providers.dart';
import 'account_form_sheet.dart';

IconData accountTypeIcon(String type) => switch (type) {
  'cash' => Icons.payments_outlined,
  'bank' => Icons.account_balance,
  'mobile' => Icons.smartphone,
  _ => Icons.wallet,
};

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final filter = ref.watch(accountFilterProvider);
    final async = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add account',
              onPressed: () => showAccountForm(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search accounts',
                border: OutlineInputBorder(),
              ),
              onChanged: ref.read(accountFilterProvider.notifier).setSearch,
            ),
          ),
          SwitchListTile(
            title: const Text('Show inactive'),
            value: filter.includeInactive,
            onChanged: ref
                .read(accountFilterProvider.notifier)
                .setIncludeInactive,
          ),
          Expanded(
            child: profileId == null
                ? const EmptyState(
                    icon: Icons.person_off,
                    message: 'Select a profile to manage accounts.',
                  )
                : async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(error: e),
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            message: 'No accounts yet. Tap + to add one.',
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) => _AccountTile(item: items[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.item});
  final AccountBalance item;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final account = item.account;
    final ok = await showConfirmDialog(
      context,
      title: value ? 'Activate account?' : 'Deactivate account?',
      message: value
          ? '"${account.name}" will be available again.'
          : '"${account.name}" will be hidden from new entries. Existing data is kept.',
    );
    if (!ok) return;
    try {
      await ref
          .read(accountRepositoryProvider)
          .setActive(account.profileId, account.id, value);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = item.account;
    final theme = Theme.of(context);
    final negative = item.balanceMinor < 0;
    return ListTile(
      leading: CircleAvatar(child: Icon(accountTypeIcon(account.type))),
      title: Text(
        account.name,
        style: account.isActive ? null : TextStyle(color: theme.disabledColor),
      ),
      subtitle: Text(accountTypeLabel(account.type)),
      onTap: () => showAccountForm(context, existing: account),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinor(item.balanceMinor),
            style: theme.textTheme.titleSmall?.copyWith(
              color: negative ? AppColors.expense : null,
            ),
          ),
          Switch(
            value: account.isActive,
            onChanged: (v) => _toggle(context, ref, v),
          ),
        ],
      ),
    );
  }
}
