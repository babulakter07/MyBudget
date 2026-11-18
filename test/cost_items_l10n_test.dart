import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/cost_items/presentation/cost_item_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, Widget app) async {
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
      child: app,
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final bn in [true, false]) {
    testWidgets('cost items screen ${bn ? "Bangla" : "English smoke"}', (
      tester,
    ) async {
      final db = AppDatabase.memory();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => db.close());
      });
      await _pump(
        tester,
        db,
        bn
            ? localizedApp(home: const CostItemListScreen())
            : const MaterialApp(home: CostItemListScreen()),
      );
      expect(find.text('Flat rent'), findsOneWidget);
      expect(find.text(bn ? 'খরচের আইটেম' : 'Cost Items'), findsOneWidget);
      expect(
        find.byTooltip(bn ? 'দ্রুত যোগে যোগ করুন' : 'Add to quick add'),
        findsOneWidget,
      );
      expect(
        find.text(bn ? 'নিষ্ক্রিয় দেখান' : 'Show inactive'),
        findsOneWidget,
      );
      if (bn) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('খরচের আইটেম যোগ করুন'), findsWidgets);
        expect(find.text('বিবরণ (ঐচ্ছিক)'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
