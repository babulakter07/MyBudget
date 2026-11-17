import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/budget.dart';
import '../providers/budget_providers.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Budget tab body (no Scaffold; lives inside the home shell).
class BudgetView extends ConsumerWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final async = ref.watch(budgetSummaryProvider);

    return Column(
      children: [
        _MonthPicker(month: month),
        Expanded(
          child: profileId == null
              ? const EmptyState(
                  icon: Icons.person_off,
                  message: 'Select a profile to manage budgets.',
                )
              : async.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorState(error: e),
                  data: (mb) => mb.hasBudget
                      ? _Populated(mb: mb, profileId: profileId)
                      : _Empty(month: month, profileId: profileId),
                ),
        ),
      ],
    );
  }
}

class _MonthPicker extends ConsumerWidget {
  const _MonthPicker({required this.month});
  final SelectedMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(selectedBudgetMonthProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: notifier.previous,
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(month.year, month.month),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Select any day in the month',
            );
            if (picked != null) notifier.set(picked.year, picked.month);
          },
          child: Text('${_monthNames[month.month - 1]} ${month.year}'),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: notifier.next,
        ),
      ],
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.month, required this.profileId});
  final SelectedMonth month;
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.savings_outlined,
      message: 'New month: set a budget; nothing carries over.',
      action: FilledButton(
        onPressed: () => _showBudgetDialog(context, ref, profileId, month, 0),
        child: const Text('Set budget'),
      ),
    );
  }
}

void _snack(BuildContext context, Object e) {
  final msg = e is AppException ? e.message : 'Something went wrong: $e';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> _showBudgetDialog(
  BuildContext context,
  WidgetRef ref,
  int profileId,
  SelectedMonth month,
  int currentMinor,
) async {
  final minor = await showDialog<int>(
    context: context,
    builder: (_) => _AmountDialog(
      title: 'Monthly budget',
      label: 'Total budget',
      initialMinor: currentMinor,
    ),
  );
  if (minor == null) return;
  try {
    await ref
        .read(budgetRepositoryProvider)
        .setMonthlyBudget(
          profileId: profileId,
          year: month.year,
          month: month.month,
          totalMinor: minor,
        );
  } catch (e) {
    if (context.mounted) _snack(context, e);
  }
}

class _Populated extends ConsumerWidget {
  const _Populated({required this.mb, required this.profileId});
  final MonthBudget mb;
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = SelectedMonth(mb.year, mb.month);
    final s = mb.summary;
    final theme = Theme.of(context);
    final remColor = s.isOverspent ? AppColors.expense : null;
    final progress = (s.utilizationPercent / 100).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Budget', style: theme.textTheme.titleMedium),
                    ),
                    IconButton(
                      tooltip: 'Edit budget',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBudgetDialog(
                        context,
                        ref,
                        profileId,
                        month,
                        s.budgetMinor,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatMinor(s.budgetMinor),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  color: s.isOverspent ? AppColors.expense : null,
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text('${s.utilizationPercent.toStringAsFixed(1)}% used'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(label: 'Spent', value: formatMinor(s.expenseMinor)),
                    _Stat(
                      label: 'Remaining',
                      value: formatMinor(s.remainingMinor),
                      color: remColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Category allocations',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _editAllocation(context, ref, profileId, mb),
              icon: const Icon(Icons.add),
              label: const Text('Add allocation'),
            ),
          ],
        ),
        Text(
          'Allocated ${formatMinor(mb.allocatedMinor)} of '
          '${formatMinor(s.budgetMinor)} (inside the total, not added).',
          style: theme.textTheme.bodySmall,
        ),
        if (mb.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No category allocations for this month.'),
          ),
        for (final c in mb.categories)
          _AllocationTile(
            c: c,
            onEdit: () => _editAllocation(context, ref, profileId, mb, c),
            onRemove: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Remove allocation?',
                message: 'Remove the allocation for "${c.categoryName}"?',
                confirmLabel: 'Remove',
              );
              if (!ok) return;
              try {
                await ref
                    .read(budgetRepositoryProvider)
                    .removeCategoryAllocation(
                      profileId: profileId,
                      year: mb.year,
                      month: mb.month,
                      categoryId: c.categoryId,
                    );
              } catch (e) {
                if (context.mounted) _snack(context, e);
              }
            },
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({
    required this.c,
    required this.onEdit,
    required this.onRemove,
  });
  final CategoryBudgetSummary c;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final over = c.remainingMinor < 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(c.categoryName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (c.summary.utilizationPercent / 100).clamp(0.0, 1.0),
            color: over ? AppColors.expense : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Spent ${formatMinor(c.spentMinor)} of ${formatMinor(c.allocationMinor)}',
          ),
          Text(
            'Remaining ${formatMinor(c.remainingMinor)}',
            style: over ? const TextStyle(color: AppColors.expense) : null,
          ),
        ],
      ),
      onTap: onEdit,
      trailing: IconButton(
        tooltip: 'Remove allocation',
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}

