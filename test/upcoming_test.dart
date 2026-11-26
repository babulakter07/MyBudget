import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/credit_cards/data/credit_card_repository.dart';
import 'package:my_budget/features/debts/data/debt_repository.dart';
import 'package:my_budget/features/loans/data/loan_repository.dart';
import 'package:my_budget/features/upcoming/data/upcoming_repository.dart';
import 'package:my_budget/features/upcoming/domain/upcoming_payment.dart';
import 'package:my_budget/features/upcoming/presentation/upcoming_payments_card.dart';
import 'package:my_budget/features/upcoming/providers/upcoming_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n_test_helpers.dart';

const _today = '2026-11-26';
final _now = DateTime(2026, 11, 26, 10);

DueEntry _entry(String date, {int amount = 100, int id = 1, int? billId}) =>
    DueEntry(
      kind: UpcomingKind.loan,
      entityId: id,
      name: 'Bank $id',
      amountMinor: amount,
      dueDate: date,
      billId: billId,
    );

void main() {
  group('grouping', () {
    List<UpcomingPayment> group(List<DueEntry> entries) =>
        groupUpcoming(entries, today: _today, lastDay: '2026-12-03');

    test('today is not overdue and the last day is included', () {
      final out = group([
        _entry(_today, id: 1),
        _entry('2026-12-03', id: 2),
        _entry('2026-12-04', id: 3),
        _entry('2026-11-25', id: 4),
      ]);
      expect(out.map((p) => (p.entityId, p.overdue)), [
        (4, true),
        (1, false),
        (2, false),
      ]);
    });

    test('combines one item but keeps overdue and coming apart', () {
      final out = group([
        _entry('2026-10-01', amount: 5),
        _entry('2026-09-01', amount: 7),
        _entry('2026-11-30', amount: 11),
      ]);
      expect(out, hasLength(2));
      expect(
        (out[0].overdue, out[0].amountMinor, out[0].count, out[0].dueDate),
        (true, 12, 2, '2026-09-01'),
      );
      expect(
        (out[1].overdue, out[1].amountMinor, out[1].count),
        (false, 11, 1),
      );
    });

    test('separate card bills stay separate; nothing owed is dropped', () {
      expect(
        group([_entry('2026-11-30', billId: 1), _entry(_today, billId: 2)]),
        hasLength(2),
      );
      expect(group([_entry(_today, amount: 0)]), isEmpty);
    });
  });

  group('from the database', () {
    late AppDatabase db;
    late int p1, p2, account, category;

    Future<int> profile(String name) => db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: name,
            createdAt: _now,
            updatedAt: _now,
          ),
        );

    setUp(() async {
      db = AppDatabase.memory();
      p1 = await profile('One');
      p2 = await profile('Two');
      account = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              profileId: p1,
              name: 'Cash',
              openingDate: '2026-01-01',
              createdAt: _now,
              updatedAt: _now,
            ),
          );
      category = await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              profileId: p1,
              name: 'Home',
              createdAt: _now,
              updatedAt: _now,
            ),
          );
    });
    tearDown(() => db.close());

    Future<List<UpcomingPayment>> load([int? profileId]) =>
        UpcomingRepository(db, clock: () => _now).load(profileId ?? p1);

    Future<int> rule(
      String title, {
      String type = 'expense',
      String frequency = 'weekly',
      String next = '2026-11-28',
      String? end,
      bool active = true,
    }) => db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            profileId: p1,
            type: type,
            accountId: account,
            categoryId: Value(type == 'expense' ? category : null),
            amountMinor: 500,
            title: title,
            frequency: frequency,
            startDate: next,
            nextDueDate: next,
            endDate: Value(end),
            isActive: Value(active),
            createdAt: _now,
            updatedAt: _now,
          ),
        );

    test('loan installments show what is still unpaid', () async {
      final loans = LoanRepository(db, today: () => _today);
      // 12 x 1,000.00 at 0 %, monthly from 10 October.
      final loan = await loans.create(
        profileId: p1,
        lenderName: 'City Bank',
        principalMinor: 1200000,
        interestRateBp: 0,
        tenureCount: 12,
        startDate: '2026-09-10',
        firstDueDate: '2026-10-10',
      );
      await loans.addPayment(
        profileId: p1,
        loanId: loan.loan.id,
        amountMinor: 30000,
        paymentDate: '2026-10-09',
      );

      final out = await load();
      expect(out.map((p) => (p.overdue, p.amountMinor, p.count, p.dueDate)), [
        (true, 170000, 2, '2026-10-10'),
        (false, 100000, 1, '2026-12-10'),
      ]);
      expect(out.first.route, '/loans/${loan.loan.id}');
      expect(await load(p2), isEmpty);

      await loans.setArchived(p1, loan.loan.id, true);
      expect(await load(), isEmpty);
    });

    test('a card bill includes its late fee', () async {
      final cards = CreditCardRepository(db, today: () => _today);
      final card = await cards.createCard(
        profileId: p1,
        name: 'Visa',
        bankName: 'City Bank',
        creditLimitMinor: 10000000,
        statementDay: 1,
        dueDays: 15,
        aprBp: 0,
        minPaymentBp: 500,
        lateFeeFloorMinor: 50000,
      );
      final bill = await cards.createBill(
        profileId: p1,
        cardId: card.id,
        billMonth: '2026-10',
        amountMinor: 1000000,
      );

      final row = (await load()).single;
      expect((row.name, row.overdue, row.amountMinor), ('Visa', true, 1050000));
      expect(row.route, '/cards/${card.id}/bills/${bill.id}');

      await cards.addPayment(
        profileId: p1,
        billId: bill.id,
        amountMinor: 1050000,
        paymentDate: _today,
      );
      expect(await load(), isEmpty);
    });

    test('only borrowed debts with a due date count', () async {
      final debts = DebtRepository(db, today: () => _today);
      Future<void> add(String name, String direction, String? due) async {
        await debts.create(
          profileId: p1,
          direction: direction,
          personName: name,
          principalMinor: 2000,
          startDate: '2026-11-01',
          dueDate: due,
        );
      }

      await add('Karim', 'borrowed', '2026-12-03');
      await add('Rahim', 'lent', '2026-12-03');
      await add('Someday', 'borrowed', null);
      expect((await load()).map((p) => p.name), ['Karim']);
    });

    test('recurring expenses repeat through the 30th day', () async {
      await rule('Tutor');
      await rule('Ends', end: '2026-12-05');
      await rule('Salary', type: 'income');
      await rule('Paused', active: false);
      await rule('Far', frequency: 'yearly', next: '2027-03-01');

      final out = await load();
      expect(
        {for (final p in out) p.name: (p.count, p.amountMinor)},
        {
          // 28 Nov, 5, 12, 19 and 26 Dec (the 30th day).
          'Tutor': (5, 2500),
          'Ends': (2, 1000),
        },
      );
    });

    test('the stream updates after a change', () async {
      final repo = UpcomingRepository(db, clock: () => _now);
      final names = repo.watch(p1).map((l) => l.map((p) => p.name).join());
      final seen = expectLater(names, emitsThrough('Rent'));
      await rule('Rent');
      await seen;
    });
  });

  group('card widget', () {
    UpcomingPayment payment(
      String name,
      String date,
      int amount, {
      bool overdue = false,
      int id = 1,
    }) => UpcomingPayment(
      kind: UpcomingKind.debt,
      entityId: id,
      name: name,
      amountMinor: amount,
      dueDate: date,
      count: 1,
      overdue: overdue,
    );

    Future<SharedPreferences> pump(
      WidgetTester tester,
      List<UpcomingPayment> payments, {
      Locale locale = const Locale('en'),
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            upcomingClockProvider.overrideWithValue(() => _now),
            upcomingPaymentsProvider.overrideWith(
              (ref) => Stream.value(payments),
            ),
          ],
          child: localizedApp(
            locale: locale,
            home: const Scaffold(
              body: SingleChildScrollView(child: UpcomingPaymentsCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return prefs;
    }

    testWidgets('is hidden when nothing is owed', (tester) async {
      await pump(tester, const []);
      expect(find.byKey(const ValueKey('upcoming-card')), findsNothing);
    });

    testWidgets('switches between 7 and 30 days and remembers it', (
      tester,
    ) async {
      final prefs = await pump(tester, [
        payment('Old', '2026-11-01', 10000, overdue: true),
        payment('Now', _today, 20000, id: 2),
        payment('Later', '2026-12-20', 40000, id: 3),
      ]);
      expect(find.textContaining('Overdue: '), findsOneWidget);
      expect(find.textContaining('Due in 7 days: '), findsOneWidget);
      expect(find.textContaining('200.00'), findsWidgets);
      expect(find.textContaining('Due today'), findsOneWidget);
      expect(find.text('Later'), findsNothing);

      await tester.tap(find.text('Next 30 days'));
      await tester.pumpAndSettle();
      expect(find.text('Later'), findsOneWidget);
      expect(find.textContaining('600.00'), findsOneWidget);
      expect(prefs.getInt('upcoming_window_days'), 30);
    });

    testWidgets('stays visible when only later payments exist', (tester) async {
      await pump(tester, [payment('Later', '2026-12-20', 40000)]);
      expect(find.text('Nothing due in the next 7 days.'), findsOneWidget);
      expect(find.text('Next 30 days'), findsOneWidget);
    });

    testWidgets('collapses long lists', (tester) async {
      await pump(tester, [
        for (var i = 1; i <= 6; i++) payment('Item $i', _today, 100, id: i),
      ]);
      expect(find.text('Item 5'), findsNothing);
      await tester.tap(find.text('Show all (6)'));
      await tester.pumpAndSettle();
      expect(find.text('Item 6'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('renders in Bangla on a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, [
        payment('A very long lender name that cannot fit', _today, 123456789),
      ], locale: const Locale('bn'));
      expect(find.text('আসন্ন পেমেন্ট'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
