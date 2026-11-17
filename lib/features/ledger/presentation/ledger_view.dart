import 'package:material_ui/material_ui.dart';

import 'account_ledger_tab.dart';
import 'budget_ledger_tab.dart';

/// Ledger tab body: Account Ledger / Budget Ledger. No Scaffold of its own.
class LedgerView extends StatelessWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Account Ledger'),
              Tab(text: 'Budget Ledger'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [AccountLedgerTab(), BudgetLedgerTab()],
            ),
          ),
        ],
      ),
    );
  }
}
