import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/widgets.dart';
import '../../features/profiles/data/profile_providers.dart';

/// Bottom-nav shell: Home, Budget, Add, Ledger, Reports.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titles = ['Home', 'Budget', 'Add', 'Ledger', 'Reports'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      for (final t in _titles.skip(1)) _ComingSoon(title: t),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.construction_outlined,
    message: '$title - coming soon',
  );
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProfileProvider);
    return active.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorState(error: e),
      data: (profile) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(profile?.name ?? 'No profile'),
              subtitle: Text(profile?.currencyCode ?? ''),
              trailing: TextButton.icon(
                onPressed: () => context.go('/profiles'),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Switch'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const EmptyState(
            icon: Icons.construction_outlined,
            message: 'Dashboard - coming soon',
          ),
        ],
      ),
    );
  }
}
