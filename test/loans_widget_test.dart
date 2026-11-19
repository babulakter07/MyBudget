import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/loans/data/loan_repository.dart';
import 'package:my_budget/features/loans/domain/loan.dart';
import 'package:my_budget/features/loans/domain/loan_calculator.dart';
import 'package:my_budget/features/loans/presentation/loan_detail_screen.dart';
import 'package:my_budget/features/loans/presentation/loan_form_sheet.dart';
import 'package:my_budget/features/loans/presentation/loan_list_screen.dart';
import 'package:my_budget/features/loans/providers/loan_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

const _today = '2026-03-15';

/// 3 x 1,000.00 at 0%, due 2026-02-01 / 03-01 / 04-01.
Loan _loan({int id = 1, String lender = 'City Bank', bool active = true}) =>
    Loan(
      id: id,
      profileId: 1,
      lenderName: lender,
      loanType: 'home',
      referenceNo: 'LN-77',
      principalMinor: 300000,
      interestRateBp: 0,
      interestMethod: 'reducing',
      frequency: 'monthly',
      tenureCount: 3,
      installmentMinor: 100000,
      processingFeeMinor: 0,
      startDate: '2026-01-01',
      firstDueDate: '2026-02-01',
      note: null,
      isActive: active,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

LoanPosition _pos({int paid = 0, int id = 1, String lender = 'City Bank'}) =>
    LoanCalculator.evaluate(_loan(id: id, lender: lender), paid, _today);

LoanPayment _pay(int id, int amount, {bool voided = false}) => LoanPayment(
  id: id,
  profileId: 1,
  loanId: 1,
  amountMinor: amount,
  paymentDate: '2026-02-01',
  note: 'Feb EMI',
  isDeleted: voided,
  createdAt: DateTime(2026),
);

Future<void> _pump(WidgetTester tester, Widget home, List overrides) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/loans/:id',
        builder: (_, _) => const Scaffold(body: Text('DETAIL ROUTE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ...overrides.cast(),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
}

LoanSummary _summary() => LoanRepository.summarize([_pos(paid: 100000)]);

void main() {
  testWidgets('list shows summary, tiles and status chips', (tester) async {
    await _pump(tester, const LoanListScreen(), [
      loanSummaryProvider.overrideWith((ref) => Stream.value(_summary())),
      loansProvider.overrideWith(
        (ref) => Stream.value([
          _pos(paid: 100000),
          _pos(id: 2, lender: 'Brac Bank', paid: 300000),
        ]),
      ),
    ]);
    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('City Bank'), findsOneWidget);
    expect(find.text('Brac Bank'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets); // summary label + status chip
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Loan fully paid'), findsOneWidget);
    expect(find.textContaining('Next due 2026-03-01'), findsWidgets);
    expect(find.text('৳2,000.00'), findsWidgets); // remaining
    expect(find.byKey(const ValueKey('help-loans')), findsOneWidget);
    await tester.tap(find.text('City Bank'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('DETAIL ROUTE'), findsOneWidget);
  });

  testWidgets('list empty state', (tester) async {
    await _pump(tester, const LoanListScreen(), [
      loanSummaryProvider.overrideWith(
        (ref) => Stream.value(LoanSummary.empty),
      ),
      loansProvider.overrideWith((ref) => Stream.value(<LoanPosition>[])),
    ]);
    expect(find.textContaining('No loans yet'), findsOneWidget);
  });

  testWidgets('list error state', (tester) async {
    await _pump(tester, const LoanListScreen(), [
      loanSummaryProvider.overrideWith(
        (ref) => Stream.value(LoanSummary.empty),
      ),
      loansProvider.overrideWith(
        (ref) => Stream<List<LoanPosition>>.error('boom'),
      ),
    ]);
    await tester.pump();
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('fab opens the add loan sheet with a live preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, const LoanListScreen(), [
      loanSummaryProvider.overrideWith(
        (ref) => Stream.value(LoanSummary.empty),
      ),
      loansProvider.overrideWith((ref) => Stream.value(<LoanPosition>[])),
    ]);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add loan'), findsWidgets);
    expect(find.text('Bank / lender name'), findsOneWidget);
    expect(find.text('Number of installments'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), '100000'); // principal
    await tester.enterText(fields.at(3), '12'); // rate
    await tester.enterText(fields.at(4), '12'); // installments
    await tester.pump();
    expect(find.textContaining('≈ 1 years 0 months'), findsOneWidget);
    expect(find.textContaining('Calculated: ৳8,884.88'), findsOneWidget);
    expect(find.text('Total interest'), findsOneWidget);
    expect(find.text('Total payable'), findsOneWidget);
    // 8884.88 * 11 + last installment; total interest ~ 6,618.55
    expect(find.textContaining('৳106,6'), findsWidgets);
  });

  testWidgets('form saves a loan through the repository', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.memory();
    addTearDown(() async => db.close());
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
    final repo = LoanRepository(db, today: () => _today);
    await _pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showLoanForm(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      [loanRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Required fields are validated first.
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter the bank or lender name'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Islami Bank');
    await tester.enterText(fields.at(2), '120000');
    await tester.enterText(fields.at(3), '0');
    await tester.enterText(fields.at(4), '12');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final saved = await tester.runAsync(() => repo.watchAll(1).first);
    expect(saved, hasLength(1));
    expect(saved!.single.loan.lenderName, 'Islami Bank');
    expect(saved.single.loan.installmentMinor, 1000000);
    expect(saved.single.loan.tenureCount, 12);
    expect(find.text('Add loan'), findsNothing); // sheet closed
  });

  testWidgets('detail shows overview, schedule, payments and record sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, const LoanDetailScreen(loanId: 1), [
      loanProvider(1).overrideWith((ref) => Stream.value(_pos(paid: 150000))),
      loanPaymentsProvider(1).overrideWith(
        (ref) => Stream.value([_pay(1, 150000), _pay(2, 5000, voided: true)]),
      ),
    ]);
    expect(find.text('City Bank'), findsWidgets);
    expect(find.text('Paid so far'), findsOneWidget);
    expect(find.text('৳1,500.00'), findsNWidgets(2)); // paid + remaining
    expect(find.text('50% repaid'), findsOneWidget);
    expect(find.text('Total payable'), findsOneWidget);
    expect(find.text('LN-77'), findsOneWidget);
    // schedule
    expect(find.textContaining('Installment 1  •  2026-02-01'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets); // loan chip + installment 2
    expect(find.text('Due'), findsOneWidget); // installment 3
    expect(find.textContaining('Balance ৳0.00'), findsOneWidget);
    // payments
    await tester.tap(find.text('Payments'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Feb EMI'), findsNWidgets(2));
    expect(find.textContaining('Voided'), findsOneWidget);
    expect(find.byTooltip('Void payment'), findsOneWidget);
    await tester.tap(find.byTooltip('Void payment'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('Void the payment of ৳1,500.00'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
    // record payment
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    expect(find.text('Remaining: ৳1,500.00'), findsOneWidget);
    final amount = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(amount.controller!.text, '500.00'); // unpaid part of installment 2
    await tester.enterText(find.byType(TextFormField).first, '2000');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Maximum is ৳1,500.00'), findsOneWidget);
  });

  testWidgets('mark paid on the next installment, paid date is shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pos = LoanCalculator.evaluate(
      _loan(),
      150000,
      _today,
      payments: const [(date: '2026-01-29', amount: 150000)],
    );
    await _pump(tester, const LoanDetailScreen(loanId: 1), [
      loanProvider(1).overrideWith((ref) => Stream.value(pos)),
      loanPaymentsProvider(1)
          .overrideWith((ref) => Stream.value([_pay(1, 150000)])),
    ]);
    // Installment 1 was paid on 29 Jan although it was due on 1 Feb.
    expect(find.textContaining('Paid on 2026-01-29'), findsOneWidget);
    // Only the next unpaid installment (2) offers "Mark paid".
    expect(find.byKey(const ValueKey('mark-paid-1')), findsNothing);
    expect(find.byKey(const ValueKey('mark-paid-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('mark-paid-3')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mark-paid-2')));
    await tester.pumpAndSettle();
    expect(find.text('Mark installment 2 as paid'), findsOneWidget);
    expect(find.textContaining('Due on 2026-03-01'), findsOneWidget);
    final amount = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(amount.controller!.text, '500.00');
  });

  testWidgets('detail not found', (tester) async {
    await _pump(tester, const LoanDetailScreen(loanId: 1), [
      loanProvider(1).overrideWith((ref) => Stream.value(null)),
      loanPaymentsProvider(1)
          .overrideWith((ref) => Stream.value(<LoanPayment>[])),
    ]);
    expect(find.text('Loan not found.'), findsOneWidget);
  });

  testWidgets('closed loan has no record button', (tester) async {
    await _pump(tester, const LoanDetailScreen(loanId: 1), [
      loanProvider(1).overrideWith((ref) => Stream.value(_pos(paid: 300000))),
      loanPaymentsProvider(1)
          .overrideWith((ref) => Stream.value(<LoanPayment>[])),
    ]);
    expect(find.text('Record payment'), findsNothing);
    expect(find.text('100% repaid'), findsOneWidget);
  });

  testWidgets('Bangla: list and detail render localized text', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
          loanSummaryProvider.overrideWith((ref) => Stream.value(_summary())),
          loansProvider.overrideWith(
            (ref) => Stream.value([_pos(paid: 100000)]),
          ),
          loanProvider(1)
              .overrideWith((ref) => Stream.value(_pos(paid: 100000))),
          loanPaymentsProvider(1)
              .overrideWith((ref) => Stream.value([_pay(1, 100000)])),
        ],
        child: localizedApp(home: const LoanListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('ব্যাংক ঋণ'), findsOneWidget);
    expect(find.text('মাসিক কিস্তি'), findsOneWidget);
    expect(find.text('মেয়াদোত্তীর্ণ'), findsWidgets);
    expect(find.textContaining('পরবর্তী কিস্তি'), findsWidgets);
    expect(find.text('Loans'), findsNothing);
  });

  testWidgets('Bangla: detail renders localized text', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
          loanProvider(1)
              .overrideWith((ref) => Stream.value(_pos(paid: 100000))),
          loanPaymentsProvider(1)
              .overrideWith((ref) => Stream.value([_pay(1, 100000)])),
        ],
        child: localizedApp(home: const LoanDetailScreen(loanId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('এ পর্যন্ত পরিশোধ'), findsOneWidget);
    expect(find.text('কিস্তির সূচি'), findsOneWidget);
    expect(find.textContaining('কিস্তি 1'), findsOneWidget);
    expect(find.text('পরিশোধ লিখুন'), findsOneWidget);
    expect(find.text('Record payment'), findsNothing);
    await tester.tap(find.text('পরিশোধসমূহ'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Feb EMI'), findsOneWidget);
  });
}
