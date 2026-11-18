import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/goal.dart';

class GoalRepository {
  GoalRepository(this._db, {String Function()? todayKey})
    : _today = todayKey ?? (() => dateKey(DateTime.now()));

  final AppDatabase _db;
  final String Function() _today;

  Goal _map(SavingsGoalRow r) => Goal(
    id: r.id,
    profileId: r.profileId,
    name: r.name,
    accountId: r.accountId,
    targetMinor: r.targetMinor,
    targetDate: r.targetDate,
    note: r.note,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Goal name is required.');
    if (n.length > 80) {
      throw ValidationException('Goal name must be 80 characters or less.');
    }
    return n;
  }

  int _validTarget(int minor) {
    if (minor <= 0) {
      throw ValidationException('Target amount must be greater than zero.');
    }
    return minor;
  }

  String? _validDate(String? date) {
    if (date == null) return null;
    if (!isValidDateKey(date)) {
      throw ValidationException('Target date is invalid.');
    }
    return date;
  }

  String? _cleanNote(String? note) {
    final n = note?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  DuplicateNameException _dup(String n) =>
      DuplicateNameException('A goal named "$n" already exists.');

  Future<bool> _nameTaken(int profileId, String name, {int? excludeId}) async {
    final q = _db.select(_db.savingsGoals)
      ..where(
        (g) =>
            g.profileId.equals(profileId) &
            g.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((g) => g.id.equals(excludeId).not());
    return (await q.get()).isNotEmpty;
  }

  /// Account must belong to the profile and (when [requireActive]) be active.
  Future<void> _checkAccount(
    int profileId,
    int accountId, {
    required bool requireActive,
  }) async {
    final acc = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (acc == null) throw NotFoundException('Account not found.');
    if (acc.profileId != profileId) {
      throw ProfileMismatchException(
        'Account does not belong to the active profile.',
      );
    }
    if (requireActive && !acc.isActive) {
      throw ValidationException('The linked account is inactive.');
    }
  }

  Future<void> _checkOneActivePerAccount(
    int profileId,
    int accountId, {
    int? excludeId,
  }) async {
    final q = _db.select(_db.savingsGoals)
      ..where(
        (g) =>
            g.profileId.equals(profileId) &
            g.accountId.equals(accountId) &
            g.isActive.equals(true),
      );
    if (excludeId != null) q.where((g) => g.id.equals(excludeId).not());
    final existing = await q.get();
    if (existing.isNotEmpty) {
      throw ValidationException(
        'This account already has an active goal ("${existing.first.name}"). '
        'Archive it first or pick another account.',
      );
    }
  }

  Future<Goal> create({
    required int profileId,
    required String name,
    required int accountId,
    required int targetMinor,
    String? targetDate,
    String? note,
  }) async {
    final n = _validName(name);
    final t = _validTarget(targetMinor);
    final d = _validDate(targetDate);
    if (d != null && d.compareTo(_today()) < 0) {
      throw ValidationException('Target date cannot be in the past.');
    }
    return _db.transaction(() async {
      await _checkAccount(profileId, accountId, requireActive: true);
      if (await _nameTaken(profileId, n)) throw _dup(n);
      await _checkOneActivePerAccount(profileId, accountId);
      final now = DateTime.now();
      try {
        final id = await _db
            .into(_db.savingsGoals)
            .insert(
              SavingsGoalsCompanion.insert(
                profileId: profileId,
                name: n,
                accountId: accountId,
                targetMinor: t,
                targetDate: Value(d),
                note: Value(_cleanNote(note)),
                createdAt: now,
                updatedAt: now,
              ),
            );
        return (await getById(profileId, id))!;
      } catch (e) {
        if (_isUnique(e)) throw _dup(n);
        rethrow;
      }
    });
  }

  Future<Goal> update({
    required int profileId,
    required int id,
    required String name,
    required int accountId,
    required int targetMinor,
    String? targetDate,
    String? note,
  }) async {
    final n = _validName(name);
    final t = _validTarget(targetMinor);
    final d = _validDate(targetDate);
    return _db.transaction(() async {
      final existing = await getById(profileId, id);
      if (existing == null) throw NotFoundException('Goal not found.');
      if (d != null && d != existing.targetDate && d.compareTo(_today()) < 0) {
        throw ValidationException('Target date cannot be in the past.');
      }
      await _checkAccount(
        profileId,
        accountId,
        requireActive: accountId != existing.accountId,
      );
      if (await _nameTaken(profileId, n, excludeId: id)) throw _dup(n);
      if (existing.isActive) {
        await _checkOneActivePerAccount(profileId, accountId, excludeId: id);
      }
      try {
        await (_db.update(
          _db.savingsGoals,
        )..where((g) => g.profileId.equals(profileId) & g.id.equals(id))).write(
          SavingsGoalsCompanion(
            name: Value(n),
            accountId: Value(accountId),
            targetMinor: Value(t),
            targetDate: Value(d),
            note: Value(_cleanNote(note)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } catch (e) {
        if (_isUnique(e)) throw _dup(n);
        rethrow;
      }
      return (await getById(profileId, id))!;
    });
  }

  /// Archive (false) or restore (true). Goals are never deleted.
  Future<void> setActive(int profileId, int id, bool active) async {
    await _db.transaction(() async {
      final g = await getById(profileId, id);
      if (g == null) throw NotFoundException('Goal not found.');
      if (active && !g.isActive) {
        await _checkAccount(profileId, g.accountId, requireActive: true);
        await _checkOneActivePerAccount(profileId, g.accountId, excludeId: id);
      }
      await (_db.update(
        _db.savingsGoals,
      )..where((x) => x.profileId.equals(profileId) & x.id.equals(id))).write(
        SavingsGoalsCompanion(
          isActive: Value(active),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<Goal?> getById(int profileId, int id) async {
    final r =
        await (_db.select(_db.savingsGoals)
              ..where((g) => g.profileId.equals(profileId) & g.id.equals(id)))
            .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  static const _select = '''
SELECT g.id AS id, g.profile_id AS profile_id, g.name AS name,
  g.account_id AS account_id, g.target_minor AS target_minor,
  g.target_date AS target_date, g.note AS note, g.is_active AS is_active,
  g.created_at AS created_at, g.updated_at AS updated_at,
  a.name AS account_name, a.is_active AS account_active,
  a.opening_balance_minor + COALESCE((
    SELECT SUM(CASE
      WHEN t.type = 'income' THEN t.amount_minor
      WHEN t.type = 'expense' THEN -t.amount_minor
      WHEN t.type = 'transfer' AND t.account_id = a.id THEN -t.amount_minor
      WHEN t.type = 'transfer' AND t.to_account_id = a.id THEN t.amount_minor
      ELSE 0 END)
    FROM financial_transactions t
    WHERE t.profile_id = a.profile_id AND t.is_deleted = 0
      AND t.txn_date >= a.opening_date
      AND (t.account_id = a.id OR t.to_account_id = a.id)
  ), 0) AS balance
FROM savings_goals g
JOIN accounts a ON a.profile_id = g.profile_id AND a.id = g.account_id
WHERE g.profile_id = ?''';

  /// Goals with computed progress, reactive to goal/account/transaction
  /// changes. Active first, then by name.
  Stream<List<GoalWithProgress>> watchGoals(
    int profileId, {
    bool includeArchived = false,
  }) {
    final sql =
        '$_select${includeArchived ? '' : ' AND g.is_active = 1'} '
        'ORDER BY g.is_active DESC, lower(g.name)';
    return _db
        .customSelect(
          sql,
          variables: [Variable.withInt(profileId)],
          readsFrom: {
            _db.savingsGoals,
            _db.accounts,
            _db.financialTransactions,
          },
        )
        .watch()
        .map((rows) {
          final today = _today();
          return [
            for (final r in rows)
              GoalWithProgress(
                goal: _map(_db.savingsGoals.map(r.data)),
                accountName: r.read<String>('account_name'),
                accountActive: r.read<bool>('account_active'),
                progress: computeGoalProgress(
                  balanceMinor: r.read<int>('balance'),
                  targetMinor: r.read<int>('target_minor'),
                  today: today,
                  targetDate: r.read<String?>('target_date'),
                ),
              ),
          ];
        });
  }

  /// Active accounts of the profile for the goal form (savings type first).
  Stream<List<GoalAccountOption>> watchAccountOptions(int profileId) {
    final q = _db.select(_db.accounts)
      ..where((a) => a.profileId.equals(profileId) & a.isActive.equals(true))
      ..orderBy([(a) => OrderingTerm(expression: a.name.lower())]);
    return q.watch().map((rows) {
      final list = [
        for (final a in rows)
          GoalAccountOption(id: a.id, name: a.name, type: a.type),
      ];
      list.sort((x, y) {
        final sx = x.type == 'savings' ? 0 : 1;
        final sy = y.type == 'savings' ? 0 : 1;
        return sx != sy
            ? sx - sy
            : x.name.toLowerCase().compareTo(y.name.toLowerCase());
      });
      return list;
    });
  }

  /// One-shot progress of a single goal.
  Future<GoalWithProgress> progressOf(int profileId, int id) async {
    final list = await watchGoals(profileId, includeArchived: true).first;
    final m = list.where((g) => g.goal.id == id);
    if (m.isEmpty) throw NotFoundException('Goal not found.');
    return m.first;
  }

  bool _isUnique(Object e) => e.toString().toUpperCase().contains('UNIQUE');
}
