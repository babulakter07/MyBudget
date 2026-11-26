import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/dps.dart';

/// DPS ledger. Every query is scoped by profile; nothing is hard deleted and
/// accounts, budgets and transactions are never touched.
class DpsRepository {
  DpsRepository(this._db, {String Function()? today})
    : _today = today ?? (() => dateKey(DateTime.now()));

  final AppDatabase _db;
  final String Function() _today;

  // ------------------------------------------------------------------ mapping

  DpsAccount _account(DpsAccountRow r) => DpsAccount(
    id: r.id,
    profileId: r.profileId,
    terms: DpsTerms(
      bankName: r.bankName,
      accountNumber: r.accountNumber,
      installmentMinor: r.installmentMinor,
      tenureMonths: r.tenureMonths,
      openDate: r.openDate,
      firstDueDate: r.firstDueDate,
      rateBp: r.rateBp,
      bankMaturityMinor: r.bankMaturityMinor,
      taxRateBp: r.taxRateBp,
      lateFeeMinor: r.lateFeeMinor,
      graceDays: r.graceDays,
      missedLimit: r.missedLimit,
      note: r.note,
    ),
    isActive: r.isActive,
    closingType: DpsClosingType.parse(r.closingType),
    closedDate: r.closedDate,
    profitMinor: r.profitMinor,
    taxMinor: r.taxMinor,
    chargeMinor: r.chargeMinor,
    netReceivedMinor: r.netReceivedMinor,
  );

  DpsPayment _payment(DpsPaymentRow r) => DpsPayment(
    id: r.id,
    dpsId: r.dpsId,
    installments: r.installments,
    lateFeeMinor: r.lateFeeMinor,
    paymentDate: r.paymentDate,
    isDeleted: r.isDeleted,
    note: r.note,
  );

  // ------------------------------------------------------------------ queries

  Future<DpsAccountRow> _row(int profileId, int id) async {
    final row =
        await (_db.select(_db.dpsAccounts)
              ..where((a) => a.profileId.equals(profileId) & a.id.equals(id)))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('DPS account not found.');
    return row;
  }

  Future<List<DpsPaymentRow>> _paymentRows(int profileId, [int? dpsId]) =>
      (_db.select(_db.dpsPayments)..where(
            (p) =>
                p.profileId.equals(profileId) &
                (dpsId == null ? const Constant(true) : p.dpsId.equals(dpsId)),
          ))
          .get();

  /// Accounts of a profile: open ones first, then by bank name.
  Future<List<DpsPosition>> loadAll(
    int profileId, {
    bool includeArchived = false,
  }) async {
    final rows =
        await (_db.select(_db.dpsAccounts)..where(
              (a) =>
                  a.profileId.equals(profileId) &
                  (includeArchived
                      ? const Constant(true)
                      : a.isActive.equals(true)),
            ))
            .get();
    final payments = <int, List<DpsPayment>>{};
    for (final p in await _paymentRows(profileId)) {
      payments.putIfAbsent(p.dpsId, () => []).add(_payment(p));
    }
    final today = _today();
    final out = [
      for (final r in rows)
        DpsCalculator.position(
          account: _account(r),
          payments: payments[r.id] ?? const [],
          today: today,
        ),
    ];
    out.sort((a, b) {
      if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
      final byBank = a.terms.bankName.toLowerCase().compareTo(
        b.terms.bankName.toLowerCase(),
      );
      return byBank != 0 ? byBank : a.account.id.compareTo(b.account.id);
    });
    return out;
  }

  Future<DpsPosition?> getById(int profileId, int id) async {
    final row =
        await (_db.select(_db.dpsAccounts)
              ..where((a) => a.profileId.equals(profileId) & a.id.equals(id)))
            .getSingleOrNull();
    if (row == null) return null;
    return DpsCalculator.position(
      account: _account(row),
      payments: [
        for (final p in await _paymentRows(profileId, id)) _payment(p),
      ],
      today: _today(),
    );
  }

