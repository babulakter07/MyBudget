import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../domain/credit_card.dart';
import '../domain/credit_card_calculator.dart';

/// Credit card ledger. Separate from accounts/budgets/transactions. Every
/// query filters by profile_id; interest/fees are derived at read time.
class CreditCardRepository {
  CreditCardRepository(this._db, {String Function()? today})
    : _today = today ?? (() => dateKey(DateTime.now()));
  final AppDatabase _db;
  final String Function() _today;

  Set<TableInfo> get _readsFrom => {
    _db.creditCards,
    _db.creditCardBills,
    _db.creditCardPayments,
  };

  // ---- mapping ----

  CreditCard _card(CreditCardRow r) => CreditCard(
    id: r.id,
    profileId: r.profileId,
    name: r.name,
    bankName: r.bankName,
    lastFour: r.lastFour,
    creditLimitMinor: r.creditLimitMinor,
    statementDay: r.statementDay,
    dueDays: r.dueDays,
    aprBp: r.aprBp,
    minPaymentBp: r.minPaymentBp,
    minPaymentFloorMinor: r.minPaymentFloorMinor,
    lateFeeBp: r.lateFeeBp,
    lateFeeFloorMinor: r.lateFeeFloorMinor,
    interestFromStatement: r.interestFromStatement,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  CreditCardBill _bill(CreditCardBillRow r) => CreditCardBill(
    id: r.id,
    profileId: r.profileId,
    cardId: r.cardId,
    billMonth: r.billMonth,
    statementDate: r.statementDate,
    dueDate: r.dueDate,
    amountMinor: r.amountMinor,
    minPaymentMinor: r.minPaymentMinor,
    note: r.note,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  CardPayment _payment(CreditCardPaymentRow r) => CardPayment(
    id: r.id,
    profileId: r.profileId,
    billId: r.billId,
    amountMinor: r.amountMinor,
    paymentDate: r.paymentDate,
    note: r.note,
    isDeleted: r.isDeleted,
    createdAt: r.createdAt,
  );

  // ---- validation ----

  String _required(String v, String label, int max) {
    final t = v.trim();
    if (t.isEmpty) throw ValidationException('$label is required.');
    if (t.length > max) {
      throw ValidationException('$label must be $max characters or less.');
    }
    return t;
  }

  String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  void _range(int v, int min, int max, String label) {
    if (v < min || v > max) {
      throw ValidationException('$label must be between $min and $max.');
    }
  }

  String? _validLastFour(String? v) {
    final t = _clean(v);
    if (t == null) return null;
    if (!RegExp(r'^\d{4}$').hasMatch(t)) {
      throw ValidationException('Last digits must be exactly 4 digits.');
    }
    return t;
  }

  static final _monthRe = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  Future<CreditCardRow> _cardRow(int profileId, int id) async {
    final r = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (r == null) throw NotFoundException('Credit card not found.');
    if (r.profileId != profileId) {
      throw ProfileMismatchException(
        'Credit card belongs to a different profile.',
      );
    }
    return r;
  }

  Future<CreditCardBillRow> _billRow(int profileId, int id) async {
    final r = await (_db.select(
      _db.creditCardBills,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (r == null) throw NotFoundException('Bill not found.');
    if (r.profileId != profileId) {
      throw ProfileMismatchException('Bill belongs to a different profile.');
    }
    return r;
  }

  Future<bool> _nameTaken(int profileId, String name, {int? excludeId}) async {
    final rows = await _db
        .customSelect(
          'SELECT id FROM credit_cards WHERE profile_id = ? '
          'AND name = ? COLLATE NOCASE',
          variables: [Variable.withInt(profileId), Variable.withString(name)],
          readsFrom: {_db.creditCards},
        )
        .get();
    return rows.any((r) => r.read<int>('id') != excludeId);
  }

  // ---- cards ----

  Future<CreditCard> createCard({
    required int profileId,
    required String name,
    required String bankName,
    String? lastFour,
    required int creditLimitMinor,
    required int statementDay,
    required int dueDays,
    required int aprBp,
    required int minPaymentBp,
    int minPaymentFloorMinor = 0,
    int lateFeeBp = 0,
    int lateFeeFloorMinor = 0,
    bool interestFromStatement = false,
  }) async {
    final n = _required(name, 'Card name', 80);
    final bank = _required(bankName, 'Bank name', 80);
    final l4 = _validLastFour(lastFour);
    _validPolicy(
      creditLimitMinor,
      statementDay,
      dueDays,
      aprBp,
      minPaymentBp,
      minPaymentFloorMinor,
      lateFeeBp,
      lateFeeFloorMinor,
    );
    final profile = await (_db.select(
      _db.financialProfiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (profile == null) throw NotFoundException('Profile not found.');
    if (await _nameTaken(profileId, n)) {
      throw DuplicateNameException('A card named "$n" already exists.');
    }
    final now = DateTime.now();
    final id = await _db
        .into(_db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            profileId: profileId,
            name: n,
            bankName: bank,
            lastFour: Value(l4),
            creditLimitMinor: creditLimitMinor,
            statementDay: statementDay,
            dueDays: dueDays,
            aprBp: aprBp,
            minPaymentBp: minPaymentBp,
            minPaymentFloorMinor: Value(minPaymentFloorMinor),
            lateFeeBp: Value(lateFeeBp),
            lateFeeFloorMinor: Value(lateFeeFloorMinor),
            interestFromStatement: Value(interestFromStatement),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _card(await _cardRow(profileId, id));
  }

  void _validPolicy(
    int limit,
    int statementDay,
    int dueDays,
    int apr,
    int minBp,
    int minFloor,
    int feeBp,
    int feeFloor,
  ) {
    if (limit <= 0) {
      throw ValidationException('Credit limit must be greater than zero.');
    }
    _range(statementDay, 1, 28, 'Statement day');
    _range(dueDays, 1, 60, 'Days to pay');
    _range(apr, 0, 10000, 'Interest rate');
    _range(minBp, 0, 10000, 'Minimum payment percentage');
    _range(feeBp, 0, 10000, 'Late fee percentage');
    if (minFloor < 0 || feeFloor < 0) {
      throw ValidationException('Amounts cannot be negative.');
    }
  }

  /// Updates the card and its policy. Existing bills keep their stored dates
  /// and minimum; interest/fees of existing bills use the NEW policy rates.
  Future<CreditCard> updateCard({
    required int profileId,
    required int id,
    required String name,
    required String bankName,
    String? lastFour,
    required int creditLimitMinor,
    required int statementDay,
    required int dueDays,
    required int aprBp,
    required int minPaymentBp,
    int minPaymentFloorMinor = 0,
    int lateFeeBp = 0,
    int lateFeeFloorMinor = 0,
    bool interestFromStatement = false,
  }) async {
    final n = _required(name, 'Card name', 80);
    final bank = _required(bankName, 'Bank name', 80);
    final l4 = _validLastFour(lastFour);
    _validPolicy(
      creditLimitMinor,
      statementDay,
      dueDays,
      aprBp,
      minPaymentBp,
      minPaymentFloorMinor,
      lateFeeBp,
      lateFeeFloorMinor,
    );
    return _db.transaction(() async {
      await _cardRow(profileId, id);
      if (await _nameTaken(profileId, n, excludeId: id)) {
        throw DuplicateNameException('A card named "$n" already exists.');
      }
      await (_db.update(
        _db.creditCards,
      )..where((c) => c.profileId.equals(profileId) & c.id.equals(id))).write(
        CreditCardsCompanion(
          name: Value(n),
          bankName: Value(bank),
          lastFour: Value(l4),
          creditLimitMinor: Value(creditLimitMinor),
          statementDay: Value(statementDay),
          dueDays: Value(dueDays),
          aprBp: Value(aprBp),
          minPaymentBp: Value(minPaymentBp),
          minPaymentFloorMinor: Value(minPaymentFloorMinor),
          lateFeeBp: Value(lateFeeBp),
          lateFeeFloorMinor: Value(lateFeeFloorMinor),
          interestFromStatement: Value(interestFromStatement),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return _card(await _cardRow(profileId, id));
    });
  }

  /// Soft deactivate / reactivate. Cards are never deleted.
  Future<void> setActive(int profileId, int id, bool active) async {
    await _cardRow(profileId, id);
    await (_db.update(
      _db.creditCards,
    )..where((c) => c.profileId.equals(profileId) & c.id.equals(id))).write(
      CreditCardsCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<CreditCard?> getCard(int profileId, int id) async {
    final r =
        await (_db.select(_db.creditCards)
              ..where((c) => c.profileId.equals(profileId) & c.id.equals(id)))
            .getSingleOrNull();
    return r == null ? null : _card(r);
  }

  // ---- bills ----

  Future<CreditCardBill> createBill({
    required int profileId,
    required int cardId,
    required String billMonth,
    required int amountMinor,
    String? statementDate,
    String? dueDate,
    int? minPaymentMinor,
    String? note,
  }) async {
    if (!_monthRe.hasMatch(billMonth)) {
      throw ValidationException('Bill month must look like 2026-06.');
    }
    if (amountMinor <= 0) {
      throw ValidationException('Bill amount must be greater than zero.');
    }
    return _db.transaction(() async {
      final card = await _cardRow(profileId, cardId);
      if (!card.isActive) {
        throw ValidationException('This card is inactive.');
      }
      final stmt =
          statementDate ?? statementDateFor(billMonth, card.statementDay);
      if (!isValidDateKey(stmt)) {
        throw ValidationException('Statement date is invalid.');
      }
      final due = dueDate ?? dueDateFor(stmt, card.dueDays);
      if (!isValidDateKey(due)) {
        throw ValidationException('Due date is invalid.');
      }
      if (due.compareTo(stmt) < 0) {
        throw ValidationException(
          'Due date cannot be before the statement date.',
        );
      }
      final min =
          minPaymentMinor ??
          minimumPayment(
            billMinor: amountMinor,
            minPaymentBp: card.minPaymentBp,
            floorMinor: card.minPaymentFloorMinor,
          );
      if (min < 0 || min > amountMinor) {
        throw ValidationException(
          'Minimum payment must be between 0 and the bill amount.',
        );
      }
      final dup =
          await (_db.select(_db.creditCardBills)..where(
                (b) =>
                    b.profileId.equals(profileId) &
                    b.cardId.equals(cardId) &
                    b.billMonth.equals(billMonth) &
                    b.isActive.equals(true),
              ))
              .get();
      if (dup.isNotEmpty) {
        throw DuplicateNameException(
          'A bill for $billMonth already exists on this card.',
        );
      }
      final now = DateTime.now();
      final id = await _db
          .into(_db.creditCardBills)
          .insert(
            CreditCardBillsCompanion.insert(
              profileId: profileId,
              cardId: cardId,
              billMonth: billMonth,
              statementDate: stmt,
              dueDate: due,
              amountMinor: amountMinor,
              minPaymentMinor: min,
              note: Value(_clean(note)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _bill(await _billRow(profileId, id));
    });
  }

  /// Edits amount, dates, minimum and note (the month is fixed). The amount
  /// cannot go below what is already paid.
  Future<CreditCardBill> updateBill({
    required int profileId,
    required int billId,
    required int amountMinor,
    required String statementDate,
    required String dueDate,
    required int minPaymentMinor,
    String? note,
  }) async {
    if (amountMinor <= 0) {
      throw ValidationException('Bill amount must be greater than zero.');
    }
    if (!isValidDateKey(statementDate) || !isValidDateKey(dueDate)) {
      throw ValidationException('Statement or due date is invalid.');
    }
    if (dueDate.compareTo(statementDate) < 0) {
      throw ValidationException(
        'Due date cannot be before the statement date.',
      );
    }
    if (minPaymentMinor < 0 || minPaymentMinor > amountMinor) {
      throw ValidationException(
        'Minimum payment must be between 0 and the bill amount.',
      );
    }
    return _db.transaction(() async {
      final bill = await _billRow(profileId, billId);
      if (!bill.isActive) throw ValidationException('This bill is voided.');
      final paid = await _paidTotal(profileId, billId);
      if (amountMinor < paid) {
        throw ValidationException(
          'Amount cannot be less than the ${formatMinor(paid)} already paid.',
        );
      }
      await (_db.update(_db.creditCardBills)
            ..where((b) => b.profileId.equals(profileId) & b.id.equals(billId)))
          .write(
            CreditCardBillsCompanion(
              amountMinor: Value(amountMinor),
              statementDate: Value(statementDate),
              dueDate: Value(dueDate),
              minPaymentMinor: Value(minPaymentMinor),
              note: Value(_clean(note)),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return _bill(await _billRow(profileId, billId));
    });
  }

  /// Voids the bill (is_active = 0). Its payments are kept for history.
  Future<void> voidBill(int profileId, int billId) async {
    final bill = await _billRow(profileId, billId);
    if (!bill.isActive) {
      throw ValidationException('This bill is already voided.');
    }
    await (_db.update(
      _db.creditCardBills,
    )..where((b) => b.profileId.equals(profileId) & b.id.equals(billId))).write(
      CreditCardBillsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> _paidTotal(int profileId, int billId) async {
    final r = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount_minor),0) AS s FROM credit_card_payments '
          'WHERE profile_id = ? AND bill_id = ? AND is_deleted = 0',
          variables: [Variable.withInt(profileId), Variable.withInt(billId)],
          readsFrom: {_db.creditCardPayments},
        )
        .getSingle();
    return r.read<int>('s');
  }

  // ---- payments ----

  Future<List<CardPayment>> _paymentsOf(int profileId, int billId) async {
    final rows =
        await (_db.select(_db.creditCardPayments)
              ..where(
                (p) => p.profileId.equals(profileId) & p.billId.equals(billId),
              )
              ..orderBy([
                (p) => OrderingTerm.asc(p.paymentDate),
                (p) => OrderingTerm.asc(p.id),
              ]))
            .get();
    return rows.map(_payment).toList();
  }

  Future<CardPayment> addPayment({
    required int profileId,
    required int billId,
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
      final billRow = await _billRow(profileId, billId);
      if (!billRow.isActive) throw ValidationException('This bill is voided.');
      if (paymentDate.compareTo(billRow.statementDate) < 0) {
        throw ValidationException(
          'Payment date cannot be before the statement date '
          '(${billRow.statementDate}).',
        );
      }
      final card = _card(await _cardRow(profileId, billRow.cardId));
      final bill = _bill(billRow);
      final st = computeStatement(
        card: card,
        bill: bill,
        payments: await _paymentsOf(profileId, billId),
        asOf: paymentDate,
      );
      if (amountMinor > st.remainingMinor) {
        throw ValidationException(
          st.remainingMinor <= 0
              ? 'This bill is already fully paid.'
              : 'Amount exceeds the remaining balance. Maximum is '
                    '${formatMinor(st.remainingMinor)}.',
        );
      }
      final id = await _db
          .into(_db.creditCardPayments)
          .insert(
            CreditCardPaymentsCompanion.insert(
              profileId: profileId,
              billId: billId,
              amountMinor: amountMinor,
              paymentDate: paymentDate,
              note: Value(_clean(note)),
              createdAt: DateTime.now(),
            ),
          );
      await _touchBill(profileId, billId);
      return _payment(
        await (_db.select(
          _db.creditCardPayments,
        )..where((p) => p.id.equals(id))).getSingle(),
      );
    });
  }

  /// Soft-voids a payment; interest, fees and balance are recomputed.
  Future<void> voidPayment(int profileId, int paymentId) async {
    await _db.transaction(() async {
      final p = await (_db.select(
        _db.creditCardPayments,
      )..where((x) => x.id.equals(paymentId))).getSingleOrNull();
      if (p == null) throw NotFoundException('Payment not found.');
      if (p.profileId != profileId) {
        throw ProfileMismatchException(
          'Payment belongs to a different profile.',
        );
      }
      if (p.isDeleted) {
        throw ValidationException('This payment is already voided.');
      }
      await (_db.update(_db.creditCardPayments)..where(
            (x) => x.profileId.equals(profileId) & x.id.equals(paymentId),
          ))
          .write(const CreditCardPaymentsCompanion(isDeleted: Value(true)));
      await _touchBill(profileId, p.billId);
    });
  }

  Future<void> _touchBill(int profileId, int billId) =>
      (_db.update(_db.creditCardBills)
            ..where((b) => b.profileId.equals(profileId) & b.id.equals(billId)))
          .write(CreditCardBillsCompanion(updatedAt: Value(DateTime.now())));

  // ---- derived reads ----

  Future<List<BillStatement>> _statements(
    CreditCard card,
    String asOf, {
    bool includeVoided = false,
  }) async {
    final bills =
        await (_db.select(_db.creditCardBills)
              ..where(
                (b) =>
                    b.profileId.equals(card.profileId) &
                    b.cardId.equals(card.id) &
                    (includeVoided
                        ? const Constant(true)
                        : b.isActive.equals(true)),
              )
              ..orderBy([
                (b) => OrderingTerm.desc(b.billMonth),
                (b) => OrderingTerm.desc(b.id),
              ]))
            .get();
    if (bills.isEmpty) return const [];
    final pays =
        await (_db.select(_db.creditCardPayments)..where(
              (p) =>
                  p.profileId.equals(card.profileId) &
                  p.billId.isIn(bills.map((b) => b.id)),
            ))
            .get();
    final byBill = <int, List<CardPayment>>{};
    for (final p in pays) {
      byBill.putIfAbsent(p.billId, () => []).add(_payment(p));
    }
    return [
      for (final b in bills)
        computeStatement(
          card: card,
          bill: _bill(b),
          payments: byBill[b.id] ?? const [],
          asOf: asOf,
        ),
    ];
  }

  CardSummary _summarise(CreditCard card, List<BillStatement> active) {
    var outstanding = 0, overdue = 0, open = 0, charges = 0;
    BillStatement? next;
    for (final s in active) {
      charges += s.totalChargesMinor;
      if (s.remainingMinor <= 0) continue;
      open++;
      outstanding += s.remainingMinor;
      if (s.status == BillStatus.overdue) overdue++;
      if (next == null || s.bill.dueDate.compareTo(next.bill.dueDate) < 0) {
        next = s;
      }
    }
    return CardSummary(
      card: card,
      outstandingMinor: outstanding,
      overdueCount: overdue,
      unsettledBillCount: open,
      chargesMinor: charges,
      nextDue: next,
    );
  }

  Future<CardSummary> _summaryOf(CreditCardRow row) async {
    final card = _card(row);
    return _summarise(card, await _statements(card, _today()));
  }

  Stream<T> _watch<T>(Future<T> Function() load) => _db
      .customSelect('SELECT 1 AS x', readsFrom: _readsFrom)
      .watch()
      .asyncMap((_) => load());

  /// Cards of a profile with live summaries (active first, then by name).
  Stream<List<CardSummary>> watchCards(
    int profileId, {
    bool includeInactive = false,
  }) => _watch(() async {
    final rows =
        await (_db.select(_db.creditCards)
              ..where(
                (c) =>
                    c.profileId.equals(profileId) &
                    (includeInactive
                        ? const Constant(true)
                        : c.isActive.equals(true)),
              )
              ..orderBy([
                (c) => OrderingTerm.desc(c.isActive),
                (c) => OrderingTerm(expression: c.name.collate(Collate.noCase)),
              ]))
            .get();
    return [for (final r in rows) await _summaryOf(r)];
  });

  Stream<CardSummary?> watchCard(int profileId, int id) => _watch(() async {
    final r =
        await (_db.select(_db.creditCards)
              ..where((c) => c.profileId.equals(profileId) & c.id.equals(id)))
            .getSingleOrNull();
    return r == null ? null : _summaryOf(r);
  });

  /// Bills of a card, newest month first, as statements for today.
  Stream<List<BillStatement>> watchBills(
    int profileId,
    int cardId, {
    bool includeVoided = false,
  }) => _watch(() async {
    final card = await getCard(profileId, cardId);
    if (card == null) return const <BillStatement>[];
    return _statements(card, _today(), includeVoided: includeVoided);
  });

  Stream<BillStatement?> watchBill(int profileId, int billId) =>
      _watch(() async {
        final b =
            await (_db.select(_db.creditCardBills)..where(
                  (x) => x.profileId.equals(profileId) & x.id.equals(billId),
                ))
                .getSingleOrNull();
        if (b == null) return null;
        final card = await getCard(profileId, b.cardId);
        if (card == null) return null;
        return computeStatement(
          card: card,
          bill: _bill(b),
          payments: await _paymentsOf(profileId, billId),
          asOf: _today(),
        );
      });

  /// Projection for the bill screen (what-if block).
  Stream<BillProjection?> watchProjection(int profileId, int billId) =>
      _watch(() async {
        final b =
            await (_db.select(_db.creditCardBills)..where(
                  (x) => x.profileId.equals(profileId) & x.id.equals(billId),
                ))
                .getSingleOrNull();
        if (b == null) return null;
        final card = await getCard(profileId, b.cardId);
        if (card == null) return null;
        return projectCharges(
          card: card,
          bill: _bill(b),
          payments: await _paymentsOf(profileId, billId),
          asOf: _today(),
        );
      });

  Stream<List<CardPayment>> watchPayments(int profileId, int billId) {
    final q = _db.select(_db.creditCardPayments)
      ..where((p) => p.profileId.equals(profileId) & p.billId.equals(billId))
      ..orderBy([
        (p) => OrderingTerm.desc(p.paymentDate),
        (p) => OrderingTerm.desc(p.id),
      ]);
    return q.watch().map((rows) => rows.map(_payment).toList());
  }

  /// Totals over all active cards of the profile.
  Stream<OverallCardSummary> watchOverallSummary(int profileId) =>
      _watch(() => overallSummary(profileId));

  Future<OverallCardSummary> overallSummary(int profileId) async {
    final rows =
        await (_db.select(_db.creditCards)..where(
              (c) => c.profileId.equals(profileId) & c.isActive.equals(true),
            ))
            .get();
    var outstanding = 0, limit = 0, overdue = 0;
    DueBill? next;
    for (final r in rows) {
      final s = await _summaryOf(r);
      outstanding += s.outstandingMinor;
      limit += s.card.creditLimitMinor;
      overdue += s.overdueCount;
      final nd = s.nextDue;
      if (nd != null &&
          (next == null ||
              nd.bill.dueDate.compareTo(next.statement.bill.dueDate) < 0)) {
        next = DueBill(cardName: s.card.name, statement: nd);
      }
    }
    return OverallCardSummary(
      cardCount: rows.length,
      totalOutstandingMinor: outstanding,
      totalLimitMinor: limit,
      overdueCount: overdue,
      nextDue: next,
    );
  }
}
