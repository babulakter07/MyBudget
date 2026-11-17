import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/errors/app_exception.dart';
import 'package:my_budget/features/profiles/data/profile_repository.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = ProfileRepository(db);
  });
  tearDown(() => db.close());

  test('create profile', () async {
    final p = await repo.create('  Family ');
    expect(p.name, 'Family');
    expect(p.currencyCode, 'BDT');
    expect(p.isActive, isTrue);
    expect((await repo.getById(p.id))?.name, 'Family');
  });

  test('empty name rejected', () {
    expect(() => repo.create('   '), throwsA(isA<ValidationException>()));
  });

  test('duplicate name rejected case-insensitively', () async {
    await repo.create('Family');
    expect(() => repo.create('fAMILY'), throwsA(isA<DuplicateNameException>()));
  });

  test('rename to existing name rejected, own name allowed', () async {
    final a = await repo.create('A');
    await repo.create('B');
    expect(
      () => repo.rename(a.id, 'b'),
      throwsA(isA<DuplicateNameException>()),
    );
    await repo.rename(a.id, 'a');
    expect((await repo.getById(a.id))!.name, 'a');
  });

  test('deactivate keeps row; active profile cannot be deactivated', () async {
    final a = await repo.create('A');
    final b = await repo.create('B');
    expect(
      () => repo.setActive(a.id, false, activeProfileId: a.id),
      throwsA(isA<ValidationException>()),
    );
    await repo.setActive(b.id, false, activeProfileId: a.id);
    final all = await repo.watchAll().first;
    expect(all.length, 2);
    expect(all.firstWhere((p) => p.id == b.id).isActive, isFalse);
    await repo.setActive(b.id, true);
    expect((await repo.getById(b.id))!.isActive, isTrue);
  });

  test('active profile persists via SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c1 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    expect(c1.read(activeProfileIdProvider), isNull);
    await c1.read(activeProfileIdProvider.notifier).select(7);
    expect(c1.read(activeProfileIdProvider), 7);
    c1.dispose();

    final c2 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    expect(c2.read(activeProfileIdProvider), 7);
    c2.dispose();
  });
}
