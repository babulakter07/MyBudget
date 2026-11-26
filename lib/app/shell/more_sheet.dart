import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';

/// "More" menu on the home screen: day-to-day operations (loans, cards,
/// debts, wallets, goals, recurring tasks, reports-like views). Pure
/// settings stay in the Settings screen.
Future<void> showMoreSheet(BuildContext context) {
  final l = context.l10n;
  final items = <(IconData, String, String)>[
    (
      Icons.schedule_outlined,
      l.notificationsViewSchedule,
      '/notifications/schedule',
    ),
    (Icons.repeat, l.appShellRecurring, '/config/recurring'),
    (Icons.account_balance_outlined, l.appShellBankLoans, '/loans'),
    (Icons.savings, l.dpsTitle, '/dps'),
    (Icons.lock_clock_outlined, l.appShellFixedDeposits, '/fd'),
    (Icons.credit_card, l.appShellCreditCards, '/cards'),
    (Icons.handshake_outlined, l.appShellDebtsLoans, '/debts'),
    (Icons.account_balance_wallet_outlined, l.appShellWallets, '/wallets'),
    (Icons.savings_outlined, l.appShellSavingsGoals, '/goals'),
    (Icons.insights_outlined, l.appShellInsights, '/insights'),
    (Icons.local_offer_outlined, l.appShellTagReport, '/tags/report'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l.appShellSectionOperations,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final (icon, title, route) in items)
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(route);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
