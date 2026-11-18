import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../preferences/data/app_l10n_resolver.dart';
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
WHERE profile_id = ?1 AND is_active = 1 AND remind_days_before IS NOT NULL
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
          remindDaysBefore: r.read<int>('remind_days_before'),
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

    final plan = _planner.plan(
      l10n: _l10n(),
      now: _clock(),
      rules: await _source.recurring(pid),
      debts: await _source.debts(pid),
      hour: settings.reminderHour,
    );
    for (final n in plan) {
      await _gateway.schedule(
        id: n.id,
        when: n.when,
        title: n.title,
        body: n.body,
        kind: n.kind,
      );
    }
    await _prefs.setStringList(trackedIdsKey, [
      for (final n in plan) n.id.toString(),
    ]);
  }
}
