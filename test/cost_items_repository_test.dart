import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/cost_items/data/cost_item_repository.dart';

void main() {
  late AppDatabase db;
  late CostItemRepository repo;
  late int p1, p2, cat1, cat2, sub1, sub1b, sub2, subInactive;
  final now = DateTime(2026, 1, 1);

  Future<int> profile(String n) => db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: n,
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> category(int p, String n) => db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: p,
          name: n,
          createdAt: now,
          updatedAt: now,
        ),
      );
  Future<int> sub(int p, int c, String n, {bool active = true}) => db
      .into(db.subCategories)
      .insert(
        SubCategoriesCompanion.insert(
          profileId: p,
          categoryId: c,
          name: n,
          isActive: Value(active),
          createdAt: now,
          updatedAt: now,
        ),
      );

  setUp(() async {
    db = AppDatabase.memory();
    repo = CostItemRepository(db);
    p1 = await profile('One');
    p2 = await profile('Two');
    cat1 = await category(p1, 'Home');
    cat2 = await category(p1, 'Food');
    sub1 = await sub(p1, cat1, 'Rent');
    sub1b = await sub(p1, cat2, 'Groceries');
    subInactive = await sub(p1, cat1, 'Old', active: false);
    final c2 = await category(p2, 'Other');
    sub2 = await sub(p2, c2, 'Misc');
  });
  tearDown(() => db.close());

  Future<List<String>> names(
    int p, {
    int? c,
    int? s,
    String q = '',
    bool inactive = false,
  }) async {
    final l = await repo
        .watchAll(
          p,
          categoryId: c,
          subCategoryId: s,
          search: q,
          includeInactive: inactive,
        )
        .first;
    return l.map((e) => e.item.name).toList();
  }

  test('create and list with joined names', () async {
    await repo.create(
      profileId: p1,
      subCategoryId: sub1,
      name: '  Flat rent ',
      defaultAmountMinor: 1200000,
    );
    final l = await repo.watchAll(p1).first;
    expect(l.single.item.name, 'Flat rent');
    expect(l.single.subCategoryName, 'Rent');
    expect(l.single.categoryName, 'Home');
    expect(l.single.item.defaultAmountMinor, 1200000);
    expect(await names(p2), isEmpty);
  });

  test('validation: empty name, negative amount, inactive sub', () async {
    expect(
      () => repo.create(profileId: p1, subCategoryId: sub1, name: ' '),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => repo.create(
        profileId: p1,
        subCategoryId: sub1,
        name: 'X',
        defaultAmountMinor: -1,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => repo.create(profileId: p1, subCategoryId: subInactive, name: 'X'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => repo.create(profileId: p1, subCategoryId: 9999, name: 'X'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('case-insensitive duplicates per sub-category', () async {
    await repo.create(profileId: p1, subCategoryId: sub1, name: 'Water');
    expect(
      () => repo.create(profileId: p1, subCategoryId: sub1, name: 'WATER'),
      throwsA(isA<DuplicateNameException>()),
    );
    await repo.create(profileId: p1, subCategoryId: sub1b, name: 'water');
  });

  test('raw insert duplicate maps at DB level', () async {
    await repo.create(profileId: p1, subCategoryId: sub1, name: 'Water');
    expect(
      () => db
          .into(db.costItems)
          .insert(
            CostItemsCompanion.insert(
              profileId: p1,
              subCategoryId: sub1,
              name: 'WATER',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('cross-profile sub-category rejected', () async {
    expect(
      () => repo.create(profileId: p1, subCategoryId: sub2, name: 'X'),
      throwsA(isA<ProfileMismatchException>()),
    );
    final id = await repo.create(profileId: p1, subCategoryId: sub1, name: 'A');
    expect(
      () => repo.update(profileId: p1, id: id, subCategoryId: sub2, name: 'A'),
      throwsA(isA<ProfileMismatchException>()),
    );
    expect(
      () => repo.update(profileId: p2, id: id, subCategoryId: sub2, name: 'A'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('raw insert violating composite FK fails', () async {
    expect(
      () => db
          .into(db.costItems)
          .insert(
            CostItemsCompanion.insert(
              profileId: p1,
              subCategoryId: sub2,
              name: 'Raw',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('edit keeps own name, rejects other duplicate, can move', () async {
    final a = await repo.create(profileId: p1, subCategoryId: sub1, name: 'A');
    await repo.create(profileId: p1, subCategoryId: sub1, name: 'B');
    await repo.update(
      profileId: p1,
      id: a,
      subCategoryId: sub1,
      name: 'a',
      description: 'desc',
      defaultAmountMinor: 500,
    );
    expect((await repo.getById(p1, a))!.description, 'desc');
    expect(
      () => repo.update(profileId: p1, id: a, subCategoryId: sub1, name: 'b'),
      throwsA(isA<DuplicateNameException>()),
    );
    await repo.update(profileId: p1, id: a, subCategoryId: sub1b, name: 'a');
    expect((await repo.getById(p1, a))!.subCategoryId, sub1b);
    expect(
      () => repo.update(
        profileId: p1,
        id: a,
        subCategoryId: sub1,
        name: 'a',
        defaultAmountMinor: -5,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('deactivate preserves the row', () async {
    final a = await repo.create(profileId: p1, subCategoryId: sub1, name: 'A');
    await repo.setActive(p1, a, false);
    expect(await names(p1), isEmpty);
    expect(await names(p1, inactive: true), ['A']);
    await repo.setActive(p1, a, true);
    expect(await names(p1), ['A']);
    expect(
      () => repo.setActive(p2, a, false),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('search and filters', () async {
    await repo.create(
      profileId: p1,
      subCategoryId: sub1,
      name: 'Flat rent',
      description: 'Monthly',
    );
    await repo.create(profileId: p1, subCategoryId: sub1b, name: 'Rice');
    await repo.create(profileId: p1, subCategoryId: sub1b, name: '50%_off');
    expect(await names(p1, q: 'RENT'), ['Flat rent']);
    expect(await names(p1, q: 'month'), ['Flat rent']);
    expect(await names(p1, q: '%'), ['50%_off']);
    expect(await names(p1, q: 'zzz'), isEmpty);
    expect(await names(p1, c: cat1), ['Flat rent']);
    expect(await names(p1, c: cat2), ['50%_off', 'Rice']);
    expect(await names(p1, s: sub1b), ['50%_off', 'Rice']);
    expect(await names(p1, s: sub1), ['Flat rent']);
  });
}
