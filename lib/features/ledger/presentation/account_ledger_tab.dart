import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/ledger_models.dart';
import '../providers/ledger_providers.dart';
import 'ledger_table.dart';

class AccountLedgerTab extends ConsumerStatefulWidget {
  const AccountLedgerTab({super.key});

  @override
  ConsumerState<AccountLedgerTab> createState() => _AccountLedgerTabState();
}

class _AccountLedgerTabState extends ConsumerState<AccountLedgerTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final filter = ref.read(accountLedgerFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: parseDateKey(filter.from),
        end: parseDateKey(filter.to),
      ),
    );
    if (picked != null) {
      ref
          .read(accountLedgerFilterProvider.notifier)
          .setRange(dateKey(picked.start), dateKey(picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(ledgerAccountsProvider);
    final filter = ref.watch(accountLedgerFilterProvider);
    final effectiveId = ref.watch(effectiveLedgerAccountIdProvider);

    return accountsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorState(error: e),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: 'No accounts yet. Add an account to see its ledger.',
          );
        }
        final ledgerAsync = ref.watch(accountLedgerProvider);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey('acc-$effectiveId'),
                    initialValue: effectiveId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            a.isActive ? a.name : '${a.name} (inactive)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(accountLedgerFilterProvider.notifier)
                            .selectAccount(v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          decoration: InputDecoration(
                            hintText: 'Search title, remarks, category, item',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: filter.search.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _search.clear();
                                      ref
                                          .read(
                                            accountLedgerFilterProvider
                                                .notifier,
                                          )
                                          .setSearch('');
                                    },
                                  ),
                          ),
                          onChanged: (v) => ref
                              .read(accountLedgerFilterProvider.notifier)
                              .setSearch(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range),
                        label: Text('${filter.from} - ${filter.to}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ledgerAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorState(error: e),
                data: (ledger) => ledger == null
                    ? const LoadingView()
                    : _LedgerBody(ledger: ledger),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LedgerBody extends StatelessWidget {
  const _LedgerBody({required this.ledger});
  final AccountLedger ledger;

  static const _columns = [
    LedgerColumn('Date', 96),
    LedgerColumn('Description', 190),
    LedgerColumn('Income', 104, numeric: true),
    LedgerColumn('Expense', 104, numeric: true),
    LedgerColumn('Transfer In', 104, numeric: true),
    LedgerColumn('Transfer Out', 104, numeric: true),
    LedgerColumn('Balance', 120, numeric: true),
  ];

  Widget _amount(BuildContext context, int minor, {Color? color}) => minor == 0
      ? const SizedBox.shrink()
      : Text(formatMinor(minor), style: TextStyle(color: color));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ledger.rows;
    return Column(
      children: [
        if (!ledger.hasMovements)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'No transactions in this period.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        Expanded(
          child: LedgerTable(
            columns: _columns,
            rowCount: rows.length,
            onRowTap: (i) {
              final r = rows[i];
              if (!r.isOpening) context.push('/transactions/${r.id}');
            },
            rowBuilder: (context, i) {
              final r = rows[i];
              return [
                Text(r.date),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: r.isOpening
                          ? const TextStyle(fontWeight: FontWeight.w600)
                          : null,
                    ),
                    if (r.detail.isNotEmpty)
                      Text(
                        r.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
                _amount(context, r.incomeMinor, color: AppColors.income),
                _amount(context, r.expenseMinor, color: AppColors.expense),
                _amount(context, r.transferInMinor, color: AppColors.income),
                _amount(context, r.transferOutMinor, color: AppColors.expense),
                Text(
                  formatMinor(r.balanceMinor),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: r.balanceMinor < 0 ? theme.colorScheme.error : null,
                  ),
                ),
              ];
            },
            footer: [
              const SizedBox.shrink(),
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(formatMinor(ledger.totalIncomeMinor)),
              Text(formatMinor(ledger.totalExpenseMinor)),
              Text(formatMinor(ledger.totalTransferInMinor)),
              Text(formatMinor(ledger.totalTransferOutMinor)),
              Text(
                formatMinor(ledger.closingBalanceMinor),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
