import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_keys.dart';
import '../../credit_cards/data/credit_card_repository.dart';
import '../../debts/data/debt_repository.dart';
import '../../dps/data/dps_repository.dart';
import '../../dps/domain/dps.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/domain/loan_calculator.dart';
import '../../recurring/domain/recurrence.dart';
import '../domain/upcoming_payment.dart';

/// Longest window the card offers.
const upcomingMaxDays = 30;

/// Collects the payments the user owes. Amounts come from each feature's own
/// repository, so they match its screens (card bills include interest and
/// late fees). Read only.
class UpcomingRepository {
  UpcomingRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Re-emits whenever a source table changes.
  Stream<List<UpcomingPayment>> watch(int profileId) => _db
      .customSelect(
        'SELECT 1 AS x',
        readsFrom: {
          _db.loans,
          _db.loanPayments,
          _db.creditCards,
          _db.creditCardBills,
          _db.creditCardPayments,
          _db.debts,
          _db.debtPayments,
          _db.recurringRules,
          _db.dpsAccounts,
          _db.dpsPayments,
        },
      )
      .watch()
      .asyncMap((_) => load(profileId));

  /// Overdue payments and those due within [upcomingMaxDays].
  Future<List<UpcomingPayment>> load(int profileId) async {
    final now = _clock();
    final today = dateKey(now);
    final lastDay = dateKey(
      DateTime(now.year, now.month, now.day + upcomingMaxDays),
    );
    return groupUpcoming(
      [
        ...await _loans(profileId, today),
        ...await _cards(profileId, today),
        ...await _debts(profileId, today),
        ...await _recurring(profileId, lastDay),
        ...await _dps(profileId, today),
      ],
      today: today,
      lastDay: lastDay,
    );
  }

  Future<List<DueEntry>> _loans(int profileId, String today) async {
    final loans = await LoanRepository(
      _db,
      today: () => today,
    ).watchAll(profileId).first;
    return [
      for (final p in loans)
        if (!p.isClosed)
          for (final i in p.schedule)
            if (i.status != InstallmentStatus.paid)
              DueEntry(
                kind: UpcomingKind.loan,
                entityId: p.loan.id,
                name: p.loan.lenderName,
                amountMinor: i.unpaidMinor,
                dueDate: i.dueDate,
              ),
    ];
  }

  Future<List<DueEntry>> _cards(int profileId, String today) async {
    final repo = CreditCardRepository(_db, today: () => today);
    final out = <DueEntry>[];
    for (final c in await repo.watchCards(profileId).first) {
      if (c.unsettledBillCount == 0) continue;
      for (final s in await repo.watchBills(profileId, c.card.id).first) {
        if (s.remainingMinor <= 0) continue;
        out.add(
          DueEntry(
            kind: UpcomingKind.card,
            entityId: c.card.id,
            billId: s.bill.id,
            name: c.card.name,
            amountMinor: s.remainingMinor,
            dueDate: s.bill.dueDate,
          ),
        );
      }
    }
    return out;
  }

  Future<List<DueEntry>> _dps(int profileId, String today) async {
    final accounts = await DpsRepository(
      _db,
      today: () => today,
    ).loadAll(profileId);
    return [
      for (final p in accounts)
        if (!p.isClosed)
          for (final i in p.schedule)
            if (i.status != DpsInstallmentStatus.paid)
              DueEntry(
                kind: UpcomingKind.dps,
                entityId: p.account.id,
                name: p.terms.bankName,
                amountMinor: p.terms.installmentMinor,
                dueDate: i.dueDate,
                graceEnd: DpsCalculator.graceEnd(i.dueDate, p.terms.graceDays),
              ),
    ];
  }

  /// Only money the user owes; money owed to them is not a payment.
  Future<List<DueEntry>> _debts(int profileId, String today) async {
    final debts = await DebtRepository(
      _db,
      today: () => today,
    ).watchAll(profileId, direction: 'borrowed').first;
    return [
      for (final d in debts)
        if (d.dueDate != null)
          DueEntry(
            kind: UpcomingKind.debt,
            entityId: d.id,
            name: d.personName,
            amountMinor: d.outstandingMinor,
            dueDate: d.dueDate!,
          ),
    ];
  }

  /// Recurring expenses not yet recorded. Due ones are normally posted as soon
  /// as the app starts, so an overdue entry means posting did not happen.
  Future<List<DueEntry>> _recurring(int profileId, String lastDay) async {
    final rules =
        await (_db.select(_db.recurringRules)..where(
              (r) =>
                  r.profileId.equals(profileId) &
                  r.isActive.equals(true) &
                  r.type.equals('expense'),
            ))
            .get();
    final out = <DueEntry>[];
    for (final r in rules) {
      var due = r.nextDueDate;
      // Bounded like the recurring generator, in case of a very old date.
      for (var n = 0; n < 400; n++) {
        if (due.compareTo(lastDay) > 0) break;
        if (r.endDate != null && due.compareTo(r.endDate!) > 0) break;
        out.add(
          DueEntry(
            kind: UpcomingKind.recurring,
            entityId: r.id,
            name: r.title,
            amountMinor: r.amountMinor,
            dueDate: due,
          ),
        );
        due = nextDueKeyAfter(r.startDate, r.frequency, r.intervalCount, due);
      }
    }
    return out;
  }
}
