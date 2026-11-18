import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/recurring/data/recurring_repository.dart';
import 'package:my_budget/features/recurring/domain/recurring_models.dart';
import 'package:my_budget/features/recurring/presentation/recurring_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db) async {
  await db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: 'P',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          profileId: 1,
          name: 'Cash',
          openingDate: '2020-01-01',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: 1,
          name: 'Home',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  final repo = RecurringRepository(db);
  await repo.create(
    1,
    const RecurringInput(
      type: 'expense',
      accountId: 1,
      categoryId: 1,
      amountMinor: 150000,
      title: 'Flat rent',
      frequency: 'monthly',
      intervalCount: 2,
      startDate: '2099-01-05',
    ),
  );
  final p = await repo.create(
    1,
    const RecurringInput(
      type: 'expense',
      accountId: 1,
      categoryId: 1,
      amountMinor: 2000,
      title: 'Netflix',
      frequency: 'weekly',
      startDate: '2099-02-01',
    ),
  );
  await repo.setActive(1, p.id, false);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pump(WidgetTester tester, AppDatabase db, Widget app) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
      child: app,
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('recurring list renders in Bangla', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pump(tester, db, localizedApp(home: const RecurringListScreen()));
    expect(find.text('পুনরাবৃত্ত লেনদেন'), findsOneWidget);
    expect(find.textContaining('মাসিক (প্রতি 2)'), findsOneWidget);
    expect(find.textContaining('পরবর্তী: 2099-01-05'), findsOneWidget);
    expect(find.textContaining('বিরতিতে'), findsOneWidget);
    expect(find.byTooltip('বিরতি দিন'), findsOneWidget);
    expect(find.byTooltip('চালু করুন'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('নতুন পুনরাবৃত্ত নিয়ম'), findsOneWidget);
    expect(find.text('শিরোনাম'), findsOneWidget);
    expect(find.text('খরচ'), findsOneWidget);
    expect(find.text('নিয়ম তৈরি করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recurring list English smoke', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pump(tester, db, const MaterialApp(home: RecurringListScreen()));
    expect(find.text('Recurring transactions'), findsOneWidget);
    expect(find.textContaining('Monthly (every 2)'), findsOneWidget);
    expect(find.textContaining('Paused'), findsOneWidget);
  });
}
