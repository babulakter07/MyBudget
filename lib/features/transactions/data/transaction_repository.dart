import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/transaction_models.dart';

/// Expense / income / transfer writes and queries.
///
/// All writes run inside `db.transaction` and append a `transaction_audit_logs`
/// row. Validation of ownership (profile) happens before any write.
class TransactionRepository {
  TransactionRepository(this._db);
  final AppDatabase _db;

  // ---------------------------------------------------------------- helpers

  TransactionView _map(TransactionRow r) => TransactionView(
    id: r.id,
    profileId: r.profileId,
    type: r.type,
    accountId: r.accountId,
    toAccountId: r.toAccountId,
    categoryId: r.categoryId,
    subCategoryId: r.subCategoryId,
    costItemId: r.costItemId,
    accountName: r.accountNameSnapshot,
    toAccountName: r.toAccountNameSnapshot,
    categoryName: r.categoryNameSnapshot,
    subCategoryName: r.subCategoryNameSnapshot,
    costItemName: r.costItemNameSnapshot,
    incomeSource: r.incomeSource,
    amountMinor: r.amountMinor,
    date: r.txnDate,
    title: r.title,
    remarks: r.remarks,
    paidBy: r.paidBy,
    forWhom: r.forWhom,
    isDeleted: r.isDeleted,
    deletedAt: r.deletedAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  void _validAmount(int amountMinor) {
    if (amountMinor <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
  }

  String _validDate(String date) {
    if (!isValidDateKey(date)) {
      throw ValidationException('Enter a valid date (yyyy-MM-dd).');
    }
    return date;
  }

  Future<AccountRow> _account(
    int profileId,
    int id, {
    required bool requireActive,
    required String date,
    String label = 'Account',
  }) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('$label not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException('$label belongs to a different profile.');
    }
    if (requireActive && !row.isActive) {
      throw ValidationException('$label "${row.name}" is inactive.');
    }
    if (date.compareTo(row.openingDate) < 0) {
      throw ValidationException(
        'Date cannot be before the opening date of "${row.name}" '
        '(${row.openingDate}).',
      );
    }
    return row;
  }

  Future<CategoryRow> _category(int profileId, int id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('Category not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Category belongs to a different profile.',
      );
    }
    return row;
  }

