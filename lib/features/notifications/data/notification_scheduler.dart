import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../dps/data/dps_repository.dart';
import '../../dps/domain/dps.dart';
import '../../fixed_deposits/domain/fixed_deposit_calculator.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/domain/loan_calculator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../preferences/data/app_l10n_resolver.dart';
import '../domain/notification_models.dart';
import '../domain/notification_settings.dart';
import '../domain/reminder_planner.dart';
import 'notification_gateway.dart';

/// Reads reminder inputs straight from SQL (no other feature imports).
class ReminderDataSource {
  ReminderDataSource(this._db);
  final AppDatabase _db;

  Future<List<RecurringReminderInput>> recurring(int profileId) async {
    final rows = await _db
        .customSelect(
          '''
SELECT id, title, amount_minor, frequency, interval_count, start_date,
       end_date, next_due_date, remind_days_before
FROM recurring_rules
WHERE profile_id = ?1 AND is_active = 1
''',
          variables: [Variable.withInt(profileId)],
        )
        .get();
    return [
      for (final r in rows)
        RecurringReminderInput(
          id: r.read<int>('id'),
          title: r.read<String>('title'),
          amountMinor: r.read<int>('amount_minor'),
          frequency: r.read<String>('frequency'),
          intervalCount: r.read<int>('interval_count'),
          startDate: r.read<String>('start_date'),
          endDate: r.readNullable<String>('end_date'),
          nextDueDate: r.read<String>('next_due_date'),
          remindDaysBefore: r.readNullable<int>('remind_days_before'),
        ),
    ];
  }

  Future<List<DebtReminderInput>> debts(int profileId) async {
    final rows = await _db
        .customSelect(
          '''
SELECT d.id AS id, d.direction AS direction, d.person_name AS person_name,
       d.due_date AS due_date,
       d.principal_minor - COALESCE((
         SELECT SUM(p.amount_minor) FROM debt_payments p
         WHERE p.profile_id = d.profile_id AND p.debt_id = d.id
           AND p.is_deleted = 0), 0) AS outstanding
FROM debts d
WHERE d.profile_id = ?1 AND d.is_active = 1 AND d.due_date IS NOT NULL
''',
          variables: [Variable.withInt(profileId)],
        )
        .get();
    return [
      for (final r in rows)
        DebtReminderInput(
          id: r.read<int>('id'),
          direction: r.read<String>('direction'),
          personName: r.read<String>('person_name'),
          outstandingMinor: r.read<int>('outstanding'),
          dueDate: r.read<String>('due_date'),
        ),
    ];
  }
}

extension on ReminderDataSource {
  /// Running (not encashed / reissued) instruments of non-archived deposits.
  Future<List<MaturityReminderInput>> maturities(int profileId) async {
    final rows = await _db
        .customSelect(
          '''
SELECT t.id AS id, d.scheme_type AS scheme_type,
       t.instrument_number AS instrument_number, d.bank_name AS bank_name,
       t.principal_minor AS principal_minor, t.start_date AS start_date,
       t.tenure_days AS tenure_days
FROM fixed_deposit_terms t
JOIN fixed_deposits d ON d.profile_id = t.profile_id AND d.id = t.deposit_id
WHERE t.profile_id = ?1 AND t.outcome = 'active' AND d.is_active = 1
''',
          variables: [Variable.withInt(profileId)],
        )
        .get();
    return [
      for (final r in rows)
        MaturityReminderInput(
          id: r.read<int>('id'),
          schemeType: r.read<String>('scheme_type'),
          instrumentNumber: r.read<String>('instrument_number'),
          bankName: r.read<String>('bank_name'),
          principalMinor: r.read<int>('principal_minor'),
          maturityDate: FixedDepositCalculator.maturityDate(
            r.read<String>('start_date'),
            r.read<int>('tenure_days'),
          ),
        ),
    ];
  }

  /// Unpaid loan and DPS installments, and unpaid credit-card bills.
  Future<List<DueItemInput>> dueItems(
    int profileId,
    AppLocalizations l10n,
  ) async {
    final out = <DueItemInput>[];
    final loans = await LoanRepository(_db).watchAll(profileId).first;
    for (final p in loans) {
      if (p.isClosed) continue;
      for (final i in p.schedule) {
        if (i.status == InstallmentStatus.paid) continue;
        out.add(
          DueItemInput(
            source: 'loan',
            id: p.loan.id,
            name: l10n.notificationsLoanName(p.loan.lenderName, i.no),
            amountMinor: i.unpaidMinor,
            dueDate: i.dueDate,
          ),
        );
      }
    }
    for (final p in await DpsRepository(_db).loadAll(profileId)) {
      if (p.isClosed) continue;
      for (final i in p.schedule) {
        if (i.status == DpsInstallmentStatus.paid) continue;
        out.add(
          DueItemInput(
            source: 'dps',
            id: p.account.id,
            name: l10n.notificationsDpsName(p.terms.bankName, i.no),
            amountMinor: p.terms.installmentMinor,
            dueDate: i.dueDate,
          ),
        );
      }
    }
    final bills = await _db
        .customSelect(
          '''
SELECT b.id AS id, b.due_date AS due_date, c.name AS card_name,
       b.amount_minor - COALESCE((
         SELECT SUM(p.amount_minor) FROM credit_card_payments p
         WHERE p.profile_id = b.profile_id AND p.bill_id = b.id
           AND p.is_deleted = 0), 0) AS remaining
FROM credit_card_bills b
JOIN credit_cards c ON c.profile_id = b.profile_id AND c.id = b.card_id
WHERE b.profile_id = ?1 AND b.is_active = 1 AND c.is_active = 1
''',
          variables: [Variable.withInt(profileId)],
        )
        .get();
    for (final r in bills) {
      final remaining = r.read<int>('remaining');
      if (remaining <= 0) continue;
      out.add(
        DueItemInput(
          source: 'card',
          id: r.read<int>('id'),
          name: l10n.notificationsCardName(r.read<String>('card_name')),
          amountMinor: remaining,
          dueDate: r.read<String>('due_date'),
        ),
      );
    }
    return out;
  }
}

