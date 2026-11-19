import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../accounts/domain/account.dart';
import '../domain/wallet_models.dart';

/// Read-only queries behind the wallets screens. Balances are computed at
/// query time with the same rule as the accounts module: opening + income -
/// expense + transfers in - transfers out over non-deleted transactions dated
/// on/after the opening date.
class WalletRepository {
  WalletRepository(this._db);
  final AppDatabase _db;

  static const _select = '''
SELECT a.*,
  a.opening_balance_minor + COALESCE((
    SELECT SUM(CASE
      WHEN t.type = 'income' AND t.account_id = a.id THEN t.amount_minor
      WHEN t.type = 'expense' AND t.account_id = a.id THEN -t.amount_minor
      WHEN t.type = 'transfer' AND t.to_account_id = a.id THEN t.amount_minor
      WHEN t.type = 'transfer' AND t.account_id = a.id THEN -t.amount_minor
      ELSE 0 END)
    FROM financial_transactions t
    WHERE t.profile_id = a.profile_id AND t.is_deleted = 0
      AND t.txn_date >= a.opening_date
      AND (t.account_id = a.id OR t.to_account_id = a.id)), 0) AS balance,
  COALESCE((
    SELECT SUM(t.amount_minor) FROM financial_transactions t
    WHERE t.profile_id = a.profile_id AND t.is_deleted = 0
      AND t.txn_date >= a.opening_date AND t.txn_date BETWEEN ? AND ?
      AND ((t.type = 'income' AND t.account_id = a.id)
        OR (t.type = 'transfer' AND t.to_account_id = a.id))), 0) AS month_in,
  COALESCE((
    SELECT SUM(t.amount_minor) FROM financial_transactions t
    WHERE t.profile_id = a.profile_id AND t.is_deleted = 0
      AND t.txn_date >= a.opening_date AND t.txn_date BETWEEN ? AND ?
      AND ((t.type = 'expense' AND t.account_id = a.id)
        OR (t.type = 'transfer' AND t.account_id = a.id))), 0) AS month_out
FROM accounts a WHERE a.profile_id = ?''';

  Set<TableInfo> get _reads => {_db.accounts, _db.financialTransactions};

  List<Variable> _vars(int profileId, DateTime now, [int? accountId]) {
    final from = monthStartKey(now.year, now.month);
    final to = monthEndKey(now.year, now.month);
    return [
      Variable.withString(from),
      Variable.withString(to),
      Variable.withString(from),
      Variable.withString(to),
      Variable.withInt(profileId),
      if (accountId != null) Variable.withInt(accountId),
    ];
  }

  WalletItem _map(QueryRow r) => WalletItem(
    account: Account(
      id: r.read<int>('id'),
      profileId: r.read<int>('profile_id'),
      name: r.read<String>('name'),
      type: r.read<String>('type'),
      openingBalanceMinor: r.read<int>('opening_balance_minor'),
      openingDate: r.read<String>('opening_date'),
      isActive: r.read<bool>('is_active'),
      createdAt: r.read<DateTime>('created_at'),
      updatedAt: r.read<DateTime>('updated_at'),
    ),
    balanceMinor: r.read<int>('balance'),
    monthInMinor: r.read<int>('month_in'),
    monthOutMinor: r.read<int>('month_out'),
  );

  /// Active accounts of the profile, grouped by type.
  Stream<WalletOverview> watchOverview(int profileId, {DateTime? now}) {
    return _db
        .customSelect(
          '$_select AND a.is_active = 1 ORDER BY lower(a.name)',
          variables: _vars(profileId, now ?? DateTime.now()),
          readsFrom: _reads,
        )
        .watch()
        .map(
          (rows) => WalletOverview.fromItems([for (final r in rows) _map(r)]),
        );
  }

  /// One account (active or not). Emits an error ([NotFoundException] /
  /// [ProfileMismatchException]) for a missing or foreign account.
  Stream<WalletItem> watchWallet(
    int profileId,
    int accountId, {
    DateTime? now,
  }) async* {
    final owner = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (owner == null) throw NotFoundException('Account not found.');
    if (owner.profileId != profileId) {
      throw ProfileMismatchException('Account belongs to a different profile.');
    }
    yield* _db
        .customSelect(
          '$_select AND a.id = ?',
          variables: _vars(profileId, now ?? DateTime.now(), accountId),
          readsFrom: _reads,
        )
        .watch()
        .map((rows) => _map(rows.first));
  }
}
