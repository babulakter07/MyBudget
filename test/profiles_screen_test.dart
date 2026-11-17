import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/app/router/app_router.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/profiles/data/profile_repository.dart';
import 'package:my_budget/features/profiles/presentation/profile_selection_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('redirect rules', () {
    String? r(String loc, int? id, bool loaded, bool valid) => profileRedirect(
      location: loc,
      activeId: id,
      profilesLoaded: loaded,
      activeIsValid: valid,
    );
    expect(r('/home', null, true, false), '/profiles');
    expect(r('/home', 3, true, false), '/profiles');
    expect(r('/home', 3, true, true), isNull);
    expect(r('/profiles/new', null, true, false), isNull);
  });

  testWidgets('ProfileSelectionScreen shows empty state then profiles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ProfileSelectionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('No profiles yet'), findsOneWidget);
    expect(find.text('New profile'), findsOneWidget);

    await tester.runAsync(() => ProfileRepository(db).create('Personal'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Personal'), findsOneWidget);
  });
}
