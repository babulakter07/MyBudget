import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../domain/debt.dart';

/// Separate loan ledger: never touches accounts, budgets or transactions.
class DebtRepository {
  DebtRepository(this._db, {String Function()? today})
    : _today = today ?? (() => dateKey(DateTime.now()));
  final AppDatabase _db;
  final String Function() _today;

  static const _paidSql =
      'COALESCE((SELECT SUM(p.amount_minor) FROM debt_payments p '
      'WHERE p.profile_id = d.profile_id AND p.debt_id = d.id '
      'AND p.is_deleted = 0), 0)';

  static const _debtSelect =
      'SELECT d.*, $_paidSql AS paid_minor FROM debts d ';

  Set<TableInfo> get _readsFrom => {_db.debts, _db.debtPayments};

  Debt _mapRow(QueryRow r) {
    final principal = r.read<int>('principal_minor');
    final paid = r.read<int>('paid_minor');
    final due = r.read<String?>('due_date');
    final outstanding = principal - paid;
    final status = outstanding <= 0
        ? DebtStatus.settled
        : (due != null && due.compareTo(_today()) < 0)
        ? DebtStatus.overdue
        : DebtStatus.open;
    return Debt(
      id: r.read<int>('id'),
      profileId: r.read<int>('profile_id'),
      direction: r.read<String>('direction'),
      personName: r.read<String>('person_name'),
      principalMinor: principal,
      paidMinor: paid,
      startDate: r.read<String>('start_date'),
      dueDate: due,
      note: r.read<String?>('note'),
      isActive: r.read<bool>('is_active'),
      status: status,
      createdAt: r.read<DateTime>('created_at'),
      updatedAt: r.read<DateTime>('updated_at'),
    );
  }

  DebtPayment _mapPayment(DebtPaymentRow r) => DebtPayment(
    id: r.id,
    profileId: r.profileId,
    debtId: r.debtId,
    amountMinor: r.amountMinor,
    paymentDate: r.paymentDate,
    note: r.note,
    isDeleted: r.isDeleted,
    createdAt: r.createdAt,
  );

  // ---- validation ----

  String _validDirection(String d) {
    if (!debtDirections.contains(d)) {
      throw ValidationException('Direction must be lent or borrowed.');
    }
    return d;
  }

  String _validPerson(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Person name is required.');
    if (n.length > 80) {
      throw ValidationException('Person name must be 80 characters or less.');
    }
    return n;
  }

