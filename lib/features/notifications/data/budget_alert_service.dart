import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../preferences/data/app_l10n_resolver.dart';
import '../domain/notification_models.dart';
import '../domain/notification_settings.dart';
import 'notification_gateway.dart';

/// Fires immediate budget notifications at 80% and 100% of the monthly total
/// and of each category budget, at most once per scope/threshold/month.
class BudgetAlertService {
  BudgetAlertService({
    required this._db,
    required this._prefs,
    required this._gateway,
    AppLocalizations Function()? l10n,
  }) : _l10nOverride = l10n;

  final AppDatabase _db;
  final SharedPreferences _prefs;
  final NotificationGateway _gateway;
  final AppLocalizations Function()? _l10nOverride;

  AppLocalizations _l10n() =>
      _l10nOverride?.call() ?? resolveAppLocalizations(_prefs);

  static String dedupeKey(
    int profileId,
    int year,
    int month,
    String scope,
    int threshold,
  ) =>
      'notif_budget_${profileId}_${year.toString().padLeft(4, '0')}'
      '${two(month)}_${scope}_$threshold';

  /// Never throws: a notification problem must not break saving a txn.
  Future<void> evaluate(int profileId, {DateTime? now}) async {
    try {
      await _evaluate(profileId, now ?? DateTime.now());
    } catch (_) {}
  }

  Future<void> _evaluate(int profileId, DateTime now) async {
    final settings = NotificationSettings.load(_prefs);
    if (!settings.budgetAlertsEnabled) return;
    final y = now.year, m = now.month;
    final from = monthStartKey(y, m), to = monthEndKey(y, m);

    final budgetRows = await _db
        .customSelect(
          'SELECT id, total_budget_minor FROM monthly_budgets '
          'WHERE profile_id = ?1 AND year = ?2 AND month = ?3',
          variables: [
            Variable.withInt(profileId),
            Variable.withInt(y),
            Variable.withInt(m),
          ],
        )
        .get();
    if (budgetRows.isEmpty) return;
    final monthlyId = budgetRows.first.read<int>('id');
    final total = budgetRows.first.read<int>('total_budget_minor');

    final totalSpent =
        (await _db
                .customSelect(
                  '''
SELECT COALESCE(SUM(amount_minor), 0) AS s FROM financial_transactions
WHERE profile_id = ?1 AND is_deleted = 0 AND type = 'expense'
  AND txn_date >= ?2 AND txn_date <= ?3
''',
                  variables: [
                    Variable.withInt(profileId),
                    Variable.withString(from),
                    Variable.withString(to),
                  ],
                )
                .getSingle())
            .read<int>('s');
    await _check(
      profileId,
      y,
      m,
      scope: 'total',
      label: _l10n().notificationsMonthlyBudget,
      budget: total,
      spent: totalSpent,
    );

    final cats = await _db
        .customSelect(
          '''
SELECT cb.category_id AS category_id, cb.amount_minor AS budget,
       (SELECT c.name FROM categories c
        WHERE c.profile_id = cb.profile_id AND c.id = cb.category_id) AS name,
       COALESCE((SELECT SUM(t.amount_minor) FROM financial_transactions t
                 WHERE t.profile_id = cb.profile_id AND t.is_deleted = 0
                   AND t.type = 'expense' AND t.category_id = cb.category_id
                   AND t.txn_date >= ?3 AND t.txn_date <= ?4), 0) AS spent
FROM category_budgets cb
WHERE cb.profile_id = ?1 AND cb.monthly_budget_id = ?2
''',
          variables: [
            Variable.withInt(profileId),
            Variable.withInt(monthlyId),
            Variable.withString(from),
            Variable.withString(to),
          ],
        )
        .get();
    for (final c in cats) {
      await _check(
        profileId,
        y,
        m,
        scope: 'cat${c.read<int>('category_id')}',
        label:
            c.readNullable<String>('name') ??
            _l10n().notificationsCategoryFallback,
        budget: c.read<int>('budget'),
        spent: c.read<int>('spent'),
      );
    }
  }

  Future<void> _check(
    int profileId,
    int year,
    int month, {
    required String scope,
    required String label,
    required int budget,
    required int spent,
  }) async {
    if (budget <= 0) return;
    final crossed100 = spent >= budget;
    final crossed80 = spent * 100 >= budget * 80;
    if (!crossed80) return;

    final k80 = dedupeKey(profileId, year, month, scope, 80);
    final k100 = dedupeKey(profileId, year, month, scope, 100);
    final done80 = _prefs.getBool(k80) ?? false;
    final done100 = _prefs.getBool(k100) ?? false;

    // Highest newly crossed threshold wins; lower ones are marked as covered.
    int? fire;
    if (crossed100 && !done100) {
      fire = 100;
    } else if (!crossed100 && !done80) {
      fire = 80;
    }
    if (fire == null) {
      if (crossed100 && !done80) await _prefs.setBool(k80, true);
      return;
    }

    final spentS = formatMinor(spent), budgetS = formatMinor(budget);
    final l10n = _l10n();
    final title = fire == 100
        ? l10n.notificationsOverBudgetTitle(label)
        : l10n.notificationsBudgetWarningTitle(label);
    final body = fire == 100
        ? l10n.notificationsOverBudgetBody(spentS, budgetS)
        : l10n.notificationsBudgetWarningBody(spentS, budgetS);
    await _gateway.show(
      id: stableNotificationId('budget|$profileId|$year-$month|$scope|$fire'),
      title: title,
      body: body,
      kind: NotificationKind.budget,
    );
    await _prefs.setBool(dedupeKey(profileId, year, month, scope, fire), true);
    if (fire == 100) await _prefs.setBool(k80, true);
  }
}
