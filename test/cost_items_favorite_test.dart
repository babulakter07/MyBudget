import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/cost_items/data/cost_item_repository.dart';
import 'package:my_budget/features/cost_items/presentation/cost_item_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db) async {
  for (final n in ['A', 'B']) {
    await db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: n,
            createdAt: _now,
            updatedAt: _now,
          ),
        );
  }
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
  await db
      .into(db.subCategories)
      .insert(
        SubCategoriesCompanion.insert(
          profileId: 1,
          categoryId: 1,
          name: 'Rent',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.costItems)
      .insert(
        CostItemsCompanion.insert(
          profileId: 1,
          subCategoryId: 1,
          name: 'Flat rent',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
}

void main() {
  test(
    'setFavorite toggles, is exposed on the model, is profile-checked',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await _seed(db);
      final repo = CostItemRepository(db);
      expect((await repo.getById(1, 1))!.isFavorite, isFalse);
      await repo.setFavorite(1, 1, true);
      expect((await repo.getById(1, 1))!.isFavorite, isTrue);
      await repo.setFavorite(1, 1, false);
      expect((await repo.getById(1, 1))!.isFavorite, isFalse);
      expect(() => repo.setFavorite(2, 1, true), throwsA(isA<AppException>()));
      expect((await repo.getById(1, 1))!.isFavorite, isFalse);
      expect(
        () => repo.setFavorite(1, 99, true),
        throwsA(isA<NotFoundException>()),
      );
    },
  );

  testWidgets('star button toggles favourite', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => db.close());
    });
    await tester.runAsync(() => _seed(db));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: const MaterialApp(home: CostItemListScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    await settle();
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fav-1')));
    await settle();
    expect(find.byIcon(Icons.star), findsOneWidget);
    final row = (await tester.runAsync(
      () => (db.select(db.costItems)..where((c) => c.id.equals(1))).getSingle(),
    ))!;
    expect(row.isFavorite, isTrue);
  });
}
