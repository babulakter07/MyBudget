import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/debt.dart';
import '../providers/debt_providers.dart';
import 'debt_form_sheet.dart';
import 'debt_widgets.dart';

/// Route: /debts
class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _grouped = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _direction => _tabs.index == 0 ? 'lent' : 'borrowed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.debtsListTitle),
        actions: [
          IconButton(
            tooltip: _grouped
                ? context.l10n.debtsShowFlatList
                : context.l10n.debtsGroupByPerson,
            icon: Icon(_grouped ? Icons.view_list : Icons.people_outline),
            onPressed: () => setState(() => _grouped = !_grouped),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: context.l10n.debtsLent),
            Tab(text: context.l10n.debtsBorrowed),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: context.l10n.debtsAddDebt,
        onPressed: () => showDebtForm(context, direction: _direction),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const _SummaryHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DebtTab(direction: 'lent', grouped: _grouped),
                _DebtTab(direction: 'borrowed', grouped: _grouped),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(debtSummaryProvider).value ?? DebtSummary.empty;
    final theme = Theme.of(context);
    Widget cell(String label, int minor, Color? color) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            formatMinor(minor),
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            cell(context.l10n.debtsIAmOwed, s.owedToMeMinor, AppColors.income),
            cell(context.l10n.debtsIOwe, s.iOweMinor, AppColors.expense),
            cell(context.l10n.debtsNet, s.netMinor, null),
          ],
        ),
      ),
    );
  }
}

class _DebtTab extends ConsumerWidget {
  const _DebtTab({required this.direction, required this.grouped});
  final String direction;
  final bool grouped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debtsByDirectionProvider(direction));
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(debtsByDirectionProvider(direction)),
      ),
      data: (debts) {
        if (debts.isEmpty) {
          return EmptyState(
            icon: Icons.handshake_outlined,
            message: direction == 'lent'
                ? context.l10n.debtsNoLent
                : context.l10n.debtsNoBorrowed,
          );
        }
        final children = grouped ? _groupedChildren(debts) : null;
        return ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: children ?? [for (final d in debts) DebtTile(debt: d)],
        );
      },
    );
  }

  List<Widget> _groupedChildren(List<Debt> debts) {
    final groups = <String, List<Debt>>{};
    for (final d in debts) {
      groups.putIfAbsent(d.personName.trim().toLowerCase(), () => []).add(d);
    }
    final out = <Widget>[];
    for (final list in groups.values) {
      final total = list.fold<int>(0, (a, d) => a + d.outstandingMinor);
      out.add(_PersonHeader(name: list.first.personName, outstanding: total));
      out.addAll(list.map((d) => DebtTile(debt: d, showPerson: false)));
    }
    return out;
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.name, required this.outstanding});
  final String name;
  final int outstanding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
          Text(formatMinor(outstanding), style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class DebtTile extends StatelessWidget {
  const DebtTile({super.key, required this.debt, this.showPerson = true});
  final Debt debt;
  final bool showPerson;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final due = debt.dueDate == null
        ? l.debtsNoDueDate
        : l.debtsDue(debt.dueDate!);
    return ListTile(
      title: Text(
        showPerson ? debt.personName : l.debtsStarted(debt.startDate),
      ),
      subtitle: Text(
        showPerson
            ? l.debtsDueWithPrincipal(due, formatMinor(debt.principalMinor))
            : due,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMinor(debt.outstandingMinor),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          DebtStatusChip(status: debt.status),
        ],
      ),
      onTap: () => context.push('/debts/${debt.id}'),
    );
  }
}
