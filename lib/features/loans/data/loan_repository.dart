import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';

/// Bank-loan ledger. Separate from income/expense: it never touches accounts,
/// budgets or transactions. The repayment schedule is derived at query time
/// from the loan terms; only the real settlements are stored.
class LoanRepository {
  LoanRepository(this._db, {String Function()? today})
    : _today = today ?? (() => dateKey(DateTime.now()));
  final AppDatabase _db;
  final String Function() _today;

  static const _paidSql =
      'COALESCE((SELECT SUM(p.amount_minor) FROM loan_payments p '
      'WHERE p.profile_id = l.profile_id AND p.loan_id = l.id '
      'AND p.is_deleted = 0), 0)';

  static const _loanSelect =
      'SELECT l.*, $_paidSql AS paid_minor FROM loans l ';

  Set<TableInfo> get _readsFrom => {_db.loans, _db.loanPayments};

  LoanPosition _mapRow(
    QueryRow r, [
    List<({String date, int amount})> payments = const [],
  ]) {
    final loan = Loan(
      id: r.read<int>('id'),
      profileId: r.read<int>('profile_id'),
      lenderName: r.read<String>('lender_name'),
      loanType: r.read<String>('loan_type'),
      referenceNo: r.read<String?>('reference_no'),
      principalMinor: r.read<int>('principal_minor'),
      interestRateBp: r.read<int>('interest_rate_bp'),
      interestMethod: r.read<String>('interest_method'),
      frequency: r.read<String>('frequency'),
      tenureCount: r.read<int>('tenure_count'),
      installmentMinor: r.read<int>('installment_minor'),
      processingFeeMinor: r.read<int>('processing_fee_minor'),
      startDate: r.read<String>('start_date'),
      firstDueDate: r.read<String>('first_due_date'),
      note: r.read<String?>('note'),
      isActive: r.read<bool>('is_active'),
      createdAt: r.read<DateTime>('created_at'),
      updatedAt: r.read<DateTime>('updated_at'),
      closingType: r.read<String?>('closing_type'),
      closedDate: r.read<String?>('closed_date'),
      closingRemarks: r.read<String?>('closing_remarks'),
      closingPaidMinor: r.read<int?>('closing_paid_minor'),
      parentLoanId: r.read<int?>('parent_loan_id'),
    );
    return LoanCalculator.evaluate(
      loan,
      r.read<int>('paid_minor'),
      _today(),
      payments: payments,
    );
  }

  /// Non-deleted payments per loan, ordered by date then id (used to show
  /// the real settlement date of each paid installment).
  Future<Map<int, List<({String date, int amount})>>> _paymentsByLoan(
    int profileId,
  ) async {
    final rows =
        await (_db.select(_db.loanPayments)
              ..where(
                (p) =>
                    p.profileId.equals(profileId) & p.isDeleted.equals(false),
              )
              ..orderBy([
                (p) => OrderingTerm.asc(p.paymentDate),
                (p) => OrderingTerm.asc(p.id),
              ]))
            .get();
    final out = <int, List<({String date, int amount})>>{};
    for (final p in rows) {
      (out[p.loanId] ??= []).add((date: p.paymentDate, amount: p.amountMinor));
    }
    return out;
  }

  LoanPayment _mapPayment(LoanPaymentRow r) => LoanPayment(
    id: r.id,
    profileId: r.profileId,
    loanId: r.loanId,
    amountMinor: r.amountMinor,
    paymentDate: r.paymentDate,
    note: r.note,
    isDeleted: r.isDeleted,
    createdAt: r.createdAt,
  );

  // ---- validation ----

