import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/sub_categories/data/sub_category_repository.dart';

void main() {
  late AppDatabase db;
  late SubCategoryRepository repo;
  late int p1, p2, c1, c2, c3Other;

  Future<int> profile(String n) => db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: n,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
  Future<int> category(int p, String n, {bool active = true}) => db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: p,
          name: n,
          isActive: Value(active),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

  setUp(() async {
    db = AppDatabase.memory();
    repo = SubCategoryRepository(db);
    p1 = await profile('One');
    p2 = await profile('Two');
    c1 = await category(p1, 'Food');
    c2 = await category(p1, 'Transport');
    c3Other = await category(p2, 'Other');
  });
  tearDown(() => db.close());

  test('create', () async {
    final s = await repo.create(profileId: p1, categoryId: c1, name: ' Rice ');
    expect(s.name, 'Rice');
    expect(s.isActive, true);
  });

  test('duplicate case-insensitive in same category', () async {
    await repo.create(profileId: p1, categoryId: c1, name: 'Rice');
    expect(
      () => repo.create(profileId: p1, categoryId: c1, name: 'rICE'),
      throwsA(isA<DuplicateNameException>()),
    );
  });

  test('same name in different category ok', () async {
    await repo.create(profileId: p1, categoryId: c1, name: 'Rice');
    final s = await repo.create(profileId: p1, categoryId: c2, name: 'Rice');
    expect(s.categoryId, c2);
  });

  test('empty name rejected', () {
    expect(
      () => repo.create(profileId: p1, categoryId: c1, name: '  '),
      throwsA(isA<ValidationException>()),
    );
  });

  test('cross-profile category rejected; missing is not found', () async {
    expect(
      () => repo.create(profileId: p1, categoryId: c3Other, name: 'X'),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(
      () => repo.create(profileId: p1, categoryId: 9999, name: 'X'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('inactive category rejected for new sub-category', () async {
    final ci = await category(p1, 'Old', active: false);
    expect(
      () => repo.create(profileId: p1, categoryId: ci, name: 'X'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('FK enforced at DB level for mismatched profile', () async {
    expect(
      () => db
          .into(db.subCategories)
          .insert(
            SubCategoriesCompanion.insert(
              profileId: p1,
              categoryId: c3Other,
              name: 'Bad',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
      throwsA(anything),
    );
  });

  test('edit: keep own name, rename, move, reject other profile', () async {
    final a = await repo.create(profileId: p1, categoryId: c1, name: 'Rice');
    await repo.create(profileId: p1, categoryId: c1, name: 'Dal');
    final same = await repo.update(profileId: p1, id: a.id, name: 'RICE');
    expect(same.name, 'RICE');
    expect(
      () => repo.update(profileId: p1, id: a.id, name: 'dal'),
      throwsA(isA<DuplicateNameException>()),
    );
    final moved = await repo.update(
      profileId: p1,
      id: a.id,
      name: 'Rice',
      categoryId: c2,
    );
    expect(moved.categoryId, c2);
    expect(
      () => repo.update(
        profileId: p1,
        id: a.id,
        name: 'Rice',
        categoryId: c3Other,
      ),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(
      () => repo.update(profileId: p2, id: a.id, name: 'Z'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('deactivate preserves row; hidden unless includeInactive', () async {
    final a = await repo.create(profileId: p1, categoryId: c1, name: 'Rice');
    await repo.setActive(profileId: p1, id: a.id, isActive: false);
    expect(await repo.watchAll(p1).first, isEmpty);
    final all = await repo.watchAll(p1, includeInactive: true).first;
    expect(all.single.isActive, false);
    expect(all.single.categoryName, 'Food');
    expect((await repo.getById(p1, a.id))!.name, 'Rice');
  });

  test('filter by category, search, and profile isolation', () async {
    await repo.create(profileId: p1, categoryId: c1, name: 'Rice');
    await repo.create(profileId: p1, categoryId: c2, name: 'Bus');
    await repo.create(profileId: p2, categoryId: c3Other, name: 'Rice');
    expect((await repo.watchAll(p1).first).length, 2);
    final f = await repo.watchAll(p1, categoryId: c2).first;
    expect(f.map((e) => e.name), ['Bus']);
    final s = await repo.watchAll(p1, search: 'ric').first;
    expect(s.map((e) => e.name), ['Rice']);
    expect((await repo.watchAll(p2).first).length, 1);
  });
}
