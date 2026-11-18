import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

import 'account_ledger_tab.dart';
import 'budget_ledger_tab.dart';

/// Ledger tab body: Account Ledger / Budget Ledger. No Scaffold of its own.
class LedgerView extends StatelessWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: context.l10n.ledgerAccountTab),
              Tab(text: context.l10n.ledgerBudgetTab),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [AccountLedgerTab(), BudgetLedgerTab()],
            ),
          ),
        ],
      ),
    );
  }
}
