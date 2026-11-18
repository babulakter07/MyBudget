import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/debts/data/debt_repository.dart';
import 'package:my_budget/features/debts/domain/debt.dart';

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
  late DebtRepository repo;
  late int p1;
  late int p2;
  const today = '2026-06-15';

  setUp(() async {
    db = AppDatabase.memory();
    repo = DebtRepository(db, today: () => today);
    p1 = await _profile(db, 'One');
    p2 = await _profile(db, 'Two');
  });
  tearDown(() => db.close());

  Future<Debt> lent(
    String person,
    int amount, {
    String? due,
    int? profile,
    String direction = 'lent',
  }) => repo.create(
    profileId: profile ?? p1,
    direction: direction,
    personName: person,
    principalMinor: amount,
    startDate: '2026-06-01',
    dueDate: due,
  );

  test('create validates input', () async {
    expect(() => lent('', 100), throwsA(isA<ValidationException>()));
    expect(() => lent('A', 0), throwsA(isA<ValidationException>()));
    expect(
      () => lent('A', 100, direction: 'x'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => lent('A', 100, due: '2026-05-31'),
      throwsA(isA<ValidationException>()),
    );
    final d = await lent('  Rahim ', 100000, due: '2026-06-01');
    expect(d.personName, 'Rahim');
    expect(d.outstandingMinor, 100000);
  });

  test('outstanding math and over-payment rejection', () async {
    final d = await lent('Rahim', 100000);
    await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 30000,
      paymentDate: '2026-06-05',
    );
    var cur = (await repo.getById(p1, d.id))!;
    expect(cur.paidMinor, 30000);
    expect(cur.outstandingMinor, 70000);
    await expectLater(
      repo.addPayment(
        profileId: p1,
        debtId: d.id,
        amountMinor: 70001,
        paymentDate: '2026-06-06',
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('700.00'),
        ),
      ),
    );
    await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 70000,
      paymentDate: '2026-06-06',
    );
    cur = (await repo.getById(p1, d.id))!;
    expect(cur.outstandingMinor, 0);
    expect(cur.status, DebtStatus.settled);
  });

  test('payment validation: amount, date before start', () async {
    final d = await lent('Rahim', 1000);
    expect(
      () => repo.addPayment(
        profileId: p1,
        debtId: d.id,
        amountMinor: 0,
        paymentDate: '2026-06-05',
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => repo.addPayment(
        profileId: p1,
        debtId: d.id,
        amountMinor: 100,
        paymentDate: '2026-05-31',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('void payment restores outstanding; double void rejected', () async {
    final d = await lent('Rahim', 1000);
    final pay = await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 1000,
      paymentDate: '2026-06-02',
    );
    expect((await repo.getById(p1, d.id))!.status, DebtStatus.settled);
    await repo.voidPayment(p1, pay.id);
    final cur = (await repo.getById(p1, d.id))!;
    expect(cur.outstandingMinor, 1000);
    expect(cur.status, DebtStatus.open);
    // soft: row still exists
    final rows = await db.select(db.debtPayments).get();
    expect(rows.single.isDeleted, isTrue);
    expect(
      () => repo.voidPayment(p1, pay.id),
      throwsA(isA<ValidationException>()),
    );
  });

  test('settle records the remaining amount', () async {
    final d = await lent('Rahim', 1000);
    await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 400,
      paymentDate: '2026-06-02',
    );
    final p = await repo.settle(
      profileId: p1,
      debtId: d.id,
      paymentDate: '2026-06-10',
    );
    expect(p.amountMinor, 600);
    expect((await repo.getById(p1, d.id))!.status, DebtStatus.settled);
    expect(
      () => repo.settle(profileId: p1, debtId: d.id, paymentDate: '2026-06-10'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('status: open / overdue / settled', () async {
    final open = await lent('A', 100, due: '2026-06-15'); // due today: open
    final late = await lent('B', 100, due: '2026-06-14');
    final noDue = await lent('C', 100);
    final paidLate = await lent('D', 100, due: '2026-06-02');
    await repo.settle(
      profileId: p1,
      debtId: paidLate.id,
      paymentDate: '2026-06-03',
    );
    Future<DebtStatus> st(Debt d) async =>
        (await repo.getById(p1, d.id))!.status;
    expect(await st(open), DebtStatus.open);
    expect(await st(late), DebtStatus.overdue);
    expect(await st(noDue), DebtStatus.open);
    expect(await st(paidLate), DebtStatus.settled);
  });

  test('summary totals, overdue count, case-insensitive people', () async {
    await lent('Rahim', 100000, due: '2026-06-01'); // overdue
    final b = await lent('rahim ', 50000);
    await repo.addPayment(
      profileId: p1,
      debtId: b.id,
      amountMinor: 20000,
      paymentDate: '2026-06-02',
    );
    await lent('RAHIM', 30000, direction: 'borrowed');
    await lent('Karim', 10000, direction: 'borrowed', due: '2026-06-10');
    final settled = await lent('Done', 500);
    await repo.settle(
      profileId: p1,
      debtId: settled.id,
      paymentDate: '2026-06-02',
    );
    final s = await repo.summary(p1);
    expect(s.owedToMeMinor, 130000);
    expect(s.iOweMinor, 40000);
    expect(s.netMinor, 90000);
    expect(s.overdueCount, 2);
    expect(s.activeCount, 5);
    expect(s.people.length, 2); // Done is settled and omitted
    final rahim = s.people.firstWhere(
      (p) => p.personName.toLowerCase() == 'rahim',
    );
    expect(rahim.lentOutstandingMinor, 130000);
    expect(rahim.borrowedOutstandingMinor, 30000);
    expect(rahim.netMinor, 100000);
    expect(rahim.debtCount, 3);
  });

  test('watchSummary reacts to payments', () async {
    final d = await lent('Rahim', 1000);
    final stream = repo.watchSummary(p1);
    final expectation = expectLater(
      stream.map((s) => s.owedToMeMinor),
      emitsInOrder([1000, 400]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 600,
      paymentDate: '2026-06-02',
    );
    await expectation;
  });

  test('cross-profile isolation and rejection', () async {
    final d = await lent('Rahim', 1000);
    await lent('Other', 5000, profile: p2);
    expect(await repo.getById(p2, d.id), isNull);
    expect(
      () => repo.addPayment(
        profileId: p2,
        debtId: d.id,
        amountMinor: 100,
        paymentDate: '2026-06-02',
      ),
      throwsA(isA<NotFoundException>()),
    );
    final pay = await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 100,
      paymentDate: '2026-06-02',
    );
    expect(
      () => repo.voidPayment(p2, pay.id),
      throwsA(isA<NotFoundException>()),
    );
    expect(
      () => repo.setArchived(p2, d.id, true),
      throwsA(isA<NotFoundException>()),
    );
    expect(
      () => repo.update(
        profileId: p2,
        id: d.id,
        direction: 'lent',
        personName: 'X',
        principalMinor: 10,
        startDate: '2026-06-01',
      ),
      throwsA(isA<NotFoundException>()),
    );
    expect((await repo.summary(p2)).owedToMeMinor, 5000);
    expect((await repo.summary(p1)).owedToMeMinor, 900);
    // DB-level FK blocks mixed-profile payment rows.
    expect(
      () => db
          .into(db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              profileId: p2,
              debtId: d.id,
              amountMinor: 1,
              paymentDate: '2026-06-02',
              note: const Value(null),
              createdAt: DateTime.now(),
            ),
          ),
      throwsA(anything),
    );
    expect(
      () => lent('X', 100, profile: 999),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('archive hides from lists and summary; no hard delete', () async {
    final d = await lent('Rahim', 1000);
    await repo.setArchived(p1, d.id, true);
    expect(await repo.watchAll(p1).first, isEmpty);
    expect(await repo.watchAll(p1, includeArchived: true).first, hasLength(1));
    expect((await repo.summary(p1)).owedToMeMinor, 0);
    expect((await repo.summary(p1)).activeCount, 0);
    expect(
      () => repo.addPayment(
        profileId: p1,
        debtId: d.id,
        amountMinor: 1,
        paymentDate: '2026-06-02',
      ),
      throwsA(isA<ValidationException>()),
    );
    await repo.setArchived(p1, d.id, false);
    expect(await repo.watchAll(p1).first, hasLength(1));
    expect(await db.select(db.debts).get(), hasLength(1));
  });

  test('update cannot drop principal below paid or move start late', () async {
    final d = await lent('Rahim', 1000);
    await repo.addPayment(
      profileId: p1,
      debtId: d.id,
      amountMinor: 600,
      paymentDate: '2026-06-05',
    );
    expect(
      () => repo.update(
        profileId: p1,
        id: d.id,
        direction: 'lent',
        personName: 'Rahim',
        principalMinor: 500,
        startDate: '2026-06-01',
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => repo.update(
        profileId: p1,
        id: d.id,
        direction: 'lent',
        personName: 'Rahim',
        principalMinor: 2000,
        startDate: '2026-06-10',
      ),
      throwsA(isA<ValidationException>()),
    );
    final u = await repo.update(
      profileId: p1,
      id: d.id,
      direction: 'borrowed',
      personName: 'Rahim K',
      principalMinor: 2000,
      startDate: '2026-06-01',
      dueDate: '2026-07-01',
      note: ' hi ',
    );
    expect(u.outstandingMinor, 1400);
    expect(u.direction, 'borrowed');
    expect(u.note, 'hi');
  });

  test('debts never touch accounts, transactions or budgets', () async {
    final d = await lent('Rahim', 1000);
    await repo.settle(profileId: p1, debtId: d.id, paymentDate: '2026-06-02');
    expect(await db.select(db.accounts).get(), isEmpty);
    expect(await db.select(db.financialTransactions).get(), isEmpty);
    expect(await db.select(db.monthlyBudgets).get(), isEmpty);
  });
}
