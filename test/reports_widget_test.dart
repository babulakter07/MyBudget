import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/reports/presentation/custom_range_report_screen.dart';
import 'package:my_budget/features/reports/presentation/monthly_report_screen.dart';
import 'package:my_budget/features/reports/presentation/reports_view.dart';
import 'package:my_budget/features/reports/presentation/yearly_report_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'reports_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _mount(WidgetTester tester, AppDatabase db, Widget child) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('ReportsView shows the three report cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReportsView())),
    );
    expect(find.text('Monthly report'), findsOneWidget);
    expect(find.text('Yearly report'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);
  });

  testWidgets('MonthlyReportScreen empty month', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => addProfile(db, 'Home'));
    await _mount(tester, db, const MonthlyReportScreen(year: 2026, month: 3));
    expect(find.text('No data for this month.'), findsOneWidget);
    expect(find.text('March 2026'), findsOneWidget);
  });

  testWidgets('MonthlyReportScreen populated', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      final p = await addProfile(db, 'Home');
      final cat = await addCategory(db, p, 'Food');
      final sub = await addSub(db, p, cat, 'Groceries');
      final item = await addItem(db, p, sub, 'Rice');
      final acc = await addAccount(db, p, 'Cash');
      await addBudget(db, p, 2026, 3, 100000);
      await addExpense(
        db,
        p,
        account: acc,
        category: cat,
        sub: sub,
        item: item,
        amount: 25000,
        date: '2026-03-05',
        subName: 'Groceries',
        itemName: 'Rice',
      );
      await addIncome(db, p, account: acc, amount: 500000, date: '2026-03-01');
    });
    await _mount(tester, db, const MonthlyReportScreen(year: 2026, month: 3));
    expect(find.text('No data for this month.'), findsNothing);
    expect(find.text('৳250.00'), findsWidgets); // expense
    expect(find.text('৳5,000.00'), findsWidgets); // income
    expect(find.text('25.0%'), findsOneWidget); // utilization
    expect(find.text('Food'), findsWidgets);
    expect(find.byTooltip('Export PDF'), findsOneWidget);
    expect(find.byTooltip('Export CSV'), findsOneWidget);
  });

  testWidgets('YearlyReportScreen empty and CustomRange empty', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => addProfile(db, 'Home'));
    await _mount(tester, db, const YearlyReportScreen(year: 2026));
    expect(find.text('No data for this year.'), findsOneWidget);
  });

  testWidgets('CustomRangeReportScreen empty', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => addProfile(db, 'Home'));
    await _mount(
      tester,
      db,
      const CustomRangeReportScreen(from: '2026-03-01', to: '2026-03-31'),
    );
    expect(find.text('No transactions in this range.'), findsOneWidget);
  });
}
