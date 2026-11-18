import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/debts/domain/debt.dart';
import 'package:my_budget/features/debts/presentation/debt_detail_screen.dart';
import 'package:my_budget/features/debts/presentation/debt_list_screen.dart';
import 'package:my_budget/features/debts/presentation/debt_summary_card.dart';
import 'package:my_budget/features/debts/providers/debt_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Debt _debt(
  int id,
  String person,
  int principal, {
  int paid = 0,
  String direction = 'lent',
  String? due,
  DebtStatus status = DebtStatus.open,
}) => Debt(
  id: id,
  profileId: 1,
  direction: direction,
  personName: person,
  principalMinor: principal,
  paidMinor: paid,
  startDate: '2026-06-01',
  dueDate: due,
  note: null,
  isActive: true,
  status: status,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

DebtPayment _pay(int id, int amount, {bool voided = false}) => DebtPayment(
  id: id,
  profileId: 1,
  debtId: 1,
  amountMinor: amount,
  paymentDate: '2026-06-05',
  note: null,
  isDeleted: voided,
  createdAt: DateTime(2024),
);

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  List overrides, {
  String initial = '/',
}) async {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/debts',
        builder: (_, _) => const Scaffold(body: Text('DEBTS ROUTE')),
      ),
      GoRoute(
        path: '/debts/:id',
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

void main() {
  testWidgets('list shows summary header, tabs, status chips', (tester) async {
    await _pump(tester, const DebtListScreen(), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(
          const DebtSummary(
            owedToMeMinor: 150000,
            iOweMinor: 50000,
            overdueCount: 1,
            people: [],
            activeCount: 2,
          ),
        ),
      ),
      debtsByDirectionProvider('lent').overrideWith(
        (ref) => Stream.value([
          _debt(
            1,
            'Rahim',
            100000,
            paid: 20000,
            due: '2026-01-01',
            status: DebtStatus.overdue,
          ),
          _debt(2, 'rahim', 70000),
        ]),
      ),
      debtsByDirectionProvider('borrowed')
          .overrideWith((ref) => Stream.value(<Debt>[])),
    ]);
    expect(find.text('৳1,500.00'), findsOneWidget);
    expect(find.text('৳500.00'), findsOneWidget);
    expect(find.text('৳1,000.00'), findsOneWidget); // net
    expect(find.text('৳800.00'), findsOneWidget); // outstanding
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    // grouped: one case-insensitive person header with combined total
    await tester.tap(find.byTooltip('Group by person'));
    await tester.pump();
    expect(find.text('৳1,500.00'), findsNWidgets(2)); // header total + group
    // borrowed tab empty state
    await tester.tap(find.text('Borrowed'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('No money borrowed yet.'), findsOneWidget);
  });

  testWidgets('list empty and error states', (tester) async {
    await _pump(tester, const DebtListScreen(), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(DebtSummary.empty),
      ),
      debtsByDirectionProvider('lent')
          .overrideWith((ref) => Stream.value(<Debt>[])),
      debtsByDirectionProvider('borrowed')
          .overrideWith((ref) => Stream<List<Debt>>.error('boom')),
    ]);
    expect(find.text('No money lent yet.'), findsOneWidget);
    await tester.tap(find.text('Borrowed'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('fab opens add sheet', (tester) async {
    await _pump(tester, const DebtListScreen(), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(DebtSummary.empty),
      ),
      debtsByDirectionProvider('lent')
          .overrideWith((ref) => Stream.value(<Debt>[])),
      debtsByDirectionProvider('borrowed')
          .overrideWith((ref) => Stream.value(<Debt>[])),
    ]);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add debt'), findsWidgets);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('Due date'), findsOneWidget);
  });

  testWidgets('detail shows totals and payment history with voided', (
    tester,
  ) async {
    await _pump(tester, const DebtDetailScreen(debtId: 1), [
      debtProvider(1).overrideWith(
        (ref) => Stream.value(_debt(1, 'Rahim', 100000, paid: 30000)),
      ),
      debtPaymentsProvider(1).overrideWith(
        (ref) => Stream.value([_pay(1, 30000), _pay(2, 5000, voided: true)]),
      ),
    ]);
    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('৳1,000.00'), findsOneWidget); // principal
    expect(find.text('৳700.00'), findsOneWidget); // outstanding
    expect(find.text('৳300.00'), findsNWidgets(2)); // paid + payment row
    expect(find.textContaining('Voided'), findsOneWidget);
    expect(find.byTooltip('Void payment'), findsOneWidget);
    expect(find.text('Mark fully settled'), findsOneWidget);
    await tester.tap(find.byTooltip('Void payment'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Void payment'), findsWidgets);
    expect(find.text('Void'), findsOneWidget);
  });

  testWidgets('detail not found and settled (no add button)', (tester) async {
    await _pump(tester, const DebtDetailScreen(debtId: 1), [
      debtProvider(1).overrideWith((ref) => Stream.value(null)),
      debtPaymentsProvider(1)
          .overrideWith((ref) => Stream.value(<DebtPayment>[])),
    ]);
    expect(find.text('Debt not found.'), findsOneWidget);
  });

  testWidgets('detail settled hides add payment', (tester) async {
    await _pump(tester, const DebtDetailScreen(debtId: 1), [
      debtProvider(1).overrideWith(
        (ref) => Stream.value(
          _debt(1, 'Rahim', 1000, paid: 1000, status: DebtStatus.settled),
        ),
      ),
      debtPaymentsProvider(1)
          .overrideWith((ref) => Stream.value(<DebtPayment>[])),
    ]);
    expect(find.text('Add payment'), findsNothing);
    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('No payments yet.'), findsOneWidget);
  });

  testWidgets('summary card shows totals and navigates', (tester) async {
    await _pump(tester, const Scaffold(body: DebtSummaryCard()), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(
          const DebtSummary(
            owedToMeMinor: 150000,
            iOweMinor: 50000,
            overdueCount: 3,
            people: [],
            activeCount: 4,
          ),
        ),
      ),
    ]);
    expect(find.text('৳1,500.00'), findsOneWidget);
    expect(find.text('৳500.00'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(DebtSummaryCard));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('DEBTS ROUTE'), findsOneWidget);
  });

  testWidgets('summary card hidden when no debts', (tester) async {
    await _pump(tester, const Scaffold(body: DebtSummaryCard()), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(DebtSummary.empty),
      ),
    ]);
    expect(find.text('Debts & loans'), findsNothing);
  });
}
