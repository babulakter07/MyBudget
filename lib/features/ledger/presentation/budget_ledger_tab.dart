import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/ledger_providers.dart';
import 'ledger_table.dart';
import 'period_pickers.dart';

class BudgetLedgerTab extends ConsumerWidget {
  const BudgetLedgerTab({super.key});

  static const _columns = [
    LedgerColumn('Date', 96),
    LedgerColumn('Cost Item', 170),
    LedgerColumn('Category', 140),
    LedgerColumn('Expense', 110, numeric: true),
    LedgerColumn('Remaining Budget', 150, numeric: true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(budgetLedgerMonthProvider);
    final notifier = ref.read(budgetLedgerMonthProvider.notifier);
    final ledgerAsync = ref.watch(budgetLedgerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    notifier.set(DateTime(month.year, month.month - 1)),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showMonthYearPicker(
                    context,
                    initial: month,
                  );
                  if (picked != null) notifier.set(picked);
                },
                child: Text(monthLabel(month)),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    notifier.set(DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ledgerAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorState(error: e),
            data: (ledger) {
              if (ledger == null) return const LoadingView();
              final rows = ledger.rows;
              final errorColor = theme.colorScheme.error;
              Widget remainingText(int? v, {bool bold = false}) => v == null
                  ? Text('No budget', style: theme.textTheme.bodySmall)
                  : Text(
                      formatMinor(v),
                      style: TextStyle(
                        color: v < 0 ? errorColor : null,
                        fontWeight: bold ? FontWeight.bold : null,
                      ),
                    );
              return Column(
                children: [
                  if (ledger.budgetMinor == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'No budget set for this month.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Monthly budget: ${formatMinor(ledger.budgetMinor!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  Expanded(
                    child: rows.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: 'No expenses in this month.',
                          )
                        : LedgerTable(
                            columns: _columns,
                            rowCount: rows.length,
                            onRowTap: (i) =>
                                context.push('/transactions/${rows[i].id}'),
                            rowBuilder: (context, i) {
                              final r = rows[i];
                              return [
                                Text(r.date),
                                Text(r.costItem),
                                Text(r.category),
                                Text(
                                  formatMinor(r.expenseMinor),
                                  style: const TextStyle(
                                    color: AppColors.expense,
                                  ),
                                ),
                                remainingText(r.remainingMinor),
                              ];
                            },
                            footer: [
                              const SizedBox.shrink(),
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox.shrink(),
                              Text(formatMinor(ledger.totalExpenseMinor)),
                              remainingText(ledger.remainingMinor, bold: true),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