  Stream<T> _watch<T>(Future<T> Function() load) => _db
      .customSelect(
        'SELECT 1 AS x',
        readsFrom: {_db.dpsAccounts, _db.dpsPayments},
      )
      .watch()
      .asyncMap((_) => load());

  Stream<List<DpsPosition>> watchAll(
    int profileId, {
    bool includeArchived = false,
  }) => _watch(() => loadAll(profileId, includeArchived: includeArchived));

  Stream<DpsPosition?> watchById(int profileId, int id) =>
      _watch(() => getById(profileId, id));

  /// All deposits of an account, newest first, voided ones included.
  Stream<List<DpsPayment>> watchPayments(int profileId, int dpsId) =>
      _watch(() async {
        final rows = await _paymentRows(profileId, dpsId);
        rows.sort((a, b) {
          final c = b.paymentDate.compareTo(a.paymentDate);
          return c != 0 ? c : b.id.compareTo(a.id);
        });
        return [for (final r in rows) _payment(r)];
      });

  // ------------------------------------------------------------------- writes

  String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  Future<void> _validate(int profileId, DpsTerms t, {int? excludeId}) async {
    void check(bool ok, String message) {
      if (!ok) throw ValidationException(message);
    }

    final bank = t.bankName.trim();
    check(bank.isNotEmpty && bank.length <= 80, 'Enter the bank name.');
    check(t.installmentMinor > 0, 'Installment must be greater than zero.');
    check(
      t.tenureMonths >= 1 && t.tenureMonths <= 360,
      'Term must be 1 to 360 months.',
    );
    check(
      isValidDateKey(t.openDate) && isValidDateKey(t.firstDueDate),
      'Enter valid dates.',
    );
    check(
      t.firstDueDate.compareTo(t.openDate) >= 0,
      'The first installment cannot be due before the opening date.',
    );
    check(t.rateBp >= 0 && t.rateBp <= 10000, 'Rate must be 0% to 100%.');
    check(
      t.taxRateBp >= 0 && t.taxRateBp <= 10000,
      'Tax rate must be 0% to 100%.',
    );
    check(t.lateFeeMinor >= 0, 'Late fee cannot be negative.');
    check(
      t.graceDays >= 0 && t.graceDays <= 60,
      'Grace period must be 0 to 60 days.',
    );
    check(
      t.missedLimit >= 0 && t.missedLimit <= 24,
      'Missed installment limit must be 0 to 24.',
    );
    check(
      t.bankMaturityMinor == null ||
          t.bankMaturityMinor! >= t.installmentMinor * t.tenureMonths,
      "The bank's maturity amount cannot be less than the total deposits.",
    );

    final number = _clean(t.accountNumber);
    if (number == null) return;
    final sameNumber = await _db
        .customSelect(
          'SELECT id FROM dps_accounts WHERE profile_id = ?1 '
          'AND account_number = ?2 COLLATE NOCASE',
          variables: [Variable(profileId), Variable(number)],
        )
        .get();
    if (sameNumber.any((r) => r.read<int>('id') != excludeId)) {
      throw DuplicateNameException(
        'Another DPS already uses account number "$number".',
      );
    }
  }

  DpsAccountsCompanion _companion(DpsTerms t) => DpsAccountsCompanion(
    bankName: Value(t.bankName.trim()),
    accountNumber: Value(_clean(t.accountNumber)),
    installmentMinor: Value(t.installmentMinor),
    tenureMonths: Value(t.tenureMonths),
    openDate: Value(t.openDate),
    firstDueDate: Value(t.firstDueDate),
    rateBp: Value(t.rateBp),
    bankMaturityMinor: Value(t.bankMaturityMinor),
    taxRateBp: Value(t.taxRateBp),
    lateFeeMinor: Value(t.lateFeeMinor),
    graceDays: Value(t.graceDays),
    missedLimit: Value(t.missedLimit),
    note: Value(_clean(t.note)),
    updatedAt: Value(DateTime.now()),
  );

