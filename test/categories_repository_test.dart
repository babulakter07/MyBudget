import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/categories/data/category_repository.dart';

Future<int> _profile(AppDatabase db, String name) {
  final now = DateTime.now();
  return db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  late AppDatabase db;
  late CategoryRepository repo;
  late int p1, p2;

  setUp(() async {
    db = AppDatabase.memory();
    repo = CategoryRepository(db);
    p1 = await _profile(db, 'A');
    p2 = await _profile(db, 'B');
  });
  tearDown(() => db.close());

  test('create trims and persists', () async {
    final c = await repo.create(
      profileId: p1,
      name: '  Food ',
      icon: 'food',
      color: 0xFF112233,
    );
    expect(c.name, 'Food');
    expect(c.isActive, isTrue);
    expect(c.color, 0xFF112233);
    expect(c.icon, 'food');
  });

  test('empty name rejected', () async {
    expect(
      () => repo.create(profileId: p1, name: '   '),
      throwsA(isA<ValidationException>()),
    );
  });

  test('duplicate case-insensitive', () async {
    await repo.create(profileId: p1, name: 'Food');
    expect(
      () => repo.create(profileId: p1, name: 'fOOD'),
      throwsA(isA<DuplicateNameException>()),
    );
  });

  test('same name in different profiles', () async {
    await repo.create(profileId: p1, name: 'Food');
    final c = await repo.create(profileId: p2, name: 'Food');
    expect(c.profileId, p2);
  });

  test('edit/rename, keep own name, reject other duplicate', () async {
    final a = await repo.create(profileId: p1, name: 'Food');
    await repo.create(profileId: p1, name: 'Rent');
    final same = await repo.update(
      profileId: p1,
      id: a.id,
      name: 'FOOD',
      description: 'x',
    );
    expect(same.name, 'FOOD');
    expect(same.description, 'x');
    final r = await repo.update(profileId: p1, id: a.id, name: 'Meals');
    expect(r.name, 'Meals');
    expect(
      () => repo.update(profileId: p1, id: a.id, name: 'rent'),
      throwsA(isA<DuplicateNameException>()),
    );
  });

  test('deactivate preserved and hidden by default', () async {
    final a = await repo.create(profileId: p1, name: 'Food');
    await repo.setActive(p1, a.id, false);
    expect((await repo.getById(p1, a.id))!.isActive, isFalse);
    expect(await repo.watchAll(p1).first, isEmpty);
    expect(await repo.watchAll(p1, includeInactive: true).first, hasLength(1));
  });

  test('cross-profile get/update/setActive rejected', () async {
    final a = await repo.create(profileId: p1, name: 'Food');
    expect(await repo.getById(p2, a.id), isNull);
    expect(
      () => repo.update(profileId: p2, id: a.id, name: 'Hack'),
      throwsA(isA<NotFoundException>()),
    );
    expect(
      () => repo.setActive(p2, a.id, false),
      throwsA(isA<NotFoundException>()),
    );
    expect((await repo.getById(p1, a.id))!.name, 'Food');
    expect(await repo.watchAll(p2).first, isEmpty);
  });

  test('search filter', () async {
    await repo.create(profileId: p1, name: 'Groceries');
    await repo.create(profileId: p1, name: 'Rent');
    final r = await repo.watchAll(p1, search: 'groc').first;
    expect(r.map((c) => c.name), ['Groceries']);
    expect(await repo.watchAll(p1, search: '%').first, isEmpty);
  });
}
