import 'package:drift/drift.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/cost_items/presentation/cost_item_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

void main() {
  testWidgets('lists cost items with category path and amount', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => db.close());
    });
    final now = DateTime(2026);
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
              name: 'Home',
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
              name: 'Rent',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.costItems)
          .insert(
            CostItemsCompanion.insert(
              profileId: 1,
              subCategoryId: 1,
              name: 'Flat rent',
              defaultAmountMinor: const Value(1200050),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: const MaterialApp(home: CostItemListScreen()),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Flat rent'), findsOneWidget);
    expect(find.textContaining('12,000.50'), findsOneWidget);
    expect(find.textContaining('Home › Rent'), findsOneWidget);
  });
}
