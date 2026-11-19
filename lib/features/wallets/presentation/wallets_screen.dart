import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_list_screen.dart'
    show accountTypeIcon;
import '../../help/presentation/help_button.dart';
import '../domain/wallet_models.dart';
import '../providers/wallet_providers.dart';

/// Overview of cash / bank / wallet / savings balances.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileId = ref.watch(activeProfileIdProvider);
    final async = ref.watch(walletOverviewProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletsTitle),
        actions: const [HelpButton(topicId: 'wallets')],
      ),
      body: profileId == null
          ? EmptyState(
              icon: Icons.person_off,
              message: l10n.accountsSelectProfile,
            )
          : async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(error: e),
              data: (overview) => overview.isEmpty
                  ? EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      message: l10n.walletsEmpty,
                      action: FilledButton.icon(
                        onPressed: () => context.push('/config/accounts'),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.walletsAddAccount),
                      ),
                    )
                  : _Body(overview: overview),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.overview});
  final WalletOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = overview.totalMinor;
    final hasCards = overview.groups.any((g) => !countsInTotal(g.type));
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletsTotalBalance,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  formatMinor(total),
                  key: const ValueKey('wallets-total'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: total < 0 ? AppColors.expense : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCards ? l10n.walletsCardsNote : l10n.walletsTotalNote,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        for (final g in overview.groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    accountTypeLabel(l10n, g.type),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatMinor(g.subtotalMinor),
                  key: ValueKey('wallets-subtotal-${g.type}'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: g.subtotalMinor < 0 ? AppColors.expense : null,
                  ),
                ),
              ],
            ),
          ),
          for (final item in g.items) _WalletTile(item: item),
        ],
      ],
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.item});
  final WalletItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final a = item.account;
    return ListTile(
      key: ValueKey('wallet-${a.id}'),
      leading: CircleAvatar(child: Icon(accountTypeIcon(a.type))),
      title: Text(a.name),
      subtitle: Text(
        l10n.walletsInOut(
          formatMinor(item.monthInMinor),
          formatMinor(item.monthOutMinor),
        ),
      ),
      trailing: Text(
        formatMinor(item.balanceMinor),
        style: theme.textTheme.titleSmall?.copyWith(
          color: item.balanceMinor < 0 ? AppColors.expense : null,
        ),
      ),
      onTap: () => context.push('/wallets/${a.id}'),
    );
  }
}