/// Cancels previously scheduled reminders and schedules the planner output.
/// Safe to call repeatedly (ids are deterministic).
class NotificationScheduler {
  NotificationScheduler({
    required AppDatabase db,
    required this._prefs,
    required this._gateway,
    required this._activeProfileId,
    DateTime Function()? clock,
    this._planner = const ReminderPlanner(),
    AppLocalizations Function()? l10n,
  }) : _l10nOverride = l10n,
       _source = ReminderDataSource(db),
       _clock = clock ?? DateTime.now;

  static const trackedIdsKey = 'notif_scheduled_ids';

  final ReminderDataSource _source;
  final SharedPreferences _prefs;
  final NotificationGateway _gateway;
  final int? Function() _activeProfileId;
  final DateTime Function() _clock;
  final ReminderPlanner _planner;

  /// Language for notification text (saved app language by default).
  final AppLocalizations Function()? _l10nOverride;

  AppLocalizations _l10n() =>
      _l10nOverride?.call() ?? resolveAppLocalizations(_prefs);

  Future<void> _chain = Future.value();

  /// Every reminder that would fire in the planning window, each flagged
  /// enabled / switched off by the user. Independent of the master switch so
  /// the schedule screen can always show what is coming.
  Future<List<PlannedNotification>> buildPlan({int? profileId}) async {
    final pid = profileId ?? _activeProfileId();
    if (pid == null) return const [];
    final settings = NotificationSettings.load(_prefs);
    final disabled = NotificationSettings.loadDisabledKeys(_prefs);
    final l10n = _l10n();
    final plan = _planner.plan(
      l10n: l10n,
      now: _clock(),
      rules: await _source.recurring(pid),
      debts: await _source.debts(pid),
      dueItems: await _source.dueItems(pid, l10n),
      maturities: await _source.maturities(pid),
      hour: settings.reminderHour,
      todayEnabled: settings.todayEnabled,
      recurringToday: true,
      upcomingDays: settings.upcomingDays,
      expireAfterDays: settings.expireAfterDays,
      catchUpDone: NotificationSettings.loadCatchUpDone(_prefs),
    );
    return [
      for (final n in plan)
        PlannedNotification(
          id: n.id,
          when: n.when,
          title: n.title,
          body: n.body,
          kind: n.kind,
          key: n.key,
          phase: n.phase,
          dueDate: n.dueDate,
          enabled: !disabled.contains(n.key),
          catchUp: n.catchUp,
        ),
    ];
  }

  /// Rebuilds all scheduled reminders for [profileId] (default: active
  /// profile). Calls are serialised so concurrent resyncs cannot interleave.
  Future<void> resync({int? profileId}) {
    final next = _chain.then((_) => _resync(profileId));
    _chain = next.catchError((Object _) {});
    return next;
  }

  Future<void> _resync(int? profileId) async {
    final tracked = (_prefs.getStringList(trackedIdsKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>();
    for (final id in tracked) {
      await _gateway.cancel(id);
    }
    await _prefs.remove(trackedIdsKey);

    final settings = NotificationSettings.load(_prefs);
    final pid = profileId ?? _activeProfileId();
    if (!settings.remindersEnabled || pid == null) return;

    final plan = (await buildPlan(profileId: pid))
        .where((n) => n.enabled)
        .toList();
    final shownNow = NotificationSettings.loadCatchUpDone(_prefs);
    for (final n in plan) {
      if (n.catchUp) {
        // Its time already passed today: show it now, once.
        await _gateway.show(
          id: n.id,
          title: n.title,
          body: n.body,
          kind: n.kind,
        );
        shownNow.add(n.key);
        continue;
      }
      await _gateway.schedule(
        id: n.id,
        when: n.when,
        title: n.title,
        body: n.body,
        kind: n.kind,
      );
    }
    await NotificationSettings.saveCatchUpDone(_prefs, shownNow);
    await _prefs.setStringList(trackedIdsKey, [
      for (final n in plan)
        if (!n.catchUp) n.id.toString(),
    ]);
  }
}
