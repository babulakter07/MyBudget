import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/shell/home_tab_provider.dart';
import '../../../l10n/l10n.dart';
import '../data/setup_progress.dart';

/// Checklist that walks a new user through the first steps.
class SetupGuideScreen extends ConsumerWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(setupProgressProvider);

    void openTab(int tab) {
      ref.read(homeTabProvider.notifier).select(tab);
      context.go('/home');
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          final steps = [
            (
              key: 'account',
              done: p.hasAccount,
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.setupStepAccount,
              body: l10n.setupStepAccountBody,
              go: () => context.push('/config/accounts'),
            ),
            (
              key: 'category',
              done: p.hasCategory,
              icon: Icons.category_outlined,
              title: l10n.setupStepCategory,
              body: l10n.setupStepCategoryBody,
              go: () => context.push('/config/categories'),
            ),
            (
              key: 'budget',
              done: p.hasBudget,
              icon: Icons.pie_chart_outline,
              title: l10n.setupStepBudget,
              body: l10n.setupStepBudgetBody,
              go: () => openTab(HomeTab.budget),
            ),
            (
              key: 'transaction',
              done: p.hasTransaction,
              icon: Icons.add_circle_outline,
              title: l10n.setupStepTransaction,
              body: l10n.setupStepTransactionBody,
              go: () => openTab(HomeTab.add),
            ),
          ];
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                p.complete
                    ? l10n.setupAllDone
                    : l10n.setupProgress(p.doneCount, SetupProgress.total),
                key: const ValueKey('setup-progress-text'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: p.doneCount / SetupProgress.total),
              const SizedBox(height: 16),
              for (final s in steps)
                Card(
                  key: ValueKey('setup-step-${s.key}'),
                  child: ListTile(
                    leading: Icon(
                      s.done ? Icons.check_circle : s.icon,
                      color: s.done ? scheme.primary : null,
                    ),
                    title: Text(
                      s.title,
                      style: s.done
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: Text(s.body),
                    trailing: s.done
                        ? Text(l10n.setupDone)
                        : FilledButton.tonal(
                            key: ValueKey('setup-go-${s.key}'),
                            onPressed: s.go,
                            child: Text(l10n.setupGo),
                          ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('setup-open-manual'),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.setupOpenManual),
                onPressed: () => context.push('/help?topic=start'),
              ),
            ],
          );
        },
      ),
    );
  }
}