  Future<SubCategoryRow> _sub(int profileId, int id) async {
    final row = await (_db.select(
      _db.subCategories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('Sub-category not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Sub-category belongs to a different profile.',
      );
    }
    return row;
  }

  Future<CostItemRow> _item(int profileId, int id) async {
    final row = await (_db.select(
      _db.costItems,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('Cost item not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Cost item belongs to a different profile.',
      );
    }
    return row;
  }

  Future<TransactionRow> _row(int profileId, int id) async {
    final row =
        await (_db.select(_db.financialTransactions)
              ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('Transaction not found.');
    return row;
  }

  Future<void> _audit(
    int profileId,
    int txnId,
    String action,
    TransactionRow? previous,
    TransactionRow? next,
  ) async {
    await _db
        .into(_db.transactionAuditLogs)
        .insert(
          TransactionAuditLogsCompanion.insert(
            profileId: profileId,
            transactionId: txnId,
            action: action,
            previousJson: Value(
              previous == null ? null : jsonEncode(previous.toJson()),
            ),
            newJson: Value(next == null ? null : jsonEncode(next.toJson())),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<TransactionRow?> _byKey(int profileId, String key) =>
      (_db.select(_db.financialTransactions)..where(
            (t) => t.profileId.equals(profileId) & t.idempotencyKey.equals(key),
          ))
          .getSingleOrNull();

  Object _translate(Object e) {
    if (e is AppException) return e;
    final msg = e.toString();
    if (msg.contains('FOREIGN KEY')) {
      return ProfileMismatchException(
        'A referenced record does not belong to this profile.',
      );
    }
    if (msg.contains('CHECK')) {
      return ValidationException('The transaction values are not valid.');
    }
    return e;
  }

  /// Validates and resolves expense references to snapshot names. Only
  /// references that changed relative to [existing] must be active; unchanged
  /// ones keep their stored snapshot.
  Future<_ExpenseRefs> _expenseRefs(
    int profileId,
    int categoryId,
    int? subCategoryId,
    int? costItemId,
    TransactionRow? existing,
  ) async {
    final cat = await _category(profileId, categoryId);
    if (existing?.categoryId != categoryId && !cat.isActive) {
      throw ValidationException('Category "${cat.name}" is inactive.');
    }
    var catName = cat.name;
    if (existing?.categoryId == categoryId &&
        existing?.categoryNameSnapshot != null) {
      catName = existing!.categoryNameSnapshot!;
    }

    String? subName;
    if (subCategoryId != null) {
      final sub = await _sub(profileId, subCategoryId);
      if (sub.categoryId != categoryId) {
        throw ValidationException(
          'Sub-category "${sub.name}" does not belong to the selected category.',
        );
      }
      if (existing?.subCategoryId != subCategoryId && !sub.isActive) {
        throw ValidationException('Sub-category "${sub.name}" is inactive.');
      }
      subName = existing?.subCategoryId == subCategoryId
          ? (existing!.subCategoryNameSnapshot ?? sub.name)
          : sub.name;
    }

    String? itemName;
    if (costItemId != null) {
      if (subCategoryId == null) {
        throw ValidationException(
          'Select a sub-category together with the cost item.',
        );
      }
      final item = await _item(profileId, costItemId);
      if (item.subCategoryId != subCategoryId) {
        throw ValidationException(
          'Cost item "${item.name}" does not belong to the selected sub-category.',
        );
      }
      if (existing?.costItemId != costItemId && !item.isActive) {
        throw ValidationException('Cost item "${item.name}" is inactive.');
      }
      itemName = existing?.costItemId == costItemId
          ? (existing!.costItemNameSnapshot ?? item.name)
          : item.name;
    }
    return _ExpenseRefs(catName, subName, itemName);
  }

  // ----------------------------------------------------------------- create

  Future<TransactionView> createExpense({
    required int profileId,
    required int accountId,
    required int categoryId,
    int? subCategoryId,
    int? costItemId,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
    String? paidBy,
    String? forWhom,
    String? idempotencyKey,
  }) => _create(
    profileId: profileId,
    idempotencyKey: idempotencyKey,
    build: () async {
      _validAmount(amountMinor);
      _validDate(date);
      final acc = await _account(
        profileId,
        accountId,
        requireActive: true,
        date: date,
      );
      final refs = await _expenseRefs(
        profileId,
        categoryId,
        subCategoryId,
        costItemId,
        null,
      );
      return FinancialTransactionsCompanion.insert(
        profileId: profileId,
        type: TransactionType.expense,
        accountId: accountId,
        accountNameSnapshot: acc.name,
        categoryId: Value(categoryId),
        subCategoryId: Value(subCategoryId),
        costItemId: Value(costItemId),
        categoryNameSnapshot: Value(refs.category),
        subCategoryNameSnapshot: Value(refs.sub),
        costItemNameSnapshot: Value(refs.item),
        amountMinor: amountMinor,
        txnDate: date,
        title: Value(_clean(title)),
        remarks: Value(_clean(remarks)),
        paidBy: Value(_clean(paidBy)),
        forWhom: Value(_clean(forWhom)),
        idempotencyKey: Value(_clean(idempotencyKey)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    },
  );

  Future<TransactionView> createIncome({
    required int profileId,
    required int accountId,
    required String incomeSource,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
    String? paidBy,
    String? forWhom,
    String? idempotencyKey,
  }) => _create(
    profileId: profileId,
    idempotencyKey: idempotencyKey,
    build: () async {
      _validAmount(amountMinor);
      _validDate(date);
      final src = _clean(incomeSource);
      if (src == null) throw ValidationException('Income source is required.');
      final acc = await _account(
        profileId,
        accountId,
        requireActive: true,
        date: date,
      );
      return FinancialTransactionsCompanion.insert(
        profileId: profileId,
        type: TransactionType.income,
        accountId: accountId,
        accountNameSnapshot: acc.name,
        incomeSource: Value(src),
        amountMinor: amountMinor,
        txnDate: date,
        title: Value(_clean(title)),
        remarks: Value(_clean(remarks)),
        paidBy: Value(_clean(paidBy)),
        forWhom: Value(_clean(forWhom)),
        idempotencyKey: Value(_clean(idempotencyKey)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    },
  );

  Future<TransactionView> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
    String? idempotencyKey,
  }) => _create(
    profileId: profileId,
    idempotencyKey: idempotencyKey,
    build: () async {
      _validAmount(amountMinor);
      _validDate(date);
      if (fromAccountId == toAccountId) {
        throw ValidationException(
          'Choose two different accounts for a transfer.',
        );
      }
      final from = await _account(
        profileId,
        fromAccountId,
        requireActive: true,
        date: date,
        label: 'Source account',
      );
      final to = await _account(
        profileId,
        toAccountId,
        requireActive: true,
        date: date,
        label: 'Destination account',
      );
      return FinancialTransactionsCompanion.insert(
        profileId: profileId,
        type: TransactionType.transfer,
        accountId: fromAccountId,
        toAccountId: Value(toAccountId),
        accountNameSnapshot: from.name,
        toAccountNameSnapshot: Value(to.name),
        amountMinor: amountMinor,
        txnDate: date,
        title: Value(_clean(title)),
        remarks: Value(_clean(remarks)),
        idempotencyKey: Value(_clean(idempotencyKey)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    },
  );

  Future<TransactionView> _create({
    required int profileId,
    required String? idempotencyKey,
    required Future<FinancialTransactionsCompanion> Function() build,
  }) async {
    try {
      return await _db.transaction(() async {
        final key = _clean(idempotencyKey);
        if (key != null) {
          final existing = await _byKey(profileId, key);
          if (existing != null) return _map(existing);
        }
        final companion = await build();
        final id = await _db.into(_db.financialTransactions).insert(companion);
        final row = await _row(profileId, id);
        await _audit(profileId, id, 'create', null, row);
        return _map(row);
      });
    } on Object catch (e) {
      throw _translate(e);
    }
  }

  // ----------------------------------------------------------------- update

  Future<TransactionView> updateExpense({
    required int profileId,
    required int id,
    required int accountId,
    required int categoryId,
    int? subCategoryId,
    int? costItemId,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
    String? paidBy,
    String? forWhom,
  }) => _update(profileId, id, TransactionType.expense, (old) async {
    _validAmount(amountMinor);
    _validDate(date);
    final acc = await _account(
      profileId,
      accountId,
      requireActive: old.accountId != accountId,
      date: date,
    );
    final refs = await _expenseRefs(
      profileId,
      categoryId,
      subCategoryId,
      costItemId,
      old,
    );
    return FinancialTransactionsCompanion(
      accountId: Value(accountId),
      accountNameSnapshot: Value(
        old.accountId == accountId ? old.accountNameSnapshot : acc.name,
      ),
      categoryId: Value(categoryId),
      subCategoryId: Value(subCategoryId),
      costItemId: Value(costItemId),
      categoryNameSnapshot: Value(refs.category),
      subCategoryNameSnapshot: Value(refs.sub),
      costItemNameSnapshot: Value(refs.item),
      amountMinor: Value(amountMinor),
      txnDate: Value(date),
      title: Value(_clean(title)),
      remarks: Value(_clean(remarks)),
      paidBy: Value(_clean(paidBy)),
      forWhom: Value(_clean(forWhom)),
    );
  });

  Future<TransactionView> updateIncome({
    required int profileId,
    required int id,
    required int accountId,
    required String incomeSource,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
    String? paidBy,
    String? forWhom,
  }) => _update(profileId, id, TransactionType.income, (old) async {
    _validAmount(amountMinor);
    _validDate(date);
    final src = _clean(incomeSource);
    if (src == null) throw ValidationException('Income source is required.');
    final acc = await _account(
      profileId,
      accountId,
      requireActive: old.accountId != accountId,
      date: date,
    );
    return FinancialTransactionsCompanion(
      accountId: Value(accountId),
      accountNameSnapshot: Value(
        old.accountId == accountId ? old.accountNameSnapshot : acc.name,
      ),
      incomeSource: Value(src),
      amountMinor: Value(amountMinor),
      txnDate: Value(date),
      title: Value(_clean(title)),
      remarks: Value(_clean(remarks)),
      paidBy: Value(_clean(paidBy)),
      forWhom: Value(_clean(forWhom)),
    );
  });

  Future<TransactionView> updateTransfer({
    required int profileId,
    required int id,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required String date,
    String? title,
    String? remarks,
  }) => _update(profileId, id, TransactionType.transfer, (old) async {
    _validAmount(amountMinor);
    _validDate(date);
    if (fromAccountId == toAccountId) {
      throw ValidationException(
        'Choose two different accounts for a transfer.',
      );
    }
    final from = await _account(
      profileId,
      fromAccountId,
      requireActive: old.accountId != fromAccountId,
      date: date,
      label: 'Source account',
    );
    final to = await _account(
      profileId,
      toAccountId,
      requireActive: old.toAccountId != toAccountId,
      date: date,
      label: 'Destination account',
    );
    return FinancialTransactionsCompanion(
      accountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      accountNameSnapshot: Value(
        old.accountId == fromAccountId ? old.accountNameSnapshot : from.name,
      ),
      toAccountNameSnapshot: Value(
        old.toAccountId == toAccountId
            ? (old.toAccountNameSnapshot ?? to.name)
            : to.name,
      ),
      amountMinor: Value(amountMinor),
      txnDate: Value(date),
      title: Value(_clean(title)),
      remarks: Value(_clean(remarks)),
    );
  });

  Future<TransactionView> _update(
    int profileId,
    int id,
    String type,
    Future<FinancialTransactionsCompanion> Function(TransactionRow old) build,
  ) async {
    try {
      return await _db.transaction(() async {
        final old = await _row(profileId, id);
        if (old.type != type) {
          throw ValidationException('The transaction type cannot be changed.');
        }
        if (old.isDeleted) {
          throw ValidationException(
            'A deleted transaction cannot be edited. Restore it first.',
          );
        }
        final patch = await build(old);
        await (_db.update(_db.financialTransactions)
              ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
            .write(patch.copyWith(updatedAt: Value(DateTime.now())));
        final row = await _row(profileId, id);
        await _audit(profileId, id, 'update', old, row);
        return _map(row);
      });
    } on Object catch (e) {
      throw _translate(e);
    }
  }

  // ------------------------------------------------------- delete / restore

  /// Soft delete. A transfer is one row, so both accounts reverse atomically.
  Future<void> softDelete(int profileId, int id) async {
    await _db.transaction(() async {
      final old = await _row(profileId, id);
      if (old.isDeleted) return;
      await (_db.update(
        _db.financialTransactions,
      )..where((t) => t.id.equals(id) & t.profileId.equals(profileId))).write(
        FinancialTransactionsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _audit(profileId, id, 'delete', old, await _row(profileId, id));
    });
  }

  Future<void> restore(int profileId, int id) async {
    await _db.transaction(() async {
      final old = await _row(profileId, id);
      if (!old.isDeleted) return;
      await (_db.update(
        _db.financialTransactions,
      )..where((t) => t.id.equals(id) & t.profileId.equals(profileId))).write(
        FinancialTransactionsCompanion(
          isDeleted: const Value(false),
          deletedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _audit(profileId, id, 'restore', old, await _row(profileId, id));
    });
  }

  // ---------------------------------------------------------------- queries

  /// Returns the transaction (deleted or not) or null when it does not exist
  /// in this profile.
  Future<TransactionView?> getById(int profileId, int id) async {
    final row =
        await (_db.select(_db.financialTransactions)
              ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Stream<TransactionView?> watchById(int profileId, int id) =>
      (_db.select(_db.financialTransactions)
            ..where((t) => t.id.equals(id) & t.profileId.equals(profileId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _map(r));

  Stream<List<TransactionView>> watchRecent(int profileId, {int limit = 20}) =>
      watchByFilter(profileId, TransactionFilter(limit: limit));

  Stream<List<TransactionView>> watchByFilter(
    int profileId,
    TransactionFilter f,
  ) {
    final t = _db.financialTransactions;
    final q = _db.select(t)
      ..where((r) {
        Expression<bool> w = r.profileId.equals(profileId);
        if (!f.includeDeleted) w = w & r.isDeleted.equals(false);
        if (f.type != null) w = w & r.type.equals(f.type!);
        if (f.fromDate != null) {
          w = w & r.txnDate.isBiggerOrEqualValue(f.fromDate!);
        }
        if (f.toDate != null) {
          w = w & r.txnDate.isSmallerOrEqualValue(f.toDate!);
        }
        final term = f.search.trim();
        if (term.isNotEmpty) {
          final esc = term
              .toLowerCase()
              .replaceAll(r'\', r'\\')
              .replaceAll('%', r'\%')
              .replaceAll('_', r'\_');
          final p = '%$esc%';
          w =
              w &
              (_EscapedLike(r.title.lower(), p) |
                  _EscapedLike(r.remarks.lower(), p) |
                  _EscapedLike(r.paidBy.lower(), p) |
                  _EscapedLike(r.forWhom.lower(), p) |
                  _EscapedLike(r.incomeSource.lower(), p) |
                  _EscapedLike(r.accountNameSnapshot.lower(), p) |
                  _EscapedLike(r.toAccountNameSnapshot.lower(), p) |
                  _EscapedLike(r.categoryNameSnapshot.lower(), p) |
                  _EscapedLike(r.subCategoryNameSnapshot.lower(), p) |
                  _EscapedLike(r.costItemNameSnapshot.lower(), p));
        }
        return w;
      })
      ..orderBy([
        (r) => OrderingTerm.desc(r.txnDate),
        (r) => OrderingTerm.desc(r.id),
      ]);
    if (f.limit != null) q.limit(f.limit!);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Stream<List<TransactionAuditEntry>> watchAuditLog(int profileId, int id) =>
      (_db.select(_db.transactionAuditLogs)
            ..where(
              (a) => a.profileId.equals(profileId) & a.transactionId.equals(id),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.id)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (a) => TransactionAuditEntry(
                    id: a.id,
                    transactionId: a.transactionId,
                    action: a.action,
                    previousJson: a.previousJson,
                    newJson: a.newJson,
                    createdAt: a.createdAt,
                  ),
                )
                .toList(),
          );

  // ------------------------------------------------- form lookup (read-only)

  /// Distinct member names already used in paid-by / for-whom tags of this
  /// profile (non-deleted rows), sorted case-insensitively.
  Stream<List<String>> watchMemberNames(int profileId) => _db
      .customSelect(
        'SELECT MIN(name) AS name FROM ('
        ' SELECT paid_by AS name FROM financial_transactions'
        '  WHERE profile_id = ?1 AND is_deleted = 0 AND paid_by IS NOT NULL'
        ' UNION ALL'
        ' SELECT for_whom FROM financial_transactions'
        '  WHERE profile_id = ?1 AND is_deleted = 0 AND for_whom IS NOT NULL'
        ') GROUP BY name COLLATE NOCASE ORDER BY name COLLATE NOCASE',
        variables: [Variable.withInt(profileId)],
        readsFrom: {_db.financialTransactions},
      )
      .watch()
      .map((rows) => [for (final r in rows) r.read<String>('name')]);

  Stream<List<AccountRow>> watchActiveAccounts(int profileId) =>
      (_db.select(_db.accounts)
            ..where(
              (a) => a.profileId.equals(profileId) & a.isActive.equals(true),
            )
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .watch();

  Stream<List<CategoryRow>> watchActiveCategories(int profileId) =>
      (_db.select(_db.categories)
            ..where(
              (c) => c.profileId.equals(profileId) & c.isActive.equals(true),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<List<SubCategoryRow>> activeSubCategories(
    int profileId,
    int categoryId,
  ) =>
      (_db.select(_db.subCategories)
            ..where(
              (s) =>
                  s.profileId.equals(profileId) &
                  s.categoryId.equals(categoryId) &
                  s.isActive.equals(true),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .get();

  Future<List<CostItemRow>> activeCostItems(int profileId, int subCategoryId) =>
      (_db.select(_db.costItems)
            ..where(
              (c) =>
                  c.profileId.equals(profileId) &
                  c.subCategoryId.equals(subCategoryId) &
                  c.isActive.equals(true),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();
}

class _ExpenseRefs {
  const _ExpenseRefs(this.category, this.sub, this.item);
  final String category;
  final String? sub;
  final String? item;
}

class _EscapedLike extends Expression<bool> {
  _EscapedLike(this.target, this.pattern);
  final Expression<String> target;
  final String pattern;

  @override
  Precedence get precedence => Precedence.comparison;

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    Variable<String>(pattern).writeInto(context);
    context.buffer.write(r" ESCAPE '\'");
  }
}
