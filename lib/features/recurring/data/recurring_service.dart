import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_models.dart';

/// Posts due occurrences of recurring rules as ordinary transactions through
/// [TransactionRepository] (name snapshots, opening-date rule, audit log).
class RecurringService {
  RecurringService(this._db, this._txns);
  final AppDatabase _db;
  final TransactionRepository _txns;

  static const maxPerRulePerRun = 366;

  final Map<int, Future<GenerationResult>> _running = {};

  static String idempotencyKey(int ruleId, String date) => 'rec:$ruleId:$date';

  /// Posts every missed occurrence with date <= [today] for all active rules
  /// of [profileId]. Concurrent calls for the same profile share one run.
  Future<GenerationResult> generateDue({
    required int profileId,
    DateTime? today,
  }) {
    final existing = _running[profileId];
    if (existing != null) return existing;
    final f = _run(profileId, today ?? DateTime.now()).whenComplete(() {
      _running.remove(profileId);
    });
    _running[profileId] = f;
    return f;
  }

  Future<GenerationResult> _run(int profileId, DateTime today) async {
    final todayKey = dateKey(today);
    final rules =
        await (_db.select(_db.recurringRules)
              ..where(
                (r) =>
                    r.profileId.equals(profileId) &
                    r.isActive.equals(true) &
                    r.nextDueDate.isSmallerOrEqualValue(todayKey),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.id)]))
            .get();

    final posted = <PostedOccurrence>[];
    final skipped = <SkippedOccurrence>[];
    final completed = <int>[];

    for (final rule in rules) {
      var count = 0;
      while (count < maxPerRulePerRun) {
        try {
          final step = await _postNext(profileId, rule.id, todayKey);
          if (step == null) break; // nothing (more) due
          posted.add(step.posted);
          if (step.completed) {
            completed.add(rule.id);
            break;
          }
          count++;
        } on _Failed catch (f) {
          skipped.add(
            SkippedOccurrence(
              ruleId: rule.id,
              title: f.title,
              date: f.date,
              reason: f.reason,
            ),
          );
          break; // keep order: later occurrences wait for this one
        }
      }
    }
    return GenerationResult(
      posted: posted,
      skipped: skipped,
      completedRuleIds: completed,
    );
  }

  /// Posts the rule's current due occurrence and advances it, atomically.
  /// Returns null if the rule is no longer due. Throws [_Failed] after rolling
  /// back everything for that occurrence.
  Future<_Step?> _postNext(int profileId, int ruleId, String todayKey) async {
    String title = '';
    String date = '';
    try {
      return await _db.transaction(() async {
        final r =
            await (_db.select(_db.recurringRules)..where(
                  (t) => t.profileId.equals(profileId) & t.id.equals(ruleId),
                ))
                .getSingleOrNull();
        if (r == null || !r.isActive) return null;
        if (r.nextDueDate.compareTo(todayKey) > 0) return null;
        if (r.endDate != null && r.nextDueDate.compareTo(r.endDate!) > 0) {
          await _deactivate(profileId, ruleId);
          return null;
        }
        title = r.title;
        date = r.nextDueDate;
        final key = idempotencyKey(r.id, date);
        final view = switch (r.type) {
          'expense' => await _txns.createExpense(
            profileId: profileId,
            accountId: r.accountId,
            categoryId: r.categoryId!,
            subCategoryId: r.subCategoryId,
            costItemId: r.costItemId,
            amountMinor: r.amountMinor,
            date: date,
            title: r.title,
            remarks: r.remarks,
            idempotencyKey: key,
          ),
          'income' => await _txns.createIncome(
            profileId: profileId,
            accountId: r.accountId,
            incomeSource: r.incomeSource ?? '',
            amountMinor: r.amountMinor,
            date: date,
            title: r.title,
            remarks: r.remarks,
            idempotencyKey: key,
          ),
          _ => await _txns.createTransfer(
            profileId: profileId,
            fromAccountId: r.accountId,
            toAccountId: r.toAccountId!,
            amountMinor: r.amountMinor,
            date: date,
            title: r.title,
            remarks: r.remarks,
            idempotencyKey: key,
          ),
        };
        final next = nextDueKeyAfter(
          r.startDate,
          r.frequency,
          r.intervalCount,
          date,
        );
        final done = r.endDate != null && next.compareTo(r.endDate!) > 0;
        await (_db.update(_db.recurringRules)..where(
              (t) => t.profileId.equals(profileId) & t.id.equals(ruleId),
            ))
            .write(
              RecurringRulesCompanion(
                nextDueDate: Value(next),
                isActive: Value(!done),
                updatedAt: Value(DateTime.now()),
              ),
            );
        return _Step(
          PostedOccurrence(
            ruleId: ruleId,
            title: title,
            date: date,
            transactionId: view.id,
          ),
          done,
        );
      });
    } on Object catch (e) {
      final reason = e is AppException ? e.message : 'Unexpected error: $e';
      throw _Failed(title, date, reason);
    }
  }

  Future<void> _deactivate(int profileId, int ruleId) =>
      (_db.update(_db.recurringRules)
            ..where((t) => t.profileId.equals(profileId) & t.id.equals(ruleId)))
          .write(
            RecurringRulesCompanion(
              isActive: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
}

class _Step {
  _Step(this.posted, this.completed);
  final PostedOccurrence posted;
  final bool completed;
}

class _Failed implements Exception {
  _Failed(this.title, this.date, this.reason);
  final String title;
  final String date;
  final String reason;
}