Future<void> _editAllocation(
  BuildContext context,
  WidgetRef ref,
  int profileId,
  MonthBudget mb, [
  CategoryBudgetSummary? existing,
]) async {
  final repo = ref.read(budgetRepositoryProvider);
  List<CategoryOption> options;
  if (existing != null) {
    options = [
      CategoryOption(id: existing.categoryId, name: existing.categoryName),
    ];
  } else {
    final used = mb.categories.map((c) => c.categoryId).toSet();
    options = (await repo.activeCategories(profileId))
        .where((o) => !used.contains(o.id))
        .toList();
    if (options.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active categories left to allocate.'),
          ),
        );
      }
      return;
    }
  }
  if (!context.mounted) return;
  final result = await showDialog<(int, int)>(
    context: context,
    builder: (_) => _AllocationDialog(
      options: options,
      initialCategoryId: existing?.categoryId,
      initialMinor: existing?.allocationMinor ?? 0,
      lockCategory: existing != null,
    ),
  );
  if (result == null) return;
  try {
    await repo.setCategoryAllocation(
      profileId: profileId,
      year: mb.year,
      month: mb.month,
      categoryId: result.$1,
      amountMinor: result.$2,
    );
  } catch (e) {
    if (context.mounted) _snack(context, e);
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.label,
    required this.initialMinor,
  });
  final String title;
  final String label;
  final int initialMinor;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initialMinor == 0
        ? ''
        : (widget.initialMinor / 100).toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final m = parseMajorToMinor(_c.text);
            if (m == null) {
              setState(() => _error = 'Enter a valid amount (max 2 decimals)');
              return;
            }
            Navigator.pop(context, m);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AllocationDialog extends StatefulWidget {
  const _AllocationDialog({
    required this.options,
    required this.initialCategoryId,
    required this.initialMinor,
    required this.lockCategory,
  });
  final List<CategoryOption> options;
  final int? initialCategoryId;
  final int initialMinor;
  final bool lockCategory;

  @override
  State<_AllocationDialog> createState() => _AllocationDialogState();
}

class _AllocationDialogState extends State<_AllocationDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initialMinor == 0
        ? ''
        : (widget.initialMinor / 100).toStringAsFixed(2),
  );
  late int _category = widget.initialCategoryId ?? widget.options.first.id;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lockCategory ? 'Edit allocation' : 'Add allocation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final o in widget.options)
                DropdownMenuItem(value: o.id, child: Text(o.name)),
            ],
            onChanged: widget.lockCategory
                ? null
                : (v) => setState(() => _category = v ?? _category),
          ),
          TextField(
            controller: _c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Allocation',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final m = parseMajorToMinor(_c.text);
            if (m == null) {
              setState(() => _error = 'Enter a valid amount (max 2 decimals)');
              return;
            }
            Navigator.pop(context, (_category, m));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
