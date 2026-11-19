import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/credit_cards/data/credit_card_repository.dart';
import 'package:my_budget/features/credit_cards/domain/credit_card.dart';

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime.now();
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late CreditCardRepository repo;
  late int p1;
  late int p2;
  var today = '2026-06-10';

  setUp(() async {
    today = '2026-06-10';
    db = AppDatabase.memory();
    repo = CreditCardRepository(db, today: () => today);
    p1 = await _profile(db, 'One');
    p2 = await _profile(db, 'Two');
  });
  tearDown(() => db.close());

  Future<CreditCard> card({
    String name = 'Visa',
    int? profile,
    int limit = 10000000,
    String? last4,
  }) => repo.createCard(
    profileId: profile ?? p1,
    name: name,
    bankName: 'City Bank',
    lastFour: last4,
    creditLimitMinor: limit,
    statementDay: 5,
    dueDays: 20,
    aprBp: 2400,
    minPaymentBp: 500,
    minPaymentFloorMinor: 50000,
    lateFeeBp: 200,
    lateFeeFloorMinor: 30000,
  );

  Future<CreditCardBill> bill(
    CreditCard c, {
    String month = '2026-06',
    int amount = 1000000,
  }) => repo.createBill(
    profileId: c.profileId,
    cardId: c.id,
    billMonth: month,
    amountMinor: amount,
  );

  group('cards', () {
    test(
      'create trims, validates and rejects duplicate names (nocase)',
      () async {
        final c = await card(name: '  Visa Gold ', last4: '1234');
        expect(c.name, 'Visa Gold');
        expect(c.lastFour, '1234');
        await expectLater(
          card(name: 'visa gold'),
          throwsA(isA<DuplicateNameException>()),
        );
        // same name in another profile is fine
        await card(name: 'Visa Gold', profile: p2);
      },
    );

    test('validation errors', () async {
      Future<void> bad({
        String name = 'X',
        String bank = 'B',
        String? l4,
        int limit = 100,
        int stmt = 5,
        int due = 20,
        int apr = 2400,
        int minBp = 500,
        int feeBp = 0,
      }) => repo.createCard(
        profileId: p1,
        name: name,
        bankName: bank,
        lastFour: l4,
        creditLimitMinor: limit,
        statementDay: stmt,
        dueDays: due,
        aprBp: apr,
        minPaymentBp: minBp,
        lateFeeBp: feeBp,
      );
      for (final f in [
        () => bad(name: ' '),
        () => bad(bank: ''),
        () => bad(l4: '12a4'),
        () => bad(l4: '123'),
        () => bad(limit: 0),
        () => bad(stmt: 0),
        () => bad(stmt: 29),
        () => bad(due: 0),
        () => bad(due: 61),
        () => bad(apr: 10001),
        () => bad(apr: -1),
        () => bad(minBp: 10001),
        () => bad(feeBp: 10001),
      ]) {
        await expectLater(f(), throwsA(isA<ValidationException>()));
      }
    });

    test('unknown profile and cross-profile access are rejected', () async {
      await expectLater(card(profile: 999), throwsA(isA<NotFoundException>()));
      final c = await card();
      await expectLater(
        repo.updateCard(
          profileId: p2,
          id: c.id,
          name: 'Hack',
          bankName: 'B',
          creditLimitMinor: 100,
          statementDay: 1,
          dueDays: 1,
          aprBp: 0,
          minPaymentBp: 0,
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.setActive(p2, c.id, false),
        throwsA(isA<ProfileMismatchException>()),
      );
      await expectLater(
        repo.createBill(
          profileId: p2,
          cardId: c.id,
          billMonth: '2026-06',
          amountMinor: 100,
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
      expect(await repo.getCard(p2, c.id), isNull);
    });

    test('update and deactivate keep the row', () async {
      final c = await card();
      final u = await repo.updateCard(
        profileId: p1,
        id: c.id,
        name: 'Visa Platinum',
        bankName: 'City Bank',
        creditLimitMinor: 20000000,
        statementDay: 10,
        dueDays: 15,
        aprBp: 2000,
        minPaymentBp: 300,
        interestFromStatement: true,
      );
      expect(u.name, 'Visa Platinum');
      expect(u.interestFromStatement, isTrue);
      await repo.setActive(p1, c.id, false);
      expect((await repo.getCard(p1, c.id))!.isActive, isFalse);
      final active = await repo.watchCards(p1).first;
      expect(active, isEmpty);
      final all = await repo.watchCards(p1, includeInactive: true).first;
      expect(all.single.card.name, 'Visa Platinum');
      // inactive cards cannot get new bills
      await expectLater(bill(u), throwsA(isA<ValidationException>()));
    });
  });

  group('bills', () {
    test('defaults come from the card policy', () async {
      final c = await card();
      final b = await bill(c);
      expect(b.statementDate, '2026-06-05');
      expect(b.dueDate, '2026-06-25');
      expect(b.minPaymentMinor, 50000);
    });

    test('duplicate month rejected; voiding frees the month', () async {
      final c = await card();
      final b = await bill(c);
      await expectLater(bill(c), throwsA(isA<DuplicateNameException>()));
      await repo.voidBill(p1, b.id);
      final again = await bill(c, amount: 500000);
      expect(again.id, isNot(b.id));
      await expectLater(
        repo.voidBill(p1, b.id),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validation', () async {
      final c = await card();
      for (final f in [
        () => repo.createBill(
          profileId: p1,
          cardId: c.id,
          billMonth: '2026-13',
          amountMinor: 100,
        ),
        () => repo.createBill(
          profileId: p1,
          cardId: c.id,
          billMonth: '2026-06',
          amountMinor: 0,
        ),
        () => repo.createBill(
          profileId: p1,
          cardId: c.id,
          billMonth: '2026-06',
          amountMinor: 100,
          minPaymentMinor: 101,
        ),
        () => repo.createBill(
          profileId: p1,
          cardId: c.id,
          billMonth: '2026-06',
          amountMinor: 100,
          statementDate: '2026-06-10',
          dueDate: '2026-06-01',
        ),
      ]) {
        await expectLater(f(), throwsA(isA<ValidationException>()));
      }
      await expectLater(
        repo.createBill(
          profileId: p1,
          cardId: 999,
          billMonth: '2026-06',
          amountMinor: 100,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('FK enforced by the database', () async {
      await expectLater(
        db
            .into(db.creditCardBills)
            .insert(
              CreditCardBillsCompanion.insert(
                profileId: p1,
                cardId: 999,
                billMonth: '2026-06',
                statementDate: '2026-06-05',
                dueDate: '2026-06-25',
                amountMinor: 100,
                minPaymentMinor: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
        throwsA(anything),
      );
    });

    test('update cannot drop below what is paid', () async {
      final c = await card();
      final b = await bill(c);
      await repo.addPayment(
        profileId: p1,
        billId: b.id,
        amountMinor: 600000,
        paymentDate: '2026-06-10',
      );
      await expectLater(
        repo.updateBill(
          profileId: p1,
          billId: b.id,
          amountMinor: 500000,
          statementDate: b.statementDate,
          dueDate: b.dueDate,
          minPaymentMinor: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      final u = await repo.updateBill(
        profileId: p1,
        billId: b.id,
        amountMinor: 1200000,
        statementDate: b.statementDate,
        dueDate: b.dueDate,
        minPaymentMinor: 60000,
        note: ' n ',
      );
      expect(u.amountMinor, 1200000);
      expect(u.note, 'n');
    });
  });

  group('payments', () {
    test('pay, overpay rejected, void restores balance', () async {
      final c = await card();
      final b = await bill(c);
      final p = await repo.addPayment(
        profileId: p1,
        billId: b.id,
        amountMinor: 400000,
        paymentDate: '2026-06-10',
      );
      var st = (await repo.watchBill(p1, b.id).first)!;
      expect(st.paidMinor, 400000);
      expect(st.status, BillStatus.partial);
      await expectLater(
        repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 600001,
          paymentDate: '2026-06-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await repo.addPayment(
        profileId: p1,
        billId: b.id,
        amountMinor: 600000,
        paymentDate: '2026-06-11',
      );
      today = '2026-06-12';
      st = (await repo.watchBill(p1, b.id).first)!;
      expect(st.status, BillStatus.paid);
      await expectLater(
        repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 1,
          paymentDate: '2026-06-12',
        ),
        throwsA(isA<ValidationException>()),
      );
      await repo.voidPayment(p1, p.id);
      st = (await repo.watchBill(p1, b.id).first)!;
      expect(st.paidMinor, 600000);
      expect(st.remainingMinor, 400000);
      await expectLater(
        repo.voidPayment(p1, p.id),
        throwsA(isA<ValidationException>()),
      );
      // soft delete: the row is still there
      final rows = await repo.watchPayments(p1, b.id).first;
      expect(rows.length, 2);
      expect(rows.where((r) => r.isDeleted).length, 1);
    });

    test('payment on a voided bill, before the statement, bad input', () async {
      final c = await card();
      final b = await bill(c);
      for (final f in [
        () => repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 0,
          paymentDate: '2026-06-10',
        ),
        () => repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 100,
          paymentDate: 'nope',
        ),
        () => repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 100,
          paymentDate: '2026-06-01',
        ),
      ]) {
        await expectLater(f(), throwsA(isA<ValidationException>()));
      }
      await repo.voidBill(p1, b.id);
      await expectLater(
        repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 100,
          paymentDate: '2026-06-10',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.addPayment(
          profileId: p2,
          billId: b.id,
          amountMinor: 100,
          paymentDate: '2026-06-10',
        ),
        throwsA(isA<ProfileMismatchException>()),
      );
    });

    test('paying after the due date includes interest and the fee', () async {
      final c = await card();
      final b = await bill(c);
      today = '2026-07-25';
      final st = (await repo.watchBill(p1, b.id).first)!;
      expect(st.status, BillStatus.overdue);
      expect(st.remainingMinor, 1049726);
      // the full remaining is accepted, one more minor unit is not
      await expectLater(
        repo.addPayment(
          profileId: p1,
          billId: b.id,
          amountMinor: 1049727,
          paymentDate: '2026-07-25',
        ),
        throwsA(isA<ValidationException>()),
      );
      await repo.addPayment(
        profileId: p1,
        billId: b.id,
        amountMinor: 1049726,
        paymentDate: '2026-07-25',
      );
      final after = (await repo.watchBill(p1, b.id).first)!;
      expect(after.status, BillStatus.paid);
    });
  });

  group('summaries', () {
    test('card and overall summary', () async {
      final c1 = await card(limit: 10000000);
      final c2 = await card(name: 'Master', limit: 5000000);
      await bill(c1);
      await bill(c2, amount: 200000);
      await card(name: 'Other profile', profile: p2);
      final s = await repo.watchCard(p1, c1.id).first;
      expect(s!.outstandingMinor, 1000000);
      expect(s.availableMinor, 9000000);
      expect(s.utilisationBp, 1000);
      expect(s.nextDue!.bill.dueDate, '2026-06-25');

      var o = await repo.overallSummary(p1);
      expect(o.cardCount, 2);
      expect(o.totalOutstandingMinor, 1200000);
      expect(o.totalLimitMinor, 15000000);
      expect(o.overdueCount, 0);
      expect(o.nextDue!.cardName, isNotEmpty);

      today = '2026-07-25';
      o = await repo.overallSummary(p1);
      expect(o.overdueCount, 2);
      expect(o.totalOutstandingMinor, greaterThan(1200000));
      // profile isolation
      final other = await repo.overallSummary(p2);
      expect(other.totalOutstandingMinor, 0);
      expect(other.cardCount, 1);
    });

    test('bills listed newest first and voided excluded by default', () async {
      final c = await card();
      await bill(c, month: '2026-04');
      final may = await bill(c, month: '2026-05');
      await bill(c, month: '2026-06');
      await repo.voidBill(p1, may.id);
      final list = await repo.watchBills(p1, c.id).first;
      expect(list.map((s) => s.bill.billMonth), ['2026-06', '2026-04']);
      final all = await repo.watchBills(p1, c.id, includeVoided: true).first;
      expect(all.length, 3);
      // voided bills do not count as outstanding
      final s = await repo.watchCard(p1, c.id).first;
      expect(s!.unsettledBillCount, 2);
    });
  });

  test('unused import guard', () {
    expect(const Value(1).value, 1);
  });
}
