import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/budgets/presentation/budget_view.dart';
import '../../features/dashboard/presentation/dashboard_view.dart';
import '../../features/ledger/presentation/ledger_view.dart';
import '../../features/reports/presentation/reports_view.dart';
import '../../features/transactions/presentation/add_transaction_view.dart';
import '../../features/onboarding/presentation/backup_reminder_card.dart';
import '../../features/onboarding/presentation/setup_guide_card.dart';
import '../../l10n/l10n.dart';
import 'home_tab_provider.dart';
import 'more_sheet.dart';

/// Bottom-nav shell: Home, Budget, Add, Ledger, Reports.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabProvider);
    final l10n = context.l10n;
    final titles = [
      l10n.appShellTabHome,
      l10n.appShellTabBudget,
      l10n.appShellTabAdd,
      l10n.appShellTabLedger,
      l10n.appShellTabReports,
    ];
    final pages = <Widget>[
      const DashboardView(),
      const BudgetView(),
      const AddTransactionView(),
      const LedgerView(),
      const ReportsView(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            tooltip: l10n.appShellMore,
            icon: const Icon(Icons.apps),
            onPressed: () => showMoreSheet(context),
          ),
          IconButton(
            tooltip: l10n.commonSearch,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: l10n.appShellSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (index == HomeTab.home) const SetupGuideCard(),
          if (index == HomeTab.home) const BackupReminderCard(),
          Expanded(
            child: IndexedStack(index: index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).select(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: titles[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: titles[2],
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: titles[3],
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: titles[4],
          ),
        ],
      ),
    );
  }
}
