import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../providers/ledger_providers.dart';
import 'ledger_table.dart';
import 'period_pickers.dart';

class BudgetLedgerTab extends ConsumerWidget {
  const BudgetLedgerTab({super.key});

  static List<LedgerColumn> _columns(AppLocalizations l) => [
    LedgerColumn(l.ledgerColDate, 96),
    LedgerColumn(l.ledgerColCostItem, 170),
    LedgerColumn(l.ledgerColCategory, 140),
    LedgerColumn(l.ledgerColExpense, 110, numeric: true),
    LedgerColumn(l.ledgerColRemainingBudget, 150, numeric: true),
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
                tooltip: context.l10n.ledgerPreviousMonth,
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
                tooltip: context.l10n.ledgerNextMonth,
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
                  ? Text(
                      context.l10n.ledgerNoBudget,
                      style: theme.textTheme.bodySmall,
                    )
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
                        context.l10n.ledgerNoBudgetSet,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        context.l10n.ledgerMonthlyBudget(
                          formatMinor(ledger.budgetMinor!),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  Expanded(
                    child: rows.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: context.l10n.ledgerNoExpenses,
                          )
                        : LedgerTable(
                            columns: _columns(context.l10n),
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
                              Text(
                                context.l10n.ledgerTotal,
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
