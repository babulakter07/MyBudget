import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logging/app_logger.dart';
import '../../l10n/l10n.dart';

Future<void> _shareErrorLog(BuildContext context) async {
  final files = AppLogger.instance?.files() ?? const [];
  if (files.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.appShellNoErrorsLogged)),
    );
    return;
  }
  await SharePlus.instance.share(
    ShareParams(
      subject: 'MyBudget error log',
      files: [for (final f in files) XFile(f.path)],
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tile(IconData icon, String title, String route) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appShellSettings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.appShellSectionMaster,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          tile(
            Icons.category_outlined,
            l10n.appShellCategories,
            '/config/categories',
          ),
          tile(
            Icons.account_tree_outlined,
            l10n.appShellSubCategories,
            '/config/sub-categories',
          ),
          tile(
            Icons.list_alt_outlined,
            l10n.appShellCostItems,
            '/config/cost-items',
          ),
          tile(
            Icons.account_balance_wallet_outlined,
            l10n.appShellAccounts,
            '/config/accounts',
          ),
          tile(Icons.people_outline, l10n.appShellProfiles, '/profiles'),
          tile(Icons.sell_outlined, l10n.appShellTags, '/config/tags'),
          tile(
            Icons.currency_exchange,
            l10n.appShellExchangeRates,
            '/config/currencies',
          ),
          tile(Icons.repeat, l10n.appShellRecurring, '/config/recurring'),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.appShellSectionPlan,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          tile(Icons.savings_outlined, l10n.appShellSavingsGoals, '/goals'),
          tile(
            Icons.account_balance_wallet_outlined,
            l10n.appShellWallets,
            '/wallets',
          ),
          tile(
            Icons.account_balance_outlined,
            l10n.appShellBankLoans,
            '/loans',
          ),
          tile(Icons.credit_card, l10n.appShellCreditCards, '/cards'),
          tile(Icons.handshake_outlined, l10n.appShellDebtsLoans, '/debts'),
          tile(Icons.insights_outlined, l10n.appShellInsights, '/insights'),
          tile(
            Icons.local_offer_outlined,
            l10n.appShellTagReport,
            '/tags/report',
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.appShellSectionApp,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          tile(Icons.checklist_rtl, l10n.setupTitle, '/setup'),
          tile(Icons.lock_outline, l10n.appShellSecurity, '/settings/security'),
          tile(
            Icons.notifications_outlined,
            l10n.appShellNotifications,
            '/settings/notifications',
          ),
          tile(
            Icons.palette_outlined,
            l10n.appShellPreferences,
            '/settings/preferences',
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.appShellSectionData,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          tile(
            Icons.backup_outlined,
            l10n.appShellBackupRestore,
            '/settings/backup',
          ),
          tile(
            Icons.upload_file_outlined,
            l10n.appShellImportCsv,
            '/settings/import',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.appShellShareErrorLog),
            subtitle: Text(l10n.appShellShareErrorLogSubtitle),
            onTap: () => _shareErrorLog(context),
          ),
          tile(
            Icons.menu_book_outlined,
            Localizations.localeOf(context).languageCode == 'bn'
                ? 'ব্যবহার নির্দেশিকা'
                : 'User manual',
            '/help',
          ),
          tile(Icons.info_outline, l10n.appShellAbout, '/about'),
        ],
      ),
    );
  }
}
