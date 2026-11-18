import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/budgets/domain/budget.dart';
import 'package:my_budget/features/budgets/presentation/budget_view.dart';
import 'package:my_budget/features/budgets/providers/budget_providers.dart';
import 'package:my_budget/features/debts/domain/debt.dart';
import 'package:my_budget/features/debts/presentation/debt_detail_screen.dart';
import 'package:my_budget/features/debts/presentation/debt_list_screen.dart';
import 'package:my_budget/features/debts/providers/debt_providers.dart';
import 'package:my_budget/features/goals/domain/goal.dart';
import 'package:my_budget/features/goals/presentation/goal_list_screen.dart';
import 'package:my_budget/features/goals/providers/goal_providers.dart';
import 'package:my_budget/l10n/l10n.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

Widget localizedApp({required Widget home}) => MaterialApp(
  locale: const Locale('bn'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: _delegates,
  home: home,
);

/// The bare test app has no Cupertino delegate for `bn`; Flutter reports that
/// as a (harmless) warning exception, so only fail on anything else.
void _expectNoRealException(WidgetTester tester) {
  final e = tester.takeException();
  if (e == null) return;
  expect(
    e.toString(),
    contains('not supported by all of its localization delegates'),
  );
}

class _May extends SelectedMonthNotifier {
  @override
  SelectedMonth build() => const SelectedMonth(2026, 5);
}

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

const _mb = MonthBudget(
  year: 2026,
  month: 5,
  hasBudget: true,
  summary: BudgetSummary(budgetMinor: 100000, expenseMinor: 30000),
  categories: [
    CategoryBudgetSummary(
      categoryId: 1,
      categoryName: 'Food',
      allocationMinor: 50000,
      spentMinor: 20000,
      rolloverEnabled: true,
      carriedOverMinor: 5000,
    ),
  ],
);

Future<void> _pumpBudget(WidgetTester tester, {required bool bn}) async {
  const home = Scaffold(body: BudgetView());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        selectedBudgetMonthProvider.overrideWith(_May.new),
        budgetSummaryProvider.overrideWith((ref) => Stream.value(_mb)),
      ],
      child: bn ? localizedApp(home: home) : const MaterialApp(home: home),
    ),
  );
  await tester.pump();
  await tester.pump();
}

