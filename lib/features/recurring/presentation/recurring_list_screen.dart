import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_models.dart';
import '../providers/recurring_providers.dart';
import 'recurring_form_sheet.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final async = ref.watch(recurringRulesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recurringTitle)),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: context.l10n.recurringAddTooltip,
              onPressed: () => showRecurringForm(context),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(
              icon: Icons.person_off,
              message: context.l10n.recurringNoProfile,
            )
          : async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(recurringRulesProvider),
              ),
              data: (rules) => rules.isEmpty
                  ? EmptyState(
                      icon: Icons.repeat,
                      message: context.l10n.recurringEmpty,
                    )
                  : ListView.builder(
                      itemCount: rules.length,
                      itemBuilder: (_, i) => _RuleTile(rule: rules[i]),
                    ),
            ),
    );
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});
  final RecurringRule rule;

  String _every(BuildContext context) {
    final f = recurrenceFrequencyLabel(context.l10n, rule.frequency);
    return rule.intervalCount == 1
        ? f
        : context.l10n.recurringEveryN(f, rule.intervalCount);
  }

  String _status(BuildContext context) {
    final l10n = context.l10n;
    if (rule.isCompleted) return l10n.recurringStatusEnded;
    if (!rule.isActive) return l10n.recurringStatusPaused;
    return l10n.recurringStatusNext(rule.nextDueDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = !rule.isActive;
    return ListTile(
      key: ValueKey('rule-${rule.id}'),
      leading: Icon(switch (rule.type) {
        'income' => Icons.arrow_downward,
        'transfer' => Icons.swap_horiz,
        _ => Icons.arrow_upward,
      }, color: muted ? scheme.outline : null),
      title: Text(rule.title),
      subtitle: Text('${_every(context)} · ${_status(context)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinor(rule.amountMinor),
            style: TextStyle(color: muted ? scheme.outline : null),
          ),
          if (!rule.isCompleted)
            IconButton(
              tooltip: rule.isActive
                  ? context.l10n.recurringPause
                  : context.l10n.recurringResume,
              icon: Icon(
                rule.isActive ? Icons.pause_circle_outline : Icons.play_circle,
              ),
              onPressed: () => _toggle(context, ref),
            ),
        ],
      ),
      onTap: () => showRecurringForm(context, existing: rule),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(recurringRepositoryProvider)
          .setActive(rule.profileId, rule.id, !rule.isActive);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

/// Localized display label of a stored frequency value.
String recurrenceFrequencyLabel(AppLocalizations l10n, String f) => switch (f) {
  RecurrenceFrequency.daily => l10n.recurringFreqDaily,
  RecurrenceFrequency.weekly => l10n.recurringFreqWeekly,
  RecurrenceFrequency.monthly => l10n.recurringFreqMonthly,
  RecurrenceFrequency.yearly => l10n.recurringFreqYearly,
  _ => f,
};
