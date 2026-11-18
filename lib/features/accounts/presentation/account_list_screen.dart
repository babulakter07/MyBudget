import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/account.dart';
import '../providers/account_providers.dart';
import 'account_form_sheet.dart';

IconData accountTypeIcon(String type) => switch (type) {
  'cash' => Icons.payments_outlined,
  'bank' => Icons.account_balance,
  'mobile' => Icons.smartphone,
  'savings' => Icons.savings_outlined,
  'credit_card' => Icons.credit_card,
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
      appBar: AppBar(title: Text(context.l10n.accountsTitle)),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: context.l10n.accountsAdd,
              onPressed: () => showAccountForm(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.accountsSearchHint,
                border: OutlineInputBorder(),
              ),
              onChanged: ref.read(accountFilterProvider.notifier).setSearch,
            ),
          ),
          SwitchListTile(
            title: Text(context.l10n.accountsShowInactive),
            value: filter.includeInactive,
            onChanged: ref
                .read(accountFilterProvider.notifier)
                .setIncludeInactive,
          ),
          Expanded(
            child: profileId == null
                ? EmptyState(
                    icon: Icons.person_off,
                    message: context.l10n.accountsSelectProfile,
                  )
                : async.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(error: e),
                    data: (items) => items.isEmpty
                        ? EmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            message: context.l10n.accountsEmpty,
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
      title: value
          ? context.l10n.accountsActivateTitle
          : context.l10n.accountsDeactivateTitle,
      message: value
          ? context.l10n.accountsActivateMessage(account.name)
          : context.l10n.accountsDeactivateMessage(account.name),
      confirmLabel: context.l10n.commonConfirm,
      cancelLabel: context.l10n.commonCancel,
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
      subtitle: Text(accountTypeLabel(context.l10n, account.type)),
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