  String? _clean(String? s) {
    final n = s?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  void _validate({
    required String lenderName,
    required String loanType,
    required int principalMinor,
    required int interestRateBp,
    required String interestMethod,
    required String frequency,
    required int tenureCount,
    required int installmentMinor,
    required int processingFeeMinor,
    required String startDate,
    required String firstDueDate,
  }) {
    final lender = lenderName.trim();
    if (lender.isEmpty) throw ValidationException('Lender name is required.');
    if (lender.length > 80) {
      throw ValidationException('Lender name must be 80 characters or less.');
    }
    if (!loanTypes.contains(loanType)) {
      throw ValidationException('Unknown loan type.');
    }
    if (!loanMethods.contains(interestMethod)) {
      throw ValidationException('Interest method must be reducing or flat.');
    }
    if (!loanFrequencies.contains(frequency)) {
      throw ValidationException('Frequency must be weekly, monthly or yearly.');
    }
    if (principalMinor <= 0) {
      throw ValidationException('Loan amount must be greater than zero.');
    }
    if (interestRateBp < 0 || interestRateBp > 10000) {
      throw ValidationException('Interest rate must be between 0% and 100%.');
    }
    if (tenureCount < 1 || tenureCount > 1200) {
      throw ValidationException(
        'Number of installments must be between 1 and 1200.',
      );
    }
    if (installmentMinor <= 0) {
      throw ValidationException('Installment must be greater than zero.');
    }
    if (processingFeeMinor < 0) {
      throw ValidationException('Processing fee cannot be negative.');
    }
    if (!isValidDateKey(startDate)) {
      throw ValidationException('Disbursement date is invalid.');
    }
    if (!isValidDateKey(firstDueDate)) {
      throw ValidationException('First due date is invalid.');
    }
    if (firstDueDate.compareTo(startDate) < 0) {
      throw ValidationException(
        'First due date cannot be before the disbursement date.',
      );
    }
  }

  // ---- loans ----

  Future<LoanPosition> create({
    required int profileId,
    required String lenderName,
    String loanType = 'personal',
    String? referenceNo,
    required int principalMinor,
    required int interestRateBp,
    String interestMethod = 'reducing',
    String frequency = 'monthly',
    required int tenureCount,

    /// Bank's installment; computed from the terms when null.
    int? installmentMinor,
    int processingFeeMinor = 0,
    required String startDate,
    required String firstDueDate,
    String? note,
    int? parentLoanId,
  }) async {
    final installment =
        installmentMinor ??
        LoanCalculator.computeInstallment(
          principalMinor: principalMinor,
          rateBp: interestRateBp,
          method: interestMethod,
          frequency: frequency,
          count: tenureCount,
        );
    _validate(
      lenderName: lenderName,
      loanType: loanType,
      principalMinor: principalMinor,
      interestRateBp: interestRateBp,
      interestMethod: interestMethod,
      frequency: frequency,
      tenureCount: tenureCount,
      installmentMinor: installment,
      processingFeeMinor: processingFeeMinor,
      startDate: startDate,
      firstDueDate: firstDueDate,
    );
    final profile = await (_db.select(
      _db.financialProfiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (profile == null) throw NotFoundException('Profile not found.');
    final now = DateTime.now();
    final id = await _db
        .into(_db.loans)
        .insert(
          LoansCompanion.insert(
            profileId: profileId,
            lenderName: lenderName.trim(),
            loanType: Value(loanType),
            referenceNo: Value(_clean(referenceNo)),
            principalMinor: principalMinor,
            interestRateBp: interestRateBp,
            interestMethod: Value(interestMethod),
            frequency: Value(frequency),
            tenureCount: tenureCount,
            installmentMinor: installment,
            processingFeeMinor: Value(processingFeeMinor),
            startDate: startDate,
            firstDueDate: firstDueDate,
            note: Value(_clean(note)),
            parentLoanId: Value(parentLoanId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(profileId, id))!;
  }

  // ---- closing (v7) ----

  /// Settles a running loan before its schedule ends. [paidMinor] is what the
  /// borrower actually paid to close it (recorded as a payment on
  /// [closedDate]); the rest of the schedule is waived. The loan becomes
  /// history: no more edits or payments.
  Future<LoanPosition> closeEarly({
    required int profileId,
    required int loanId,
    required String closedDate,
    String? remarks,
    int paidMinor = 0,
  }) => _db.transaction(() async {
    final pos = await _requireOpen(profileId, loanId, closedDate);
    if (paidMinor < 0) {
      throw ValidationException('Amount paid cannot be negative.');
    }
    if (paidMinor > pos.remainingMinor) {
      throw ValidationException(
        'Amount paid exceeds the remaining balance. Maximum is '
        '${formatMinor(pos.remainingMinor)}.',
      );
    }
    if (paidMinor > 0) {
      await _db
          .into(_db.loanPayments)
          .insert(
            LoanPaymentsCompanion.insert(
              profileId: profileId,
              loanId: loanId,
              amountMinor: paidMinor,
              paymentDate: closedDate,
              note: const Value('Early closure'),
              createdAt: DateTime.now(),
            ),
          );
    }
    await _markClosed(
      profileId,
      loanId,
      type: 'early',
      closedDate: closedDate,
      remarks: remarks,
      paidMinor: paidMinor > 0 ? paidMinor : null,
    );
    return (await getById(profileId, loanId))!;
  });

  /// Adjusts (tops up / refinances) a running loan: the old loan is closed as
  /// 'adjusted' and a NEW loan, linked to it, takes over. [principalMinor] is
  /// the new loan amount (typically the old remaining principal plus any new
  /// money). Returns the new loan.
  Future<LoanPosition> adjust({
    required int profileId,
    required int loanId,
    required String closedDate,
    String? remarks,
    required String lenderName,
    String loanType = 'personal',
    String? referenceNo,
    required int principalMinor,
    required int interestRateBp,
    String interestMethod = 'reducing',
    String frequency = 'monthly',
    required int tenureCount,
    int? installmentMinor,
    int processingFeeMinor = 0,
    required String startDate,
    required String firstDueDate,
    String? note,
  }) => _db.transaction(() async {
    await _requireOpen(profileId, loanId, closedDate);
    final created = await create(
      profileId: profileId,
      lenderName: lenderName,
      loanType: loanType,
      referenceNo: referenceNo,
      principalMinor: principalMinor,
      interestRateBp: interestRateBp,
      interestMethod: interestMethod,
      frequency: frequency,
      tenureCount: tenureCount,
      installmentMinor: installmentMinor,
      processingFeeMinor: processingFeeMinor,
      startDate: startDate,
      firstDueDate: firstDueDate,
      note: note,
      parentLoanId: loanId,
    );
    await _markClosed(
      profileId,
      loanId,
      type: 'adjusted',
      closedDate: closedDate,
      remarks: remarks,
      paidMinor: null,
    );
    return created;
  });

  Future<LoanPosition> _requireOpen(
    int profileId,
    int loanId,
    String closedDate,
  ) async {
    final pos = await getById(profileId, loanId);
    if (pos == null) throw NotFoundException('Loan not found.');
    if (!pos.loan.isActive) {
      throw ValidationException('This loan is archived. Restore it first.');
    }
    if (pos.isClosed) {
      throw ValidationException('This loan is already closed.');
    }
    if (!isValidDateKey(closedDate)) {
      throw ValidationException('Closing date is invalid.');
    }
    if (closedDate.compareTo(pos.loan.startDate) < 0) {
      throw ValidationException(
        'Closing date cannot be before the disbursement date '
        '(${pos.loan.startDate}).',
      );
    }
    return pos;
  }

  Future<void> _markClosed(
    int profileId,
    int loanId, {
    required String type,
    required String closedDate,
    required String? remarks,
    required int? paidMinor,
  }) =>
      (_db.update(_db.loans)
            ..where((l) => l.profileId.equals(profileId) & l.id.equals(loanId)))
          .write(
            LoansCompanion(
              closingType: Value(type),
              closedDate: Value(closedDate),
              closingRemarks: Value(_clean(remarks)),
              closingPaidMinor: Value(paidMinor),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Lender, type, reference, fee and note are always editable. The financial
  /// terms (principal, rate, method, frequency, tenure, installment, dates)
  /// can only change while the loan has no non-deleted payments.
  Future<LoanPosition> update({
    required int profileId,
    required int id,
    required String lenderName,
    required String loanType,
    String? referenceNo,
    required int principalMinor,
    required int interestRateBp,
    required String interestMethod,
    required String frequency,
    required int tenureCount,
    int? installmentMinor,
    required int processingFeeMinor,
    required String startDate,
    required String firstDueDate,
    String? note,
  }) async {
    final installment =
        installmentMinor ??
        LoanCalculator.computeInstallment(
          principalMinor: principalMinor,
          rateBp: interestRateBp,
          method: interestMethod,
          frequency: frequency,
          count: tenureCount,
        );
    _validate(
      lenderName: lenderName,
      loanType: loanType,
      principalMinor: principalMinor,
      interestRateBp: interestRateBp,
      interestMethod: interestMethod,
      frequency: frequency,
      tenureCount: tenureCount,
      installmentMinor: installment,
      processingFeeMinor: processingFeeMinor,
      startDate: startDate,
      firstDueDate: firstDueDate,
    );
    return _db.transaction(() async {
      final existing = await getById(profileId, id);
      if (existing == null) throw NotFoundException('Loan not found.');
      if (existing.loan.isClosedByUser) {
        throw ValidationException(
          'A closed (early settled / adjusted) loan cannot be edited.',
        );
      }
      final o = existing.loan;
      final termsChanged =
          o.principalMinor != principalMinor ||
          o.interestMethod != interestMethod ||
          o.frequency != frequency ||
          o.tenureCount != tenureCount ||
          o.startDate != startDate ||
          o.firstDueDate != firstDueDate;
      if (termsChanged && existing.paidMinor > 0) {
        throw ValidationException(
          'Only the interest rate and installment can be changed after '
          'payments were recorded. Void the payments to change other terms.',
        );
      }
      // Variable-rate loans: the new rate/installment re-derive the whole
      // schedule, which must still cover what was already paid.
      if (existing.paidMinor > 0 &&
          (o.interestRateBp != interestRateBp ||
              o.installmentMinor != installment)) {
        final total = LoanCalculator.buildSchedule(
          principalMinor: principalMinor,
          rateBp: interestRateBp,
          method: interestMethod,
          frequency: frequency,
          count: tenureCount,
          installmentMinor: installment,
          firstDueDate: firstDueDate,
        ).fold<int>(0, (s, i) => s + i.installmentMinor);
        if (total < existing.paidMinor) {
          throw ValidationException(
            'The new rate/installment would make the total payable lower '
            'than the amount already paid.',
          );
        }
      }
      await (_db.update(
        _db.loans,
      )..where((l) => l.profileId.equals(profileId) & l.id.equals(id))).write(
        LoansCompanion(
          lenderName: Value(lenderName.trim()),
          loanType: Value(loanType),
          referenceNo: Value(_clean(referenceNo)),
          principalMinor: Value(principalMinor),
          interestRateBp: Value(interestRateBp),
          interestMethod: Value(interestMethod),
          frequency: Value(frequency),
          tenureCount: Value(tenureCount),
          installmentMinor: Value(installment),
          processingFeeMinor: Value(processingFeeMinor),
          startDate: Value(startDate),
          firstDueDate: Value(firstDueDate),
          note: Value(_clean(note)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(profileId, id))!;
    });
  }

  /// Soft archive / unarchive. Loans are never deleted.
  Future<void> setArchived(int profileId, int id, bool archived) async {
    final n =
        await (_db.update(
          _db.loans,
        )..where((l) => l.profileId.equals(profileId) & l.id.equals(id))).write(
          LoansCompanion(
            isActive: Value(!archived),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (n == 0) throw NotFoundException('Loan not found.');
  }

  Future<LoanPosition?> getById(int profileId, int id) async {
    final rows = await _db
        .customSelect(
          '$_loanSelect WHERE l.profile_id = ? AND l.id = ?',
          variables: [Variable.withInt(profileId), Variable.withInt(id)],
          readsFrom: _readsFrom,
        )
        .get();
    if (rows.isEmpty) return null;
    final pays = await _paymentsByLoan(profileId);
    return _mapRow(rows.first, pays[id] ?? const []);
  }

  Stream<LoanPosition?> watchById(int profileId, int id) => _db
      .customSelect(
        '$_loanSelect WHERE l.profile_id = ? AND l.id = ?',
        variables: [Variable.withInt(profileId), Variable.withInt(id)],
        readsFrom: _readsFrom,
      )
      .watch()
      .asyncMap((rows) async {
        if (rows.isEmpty) return null;
        final pays = await _paymentsByLoan(profileId);
        return _mapRow(rows.first, pays[id] ?? const []);
      });

  /// Loans of a profile ordered by lender (nocase), then start date.
  Stream<List<LoanPosition>> watchAll(
    int profileId, {
    bool includeArchived = false,
  }) {
    final archived = includeArchived ? '' : ' AND l.is_active = 1';
    return _db
        .customSelect(
          '$_loanSelect WHERE l.profile_id = ?$archived '
          'ORDER BY LOWER(l.lender_name), l.start_date, l.id',
          variables: [Variable.withInt(profileId)],
          readsFrom: _readsFrom,
        )
        .watch()
        .asyncMap((rows) async {
          final pays = await _paymentsByLoan(profileId);
          return [
            for (final r in rows)
              _mapRow(r, pays[r.read<int>('id')] ?? const []),
          ];
        });
  }

  // ---- payments ----

  Stream<List<LoanPayment>> watchPayments(int profileId, int loanId) {
    final q = _db.select(_db.loanPayments)
      ..where((p) => p.profileId.equals(profileId) & p.loanId.equals(loanId))
      ..orderBy([
        (p) => OrderingTerm.desc(p.paymentDate),
        (p) => OrderingTerm.desc(p.id),
      ]);
    return q.watch().map((rows) => rows.map(_mapPayment).toList());
  }

  Future<LoanPayment> addPayment({
    required int profileId,
    required int loanId,
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
      final pos = await getById(profileId, loanId);
      if (pos == null) throw NotFoundException('Loan not found.');
      if (!pos.loan.isActive) {
        throw ValidationException('This loan is archived.');
      }
      if (pos.loan.isClosedByUser) {
        throw ValidationException(
          'This loan is closed (early settled / adjusted).',
        );
      }
      if (paymentDate.compareTo(pos.loan.startDate) < 0) {
        throw ValidationException(
          'Payment date cannot be before the disbursement date '
          '(${pos.loan.startDate}).',
        );
      }
      if (amountMinor > pos.remainingMinor) {
        throw ValidationException(
          pos.remainingMinor <= 0
              ? 'This loan is already fully paid.'
              : 'Amount exceeds the remaining balance. Maximum is '
                    '${formatMinor(pos.remainingMinor)}.',
        );
      }
      final id = await _db
          .into(_db.loanPayments)
          .insert(
            LoanPaymentsCompanion.insert(
              profileId: profileId,
              loanId: loanId,
              amountMinor: amountMinor,
              paymentDate: paymentDate,
              note: Value(_clean(note)),
              createdAt: DateTime.now(),
            ),
          );
      await _touch(profileId, loanId);
      final row = await (_db.select(
        _db.loanPayments,
      )..where((p) => p.id.equals(id))).getSingle();
      return _mapPayment(row);
    });
  }

  /// Soft-voids a payment; the remaining balance is recomputed automatically.
  Future<void> voidPayment(int profileId, int paymentId) async {
    await _db.transaction(() async {
      final p =
          await (_db.select(_db.loanPayments)..where(
                (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
              ))
              .getSingleOrNull();
      if (p == null) throw NotFoundException('Payment not found.');
      if (p.isDeleted) {
        throw ValidationException('This payment is already voided.');
      }
      final loan =
          await (_db.select(_db.loans)..where(
                (l) => l.profileId.equals(profileId) & l.id.equals(p.loanId),
              ))
              .getSingle();
      if (loan.closingType != null) {
        throw ValidationException(
          'Payments of a closed (early settled / adjusted) loan cannot be '
          'voided.',
        );
      }
      await (_db.update(_db.loanPayments)..where(
            (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
          ))
          .write(const LoanPaymentsCompanion(isDeleted: Value(true)));
      await _touch(profileId, p.loanId);
    });
  }

  Future<void> _touch(int profileId, int loanId) =>
      (_db.update(_db.loans)
            ..where((l) => l.profileId.equals(profileId) & l.id.equals(loanId)))
          .write(LoansCompanion(updatedAt: Value(DateTime.now())));

  // ---- summary ----

  Stream<LoanSummary> watchSummary(int profileId) => _db
      .customSelect(
        '$_loanSelect WHERE l.profile_id = ? AND l.is_active = 1',
        variables: [Variable.withInt(profileId)],
        readsFrom: _readsFrom,
      )
      .watch()
      .map((rows) => summarize(rows.map(_mapRow).toList()));

  Future<LoanSummary> summary(int profileId) async {
    final rows = await _db
        .customSelect(
          '$_loanSelect WHERE l.profile_id = ? AND l.is_active = 1',
          variables: [Variable.withInt(profileId)],
          readsFrom: _readsFrom,
        )
        .get();
    return summarize(rows.map(_mapRow).toList());
  }

  /// Totals over [positions] (callers pass the non-archived loans).
  static LoanSummary summarize(List<LoanPosition> positions) {
    var remaining = 0, overdue = 0, overdueCount = 0, monthly = 0;
    String? nextDate;
    var nextMinor = 0;
    for (final p in positions) {
      if (p.isClosed) continue;
      remaining += p.remainingMinor;
      overdue += p.overdueMinor;
      overdueCount += p.overdueCount;
      monthly += LoanCalculator.monthlyEquivalent(
        p.loan.installmentMinor,
        p.loan.frequency,
      );
      final n = p.nextDue;
      if (n != null) {
        final cmp = nextDate == null ? -1 : n.dueDate.compareTo(nextDate);
        if (cmp < 0) {
          nextDate = n.dueDate;
          nextMinor = n.unpaidMinor;
        } else if (cmp == 0) {
          nextMinor += n.unpaidMinor;
        }
      }
    }
    return LoanSummary(
      remainingMinor: remaining,
      overdueMinor: overdue,
      overdueCount: overdueCount,
      activeCount: positions.length,
      monthlyCommitmentMinor: monthly,
      nextDueDate: nextDate,
      nextDueMinor: nextMinor,
    );
  }
}
