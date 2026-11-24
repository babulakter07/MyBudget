import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:quick_actions/quick_actions.dart';

import '../../core/logging/app_logger.dart';
import '../../features/attachments/providers/attachment_providers.dart';
import '../../features/notifications/data/notification_providers.dart';
import '../../features/recurring/providers/recurring_providers.dart';
import '../../shared/providers/core_providers.dart';
import '../router/app_router.dart';
import '../shell/home_tab_provider.dart';

/// Emits a fingerprint that changes whenever transactions, recurring rules or
/// debts of the active profile change. Used to re-evaluate budget alerts and
/// reschedule reminders without touching each feature's save flow.
final dataChangeFingerprintProvider = StreamProvider<String>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return const Stream<String>.empty();
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM financial_transactions WHERE profile_id = ?1) AS t, '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM recurring_rules WHERE profile_id = ?1) AS r, '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM debts WHERE profile_id = ?1) AS d, '
        '(SELECT COUNT(*) FROM debt_payments WHERE profile_id = ?1) AS dp, '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM loans WHERE profile_id = ?1) AS l, '
        '(SELECT COUNT(*) FROM loan_payments WHERE profile_id = ?1 AND is_deleted = 0) AS lp, '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM credit_card_bills WHERE profile_id = ?1) AS b, '
        '(SELECT COUNT(*) FROM credit_card_payments WHERE profile_id = ?1 AND is_deleted = 0) AS cp, '
        '(SELECT COUNT(*) || \':\' || IFNULL(MAX(updated_at), 0) FROM fixed_deposit_terms WHERE profile_id = ?1) AS fd',
        variables: [Variable.withInt(profileId)],
        readsFrom: {
          db.financialTransactions,
          db.recurringRules,
          db.debts,
          db.debtPayments,
          db.loans,
          db.loanPayments,
          db.creditCardBills,
          db.creditCardPayments,
          db.fixedDepositTerms,
        },
      )
      .watchSingle()
      .map(
        (r) =>
            '${r.read<String>('t')}|${r.read<String>('r')}|'
            '${r.read<String>('d')}|${r.read<int>('dp')}|'
            '${r.read<String>('l')}|${r.read<int>('lp')}|'
            '${r.read<String>('b')}|${r.read<int>('cp')}|'
            '${r.read<String>('fd')}',
      );
});

/// Runs background chores: initialise notifications, post due recurring
/// transactions (start / resume / profile switch) and keep reminders and
/// budget alerts current. Wrap the app with this; it renders [child] as is.
class AppTasks extends ConsumerStatefulWidget {
  const AppTasks({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppTasks> createState() => _AppTasksState();
}

class _AppTasksState extends ConsumerState<AppTasks>
    with WidgetsBindingObserver {
  bool _gatewayReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAll();
      _initShortcuts();
    });
  }

  /// Launcher long-press shortcuts: jump straight to the Add tab.
  Future<void> _initShortcuts() async {
    await _guard('shortcuts', () async {
      const qa = QuickActions();
      await qa.initialize((type) {
        if (!mounted) return;
        ref.read(homeTabProvider.notifier).select(HomeTab.add);
        ref.read(appRouterProvider).go('/home');
      });
      await qa.setShortcutItems(const [
        ShortcutItem(
          type: 'add_expense',
          localizedTitle: 'Add expense',
          icon: 'ic_launcher',
        ),
        ShortcutItem(
          type: 'add_income',
          localizedTitle: 'Add income',
          icon: 'ic_launcher',
        ),
      ]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runAll();
  }

  Future<void> _guard(String what, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      AppLogger.instance?.logError(e, st, context: 'AppTasks.$what');
      debugPrint('AppTasks.$what failed: $e');
    }
  }

  Future<void> _ensureGateway() async {
    if (_gatewayReady) return;
    await ref.read(notificationGatewayProvider).init();
    _gatewayReady = true;
  }

  Future<void> _runAll() async {
    if (!mounted || ref.read(activeProfileIdProvider) == null) return;
    await _guard('attachments', () async {
      await ref
          .read(attachmentRepositoryProvider)
          .purgeDeletedTransactionAttachments();
    });
    await _guard('recurring', () async {
      await ref.read(recurringGenerationProvider.notifier).run();
    });
    await _resync();
  }

  Future<void> _resync() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (!mounted || profileId == null) return;
    await _guard('notifications', () async {
      await _ensureGateway();
      await ref.read(notificationSchedulerProvider).resync();
      await ref.read(budgetAlertServiceProvider).evaluate(profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(activeProfileIdProvider, (_, _) => _runAll());
    ref.listen<AsyncValue<String>>(dataChangeFingerprintProvider, (prev, next) {
      // Skip the very first emission (covered by _runAll on start).
      if (prev == null || !prev.hasValue || !next.hasValue) return;
      if (prev.value != next.value) _resync();
    });
    return widget.child;
  }
}
