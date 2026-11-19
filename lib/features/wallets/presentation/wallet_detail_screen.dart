import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../help/presentation/help_button.dart';
import '../../ledger/domain/ledger_models.dart';
import '../domain/wallet_models.dart';
import '../providers/wallet_providers.dart';
import 'wallet_dialogs.dart';

/// Balance, quick actions and running-balance ledger of one account.
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wallet = ref.watch(walletProvider(accountId));
    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.value?.account.name ?? l10n.walletsTitle),
        actions: const [HelpButton(topicId: 'wallets')],
      ),
      body: wallet.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(error: e),
        data: (w) => w == null
            ? EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: l10n.walletsNotFound,
              )
            : _Detail(wallet: w),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.wallet});
  final WalletItem wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final period = ref.watch(walletPeriodProvider);
    final ledger = ref.watch(walletLedgerProvider(wallet.account.id));
    final negative = wallet.balanceMinor < 0;

    final periodLabels = {
      WalletPeriod.thisMonth: l10n.walletsPeriodMonth,
      WalletPeriod.last3Months: l10n.walletsPeriod3Months,
      WalletPeriod.thisYear: l10n.walletsPeriodYear,
      WalletPeriod.all: l10n.walletsPeriodAll,
    };

    final header = <Widget>[
      Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walletsCurrentBalance,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                formatMinor(wallet.balanceMinor),
                key: const ValueKey('wallet-balance'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: negative ? AppColors.expense : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.walletsThisMonth, style: theme.textTheme.labelMedium),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.walletsMoneyIn}: ${formatMinor(wallet.monthInMinor)}',
                      style: const TextStyle(color: AppColors.income),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${l10n.walletsMoneyOut}: ${formatMinor(wallet.monthOutMinor)}',
                      style: const TextStyle(color: AppColors.expense),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (wallet.account.isActive) ...[
              FilledButton.icon(
                key: const ValueKey('wallet-add-money'),
                onPressed: () => showAddMoneyDialog(context, wallet),
                icon: const Icon(Icons.add),
                label: Text(l10n.walletsAddMoney),
              ),
              OutlinedButton.icon(
                key: const ValueKey('wallet-transfer'),
                onPressed: () => showTransferDialog(context, wallet),
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.walletsTransferWithdraw),
              ),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          l10n.walletsLedgerTitle,
          style: theme.textTheme.titleMedium,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          children: [
            for (final p in WalletPeriod.values)
              ChoiceChip(
                key: ValueKey('wallet-period-${p.name}'),
                label: Text(periodLabels[p]!),
                selected: period == p,
                onSelected: (_) =>
                    ref.read(walletPeriodProvider.notifier).set(p),
              ),
          ],
        ),
      ),
    ];

    return ledger.when(
      loading: () => ListView(children: [...header, const LoadingView()]),
      error: (e, _) => ListView(
        children: [
          ...header,
          ErrorState(error: e),
        ],
      ),
      data: (data) {
        final opening = data.rows.isEmpty ? null : data.rows.first;
        final movements = data.rows.skip(1).toList().reversed.toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ...header,
            _SummaryStrip(ledger: data),
            if (movements.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l10n.walletsNoMovements)),
              ),
            for (final r in movements) _LedgerTile(row: r),
            if (opening != null) _OpeningTile(row: opening),
          ],
        );
      },
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.ledger});
  final AccountLedger ledger;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget cell(String label, int minor, Color? color, String key) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            formatMinor(minor),
            key: ValueKey(key),
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            cell(
              l10n.walletsOpening,
              ledger.openingBalanceMinor,
              null,
              'wallet-sum-opening',
            ),
            cell(
              l10n.walletsTotalIn,
              ledger.totalIncomeMinor + ledger.totalTransferInMinor,
              AppColors.income,
              'wallet-sum-in',
            ),
            cell(
              l10n.walletsTotalOut,
              ledger.totalExpenseMinor + ledger.totalTransferOutMinor,
              AppColors.expense,
              'wallet-sum-out',
            ),
            cell(
              l10n.walletsClosing,
              ledger.closingBalanceMinor,
              null,
              'wallet-sum-closing',
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.row});
  final AccountLedgerRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final net =
        row.incomeMinor +
        row.transferInMinor -
        row.expenseMinor -
        row.transferOutMinor;
    final positive = net >= 0;
    return ListTile(
      key: ValueKey('wallet-row-${row.id}'),
      title: Text(row.description),
      subtitle: Text(
        [
          row.date,
          if (row.detail.isNotEmpty) row.detail,
          l10n.walletsBalanceAfter(formatMinor(row.balanceMinor)),
        ].join(' · '),
      ),
      trailing: Text(
        '${positive ? '+' : '-'}${formatMinor(net.abs())}',
        style: TextStyle(
          color: positive ? AppColors.income : AppColors.expense,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OpeningTile extends StatelessWidget {
  const _OpeningTile({required this.row});
  final AccountLedgerRow row;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey('wallet-row-opening'),
      leading: const Icon(Icons.flag_outlined),
      title: Text(context.l10n.walletsOpeningBalance),
      subtitle: Text(row.date),
      trailing: Text(formatMinor(row.balanceMinor)),
    );
  }
}
