import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/app/theme/app_colors.dart';
import 'package:my_budget/features/budgets/domain/budget.dart';
import 'package:my_budget/features/budgets/presentation/budget_view.dart';
import 'package:my_budget/features/budgets/providers/budget_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _May extends SelectedMonthNotifier {
  @override
  SelectedMonth build() => const SelectedMonth(2026, 5);
}

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, MonthBudget mb) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        selectedBudgetMonthProvider.overrideWith(_May.new),
        budgetSummaryProvider.overrideWith((ref) => Stream.value(mb)),
      ],
      child: const MaterialApp(home: Scaffold(body: BudgetView())),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('empty month shows reset message and set budget button', (
    tester,
  ) async {
    await _pump(
      tester,
      const MonthBudget(
        year: 2026,
        month: 5,
        hasBudget: false,
        summary: BudgetSummary(budgetMinor: 0, expenseMinor: 0),
        categories: [],
      ),
    );
    expect(
      find.text('New month: set a budget; nothing carries over.'),
      findsOneWidget,
    );
    expect(find.text('Set budget'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets(
    'populated month shows totals, red negative remaining, allocations',
    (tester) async {
      await _pump(
        tester,
        const MonthBudget(
          year: 2026,
          month: 5,
          hasBudget: true,
          summary: BudgetSummary(budgetMinor: 100000, expenseMinor: 130000),
          categories: [
            CategoryBudgetSummary(
              categoryId: 1,
              categoryName: 'Food',
              allocationMinor: 50000,
              spentMinor: 20000,
            ),
          ],
        ),
      );
      expect(find.text('May 2026'), findsOneWidget);
      expect(find.text('৳1,000.00'), findsOneWidget);
      expect(find.text('৳1,300.00'), findsOneWidget);
      final rem = tester.widget<Text>(find.text('-৳300.00'));
      expect(rem.style?.color, AppColors.expense);
      expect(find.text('130.0% used'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Spent ৳200.00 of ৳500.00'), findsOneWidget);
      expect(find.text('Remaining ৳300.00'), findsOneWidget);
      expect(find.byTooltip('Edit budget'), findsOneWidget);
    },
  );

  testWidgets('prev/next change the displayed month', (tester) async {
    await _pump(
      tester,
      const MonthBudget(
        year: 2026,
        month: 5,
        hasBudget: false,
        summary: BudgetSummary(budgetMinor: 0, expenseMinor: 0),
        categories: [],
      ),
    );
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pump();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(find.text('June 2026'), findsOneWidget);
  });

  testWidgets(
    'rollover toggle and carried-over label use effective allowance',
    (tester) async {
      await _pump(
        tester,
        const MonthBudget(
          year: 2026,
          month: 5,
          hasBudget: true,
          summary: BudgetSummary(budgetMinor: 100000, expenseMinor: 0),
          categories: [
            CategoryBudgetSummary(
              categoryId: 1,
              categoryName: 'Food',
              allocationMinor: 50000,
              spentMinor: 20000,
              categoryBudgetId: 7,
              rolloverEnabled: true,
              carriedOverMinor: 8000,
            ),
          ],
        ),
      );
      expect(find.text('Carry over unspent'), findsOneWidget);
      expect(find.text('+৳80.00 carried over'), findsOneWidget);
      expect(find.text('Spent ৳200.00 of ৳580.00'), findsOneWidget);
      expect(find.text('Remaining ৳380.00'), findsOneWidget);
      final sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, isTrue);
    },
  );

  testWidgets('no carried-over line when rollover is off', (tester) async {
    await _pump(
      tester,
      const MonthBudget(
        year: 2026,
        month: 5,
        hasBudget: true,
        summary: BudgetSummary(budgetMinor: 100000, expenseMinor: 0),
        categories: [
          CategoryBudgetSummary(
            categoryId: 1,
            categoryName: 'Food',
            allocationMinor: 50000,
            spentMinor: 0,
          ),
        ],
      ),
    );
    expect(find.textContaining('carried over'), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });
}
