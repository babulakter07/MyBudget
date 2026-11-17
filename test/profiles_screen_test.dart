import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/app/router/app_router.dart';
import 'package:my_budget/features/profiles/data/profile_providers.dart';
import 'package:my_budget/features/profiles/domain/profile.dart';
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

  Future<void> pumpScreen(
    WidgetTester tester,
    List<Profile> profiles, {
    int? activeId,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (activeId != null) activeProfileKey: activeId,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesStreamProvider.overrideWith((ref) => Stream.value(profiles)),
        ],
        child: const MaterialApp(home: ProfileSelectionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('ProfileSelectionScreen shows empty state', (tester) async {
    await pumpScreen(tester, []);
    expect(find.textContaining('No profiles yet'), findsOneWidget);
    expect(find.text('New profile'), findsOneWidget);
  });

  testWidgets('ProfileSelectionScreen lists profiles and inactive flag', (
    tester,
  ) async {
    final now = DateTime(2026);
    Profile mk(int id, String n, bool a) => Profile(
      id: id,
      name: n,
      currencyCode: 'BDT',
      isActive: a,
      createdAt: now,
      updatedAt: now,
    );
    await pumpScreen(tester, [mk(1, 'Personal', true), mk(2, 'Old', false)]);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('BDT - Inactive'), findsOneWidget);
    expect(find.byTooltip('Reactivate'), findsOneWidget);
  });
}
