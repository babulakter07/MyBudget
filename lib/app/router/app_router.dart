import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/categories/presentation/category_list_screen.dart';
import '../../features/cost_items/presentation/cost_item_list_screen.dart';
import '../../features/accounts/presentation/account_list_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/reports/presentation/custom_range_report_screen.dart';
import '../../features/reports/presentation/monthly_report_screen.dart';
import '../../features/reports/presentation/yearly_report_screen.dart';
import '../../features/transactions/presentation/edit_transaction_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../shell/about_screen.dart';
import '../shell/home_shell.dart';
import '../../features/profiles/data/profile_providers.dart';
import '../../features/profiles/presentation/profile_create_screen.dart';
import '../../features/profiles/presentation/profile_selection_screen.dart';
import '../shell/settings_screen.dart';
import '../../features/sub_categories/presentation/sub_category_list_screen.dart';
import '../../shared/providers/core_providers.dart';
import '../../features/currency/presentation/exchange_rates_screen.dart';
import '../../features/debts/presentation/debt_detail_screen.dart';
import '../../features/debts/presentation/debt_list_screen.dart';
import '../../features/goals/presentation/goal_list_screen.dart';
import '../../features/import/presentation/csv_import_screen.dart';
import '../../features/help/presentation/user_manual_screen.dart';
import '../../features/onboarding/presentation/setup_guide_screen.dart';
import '../../features/transactions/presentation/split_expense_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/preferences/preferences.dart';
import '../../features/recurring/presentation/recurring_list_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/security/security.dart';
import '../../features/tags/presentation/tag_list_screen.dart';
import '../../features/tags/presentation/tag_report_screen.dart';

/// Pure redirect decision, exposed for testing.
String? profileRedirect({
  required String location,
  required int? activeId,
  required bool profilesLoaded,
  required bool activeIsValid,
}) {
  final onProfileRoute = location == '/profiles' || location == '/profiles/new';
  if (onProfileRoute) return null;
  if (activeId == null) return '/profiles';
  // While profiles are loading we cannot judge validity yet.
  if (!profilesLoaded) return null;
  if (!activeIsValid) return '/profiles';
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(activeProfileIdProvider, (_, _) => refresh.value++);
  ref.listen(profilesStreamProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final activeId = ref.read(activeProfileIdProvider);
      final profiles = ref.read(profilesStreamProvider);
      final list = profiles.asData?.value;
      final valid =
          list != null &&
          activeId != null &&
          list.any((p) => p.id == activeId && p.isActive);
      return profileRedirect(
        location: state.matchedLocation,
        activeId: activeId,
        profilesLoaded: list != null,
        activeIsValid: valid,
      );
    },
    routes: [
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const ProfileSelectionScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const ProfileCreateScreen()),
        ],
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(
        path: '/config/categories',
        builder: (_, _) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/config/sub-categories',
        builder: (_, _) => const SubCategoryListScreen(),
      ),
      GoRoute(
        path: '/config/cost-items',
        builder: (_, _) => const CostItemListScreen(),
      ),
      GoRoute(
        path: '/config/accounts',
        builder: (_, _) => const AccountListScreen(),
      ),
      GoRoute(
        path: '/transactions/split',
        builder: (_, _) => const SplitExpenseScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (_, state) => TransactionDetailScreen(
          transactionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => EditTransactionScreen(
              transactionId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/reports/monthly',
        builder: (_, state) => MonthlyReportScreen(
          year: int.tryParse(state.uri.queryParameters['year'] ?? ''),
          month: int.tryParse(state.uri.queryParameters['month'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/reports/yearly',
        builder: (_, state) => YearlyReportScreen(
          year: int.tryParse(state.uri.queryParameters['year'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/reports/range',
        builder: (_, _) => const CustomRangeReportScreen(),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
      GoRoute(path: '/goals', builder: (_, _) => const GoalListScreen()),
      GoRoute(
        path: '/debts',
        builder: (_, _) => const DebtListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => DebtDetailScreen(
              debtId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/config/recurring',
        builder: (_, _) => const RecurringListScreen(),
      ),
      GoRoute(
        path: '/config/currencies',
        builder: (_, _) => const ExchangeRatesScreen(),
      ),
      GoRoute(path: '/config/tags', builder: (_, _) => const TagListScreen()),
      GoRoute(path: '/tags/report', builder: (_, _) => const TagReportScreen()),
      GoRoute(path: '/setup', builder: (_, _) => const SetupGuideScreen()),
      GoRoute(
        path: '/help',
        builder: (_, state) => UserManualScreen(
          initialTopicId: state.uri.queryParameters['topic'],
        ),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (_, _) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/preferences',
        builder: (_, _) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/import',
        builder: (_, _) => const CsvImportScreen(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (_, _) => const BackupScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