  /// Creates an account. For a DPS that is already running, [paidInstallments]
  /// records the installments deposited before it was added to the app, dated
  /// on their due dates (never later than today) and without late fees.
  Future<DpsPosition> create({
    required int profileId,
    required DpsTerms terms,
    int paidInstallments = 0,
  }) => _db.transaction(() async {
    await _validate(profileId, terms);
    if (paidInstallments < 0 || paidInstallments > terms.tenureMonths) {
      throw ValidationException(
        'Installments already paid must be between 0 and the term.',
      );
    }
    final profile = await (_db.select(
      _db.financialProfiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (profile == null) throw NotFoundException('Profile not found.');
    final now = DateTime.now();
    final id = await _db
        .into(_db.dpsAccounts)
        .insert(
          _companion(terms)
              .copyWith(profileId: Value(profileId), createdAt: Value(now)),
        );
    final today = _today();
    for (var i = 0; i < paidInstallments; i++) {
      final due = DpsCalculator.addMonths(terms.firstDueDate, i);
      await _insertPayment(
        profileId,
        id,
        installments: 1,
        lateFeeMinor: 0,
        paymentDate: due.compareTo(today) > 0 ? today : due,
      );
    }
    return (await getById(profileId, id))!;
  });

  /// The installment, term and dates lock after the first deposit because
  /// they define the schedule the deposits were made against.
  Future<DpsPosition> update({
    required int profileId,
    required int id,
    required DpsTerms terms,
  }) => _db.transaction(() async {
    final old = await _row(profileId, id);
    _requireOpen(old);
    await _validate(profileId, terms, excludeId: id);
    final hasPayments = (await _paymentRows(
      profileId,
      id,
    )).any((p) => !p.isDeleted);
    if (hasPayments &&
        (terms.installmentMinor != old.installmentMinor ||
            terms.tenureMonths != old.tenureMonths ||
            terms.openDate != old.openDate ||
            terms.firstDueDate != old.firstDueDate)) {
      throw ValidationException(
        'The installment, term and dates cannot change after a deposit. '
        'Void the deposits first.',
      );
    }
    await (_db.update(_db.dpsAccounts)
          ..where((a) => a.profileId.equals(profileId) & a.id.equals(id)))
        .write(_companion(terms));
    return (await getById(profileId, id))!;
  });

  void _requireOpen(DpsAccountRow row) {
    if (row.closingType != null) {
      throw ValidationException('This DPS is closed and cannot be changed.');
    }
  }

  Future<int> _insertPayment(
    int profileId,
    int dpsId, {
    required int installments,
    required int lateFeeMinor,
    required String paymentDate,
    String? note,
  }) => _db
      .into(_db.dpsPayments)
      .insert(
        DpsPaymentsCompanion.insert(
          profileId: profileId,
          dpsId: dpsId,
          installments: installments,
          lateFeeMinor: Value(lateFeeMinor),
          paymentDate: paymentDate,
          note: Value(_clean(note)),
          createdAt: DateTime.now(),
        ),
      );

  /// Records a deposit of whole installments.
  Future<void> addPayment({
    required int profileId,
    required int dpsId,
    required int installments,
    int lateFeeMinor = 0,
    required String paymentDate,
    String? note,
  }) => _db.transaction(() async {
    final row = await _row(profileId, dpsId);
    _requireOpen(row);
    if (!row.isActive) {
      throw ValidationException('This DPS is archived.');
    }
    final position = (await getById(profileId, dpsId))!;
    if (installments < 1 || installments > position.remainingCount) {
      throw ValidationException(
        position.remainingCount == 0
            ? 'All installments are already paid.'
            : 'Enter 1 to ${position.remainingCount} installments.',
      );
    }
    if (lateFeeMinor < 0) {
      throw ValidationException('Late fee cannot be negative.');
    }
    if (!isValidDateKey(paymentDate) ||
        paymentDate.compareTo(row.openDate) < 0 ||
        paymentDate.compareTo(_today()) > 0) {
      throw ValidationException(
        'The deposit date must be between the opening date and today.',
      );
    }
    await _insertPayment(
      profileId,
      dpsId,
      installments: installments,
      lateFeeMinor: lateFeeMinor,
      paymentDate: paymentDate,
      note: note,
    );
    await _touch(profileId, dpsId);
  });

  Future<void> voidPayment(int profileId, int paymentId) =>
      _db.transaction(() async {
        final p =
            await (_db.select(_db.dpsPayments)..where(
                  (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
                ))
                .getSingleOrNull();
        if (p == null) throw NotFoundException('Deposit not found.');
        _requireOpen(await _row(profileId, p.dpsId));
        if (p.isDeleted) return;
        await (_db.update(_db.dpsPayments)..where(
              (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
            ))
            .write(const DpsPaymentsCompanion(isDeleted: Value(true)));
        await _touch(profileId, p.dpsId);
      });

  /// Bumps `updated_at` so reminders and backups notice a change.
  Future<void> _touch(int profileId, int id) =>
      (_db.update(_db.dpsAccounts)
            ..where((a) => a.profileId.equals(profileId) & a.id.equals(id)))
          .write(DpsAccountsCompanion(updatedAt: Value(DateTime.now())));

  /// Closes the account with the figures on the bank's statement. Net received
  /// defaults to deposits + profit - tax - charges.
  Future<DpsPosition> close({
    required int profileId,
    required int id,
    required DpsClosingType type,
    required String closedDate,
    required int profitMinor,
    required int taxMinor,
    required int chargeMinor,
    int? netReceivedMinor,
  }) => _db.transaction(() async {
    final row = await _row(profileId, id);
    _requireOpen(row);
    if (!row.isActive) {
      throw ValidationException('Unarchive this DPS before closing it.');
    }
    final position = (await getById(profileId, id))!;
    if (!isValidDateKey(closedDate) ||
        closedDate.compareTo(row.openDate) < 0 ||
        closedDate.compareTo(_today()) > 0) {
      throw ValidationException(
        'The closing date must be between the opening date and today.',
      );
    }
    final deposits = await _paymentRows(profileId, id);
    if (deposits.any(
      (p) => !p.isDeleted && p.paymentDate.compareTo(closedDate) > 0,
    )) {
      throw ValidationException('A deposit is dated after the closing date.');
    }
    if (type == DpsClosingType.matured) {
      if (position.remainingCount > 0) {
        throw ValidationException(
          'Not all installments are paid. Choose premature or closed by bank.',
        );
      }
      if (closedDate.compareTo(position.maturityDate) < 0) {
        throw ValidationException(
          'It matures on ${position.maturityDate}. Choose premature to close '
          'it earlier.',
        );
      }
    }
    if (profitMinor < 0 || taxMinor < 0 || chargeMinor < 0) {
      throw ValidationException('Amounts cannot be negative.');
    }
    final net =
        netReceivedMinor ??
        position.depositedMinor + profitMinor - taxMinor - chargeMinor;
    if (net < 0) {
      throw ValidationException('The amount received cannot be negative.');
    }
    await (_db.update(
      _db.dpsAccounts,
    )..where((a) => a.profileId.equals(profileId) & a.id.equals(id))).write(
      DpsAccountsCompanion(
        closingType: Value(type.code),
        closedDate: Value(closedDate),
        profitMinor: Value(profitMinor),
        taxMinor: Value(taxMinor),
        chargeMinor: Value(chargeMinor),
        netReceivedMinor: Value(net),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (await getById(profileId, id))!;
  });

  /// Soft archive / unarchive.
  Future<void> setArchived(int profileId, int id, bool archived) async {
    await _row(profileId, id);
    await (_db.update(
      _db.dpsAccounts,
    )..where((a) => a.profileId.equals(profileId) & a.id.equals(id))).write(
      DpsAccountsCompanion(
        isActive: Value(!archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
