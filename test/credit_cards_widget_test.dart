import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/credit_cards/data/credit_card_repository.dart';
import 'package:my_budget/features/credit_cards/domain/credit_card.dart';
import 'package:my_budget/features/credit_cards/domain/credit_card_calculator.dart';
import 'package:my_budget/features/credit_cards/presentation/credit_card_bill_screen.dart';
import 'package:my_budget/features/credit_cards/presentation/credit_card_detail_screen.dart';
import 'package:my_budget/features/credit_cards/presentation/credit_card_form_sheet.dart';
import 'package:my_budget/features/credit_cards/presentation/credit_card_list_screen.dart';
import 'package:my_budget/features/credit_cards/providers/credit_card_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

CreditCard _card({int id = 1, String name = 'Visa Gold'}) => CreditCard(
  id: id,
  profileId: 1,
  name: name,
  bankName: 'City Bank',
  lastFour: '4242',
  creditLimitMinor: 10000000,
  statementDay: 5,
  dueDays: 20,
  aprBp: 2400,
  minPaymentBp: 500,
  minPaymentFloorMinor: 50000,
  lateFeeBp: 200,
  lateFeeFloorMinor: 30000,
  interestFromStatement: false,
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

CreditCardBill _bill({int id = 10}) => CreditCardBill(
  id: id,
  profileId: 1,
  cardId: 1,
  billMonth: '2026-06',
  statementDate: '2026-06-05',
  dueDate: '2026-06-25',
  amountMinor: 1000000,
  minPaymentMinor: 50000,
  note: null,
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

BillStatement _statement(String asOf, {List<CardPayment> pays = const []}) =>
    computeStatement(card: _card(), bill: _bill(), payments: pays, asOf: asOf);

CardSummary _summary(BillStatement? s, {String name = 'Visa Gold'}) =>
    CardSummary(
      card: _card(name: name),
      outstandingMinor: s?.remainingMinor ?? 0,
      overdueCount: s?.status == BillStatus.overdue ? 1 : 0,
      unsettledBillCount: s == null ? 0 : 1,
      chargesMinor: s?.totalChargesMinor ?? 0,
      nextDue: s,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  List overrides, {
  Widget Function(Widget)? wrap,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ...overrides.cast(),
      ],
      child: wrap == null ? MaterialApp(home: home) : wrap(home),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('list: empty state', (tester) async {
    await _pump(tester, const CreditCardListScreen(), [
      creditCardSummariesProvider.overrideWith(
        (ref) => Stream.value(const <CardSummary>[]),
      ),
      overallCardSummaryProvider.overrideWith(
        (ref) => Stream.value(OverallCardSummary.empty),
      ),
    ]);
    expect(
      find.text(
        'No credit cards yet. Add one to track bills, interest and late fees.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Add card'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('list: error state', (tester) async {
    await _pump(tester, const CreditCardListScreen(), [
      creditCardSummariesProvider.overrideWith(
        (ref) => Stream<List<CardSummary>>.error('boom'),
      ),
      overallCardSummaryProvider.overrideWith(
        (ref) => Stream.value(OverallCardSummary.empty),
      ),
    ]);
    expect(find.text('Something went wrong'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('list: cards with overdue badge and overall summary', (
    tester,
  ) async {
    final overdue = _statement('2026-07-25');
    await _pump(tester, const CreditCardListScreen(), [
      creditCardSummariesProvider.overrideWith(
        (ref) => Stream.value([_summary(overdue)]),
      ),
      overallCardSummaryProvider.overrideWith(
        (ref) => Stream.value(
          OverallCardSummary(
            cardCount: 1,
            totalOutstandingMinor: overdue.remainingMinor,
            totalLimitMinor: 10000000,
            overdueCount: 1,
            nextDue: DueBill(cardName: 'Visa Gold', statement: overdue),
          ),
        ),
      ),
    ]);
    expect(find.text('Visa Gold'), findsOneWidget);
    expect(find.text('City Bank  •••• 4242'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Total outstanding'), findsOneWidget);
    expect(find.text('Overdue bills: 1'), findsOneWidget);
    expect(find.text('Next due: Visa Gold on 2026-06-25'), findsOneWidget);
    // outstanding 1,049,726 minor shown in summary and tile
    expect(find.text('৳10,497.26'), findsNWidgets(2));
    await _teardown(tester);
  });

  testWidgets('form: validates, then saves a card to the database', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final repo = CreditCardRepository(db);
    await tester.runAsync(() async {
      final now = DateTime.now();
      await db
          .into(db.financialProfiles)
          .insert(
            FinancialProfilesCompanion.insert(
              name: 'P',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, const Scaffold(body: CreditCardFormSheet()), [
      creditCardRepositoryProvider.overrideWithValue(repo),
    ]);
    // empty submit shows validation messages
    await tester.tap(find.byKey(const ValueKey('cc-save')));
    await tester.pump();
    expect(find.text('Required'), findsWidgets);

    Future<void> type(String key, String text) async {
      await tester.enterText(find.byKey(ValueKey(key)), text);
    }

    await type('cc-name', 'Visa Gold');
    await type('cc-bank', 'City Bank');
    await type('cc-last4', '4242');
    await type('cc-limit', '100000');
    await type('cc-stmt-day', '5');
    await type('cc-due-days', '20');
    await type('cc-apr', '24');
    await type('cc-min-pct', '5');
    await type('cc-min-floor', '500');
    await type('cc-fee-pct', '2');
    await type('cc-fee-floor', '300');
    await tester.ensureVisible(find.byKey(const ValueKey('cc-save')));
    await tester.tap(find.byKey(const ValueKey('cc-save')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    final saved = await tester.runAsync(() => repo.getCard(1, 1));
    expect(saved, isNotNull);
    expect(saved!.name, 'Visa Gold');
    expect(saved.creditLimitMinor, 10000000);
    expect(saved.aprBp, 2400);
    expect(saved.minPaymentFloorMinor, 50000);
    expect(saved.lateFeeBp, 200);
    expect(saved.lateFeeFloorMinor, 30000);

    await _teardown(tester);
    await tester.runAsync(() => db.close());
  });

  testWidgets('detail: policy chips and bills with charges', (tester) async {
    final st = _statement('2026-07-25');
    await _pump(tester, const CreditCardDetailScreen(cardId: 1), [
      creditCardProvider(1).overrideWith((ref) => Stream.value(_summary(st))),
      cardBillsProvider(1).overrideWith((ref) => Stream.value([st])),
    ]);
    expect(find.text('APR 24%'), findsOneWidget);
    expect(find.text('Min 5%'), findsOneWidget);
    expect(find.text('Late fee 2%'), findsOneWidget);
    expect(find.text('Statement day 5'), findsOneWidget);
    expect(find.text('Pay within 20 days'), findsOneWidget);
    expect(find.text('2026-06'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.textContaining('+4.97% charges'), findsOneWidget);
    expect(find.text('Add bill'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('detail: no bills and card not found', (tester) async {
    await _pump(tester, const CreditCardDetailScreen(cardId: 1), [
      creditCardProvider(1).overrideWith((ref) => Stream.value(_summary(null))),
      cardBillsProvider(1)
          .overrideWith((ref) => Stream.value(const <BillStatement>[])),
    ]);
    expect(
      find.text('No bills yet. Add a monthly statement to start tracking.'),
      findsOneWidget,
    );
    await _teardown(tester);

    await _pump(tester, const CreditCardDetailScreen(cardId: 2), [
      creditCardProvider(2).overrideWith((ref) => Stream.value(null)),
      cardBillsProvider(2)
          .overrideWith((ref) => Stream.value(const <BillStatement>[])),
    ]);
    expect(find.text('Card not found.'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('bill screen: breakdown, projection, payments and pay sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pay = CardPayment(
      id: 1,
      profileId: 1,
      billId: 10,
      amountMinor: 20000,
      paymentDate: '2026-06-10',
      note: 'first',
      isDeleted: false,
      createdAt: DateTime(2024),
    );
    final st = _statement('2026-07-25', pays: [pay]);
    final projection = projectCharges(
      card: _card(),
      bill: _bill(),
      payments: [pay],
      asOf: '2026-07-25',
    );
    await _pump(tester, const CreditCardBillScreen(cardId: 1, billId: 10), [
      creditCardProvider(1).overrideWith((ref) => Stream.value(_summary(st))),
      cardBillProvider(10).overrideWith((ref) => Stream.value(st)),
      billProjectionProvider(10)
          .overrideWith((ref) => Stream.value(projection)),
      cardPaymentsProvider(10).overrideWith((ref) => Stream.value([pay])),
    ]);
    expect(find.text('2026-06 bill'), findsOneWidget);
    expect(find.text('Bill breakdown'), findsOneWidget);
    expect(find.text('Interest (24% APR)'), findsOneWidget);
    expect(find.text('Late fee (2%)'), findsOneWidget);
    expect(find.text('Added to this bill'), findsOneWidget);
    expect(find.text('What if you delay?'), findsOneWidget);
    expect(find.textContaining('Pay only the minimum'), findsOneWidget);
    expect(find.text('first', skipOffstage: false), findsNothing);
    expect(find.textContaining('first'), findsOneWidget);
    expect(find.byTooltip('Void payment'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Record payment'), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-full')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pay-full')));
    await tester.pump();
    expect(
      find.widgetWithText(TextFormField, minorOf(st.remainingMinor)),
      findsOneWidget,
    );
    await _teardown(tester);
  });

  testWidgets('bill screen: paying through the sheet updates the database', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final repo = CreditCardRepository(db, today: () => '2026-06-10');
    late BillStatement st;
    await tester.runAsync(() async {
      final now = DateTime.now();
      await db
          .into(db.financialProfiles)
          .insert(
            FinancialProfilesCompanion.insert(
              name: 'P',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final c = await repo.createCard(
        profileId: 1,
        name: 'Visa Gold',
        bankName: 'City Bank',
        creditLimitMinor: 10000000,
        statementDay: 5,
        dueDays: 20,
        aprBp: 2400,
        minPaymentBp: 500,
        minPaymentFloorMinor: 50000,
      );
      final b = await repo.createBill(
        profileId: 1,
        cardId: c.id,
        billMonth: '2026-06',
        amountMinor: 1000000,
      );
      st = (await repo.watchBill(1, b.id).first)!;
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, const CreditCardBillScreen(cardId: 1, billId: 1), [
      creditCardRepositoryProvider.overrideWithValue(repo),
    ]);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Pay'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('pay-min')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pay-save')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    final after = await tester.runAsync(
      () => repo.watchPayments(1, st.bill.id).first,
    );
    expect(after!.single.amountMinor, 50000);
    await _teardown(tester);
    await tester.runAsync(() => db.close());
  });

  testWidgets('Bangla: list and bill screens render localized text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final st = _statement('2026-07-25');
    await _pump(tester, const CreditCardListScreen(), [
      creditCardSummariesProvider.overrideWith(
        (ref) => Stream.value([_summary(st)]),
      ),
      overallCardSummaryProvider.overrideWith(
        (ref) => Stream.value(
          OverallCardSummary(
            cardCount: 1,
            totalOutstandingMinor: st.remainingMinor,
            totalLimitMinor: 10000000,
            overdueCount: 1,
            nextDue: DueBill(cardName: 'Visa Gold', statement: st),
          ),
        ),
      ),
    ], wrap: (h) => localizedApp(home: h));
    expect(find.text('ক্রেডিট কার্ড'), findsOneWidget);
    expect(find.text('মোট বকেয়া'), findsOneWidget);
    expect(find.text('মেয়াদোত্তীর্ণ'), findsOneWidget);
    await _teardown(tester);

    await _pump(tester, const CreditCardBillScreen(cardId: 1, billId: 10), [
      creditCardProvider(1).overrideWith((ref) => Stream.value(_summary(st))),
      cardBillProvider(10).overrideWith((ref) => Stream.value(st)),
      billProjectionProvider(10).overrideWith((ref) => Stream.value(null)),
      cardPaymentsProvider(10)
          .overrideWith((ref) => Stream.value(const <CardPayment>[])),
    ], wrap: (h) => localizedApp(home: h));
    expect(find.text('বিলের বিবরণ'), findsOneWidget);
    expect(find.text('সুদ (APR 24%)'), findsOneWidget);
    expect(find.text('কোনো পরিশোধ নথিভুক্ত নেই।'), findsOneWidget);
    await _teardown(tester);
  });
}

String minorOf(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
