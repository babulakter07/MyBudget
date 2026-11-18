import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/insights/domain/insights_calculations.dart';
import 'package:my_budget/features/insights/domain/insights_models.dart';
import 'package:my_budget/features/insights/presentation/insights_screen.dart';
import 'package:my_budget/features/insights/providers/insights_providers.dart';
import 'package:my_budget/l10n/generated/app_localizations.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, {required bool bangla}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db, 'Family');
    final acc = await addAccount(db, 1, 'Cash');
    final food = await addCategory(db, 1, 'Food');
    await addBudget(db, 1, 2026, 3, 100000);
    await addTxn(
      db,
      profileId: 1,
      type: 'expense',
      accountId: acc,
      amount: 20000,
      date: '2026-03-05',
      categoryId: food,
      category: 'Food',
      title: 'Rice',
    );
  });
  const home = InsightsScreen();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        insightsClockProvider.overrideWithValue(() => DateTime(2026, 3, 20)),
      ],
      child: bangla ? localizedApp(home: home) : const MaterialApp(home: home),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('insights screen renders in Bangla', (tester) async {
    await _pump(tester, bangla: true);
    expect(find.text('ইনসাইটস'), findsOneWidget);
    expect(find.text('মাস শেষের পূর্বাভাস'), findsOneWidget);
    expect(find.text('গত মাসের তুলনায়'), findsOneWidget);
    expect(find.text('অস্বাভাবিক খরচ'), findsOneWidget);
    expect(find.text('সঞ্চয়ের হার'), findsOneWidget);
    expect(find.text('Month-end forecast'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('insights screen still renders in English by default', (
    tester,
  ) async {
    await _pump(tester, bangla: false);
    expect(find.text('Month-end forecast'), findsOneWidget);
    expect(find.text('Vs last month'), findsOneWidget);
    expect(find.text('March 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('message builders speak Bangla', () {
    final l = lookupAppLocalizations(const Locale('bn'));
    const up = CategoryDelta(
      categoryId: 1,
      name: 'Food',
      currentMinor: 786700,
      previousMinor: 666700,
    );
    expect(
      InsightMessages.categoryDelta(l, up),
      'গত মাসের তুলনায় Food ৳1,200.00 (18%) বেড়েছে',
    );
    expect(
      InsightMessages.savings(
        l,
        const SavingsRate(incomeMinor: 1000, expenseMinor: 750),
      ),
      'এই মাসে আপনি আয়ের 25% সঞ্চয় করেছেন',
    );
    expect(
      InsightMessages.weekday(l, const [
        WeekdayBucket(weekday: 3, totalMinor: 500),
      ]),
      contains('বুধবারে'),
    );
  });
}
