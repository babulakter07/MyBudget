import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/account.dart';

class AccountRepository {
  AccountRepository(this._db);
  final AppDatabase _db;

  Account _map(AccountRow r) => Account(
    id: r.id,
    profileId: r.profileId,
    name: r.name,
    type: r.type,
    openingBalanceMinor: r.openingBalanceMinor,
    openingDate: r.openingDate,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Account name is required.');
    if (n.length > 80) {
      throw ValidationException('Account name must be 80 characters or less.');
    }
    return n;
  }

  String _validType(String type) {
    if (!accountTypes.contains(type)) {
      throw ValidationException(
        'Account type must be cash, bank, mobile or other.',
      );
    }
    return type;
  }

  int _validOpening(int minor) {
    if (minor < 0) {
      throw ValidationException('Opening balance cannot be negative.');
    }
    return minor;
  }

  String _validDate(String date) {
    if (!isValidDateKey(date)) {
      throw ValidationException('Opening date is invalid.');
    }
    return date;
  }

  Future<bool> _nameTaken(int profileId, String name, {int? excludeId}) async {
    final q = _db.select(_db.accounts)
      ..where(
        (a) =>
            a.profileId.equals(profileId) &
            a.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((a) => a.id.equals(excludeId).not());
    return (await q.get()).isNotEmpty;
  }

  DuplicateNameException _dup(String n) =>
      DuplicateNameException('An account named "$n" already exists.');

  Future<Account> create({
    required int profileId,
    required String name,
    required String type,
    required int openingBalanceMinor,
    required String openingDate,
  }) async {
    final n = _validName(name);
    final t = _validType(type);
    final ob = _validOpening(openingBalanceMinor);
    final od = _validDate(openingDate);
    if (await _nameTaken(profileId, n)) throw _dup(n);
    final now = DateTime.now();
    try {
      final id = await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              profileId: profileId,
              name: n,
              type: Value(t),
              openingBalanceMinor: Value(ob),
              openingDate: od,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return (await getById(profileId, id))!;
    } catch (e) {
      if (_isUnique(e)) throw _dup(n);
      rethrow;
    }
  }

  Future<Account> update({
    required int profileId,
    required int id,
    required String name,
    required String type,
    required int openingBalanceMinor,
    required String openingDate,
  }) async {
    final n = _validName(name);
    final t = _validType(type);
    final ob = _validOpening(openingBalanceMinor);
    final od = _validDate(openingDate);
    final existing = await getById(profileId, id);
    if (existing == null) throw NotFoundException('Account not found.');
    if (await _nameTaken(profileId, n, excludeId: id)) throw _dup(n);
    if (od != existing.openingDate) {
      final earlier = await _db
          .customSelect(
            'SELECT COUNT(*) AS c FROM financial_transactions '
            'WHERE profile_id = ? AND is_deleted = 0 AND txn_date < ? '
            'AND (account_id = ? OR to_account_id = ?)',
            variables: [
              Variable.withInt(profileId),
              Variable.withString(od),
              Variable.withInt(id),
              Variable.withInt(id),
            ],
          )
          .getSingle();
      if (earlier.read<int>('c') > 0) {
        throw ValidationException(
          'Opening date cannot be after existing transactions of this account.',
        );
      }
    }
    try {
      await (_db.update(
        _db.accounts,
      )..where((a) => a.profileId.equals(profileId) & a.id.equals(id))).write(
        AccountsCompanion(
          name: Value(n),
          type: Value(t),
          openingBalanceMinor: Value(ob),
          openingDate: Value(od),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      if (_isUnique(e)) throw _dup(n);
      rethrow;
    }
    return (await getById(profileId, id))!;
  }

  /// Soft (de)activation only; accounts are never deleted.
  Future<void> setActive(int profileId, int id, bool active) async {
    final n =
        await (_db.update(
          _db.accounts,
        )..where((a) => a.profileId.equals(profileId) & a.id.equals(id))).write(
          AccountsCompanion(
            isActive: Value(active),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (n == 0) throw NotFoundException('Account not found.');
  }

  Future<Account?> getById(int profileId, int id) async {
    final r =
        await (_db.select(_db.accounts)
              ..where((a) => a.profileId.equals(profileId) & a.id.equals(id)))
            .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  String _esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  Stream<List<Account>> watchAll(
    int profileId, {
    String? search,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.accounts)
      ..where((a) => a.profileId.equals(profileId))
      ..orderBy([(a) => OrderingTerm(expression: a.name.lower())]);
    if (!includeInactive) q.where((a) => a.isActive.equals(true));
    final s = search?.trim().toLowerCase();
    if (s != null && s.isNotEmpty) {
      q.where((a) => a.name.lower().like('%${_esc(s)}%', escapeChar: r'\'));
    }
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  static const _balanceSelect = '''
SELECT a.id AS id, a.profile_id AS profile_id, a.name AS name, a.type AS type,
  a.opening_balance_minor AS opening_balance_minor,
  a.opening_date AS opening_date, a.is_active AS is_active,
  a.created_at AS created_at, a.updated_at AS updated_at,
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
FROM accounts a WHERE a.profile_id = ?''';

  /// Accounts with their current balance, reactive to transaction changes.
  Stream<List<AccountBalance>> watchBalances(
    int profileId, {
    String? search,
    bool includeInactive = false,
  }) {
    final s = search?.trim().toLowerCase() ?? '';
    final sql = StringBuffer(_balanceSelect);
    final vars = <Variable>[Variable.withInt(profileId)];
    if (!includeInactive) sql.write(' AND a.is_active = 1');
    if (s.isNotEmpty) {
      sql.write(r" AND lower(a.name) LIKE ? ESCAPE '\'");
      vars.add(Variable.withString('%${_esc(s)}%'));
    }
    sql.write(' ORDER BY lower(a.name)');
    return _db
        .customSelect(
          sql.toString(),
          variables: vars,
          readsFrom: {_db.accounts, _db.financialTransactions},
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              AccountBalance(
                account: _map(_db.accounts.map(r.data)),
                balanceMinor: r.read<int>('balance'),
              ),
          ],
        );
  }

  /// One-shot current balance of a single account.
  Future<int> balanceOf(int profileId, int accountId) async {
    final list = await watchBalances(profileId, includeInactive: true).first;
    final m = list.where((b) => b.account.id == accountId);
    if (m.isEmpty) throw NotFoundException('Account not found.');
    return m.first.balanceMinor;
  }

  bool _isUnique(Object e) => e.toString().toUpperCase().contains('UNIQUE');
}
