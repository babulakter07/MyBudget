import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/loans/data/loan_repository.dart';
import 'package:my_budget/features/loans/presentation/loan_detail_screen.dart';
import 'package:my_budget/features/loans/presentation/loan_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _transition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
}

/// 12 x 1,000.00 at 0 %, started on 2026-01-01.
Future<void> _loan(LoanRepository repo, {String lender = 'City Bank'}) =>
    repo.create(
      profileId: 1,
      lenderName: lender,
      principalMinor: 1200000,
      interestRateBp: 0,
      tenureCount: 12,
      startDate: '2026-01-01',
      firstDueDate: '2026-02-01',
    );

Future<LoanRepository> _pump(
  WidgetTester tester,
  Future<void> Function(LoanRepository repo) seed, {
  String initial = '/loans/1',
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  final repo = LoanRepository(db);
  await tester.runAsync(() async {
    await addProfile(db);
    await seed(repo);
  });
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/loans', builder: (_, _) => const LoanListScreen()),
      GoRoute(
        path: '/loans/:id',
        builder: (_, s) =>
            LoanDetailScreen(loanId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/help',
        builder: (_, _) => const Scaffold(body: Text('help page')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return repo;
}

void main() {
  testWidgets('open loan offers close early and adjust', (tester) async {
    await _pump(tester, _loan);
    expect(find.byKey(const ValueKey('btn-close-early')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-adjust')), findsOneWidget);
    expect(find.byKey(const ValueKey('closing-banner')), findsNothing);
  });

  testWidgets('close early records the payment and shows the banner', (
    tester,
  ) async {
    final repo = await _pump(tester, _loan);
    await tester.tap(find.byKey(const ValueKey('btn-close-early')));
    await _transition(tester);
    expect(find.text('Close loan early'), findsOneWidget);
    expect(find.text('Remaining installments'), findsOneWidget);
    expect(find.text('12'), findsWidgets);

    // More than what is owed is refused by the form.
    await tester.enterText(find.byKey(const ValueKey('close-paid')), '99999');
    await _tap(tester, find.byKey(const ValueKey('close-confirm')));
    await tester.pump();
    expect(find.textContaining('Maximum is'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('close-paid')), '9000');
    await tester.enterText(
      find.byKey(const ValueKey('close-remarks')),
      'Paid from bonus',
    );
    await _tap(tester, find.byKey(const ValueKey('close-confirm')));
    await tester.pump();
    await _settle(tester);
    await _transition(tester);

    final pos = (await tester.runAsync(() => repo.getById(1, 1)))!;
    expect(pos.isEarlyClosed, isTrue);
    expect(pos.paidMinor, 900000);
    expect(find.byKey(const ValueKey('closing-banner')), findsOneWidget);
    expect(find.textContaining('Closed early on'), findsOneWidget);
    expect(find.text('Paid to close: ৳9,000.00'), findsOneWidget);
    expect(find.text('Remarks: Paid from bonus'), findsOneWidget);
    expect(find.text('Early closed'), findsOneWidget);
    // Closed loans have no edit / pay / close actions.
    expect(find.byKey(const ValueKey('btn-close-early')), findsNothing);
    expect(find.byKey(const ValueKey('btn-adjust')), findsNothing);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.text('Record payment'), findsNothing);
  });

  testWidgets('adjust creates a linked loan and both show their banners', (
    tester,
  ) async {
    final repo = await _pump(tester, _loan);
    await tester.tap(find.byKey(const ValueKey('btn-adjust')));
    await _transition(tester);
    expect(find.text('Adjust loan'), findsOneWidget);

    // Prefilled with the principal still owed (12,000.00) and 12 installments.
    Finder field(String label) => find.widgetWithText(TextFormField, label);
    expect(
      tester
          .widget<TextFormField>(field('Loan amount (principal)'))
          .controller!
          .text,
      '12000.00',
    );
    expect(
      tester
          .widget<TextFormField>(field('Number of installments'))
          .controller!
          .text,
      '12',
    );
    // Top-up: 3,000.00 of new money over 15 installments.
    await tester.enterText(field('Loan amount (principal)'), '15000');
    await tester.enterText(field('Number of installments'), '15');
    await tester.enterText(
      find.byKey(const ValueKey('adjust-remarks')),
      'Top-up',
    );
    await tester.pump();
    await _tap(tester, find.text('Save'));
    await tester.pump();
    await _settle(tester);
    await _transition(tester);
    await _settle(tester);

    final all = (await tester.runAsync(() => repo.watchAll(1).first))!;
    expect(all, hasLength(2));
    final old = all.firstWhere((p) => p.loan.id == 1);
    final created = all.firstWhere((p) => p.loan.id == 2);
    expect(old.isAdjusted, isTrue);
    expect(old.loan.closingRemarks, 'Top-up');
    expect(created.loan.parentLoanId, 1);
    expect(created.loan.principalMinor, 1500000);
    expect(created.loan.tenureCount, 15);

    // Now on the NEW loan: it links back to the previous one.
    expect(find.byKey(const ValueKey('adjusted-from-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-close-early')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('view-previous')));
    await _transition(tester);
    await _settle(tester);

    // The OLD loan shows the adjusted banner and links forward.
    expect(find.textContaining('Adjusted on'), findsOneWidget);
    expect(find.text('Adjusted'), findsOneWidget);
    expect(find.byKey(const ValueKey('view-replacement')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-adjust')), findsNothing);
  });

  testWidgets('list labels early closed and adjusted loans', (tester) async {
    await _pump(tester, (repo) async {
      await _loan(repo, lender: 'Alpha Bank');
      await _loan(repo, lender: 'Beta Bank');
      await repo.closeEarly(
        profileId: 1,
        loanId: 1,
        closedDate: '2026-03-15',
        paidMinor: 100000,
      );
      await repo.adjust(
        profileId: 1,
        loanId: 2,
        closedDate: '2026-03-15',
        lenderName: 'Beta Bank',
        principalMinor: 1000000,
        interestRateBp: 0,
        tenureCount: 10,
        startDate: '2026-03-15',
        firstDueDate: '2026-04-01',
      );
    }, initial: '/loans');
    expect(find.text('Early closed'), findsOneWidget);
    expect(find.text('Adjusted'), findsOneWidget);
    expect(find.textContaining('Closed early on 2026-03-15'), findsOneWidget);
    expect(find.textContaining('Adjusted on 2026-03-15'), findsOneWidget);
    // The replacing loan is a separate open loan of the same lender.
    expect(find.text('Beta Bank'), findsNWidgets(2));
  });
}
