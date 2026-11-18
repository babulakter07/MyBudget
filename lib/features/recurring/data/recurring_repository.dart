import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_models.dart';

/// CRUD + validation for `recurring_rules`. No hard delete: rules are paused
/// (`is_active = false`). Every query filters by `profile_id`.
class RecurringRepository {
  RecurringRepository(this._db);
  final AppDatabase _db;

  static RecurringRule map(RecurringRuleRow r) => RecurringRule(
    id: r.id,
    profileId: r.profileId,
    type: r.type,
    accountId: r.accountId,
    toAccountId: r.toAccountId,
    categoryId: r.categoryId,
    subCategoryId: r.subCategoryId,
    costItemId: r.costItemId,
    incomeSource: r.incomeSource,
    amountMinor: r.amountMinor,
    title: r.title,
    remarks: r.remarks,
    frequency: r.frequency,
    intervalCount: r.intervalCount,
    startDate: r.startDate,
    endDate: r.endDate,
    nextDueDate: r.nextDueDate,
    remindDaysBefore: r.remindDaysBefore,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // ------------------------------------------------------------ validation

  Future<AccountRow> _account(int profileId, int id, String label) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('$label not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException('$label belongs to a different profile.');
    }
    if (!row.isActive) {
      throw ValidationException('$label "${row.name}" is inactive.');
    }
    return row;
  }

