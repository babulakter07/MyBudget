import 'package:drift/drift.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/sub_categories/presentation/sub_category_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('lists sub-categories and shows duplicate message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({activeProfileKey: 1});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => db.close());
    });
    final now = DateTime.now();
    await tester.runAsync(() async {
      await db
          .into(db.financialProfiles)
          .insert(
            FinancialProfilesCompanion.insert(
              name: 'P',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              profileId: 1,
              name: 'Food',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.subCategories)
          .insert(
            SubCategoriesCompanion.insert(
              profileId: 1,
              categoryId: 1,
              name: 'Rice',
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: SubCategoryListScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('Rice'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Food').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextFormField), 'rice');
    await tester.tap(find.text('Save'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('already exists'), findsOneWidget);
  });
}