  int _validPrincipal(int minor) {
    if (minor <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    return minor;
  }

  void _validDates(String start, String? due) {
    if (!isValidDateKey(start)) {
      throw ValidationException('Start date is invalid.');
    }
    if (due != null) {
      if (!isValidDateKey(due)) {
        throw ValidationException('Due date is invalid.');
      }
      if (due.compareTo(start) < 0) {
        throw ValidationException('Due date cannot be before the start date.');
      }
    }
  }

  String? _cleanNote(String? note) {
    final n = note?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  // ---- debts ----

  Future<Debt> create({
    required int profileId,
    required String direction,
    required String personName,
    required int principalMinor,
    required String startDate,
    String? dueDate,
    String? note,
  }) async {
    final dir = _validDirection(direction);
    final person = _validPerson(personName);
    final principal = _validPrincipal(principalMinor);
    _validDates(startDate, dueDate);
    final profile = await (_db.select(
      _db.financialProfiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (profile == null) throw NotFoundException('Profile not found.');
    final now = DateTime.now();
    final id = await _db
        .into(_db.debts)
        .insert(
          DebtsCompanion.insert(
            profileId: profileId,
            direction: dir,
            personName: person,
            principalMinor: principal,
            startDate: startDate,
            dueDate: Value(dueDate),
            note: Value(_cleanNote(note)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(profileId, id))!;
  }

  Future<Debt> update({
    required int profileId,
    required int id,
    required String direction,
    required String personName,
    required int principalMinor,
    required String startDate,
    String? dueDate,
    String? note,
  }) async {
    final dir = _validDirection(direction);
    final person = _validPerson(personName);
    final principal = _validPrincipal(principalMinor);
    _validDates(startDate, dueDate);
    return _db.transaction(() async {
      final existing = await getById(profileId, id);
      if (existing == null) throw NotFoundException('Debt not found.');
      if (principal < existing.paidMinor) {
        throw ValidationException(
          'Amount cannot be less than the ${formatMinor(existing.paidMinor)} '
          'already repaid.',
        );
      }
      final earliest = await _earliestPaymentDate(profileId, id);
      if (earliest != null && startDate.compareTo(earliest) > 0) {
        throw ValidationException(
          'Start date cannot be after the first repayment ($earliest).',
        );
      }
      await (_db.update(
        _db.debts,
      )..where((d) => d.profileId.equals(profileId) & d.id.equals(id))).write(
        DebtsCompanion(
          direction: Value(dir),
          personName: Value(person),
          principalMinor: Value(principal),
          startDate: Value(startDate),
          dueDate: Value(dueDate),
          note: Value(_cleanNote(note)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(profileId, id))!;
    });
  }

  Future<String?> _earliestPaymentDate(int profileId, int debtId) async {
    final r = await _db
        .customSelect(
          'SELECT MIN(payment_date) AS d FROM debt_payments '
          'WHERE profile_id = ? AND debt_id = ? AND is_deleted = 0',
          variables: [Variable.withInt(profileId), Variable.withInt(debtId)],
        )
        .getSingle();
    return r.read<String?>('d');
  }

  /// Soft archive / unarchive. Debts are never deleted.
  Future<void> setArchived(int profileId, int id, bool archived) async {
    final n =
        await (_db.update(
          _db.debts,
        )..where((d) => d.profileId.equals(profileId) & d.id.equals(id))).write(
          DebtsCompanion(
            isActive: Value(!archived),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (n == 0) throw NotFoundException('Debt not found.');
  }

  Future<Debt?> getById(int profileId, int id) async {
    final rows = await _db
        .customSelect(
          '$_debtSelect WHERE d.profile_id = ? AND d.id = ?',
          variables: [Variable.withInt(profileId), Variable.withInt(id)],
          readsFrom: _readsFrom,
        )
        .get();
    return rows.isEmpty ? null : _mapRow(rows.first);
  }

  Stream<Debt?> watchById(int profileId, int id) => _db
      .customSelect(
        '$_debtSelect WHERE d.profile_id = ? AND d.id = ?',
        variables: [Variable.withInt(profileId), Variable.withInt(id)],
        readsFrom: _readsFrom,
      )
      .watch()
      .map((rows) => rows.isEmpty ? null : _mapRow(rows.first));

  /// Debts of a profile, optionally by direction. Order: person (nocase),
  /// then start date.
  Stream<List<Debt>> watchAll(
    int profileId, {
    String? direction,
    bool includeArchived = false,
  }) {
    final where = StringBuffer('WHERE d.profile_id = ?');
    final vars = <Variable>[Variable.withInt(profileId)];
    if (direction != null) {
      where.write(' AND d.direction = ?');
      vars.add(Variable.withString(direction));
    }
    if (!includeArchived) where.write(' AND d.is_active = 1');
    return _db
        .customSelect(
          '$_debtSelect$where '
          'ORDER BY LOWER(d.person_name), d.start_date, d.id',
          variables: vars,
          readsFrom: _readsFrom,
        )
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  // ---- payments ----

  Stream<List<DebtPayment>> watchPayments(int profileId, int debtId) {
    final q = _db.select(_db.debtPayments)
      ..where((p) => p.profileId.equals(profileId) & p.debtId.equals(debtId))
      ..orderBy([
        (p) => OrderingTerm.desc(p.paymentDate),
        (p) => OrderingTerm.desc(p.id),
      ]);
    return q.watch().map((rows) => rows.map(_mapPayment).toList());
  }

  Future<DebtPayment> addPayment({
    required int profileId,
    required int debtId,
    required int amountMinor,
    required String paymentDate,
    String? note,
  }) async {
    if (amountMinor <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }
    if (!isValidDateKey(paymentDate)) {
      throw ValidationException('Payment date is invalid.');
    }
    return _db.transaction(() async {
      final debt = await getById(profileId, debtId);
      if (debt == null) throw NotFoundException('Debt not found.');
      if (!debt.isActive) {
        throw ValidationException('This debt is archived.');
      }
      if (paymentDate.compareTo(debt.startDate) < 0) {
        throw ValidationException(
          'Payment date cannot be before the debt start date '
          '(${debt.startDate}).',
        );
      }
      if (amountMinor > debt.outstandingMinor) {
        throw ValidationException(
          debt.outstandingMinor <= 0
              ? 'This debt is already settled.'
              : 'Amount exceeds the outstanding balance. Maximum is '
                    '${formatMinor(debt.outstandingMinor)}.',
        );
      }
      final id = await _db
          .into(_db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              profileId: profileId,
              debtId: debtId,
              amountMinor: amountMinor,
              paymentDate: paymentDate,
              note: Value(_cleanNote(note)),
              createdAt: DateTime.now(),
            ),
          );
      await _touch(profileId, debtId);
      final row = await (_db.select(
        _db.debtPayments,
      )..where((p) => p.id.equals(id))).getSingle();
      return _mapPayment(row);
    });
  }

  /// Records the full remaining amount as one repayment.
  Future<DebtPayment> settle({
    required int profileId,
    required int debtId,
    required String paymentDate,
    String? note,
  }) {
    return _db.transaction(() async {
      final debt = await getById(profileId, debtId);
      if (debt == null) throw NotFoundException('Debt not found.');
      if (debt.outstandingMinor <= 0) {
        throw ValidationException('This debt is already settled.');
      }
      return addPayment(
        profileId: profileId,
        debtId: debtId,
        amountMinor: debt.outstandingMinor,
        paymentDate: paymentDate,
        note: note,
      );
    });
  }

  /// Soft-voids a repayment; outstanding is recomputed automatically.
  Future<void> voidPayment(int profileId, int paymentId) async {
    await _db.transaction(() async {
      final p =
          await (_db.select(_db.debtPayments)..where(
                (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
              ))
              .getSingleOrNull();
      if (p == null) throw NotFoundException('Payment not found.');
      if (p.isDeleted) {
        throw ValidationException('This payment is already voided.');
      }
      await (_db.update(_db.debtPayments)..where(
            (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
          ))
          .write(const DebtPaymentsCompanion(isDeleted: Value(true)));
      await _touch(profileId, p.debtId);
    });
  }

  Future<void> _touch(int profileId, int debtId) =>
      (_db.update(_db.debts)
            ..where((d) => d.profileId.equals(profileId) & d.id.equals(debtId)))
          .write(DebtsCompanion(updatedAt: Value(DateTime.now())));

  // ---- summary ----

  Stream<DebtSummary> watchSummary(int profileId) => _db
      .customSelect(
        'SELECT 1 AS x FROM debts WHERE profile_id = ?',
        variables: [Variable.withInt(profileId)],
        readsFrom: _readsFrom,
      )
      .watch()
      .asyncMap((_) => summary(profileId));

  /// Totals over active (non-archived) debts, SQL-computed. Settled debts
  /// contribute zero; people with nothing outstanding are omitted.
  Future<DebtSummary> summary(int profileId) async {
    final totals = await _db
        .customSelect(
          '''
SELECT
  COALESCE(SUM(CASE WHEN direction = 'lent' THEN o ELSE 0 END), 0) AS owed,
  COALESCE(SUM(CASE WHEN direction = 'borrowed' THEN o ELSE 0 END), 0) AS owe,
  COALESCE(SUM(CASE WHEN o > 0 AND due_date IS NOT NULL AND due_date < ?
                    THEN 1 ELSE 0 END), 0) AS overdue,
  COUNT(*) AS cnt
FROM (SELECT d.direction AS direction, d.due_date AS due_date,
             d.principal_minor - $_paidSql AS o
      FROM debts d WHERE d.profile_id = ? AND d.is_active = 1)
''',
          variables: [
            Variable.withString(_today()),
            Variable.withInt(profileId),
          ],
          readsFrom: _readsFrom,
        )
        .getSingle();
    final people = await _db
        .customSelect(
          '''
SELECT MIN(person_name) AS person_name,
  COALESCE(SUM(CASE WHEN direction = 'lent' THEN o ELSE 0 END), 0) AS lent,
  COALESCE(SUM(CASE WHEN direction = 'borrowed' THEN o ELSE 0 END), 0) AS borrowed,
  COUNT(*) AS cnt
FROM (SELECT d.direction AS direction, TRIM(d.person_name) AS person_name,
             d.principal_minor - $_paidSql AS o
      FROM debts d WHERE d.profile_id = ? AND d.is_active = 1)
WHERE o > 0
GROUP BY LOWER(person_name)
ORDER BY LOWER(person_name)
''',
          variables: [Variable.withInt(profileId)],
          readsFrom: _readsFrom,
        )
        .get();
    return DebtSummary(
      owedToMeMinor: totals.read<int>('owed'),
      iOweMinor: totals.read<int>('owe'),
      overdueCount: totals.read<int>('overdue'),
      activeCount: totals.read<int>('cnt'),
      people: [
        for (final r in people)
          PersonBalance(
            personName: r.read<String>('person_name'),
            lentOutstandingMinor: r.read<int>('lent'),
            borrowedOutstandingMinor: r.read<int>('borrowed'),
            debtCount: r.read<int>('cnt'),
          ),
      ],
    );
  }
}