  /// Validates [i] and returns the cleaned values (unused parents nulled).
  Future<RecurringInput> _validate(int profileId, RecurringInput i) async {
    if (const ['expense', 'income', 'transfer'].contains(i.type) == false) {
      throw ValidationException('Choose expense, income or transfer.');
    }
    if (i.amountMinor <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    if (!RecurrenceFrequency.all.contains(i.frequency)) {
      throw ValidationException('Choose a valid frequency.');
    }
    if (i.intervalCount < 1) {
      throw ValidationException('Repeat interval must be at least 1.');
    }
    final title = _clean(i.title);
    if (title == null) throw ValidationException('Title is required.');
    if (!isValidDateKey(i.startDate)) {
      throw ValidationException('Enter a valid start date.');
    }
    final end = _clean(i.endDate);
    if (end != null) {
      if (!isValidDateKey(end)) {
        throw ValidationException('Enter a valid end date.');
      }
      if (end.compareTo(i.startDate) < 0) {
        throw ValidationException('End date cannot be before the start date.');
      }
    }
    final r = i.remindDaysBefore;
    if (r != null && (r < 0 || r > 30)) {
      throw ValidationException('Reminder must be between 0 and 30 days.');
    }

    await _account(
      profileId,
      i.accountId,
      i.type == 'transfer' ? 'Source account' : 'Account',
    );
    int? toAccount, cat, sub, item;
    String? source;
    if (i.type == 'transfer') {
      if (i.toAccountId == null) {
        throw ValidationException('Choose a destination account.');
      }
      if (i.toAccountId == i.accountId) {
        throw ValidationException(
          'Choose two different accounts for a transfer.',
        );
      }
      await _account(profileId, i.toAccountId!, 'Destination account');
      toAccount = i.toAccountId;
    } else if (i.type == 'income') {
      source = _clean(i.incomeSource);
      if (source == null) {
        throw ValidationException('Income source is required.');
      }
    } else {
      if (i.categoryId == null) {
        throw ValidationException('Category is required for an expense.');
      }
      final c = await (_db.select(
        _db.categories,
      )..where((t) => t.id.equals(i.categoryId!))).getSingleOrNull();
      if (c == null) throw NotFoundException('Category not found.');
      if (c.profileId != profileId) {
        throw ProfileMismatchException(
          'Category belongs to a different profile.',
        );
      }
      if (!c.isActive) {
        throw ValidationException('Category "${c.name}" is inactive.');
      }
      cat = c.id;
      if (i.subCategoryId != null) {
        final s = await (_db.select(
          _db.subCategories,
        )..where((t) => t.id.equals(i.subCategoryId!))).getSingleOrNull();
        if (s == null) throw NotFoundException('Sub-category not found.');
        if (s.profileId != profileId) {
          throw ProfileMismatchException(
            'Sub-category belongs to a different profile.',
          );
        }
        if (s.categoryId != c.id) {
          throw ValidationException(
            'Sub-category "${s.name}" does not belong to "${c.name}".',
          );
        }
        if (!s.isActive) {
          throw ValidationException('Sub-category "${s.name}" is inactive.');
        }
        sub = s.id;
        if (i.costItemId != null) {
          final it = await (_db.select(
            _db.costItems,
          )..where((t) => t.id.equals(i.costItemId!))).getSingleOrNull();
          if (it == null) throw NotFoundException('Cost item not found.');
          if (it.profileId != profileId) {
            throw ProfileMismatchException(
              'Cost item belongs to a different profile.',
            );
          }
          if (it.subCategoryId != s.id) {
            throw ValidationException(
              'Cost item "${it.name}" does not belong to "${s.name}".',
            );
          }
          if (!it.isActive) {
            throw ValidationException('Cost item "${it.name}" is inactive.');
          }
          item = it.id;
        }
      } else if (i.costItemId != null) {
        throw ValidationException('Choose a sub-category for the cost item.');
      }
    }
    return RecurringInput(
      type: i.type,
      accountId: i.accountId,
      toAccountId: toAccount,
      categoryId: cat,
      subCategoryId: sub,
      costItemId: item,
      incomeSource: source,
      amountMinor: i.amountMinor,
      title: title,
      remarks: _clean(i.remarks),
      frequency: i.frequency,
      intervalCount: i.intervalCount,
      startDate: i.startDate,
      endDate: end,
      remindDaysBefore: r,
    );
  }

  Never _rethrow(Object e) {
    if (e is AppException) throw e;
    final m = e.toString().toLowerCase();
    if (m.contains('foreign key')) {
      throw ProfileMismatchException(
        'A selected item belongs to another profile.',
      );
    }
    if (m.contains('check constraint')) {
      throw ValidationException('The recurring rule values are not valid.');
    }
    throw e;
  }

  // ------------------------------------------------------------------ write

  Future<RecurringRule> create(int profileId, RecurringInput input) async {
    try {
      final v = await _validate(profileId, input);
      final now = DateTime.now();
      final id = await _db
          .into(_db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              profileId: profileId,
              type: v.type,
              accountId: v.accountId,
              toAccountId: Value(v.toAccountId),
              categoryId: Value(v.categoryId),
              subCategoryId: Value(v.subCategoryId),
              costItemId: Value(v.costItemId),
              incomeSource: Value(v.incomeSource),
              amountMinor: v.amountMinor,
              title: v.title,
              remarks: Value(v.remarks),
              frequency: v.frequency,
              intervalCount: Value(v.intervalCount),
              startDate: v.startDate,
              endDate: Value(v.endDate),
              nextDueDate: v.startDate,
              remindDaysBefore: Value(v.remindDaysBefore),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return (await getById(profileId, id))!;
    } on Object catch (e) {
      _rethrow(e);
    }
  }

  /// Edits a rule. When start/frequency/interval change, the schedule is
  /// re-anchored: next due becomes the first occurrence on/after the old
  /// next-due date (generated duplicates are still blocked by the
  /// idempotency key).
  Future<RecurringRule> update(
    int profileId,
    int id,
    RecurringInput input,
  ) async {
    try {
      final old = await _row(profileId, id);
      final v = await _validate(profileId, input);
      var next = old.nextDueDate;
      final scheduleChanged =
          old.startDate != v.startDate ||
          old.frequency != v.frequency ||
          old.intervalCount != v.intervalCount;
      if (scheduleChanged) {
        next = firstDueKeyOnOrAfter(
          v.startDate,
          v.frequency,
          v.intervalCount,
          old.nextDueDate,
        );
      }
      var active = old.isActive;
      if (v.endDate != null && next.compareTo(v.endDate!) > 0) active = false;
      await (_db.update(
        _db.recurringRules,
      )..where((t) => t.profileId.equals(profileId) & t.id.equals(id))).write(
        RecurringRulesCompanion(
          type: Value(v.type),
          accountId: Value(v.accountId),
          toAccountId: Value(v.toAccountId),
          categoryId: Value(v.categoryId),
          subCategoryId: Value(v.subCategoryId),
          costItemId: Value(v.costItemId),
          incomeSource: Value(v.incomeSource),
          amountMinor: Value(v.amountMinor),
          title: Value(v.title),
          remarks: Value(v.remarks),
          frequency: Value(v.frequency),
          intervalCount: Value(v.intervalCount),
          startDate: Value(v.startDate),
          endDate: Value(v.endDate),
          nextDueDate: Value(next),
          remindDaysBefore: Value(v.remindDaysBefore),
          isActive: Value(active),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(profileId, id))!;
    } on Object catch (e) {
      _rethrow(e);
    }
  }

  /// Pause (`active: false`) or resume. Resuming skips occurrences that fell
  /// due while paused (next due moves to the first occurrence on/after
  /// [today]) and is rejected for ended rules or inactive parents.
  Future<RecurringRule> setActive(
    int profileId,
    int id,
    bool active, {
    DateTime? today,
  }) async {
    try {
      final old = await _row(profileId, id);
      var next = old.nextDueDate;
      if (active && !old.isActive) {
        final todayKey = dateKey(today ?? DateTime.now());
        if (next.compareTo(todayKey) < 0) {
          next = firstDueKeyOnOrAfter(
            old.startDate,
            old.frequency,
            old.intervalCount,
            todayKey,
          );
        }
        if (old.endDate != null && next.compareTo(old.endDate!) > 0) {
          throw ValidationException('This rule has ended; edit the end date.');
        }
        await _account(profileId, old.accountId, 'Account');
        if (old.toAccountId != null) {
          await _account(profileId, old.toAccountId!, 'Destination account');
        }
      }
      await (_db.update(
        _db.recurringRules,
      )..where((t) => t.profileId.equals(profileId) & t.id.equals(id))).write(
        RecurringRulesCompanion(
          isActive: Value(active),
          nextDueDate: Value(next),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(profileId, id))!;
    } on Object catch (e) {
      _rethrow(e);
    }
  }

  // ------------------------------------------------------------------- read

  Future<RecurringRuleRow> _row(int profileId, int id) async {
    final row = await (_db.select(
      _db.recurringRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw NotFoundException('Recurring rule not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Recurring rule belongs to a different profile.',
      );
    }
    return row;
  }

  Future<RecurringRule?> getById(int profileId, int id) async {
    final row =
        await (_db.select(_db.recurringRules)
              ..where((t) => t.profileId.equals(profileId) & t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : map(row);
  }

  SimpleSelectStatement<$RecurringRulesTable, RecurringRuleRow> _listQuery(
    int profileId,
  ) => _db.select(_db.recurringRules)
    ..where((t) => t.profileId.equals(profileId))
    ..orderBy([
      (t) => OrderingTerm.desc(t.isActive),
      (t) => OrderingTerm.asc(t.nextDueDate),
      (t) => OrderingTerm.asc(t.id),
    ]);

  /// Active rules first (soonest next due), then paused/ended.
  Future<List<RecurringRule>> list(int profileId) async =>
      (await _listQuery(profileId).get()).map(map).toList();

  Stream<List<RecurringRule>> watchAll(int profileId) =>
      _listQuery(profileId).watch().map((rows) => rows.map(map).toList());

  /// Active, not-ended rules due on or before today + [days] (overdue rules
  /// included), soonest first.
  Future<List<RecurringRule>> upcoming(
    int profileId,
    int days, {
    DateTime? today,
  }) async {
    final t = today ?? DateTime.now();
    final limit = dateKey(DateTime(t.year, t.month, t.day + days));
    final rows =
        await (_db.select(_db.recurringRules)
              ..where(
                (r) =>
                    r.profileId.equals(profileId) &
                    r.isActive.equals(true) &
                    r.nextDueDate.isSmallerOrEqualValue(limit),
              )
              ..orderBy([
                (r) => OrderingTerm.asc(r.nextDueDate),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    return rows.map(map).where((r) => !r.isCompleted).toList();
  }
}
