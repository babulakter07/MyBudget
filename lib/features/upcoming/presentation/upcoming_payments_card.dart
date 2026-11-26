import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/upcoming_payment.dart';
import '../providers/upcoming_providers.dart';

const _collapsedRows = 4;

/// Home card listing what must be paid. Hidden when nothing is overdue or due
/// within 30 days.
class UpcomingPaymentsCard extends ConsumerStatefulWidget {
  const UpcomingPaymentsCard({super.key});

  @override
  ConsumerState<UpcomingPaymentsCard> createState() =>
      _UpcomingPaymentsCardState();
}

class _UpcomingPaymentsCardState extends ConsumerState<UpcomingPaymentsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(upcomingPaymentsProvider).value;
    if (all == null || all.isEmpty) return const SizedBox.shrink();
    final window = ref.watch(upcomingWindowProvider);
    final now = ref.watch(upcomingClockProvider)();
    final lastDay = dateKey(DateTime(now.year, now.month, now.day + window));
    final shown = [
      for (final p in all)
        if (p.overdue || p.dueDate.compareTo(lastDay) <= 0) p,
    ];
    var overdue = 0, coming = 0;
    for (final p in shown) {
      if (p.overdue) {
        overdue += p.amountMinor;
      } else {
        coming += p.amountMinor;
      }
    }
    final rows = _expanded ? shown : shown.take(_collapsedRows).toList();
    final theme = Theme.of(context);
    final l = context.l10n;
    return Card(
      key: const ValueKey('upcoming-card'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.upcomingTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final days in upcomingWindowChoices)
                        ChoiceChip(
                          label: Text(l.upcomingNextDays(days)),
                          selected: window == days,
                          onSelected: (_) {
                            setState(() => _expanded = false);
                            ref
                                .read(upcomingWindowProvider.notifier)
                                .select(days);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (overdue > 0)
                    Text(
                      l.upcomingOverdueTotal(formatMinor(overdue)),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.expense,
                      ),
                    ),
                  Text(
                    coming > 0
                        ? l.upcomingDueTotal(formatMinor(coming), window)
                        : l.upcomingNothingDue(window),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            for (final p in rows) _UpcomingTile(payment: p, today: now),
            if (shown.length > _collapsedRows)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? l.upcomingShowLess
                        : l.upcomingShowAll(shown.length),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.payment, required this.today});

  final UpcomingPayment payment;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = payment;
    final (icon, kind) = switch (p.kind) {
      UpcomingKind.loan => (Icons.account_balance_outlined, l.upcomingLoan),
      UpcomingKind.card => (Icons.credit_card, l.upcomingCard),
      UpcomingKind.debt => (Icons.handshake_outlined, l.upcomingDebt),
      UpcomingKind.recurring => (Icons.event_repeat, l.upcomingRecurring),
      UpcomingKind.dps => (Icons.savings, l.upcomingDps),
    };
    final String when;
    if (p.overdue) {
      when = l.upcomingOverdueSince(p.dueDate);
    } else if (p.dueDate == dateKey(today)) {
      when = l.upcomingDueToday;
    } else if (p.dueDate ==
        dateKey(DateTime(today.year, today.month, today.day + 1))) {
      when = l.upcomingDueTomorrow;
    } else {
      when = l.upcomingDueOn(p.dueDate);
    }
    final color = p.overdue ? AppColors.expense : null;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: color),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [kind, when, if (p.count > 1) l.upcomingCount(p.count)].join(' · '),
        style: TextStyle(color: color),
      ),
      trailing: Text(
        formatMinor(p.amountMinor),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
      onTap: () => context.push(p.route),
    );
  }
}
