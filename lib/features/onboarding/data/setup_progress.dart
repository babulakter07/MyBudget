import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';

/// Which first-run steps the active profile has completed.
class SetupProgress {
  const SetupProgress({
    required this.hasAccount,
    required this.hasCategory,
    required this.hasBudget,
    required this.hasTransaction,
  });

  final bool hasAccount;
  final bool hasCategory;
  final bool hasBudget;
  final bool hasTransaction;

  static const total = 4;

  int get doneCount => [
    hasAccount,
    hasCategory,
    hasBudget,
    hasTransaction,
  ].where((d) => d).length;

  bool get complete => doneCount == total;
}

/// Live setup progress of the active profile (every query filters
/// `profile_id`; soft-deleted transactions and inactive rows do not count).
final setupProgressProvider = StreamProvider<SetupProgress?>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return Stream.value(null);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM accounts WHERE profile_id = ?1 AND is_active = 1) AS a, '
        '(SELECT COUNT(*) FROM categories WHERE profile_id = ?1 AND is_active = 1) AS c, '
        '(SELECT COUNT(*) FROM monthly_budgets WHERE profile_id = ?1 '
        'AND year = ?2 AND month = ?3 AND total_budget_minor > 0) AS b, '
        '(SELECT COUNT(*) FROM financial_transactions WHERE profile_id = ?1 '
        'AND is_deleted = 0) AS t',
        variables: [
          Variable.withInt(profileId),
          Variable.withInt(now.year),
          Variable.withInt(now.month),
        ],
        readsFrom: {
          db.accounts,
          db.categories,
          db.monthlyBudgets,
          db.financialTransactions,
        },
      )
      .watchSingle()
      .map(
        (r) => SetupProgress(
          hasAccount: r.read<int>('a') > 0,
          hasCategory: r.read<int>('c') > 0,
          hasBudget: r.read<int>('b') > 0,
          hasTransaction: r.read<int>('t') > 0,
        ),
      );
});

const _dismissedKey = 'setup_guide_dismissed';

/// Whether the user hid the home-screen setup card (persisted).
class SetupGuideDismissedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_dismissedKey) ?? false;

  Future<void> set(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(_dismissedKey, v);
    state = v;
  }
}

final setupGuideDismissedProvider =
    NotifierProvider<SetupGuideDismissedNotifier, bool>(
      SetupGuideDismissedNotifier.new,
    );
