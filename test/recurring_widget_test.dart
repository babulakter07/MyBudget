import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/recurring/data/recurring_repository.dart';
import 'package:my_budget/features/recurring/domain/recurring_models.dart';
import 'package:my_budget/features/recurring/presentation/recurring_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

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
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpApp(WidgetTester tester, AppDatabase db) async {
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
      child: const MaterialApp(home: RecurringListScreen()),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('empty state', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db);
    expect(find.textContaining('No recurring rules yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('lists active and paused rules; pause toggles', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      await _seed(db);
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
    });
    await _pumpApp(tester, db);
    expect(find.text('Flat rent'), findsOneWidget);
    expect(find.text('৳1,500.00'), findsOneWidget);
    expect(find.textContaining('Next: 2099-01-05'), findsOneWidget);
    expect(find.textContaining('Paused'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await _settle(tester);
    expect(find.textContaining('Paused'), findsNWidgets(2));
  });

  testWidgets('add form validates then creates a rule', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('New recurring rule'), findsOneWidget);

    await tester.tap(find.text('Create rule'));
    await tester.pump();
    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(find.text('Select an account'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Gym');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500');
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cash').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Home').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Create rule'));
    await tester.tap(find.text('Create rule'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('New recurring rule'), findsNothing);
    expect(find.text('Gym'), findsOneWidget);
    final rows = await tester.runAsync(
      () => db.select(db.recurringRules).get(),
    );
    expect(rows!.single.amountMinor, 50000);
    expect(rows.single.title, 'Gym');
  });
}
