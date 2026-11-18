import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/tag.dart';

class TagRepository {
  TagRepository(this._db);
  final AppDatabase _db;

  Tag _map(TagRow r) => Tag(
    id: r.id,
    profileId: r.profileId,
    name: r.name,
    color: r.color,
    isActive: r.isActive,
    createdAt: r.createdAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Tag name is required.');
    if (n.length > tagNameMaxLength) {
      throw ValidationException(
        'Tag name must be $tagNameMaxLength characters or less.',
      );
    }
    return n;
  }

  Future<bool> _nameTaken(int profileId, String name, {int? excludeId}) async {
    final q = _db.select(_db.tags)
      ..where(
        (t) =>
            t.profileId.equals(profileId) &
            t.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((t) => t.id.equals(excludeId).not());
    return (await q.get()).isNotEmpty;
  }

  DuplicateNameException _dup(String n) =>
      DuplicateNameException('A tag named "$n" already exists.');

  Future<TagRow> _row(int profileId, int id) async {
    final r = await (_db.select(
      _db.tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) throw NotFoundException('Tag not found.');
    if (r.profileId != profileId) {
      throw ProfileMismatchException('Tag belongs to another profile.');
    }
    return r;
  }

  Future<Tag> create({
    required int profileId,
    required String name,
    int? color,
  }) async {
    final n = _validName(name);
    return _db.transaction(() async {
      if (await _nameTaken(profileId, n)) throw _dup(n);
      final id = await _db
          .into(_db.tags)
          .insert(
            TagsCompanion.insert(
              profileId: profileId,
              name: n,
              color: Value(color),
              createdAt: DateTime.now(),
            ),
          );
      return _map(await _row(profileId, id));
    });
  }

  Future<Tag> rename(int profileId, int id, String name) async {
    final n = _validName(name);
    return _db.transaction(() async {
      await _row(profileId, id);
      if (await _nameTaken(profileId, n, excludeId: id)) throw _dup(n);
      await (_db.update(_db.tags)
            ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
          .write(TagsCompanion(name: Value(n)));
      return _map(await _row(profileId, id));
    });
  }

  Future<Tag> recolor(int profileId, int id, int? color) async {
    await _row(profileId, id);
    await (_db.update(_db.tags)
          ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
        .write(TagsCompanion(color: Value(color)));
    return _map(await _row(profileId, id));
  }

  /// Archive (isActive=false) or restore a tag. Archived tags stay attached to
  /// old transactions but cannot be newly assigned.
  Future<Tag> setActive(int profileId, int id, bool active) async {
    await _row(profileId, id);
    await (_db.update(_db.tags)
          ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
        .write(TagsCompanion(isActive: Value(active)));
    return _map(await _row(profileId, id));
  }

  Future<Tag> archive(int profileId, int id) => setActive(profileId, id, false);

  Stream<List<Tag>> watchTags(int profileId, {bool includeArchived = false}) {
    final q = _db.select(_db.tags)
      ..where((t) => t.profileId.equals(profileId))
      ..orderBy([(t) => OrderingTerm(expression: t.name.lower())]);
    if (!includeArchived) q.where((t) => t.isActive.equals(true));
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<List<Tag>> listTags(int profileId, {bool includeArchived = false}) =>
      watchTags(profileId, includeArchived: includeArchived).first;

  /// Replaces the tag set of a transaction atomically. Tags must be active,
  /// except tags already attached to the transaction (archived tags are kept
  /// on old transactions). The transaction must exist, belong to the profile
  /// and not be deleted.
  Future<void> setTagsForTransaction(
    int profileId,
    int transactionId,
    Iterable<int> tagIds,
  ) async {
    final ids = tagIds.toSet();
    await _db.transaction(() async {
      final txn = await (_db.select(
        _db.financialTransactions,
      )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
      if (txn == null) throw NotFoundException('Transaction not found.');
      if (txn.profileId != profileId) {
        throw ProfileMismatchException(
          'Transaction belongs to another profile.',
        );
      }
      if (txn.isDeleted) {
        throw NotFoundException('Transaction has been deleted.');
      }
      final existing =
          (await (_db.select(
                _db.transactionTags,
              )..where((t) => t.transactionId.equals(transactionId))).get())
              .map((r) => r.tagId)
              .toSet();
      for (final id in ids) {
        final tag = await _row(profileId, id);
        if (!tag.isActive && !existing.contains(id)) {
          throw ValidationException('Tag "${tag.name}" is archived.');
        }
      }
      await (_db.delete(_db.transactionTags)..where(
            (t) =>
                t.transactionId.equals(transactionId) &
                t.profileId.equals(profileId),
          ))
          .go();
      for (final id in ids) {
        await _db
            .into(_db.transactionTags)
            .insert(
              TransactionTagsCompanion.insert(
                profileId: profileId,
                transactionId: transactionId,
                tagId: id,
              ),
            );
      }
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joined(
    int profileId,
    Expression<bool> extra,
  ) {
    return _db.select(_db.transactionTags).join([
        innerJoin(_db.tags, _db.tags.id.equalsExp(_db.transactionTags.tagId)),
      ])
      ..where(
        _db.transactionTags.profileId.equals(profileId) &
            _db.tags.profileId.equals(profileId) &
            extra,
      )
      ..orderBy([OrderingTerm(expression: _db.tags.name.lower())]);
  }

  Stream<List<Tag>> tagsForTransaction(int profileId, int transactionId) {
    return _joined(
      profileId,
      _db.transactionTags.transactionId.equals(transactionId),
    ).watch().map(
      (rows) => rows.map((r) => _map(r.readTable(_db.tags))).toList(),
    );
  }

  /// Bulk map transactionId -> tags (for list screens).
  Stream<Map<int, List<Tag>>> tagsForTransactions(
    int profileId,
    Iterable<int> transactionIds,
  ) {
    final ids = transactionIds.toList();
    if (ids.isEmpty) return Stream.value(const {});
    return _joined(
      profileId,
      _db.transactionTags.transactionId.isIn(ids),
    ).watch().map((rows) {
      final map = <int, List<Tag>>{};
      for (final r in rows) {
        final tt = r.readTable(_db.transactionTags);
        (map[tt.transactionId] ??= []).add(_map(r.readTable(_db.tags)));
      }
      return map;
    });
  }

  static const _totalsSql = '''
SELECT t.id AS tag_id, t.name AS name, t.color AS color,
  COALESCE(SUM(CASE WHEN ft.type = 'expense' THEN ft.amount_minor ELSE 0 END), 0) AS expense_minor,
  COALESCE(SUM(CASE WHEN ft.type = 'income' THEN ft.amount_minor ELSE 0 END), 0) AS income_minor,
  COUNT(ft.id) AS cnt
FROM transaction_tags tt
JOIN tags t ON t.profile_id = tt.profile_id AND t.id = tt.tag_id
JOIN financial_transactions ft
  ON ft.profile_id = tt.profile_id AND ft.id = tt.transaction_id
WHERE tt.profile_id = ?1 AND ft.is_deleted = 0
  AND ft.type IN ('expense', 'income')
  AND ft.txn_date >= ?2 AND ft.txn_date <= ?3
GROUP BY t.id, t.name, t.color
ORDER BY expense_minor DESC, income_minor DESC, t.name COLLATE NOCASE
''';

  Selectable<TagTotal> _totalsQuery(int profileId, DateTime from, DateTime to) {
    return _db
        .customSelect(
          _totalsSql,
          variables: [
            Variable.withInt(profileId),
            Variable.withString(dateKey(from)),
            Variable.withString(dateKey(to)),
          ],
          readsFrom: {_db.transactionTags, _db.tags, _db.financialTransactions},
        )
        .map(
          (r) => TagTotal(
            tagId: r.read<int>('tag_id'),
            name: r.read<String>('name'),
            color: r.readNullable<int>('color'),
            expenseMinor: r.read<int>('expense_minor'),
            incomeMinor: r.read<int>('income_minor'),
            count: r.read<int>('cnt'),
          ),
        );
  }

  /// Per-tag expense/income totals and counts for [from]..[to] inclusive.
  Future<List<TagTotal>> tagTotals(int profileId, DateTime from, DateTime to) =>
      _totalsQuery(profileId, from, to).get();

  Stream<List<TagTotal>> watchTagTotals(
    int profileId,
    DateTime from,
    DateTime to,
  ) => _totalsQuery(profileId, from, to).watch();
}