GoalWithProgress _goal() => GoalWithProgress(
  goal: Goal(
    id: 1,
    profileId: 1,
    name: 'Bike',
    accountId: 1,
    targetMinor: 100000,
    targetDate: '2026-09-01',
    note: null,
    isActive: true,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  accountName: 'Savings',
  accountActive: true,
  progress: computeGoalProgress(
    balanceMinor: 25000,
    targetMinor: 100000,
    today: '2026-06-01',
    targetDate: '2026-09-01',
  ),
);

Debt _debt({String direction = 'lent', String? due}) => Debt(
  id: 1,
  profileId: 1,
  direction: direction,
  personName: 'Rahim',
  principalMinor: 100000,
  paidMinor: 30000,
  startDate: '2026-06-01',
  dueDate: due,
  note: null,
  isActive: true,
  status: DebtStatus.overdue,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _pumpRouter(
  WidgetTester tester,
  Widget home,
  List overrides, {
  required bool bn,
}) async {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ...overrides.cast(),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(bn ? 'bn' : 'en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _delegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('budget view renders in Bangla', (tester) async {
    await _pumpBudget(tester, bn: true);
    expect(find.text('মে 2026'), findsOneWidget);
    expect(find.text('বাজেট'), findsOneWidget);
    expect(find.text('ক্যাটাগরি বরাদ্দ'), findsOneWidget);
    expect(find.text('অব্যয়িত টাকা পরের মাসে নিন'), findsOneWidget);
    expect(find.textContaining('আগের মাস থেকে এসেছে'), findsOneWidget);
    expect(find.text('Budget'), findsNothing);
    _expectNoRealException(tester);
  });

  testWidgets('budget view English smoke', (tester) async {
    await _pumpBudget(tester, bn: false);
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.text('Category allocations'), findsOneWidget);
    expect(find.text('+৳50.00 carried over'), findsOneWidget);
    expect(find.text('Carry over unspent'), findsOneWidget);
  });

  testWidgets('goals list renders in Bangla with plural sentence', (
    tester,
  ) async {
    await _pumpRouter(tester, const GoalListScreen(), [
      goalsProvider.overrideWith((ref) => Stream.value([_goal()])),
      activeGoalsProvider.overrideWith((ref) => Stream.value([_goal()])),
    ], bn: true);
    expect(find.text('সঞ্চয় লক্ষ্য'), findsOneWidget);
    expect(find.text('আর্কাইভ করা দেখান'), findsOneWidget);
    expect(find.text('হিসাব: Savings'), findsOneWidget);
    expect(find.textContaining('দিন বাকি'), findsOneWidget);
    expect(find.textContaining('প্রতি মাসে'), findsOneWidget);
    _expectNoRealException(tester);
  });

  testWidgets('goals list English smoke', (tester) async {
    await _pumpRouter(tester, const GoalListScreen(), [
      goalsProvider.overrideWith((ref) => Stream.value([_goal()])),
    ], bn: false);
    expect(find.text('Savings goals'), findsOneWidget);
    expect(find.text('Account: Savings'), findsOneWidget);
    expect(find.textContaining('days left'), findsOneWidget);
  });

  testWidgets('debts list and detail render in Bangla', (tester) async {
    await _pumpRouter(tester, const DebtListScreen(), [
      debtSummaryProvider.overrideWith(
        (ref) => Stream.value(
          const DebtSummary(
            owedToMeMinor: 70000,
            iOweMinor: 0,
            overdueCount: 1,
            people: [],
            activeCount: 1,
          ),
        ),
      ),
      debtsByDirectionProvider('lent')
          .overrideWith((ref) => Stream.value([_debt(due: '2026-01-01')])),
      debtsByDirectionProvider('borrowed')
          .overrideWith((ref) => Stream.value(<Debt>[])),
    ], bn: true);
    expect(find.text('ঋণ ও দেনা-পাওনা'), findsOneWidget);
    expect(find.text('দেওয়া'), findsOneWidget);
    expect(find.text('নেওয়া'), findsOneWidget);
    expect(find.text('আমি পাব'), findsOneWidget);
    expect(find.text('মেয়াদোত্তীর্ণ'), findsOneWidget);
    _expectNoRealException(tester);

    await tester.pumpWidget(const SizedBox());
    await _pumpRouter(tester, const DebtDetailScreen(debtId: 1), [
      debtProvider(1).overrideWith((ref) => Stream.value(_debt())),
      debtPaymentsProvider(1).overrideWith(
        (ref) => Stream.value(<DebtPayment>[
          DebtPayment(
            id: 1,
            profileId: 1,
            debtId: 1,
            amountMinor: 30000,
            paymentDate: '2026-06-05',
            note: null,
            isDeleted: true,
            createdAt: DateTime(2024),
          ),
        ]),
      ),
    ], bn: true);
    expect(find.text('সম্পূর্ণ পরিশোধিত হিসেবে চিহ্নিত করুন'), findsOneWidget);
    expect(find.text('মূল টাকা'), findsOneWidget);
    expect(find.textContaining('বাতিল করা'), findsOneWidget);
    _expectNoRealException(tester);
  });

  testWidgets('debt reminder text is localized', (tester) async {
    late AppLocalizations l;
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (c) {
            l = c.l10n;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      l.debtsReminderLentDue('Rahim', '৳700.00', '৳1,000.00', '2026-07-01'),
      contains('রিমাইন্ডার'),
    );
    expect(l.goalsOverdueBy(1, '2026-01-01'), contains('1 দিন'));
    _expectNoRealException(tester);
  });
}
