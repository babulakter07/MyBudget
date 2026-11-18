import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/profiles/data/profile_providers.dart';
import 'package:my_budget/features/profiles/domain/profile.dart';
import 'package:my_budget/features/profiles/presentation/profile_selection_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell_localized_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<Profile> profiles,
    Widget app,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesStreamProvider.overrideWith((ref) => Stream.value(profiles)),
        ],
        child: app,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('empty state in Bangla', (tester) async {
    await pump(tester, [], localizedApp(home: const ProfileSelectionScreen()));
    expect(find.text('প্রোফাইল নির্বাচন'), findsOneWidget);
    expect(find.text('নতুন প্রোফাইল'), findsOneWidget);
    expect(find.textContaining('কোনো প্রোফাইল নেই'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English smoke', (tester) async {
    await pump(tester, [], const MaterialApp(home: ProfileSelectionScreen()));
    expect(find.text('Select profile'), findsOneWidget);
    expect(find.text('New profile'), findsOneWidget);
  });
}
