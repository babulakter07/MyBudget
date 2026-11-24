import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/fixed_deposit.dart';
import '../domain/fixed_deposit_calculator.dart';

/// Deposit-scheme (FDR, DPS, Sanchaypatra...) ledger, modelled on the MegaFeed
/// "Deposit Scheme" business. Separate from income/expense: it never touches
/// accounts, budgets or transactions. A deposit is a chain of instruments; an
/// instrument is closed by encashing it or by reissuing it (its net received
/// amount becomes the principal of a new instrument linked to the old one).
class FixedDepositRepository {
  FixedDepositRepository(this._db, {String Function()? today})
    : _today = today ?? (() => dateKey(DateTime.now()));
  final AppDatabase _db;
  final String Function() _today;

  Set<TableInfo> get _readsFrom => {_db.fixedDeposits, _db.fixedDepositTerms};

  // ---- mapping ----

  FixedDeposit _mapDeposit(FixedDepositRow r) => FixedDeposit(
    id: r.id,
    profileId: r.profileId,
    schemeType: r.schemeType,
    bankName: r.bankName,
    beneficiaryName: r.beneficiaryName,
    note: r.note,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  FixedDepositTerm _mapTerm(FixedDepositTermRow r) => FixedDepositTerm(
    id: r.id,
    profileId: r.profileId,
    depositId: r.depositId,
    termNo: r.termNo,
    instrumentNumber: r.instrumentNumber,
    startDate: r.startDate,
    tenureDays: r.tenureDays,
    rateBp: r.rateBp,
    principalMinor: r.principalMinor,
    outcome: r.outcome,
    settledDate: r.settledDate,
    interestMinor: r.interestMinor,
    taxMinor: r.taxMinor,
    bankChargeMinor: r.bankChargeMinor,
    netReceivedMinor: r.netReceivedMinor,
    renewedFromTermId: r.renewedFromTermId,
    note: r.note,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  Future<List<FixedDepositPosition>> _load(
    int profileId, {
    int? depositId,
    bool includeArchived = false,
  }) async {
    final deposits =
        await (_db.select(_db.fixedDeposits)
              ..where(
                (d) =>
                    d.profileId.equals(profileId) &
                    (depositId == null
                        ? const Constant(true)
                        : d.id.equals(depositId)) &
                    (includeArchived
                        ? const Constant(true)
                        : d.isActive.equals(true)),
              )
              ..orderBy([(d) => OrderingTerm.asc(d.id)]))
            .get();
    if (deposits.isEmpty) return const [];
    final terms =
        await (_db.select(_db.fixedDepositTerms)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy([(t) => OrderingTerm.asc(t.termNo)]))
            .get();
    final byDeposit = <int, List<FixedDepositTerm>>{};
    for (final t in terms) {
      (byDeposit[t.depositId] ??= []).add(_mapTerm(t));
    }
    final today = _today();
    final out = [
      for (final d in deposits)
        if (byDeposit[d.id] != null)
          FixedDepositPosition(
            deposit: _mapDeposit(d),
            terms: byDeposit[d.id]!,
            today: today,
          ),
    ];
    // Soonest maturity first among open deposits, closed ones last.
    out.sort((a, b) {
      final ac = a.status == FdStatus.closed, bc = b.status == FdStatus.closed;
      if (ac != bc) return ac ? 1 : -1;
      if (ac) return b.deposit.id.compareTo(a.deposit.id);
      return a.maturityDate.compareTo(b.maturityDate);
    });
    return out;
  }

  Stream<List<FixedDepositPosition>> watchAll(
    int profileId, {
    bool includeArchived = false,
  }) => _db
      .customSelect(
        'SELECT COUNT(*) AS c, IFNULL(MAX(updated_at), 0) AS u FROM '
        '(SELECT updated_at FROM fixed_deposits WHERE profile_id = ?1 '
        'UNION ALL SELECT updated_at FROM fixed_deposit_terms WHERE profile_id = ?1)',
        variables: [Variable.withInt(profileId)],
        readsFrom: _readsFrom,
      )
      .watchSingle()
      .asyncMap((_) => _load(profileId, includeArchived: includeArchived));

  Stream<FixedDepositPosition?> watchById(int profileId, int depositId) => _db
      .customSelect(
        'SELECT COUNT(*) AS c FROM fixed_deposit_terms WHERE profile_id = ?1',
        variables: [Variable.withInt(profileId)],
        readsFrom: _readsFrom,
      )
      .watch()
      .asyncMap((_) => getById(profileId, depositId));

  Stream<FixedDepositSummary> watchSummary(int profileId) =>
      watchAll(profileId).map(FixedDepositSummary.of);

  Future<FixedDepositPosition?> getById(int profileId, int depositId) async {
    final l = await _load(
      profileId,
      depositId: depositId,
      includeArchived: true,
    );
    return l.isEmpty ? null : l.first;
  }

  // ---- validation ----

  String? _clean(String? s) {
    final n = s?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  void _validateDeposit(String schemeType, String bankName) {
    final type = schemeType.trim();
    if (type.isEmpty) throw ValidationException('Scheme type is required.');
    if (type.length > 40) {
      throw ValidationException('Scheme type must be 40 characters or less.');
    }
    final bank = bankName.trim();
    if (bank.isEmpty) throw ValidationException('Bank name is required.');
    if (bank.length > 80) {
      throw ValidationException('Bank name must be 80 characters or less.');
    }
  }

  void _validateTerm({
    required String instrumentNumber,
    required String startDate,
    required int tenureDays,
    required int rateBp,
    required int principalMinor,
  }) {
    final number = instrumentNumber.trim();
    if (number.isEmpty) {
      throw ValidationException('Instrument number is required.');
    }
    if (number.length > 100) {
      throw ValidationException(
        'Instrument number must be 100 characters or less.',
      );
    }
    if (!isValidDateKey(startDate)) {
      throw ValidationException('Issue date is invalid.');
    }
    if (tenureDays < 1 || tenureDays > 36500) {
      throw ValidationException('Tenure must be between 1 and 36500 days.');
    }
    if (rateBp < 0 || rateBp > 10000) {
      throw ValidationException('Interest rate must be between 0% and 100%.');
    }
    if (principalMinor <= 0) {
      throw ValidationException('Principal must be greater than zero.');
    }
  }

  /// The instrument number must be unique per profile (case-insensitive).
  Future<void> _requireUniqueInstrument(
    int profileId,
    String instrumentNumber, {
    int? exceptTermId,
  }) async {
    final rows =
        await (_db.select(_db.fixedDepositTerms)..where(
              (t) =>
                  t.profileId.equals(profileId) &
                  t.instrumentNumber.lower().equals(
                    instrumentNumber.trim().toLowerCase(),
                  ),
            ))
            .get();
    if (rows.any((r) => r.id != exceptTermId)) {
      throw DuplicateNameException('This instrument number already exists.');
    }
  }

  // ---- deposits ----

  /// Creates a deposit together with its first instrument.
  Future<FixedDepositPosition> create({
    required int profileId,
    String schemeType = 'FDR',
    required String bankName,
    String? beneficiaryName,
    String? note,
    required String instrumentNumber,
    required String startDate,
    required int tenureDays,
    required int rateBp,
    required int principalMinor,
  }) async {
    _validateDeposit(schemeType, bankName);
    _validateTerm(
      instrumentNumber: instrumentNumber,
      startDate: startDate,
      tenureDays: tenureDays,
      rateBp: rateBp,
      principalMinor: principalMinor,
    );
    final profile = await (_db.select(
      _db.financialProfiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (profile == null) throw NotFoundException('Profile not found.');
    await _requireUniqueInstrument(profileId, instrumentNumber);
    final now = DateTime.now();
    final id = await _db.transaction(() async {
      final depositId = await _db
          .into(_db.fixedDeposits)
          .insert(
            FixedDepositsCompanion.insert(
              profileId: profileId,
              schemeType: Value(schemeType.trim()),
              bankName: bankName.trim(),
              beneficiaryName: Value(_clean(beneficiaryName)),
              note: Value(_clean(note)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _insertTerm(
        profileId: profileId,
        depositId: depositId,
        termNo: 1,
        instrumentNumber: instrumentNumber.trim(),
        startDate: startDate,
        tenureDays: tenureDays,
        rateBp: rateBp,
        principalMinor: principalMinor,
        renewedFromTermId: null,
        now: now,
      );
      return depositId;
    });
    return (await getById(profileId, id))!;
  }

  Future<int> _insertTerm({
    required int profileId,
    required int depositId,
    required int termNo,
    required String instrumentNumber,
    required String startDate,
    required int tenureDays,
    required int rateBp,
    required int principalMinor,
    required int? renewedFromTermId,
    required DateTime now,
  }) => _db
      .into(_db.fixedDepositTerms)
      .insert(
        FixedDepositTermsCompanion.insert(
          profileId: profileId,
          depositId: depositId,
          termNo: termNo,
          instrumentNumber: instrumentNumber,
          startDate: startDate,
          tenureDays: tenureDays,
          rateBp: rateBp,
          principalMinor: principalMinor,
          renewedFromTermId: Value(renewedFromTermId),
          createdAt: now,
          updatedAt: now,
        ),
      );

  /// Edits the bank details of a deposit (never its money terms).
  Future<void> updateDeposit({
    required int profileId,
    required int depositId,
    required String schemeType,
    required String bankName,
    String? beneficiaryName,
    String? note,
  }) async {
    _validateDeposit(schemeType, bankName);
    await _requireDeposit(profileId, depositId);
    await (_db.update(
          _db.fixedDeposits,
        )..where((d) => d.profileId.equals(profileId) & d.id.equals(depositId)))
        .write(
          FixedDepositsCompanion(
            schemeType: Value(schemeType.trim()),
            bankName: Value(bankName.trim()),
            beneficiaryName: Value(_clean(beneficiaryName)),
            note: Value(_clean(note)),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Corrects the RUNNING instrument. A closed (encashed / reissued)
  /// instrument is history and cannot be edited.
  Future<void> updateActiveTerm({
    required int profileId,
    required int termId,
    required String instrumentNumber,
    required String startDate,
    required int tenureDays,
    required int rateBp,
    required int principalMinor,
  }) async {
    final term = await _requireActiveTerm(profileId, termId);
    _validateTerm(
      instrumentNumber: instrumentNumber,
      startDate: startDate,
      tenureDays: tenureDays,
      rateBp: rateBp,
      principalMinor: principalMinor,
    );
    await _requireUniqueInstrument(
      profileId,
      instrumentNumber,
      exceptTermId: term.id,
    );
    await (_db.update(_db.fixedDepositTerms)
          ..where((t) => t.profileId.equals(profileId) & t.id.equals(term.id)))
        .write(
          FixedDepositTermsCompanion(
            instrumentNumber: Value(instrumentNumber.trim()),
            startDate: Value(startDate),
            tenureDays: Value(tenureDays),
            rateBp: Value(rateBp),
            principalMinor: Value(principalMinor),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Archives / restores a deposit. An archived deposit cannot be closed.
  Future<void> setArchived({
    required int profileId,
    required int depositId,
    required bool archived,
  }) async {
    await _requireDeposit(profileId, depositId);
    await (_db.update(
          _db.fixedDeposits,
        )..where((d) => d.profileId.equals(profileId) & d.id.equals(depositId)))
        .write(
          FixedDepositsCompanion(
            isActive: Value(!archived),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // ---- closing ----

  Future<FixedDepositRow> _requireDeposit(int profileId, int depositId) async {
    final row =
        await (_db.select(_db.fixedDeposits)..where(
              (d) => d.profileId.equals(profileId) & d.id.equals(depositId),
            ))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('Fixed deposit not found.');
    return row;
  }

  Future<FixedDepositTerm> _requireActiveTerm(int profileId, int termId) async {
    final row =
        await (_db.select(_db.fixedDepositTerms)..where(
              (t) => t.profileId.equals(profileId) & t.id.equals(termId),
            ))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('Deposit instrument not found.');
    if (row.outcome != fdOutcomeActive) {
      throw ValidationException(
        'This instrument is already closed (encashed / reissued).',
      );
    }
    return _mapTerm(row);
  }

  /// Validates the closing figures and returns the net received amount (the
  /// calculated one unless the user entered a final figure).
  Future<int> _checkClosing(
    FixedDepositTerm term, {
    required String settledDate,
    required int interestMinor,
    required int taxMinor,
    required int bankChargeMinor,
    required int? netReceivedMinor,
  }) async {
    final deposit = await _requireDeposit(term.profileId, term.depositId);
    if (!deposit.isActive) {
      throw ValidationException(
        'An archived deposit cannot be closed. Restore it first.',
      );
    }
    if (!isValidDateKey(settledDate)) {
      throw ValidationException('Closing date is invalid.');
    }
    if (settledDate.compareTo(term.startDate) < 0) {
      throw ValidationException(
        'Closing date cannot be before the issue date.',
      );
    }
    if (interestMinor < 0 || taxMinor < 0 || bankChargeMinor < 0) {
      throw ValidationException(
        'Interest, tax and bank charge cannot be negative.',
      );
    }
    final net =
        netReceivedMinor ??
        FixedDepositCalculator.calculatedNet(
          principalMinor: term.principalMinor,
          interestMinor: interestMinor,
          taxMinor: taxMinor,
          bankChargeMinor: bankChargeMinor,
        );
    if (net < 0) {
      throw ValidationException('Net received amount cannot be negative.');
    }
    return net;
  }

  Future<void> _close(
    FixedDepositTerm term, {
    required String outcome,
    required String settledDate,
    required int interestMinor,
    required int taxMinor,
    required int bankChargeMinor,
    required int netMinor,
  }) =>
      (_db.update(_db.fixedDepositTerms)..where(
            (t) => t.profileId.equals(term.profileId) & t.id.equals(term.id),
          ))
          .write(
            FixedDepositTermsCompanion(
              outcome: Value(outcome),
              settledDate: Value(settledDate),
              interestMinor: Value(interestMinor),
              taxMinor: Value(taxMinor),
              bankChargeMinor: Value(bankChargeMinor),
              netReceivedMinor: Value(netMinor),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Pays out the running instrument (at or before maturity) and closes the
  /// deposit. The figures are what the bank actually paid; [netReceivedMinor]
  /// overrides principal + interest - tax - bank charge.
  Future<FixedDepositPosition> encash({
    required int profileId,
    required int termId,
    required String settledDate,
    required int interestMinor,
    int taxMinor = 0,
    int bankChargeMinor = 0,
    int? netReceivedMinor,
  }) async {
    final term = await _requireActiveTerm(profileId, termId);
    final net = await _checkClosing(
      term,
      settledDate: settledDate,
      interestMinor: interestMinor,
      taxMinor: taxMinor,
      bankChargeMinor: bankChargeMinor,
      netReceivedMinor: netReceivedMinor,
    );
    await _db.transaction(() async {
      await _close(
        term,
        outcome: fdOutcomeEncashed,
        settledDate: settledDate,
        interestMinor: interestMinor,
        taxMinor: taxMinor,
        bankChargeMinor: bankChargeMinor,
        netMinor: net,
      );
      await _touchDeposit(profileId, term.depositId);
    });
    return (await getById(profileId, term.depositId))!;
  }

  /// Reissues the running instrument: it is closed as 'reissued' and a new
  /// instrument (new number, date, tenure and rate) is opened whose principal
  /// is the net received amount of the old one.
  Future<FixedDepositPosition> reissue({
    required int profileId,
    required int termId,
    required String settledDate,
    required int interestMinor,
    int taxMinor = 0,
    int bankChargeMinor = 0,
    int? netReceivedMinor,
    required String newInstrumentNumber,
    required String newStartDate,
    required int newTenureDays,
    required int newRateBp,
  }) async {
    final term = await _requireActiveTerm(profileId, termId);
    final net = await _checkClosing(
      term,
      settledDate: settledDate,
      interestMinor: interestMinor,
      taxMinor: taxMinor,
      bankChargeMinor: bankChargeMinor,
      netReceivedMinor: netReceivedMinor,
    );
    if (net <= 0) {
      throw ValidationException(
        'Net received amount must be greater than zero to reissue.',
      );
    }
    _validateTerm(
      instrumentNumber: newInstrumentNumber,
      startDate: newStartDate,
      tenureDays: newTenureDays,
      rateBp: newRateBp,
      principalMinor: net,
    );
    if (newStartDate.compareTo(term.startDate) <= 0) {
      throw ValidationException(
        'The reissue date must be after the issue date of the old instrument.',
      );
    }
    await _requireUniqueInstrument(profileId, newInstrumentNumber);
    final now = DateTime.now();
    await _db.transaction(() async {
      await _close(
        term,
        outcome: fdOutcomeReissued,
        settledDate: settledDate,
        interestMinor: interestMinor,
        taxMinor: taxMinor,
        bankChargeMinor: bankChargeMinor,
        netMinor: net,
      );
      await _insertTerm(
        profileId: profileId,
        depositId: term.depositId,
        termNo: term.termNo + 1,
        instrumentNumber: newInstrumentNumber.trim(),
        startDate: newStartDate,
        tenureDays: newTenureDays,
        rateBp: newRateBp,
        principalMinor: net,
        renewedFromTermId: term.id,
        now: now,
      );
      await _touchDeposit(profileId, term.depositId);
    });
    return (await getById(profileId, term.depositId))!;
  }

  Future<void> _touchDeposit(int profileId, int depositId) =>
      (_db.update(_db.fixedDeposits)..where(
            (d) => d.profileId.equals(profileId) & d.id.equals(depositId),
          ))
          .write(FixedDepositsCompanion(updatedAt: Value(DateTime.now())));
}
