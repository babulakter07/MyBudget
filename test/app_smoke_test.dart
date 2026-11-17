import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/app/app.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('wired app: every tab renders and Settings/About open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({activeProfileKey: 1});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => db.close());
    });
    final now = DateTime(2026, 11, 1);
    await tester.runAsync(() async {
      await db
          .into(db.financialProfiles)
          .insert(
            FinancialProfilesCompanion.insert(
              name: 'Personal',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyBudgetApp(),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Home = dashboard (no more "coming soon" placeholders).
    expect(find.textContaining('coming soon'), findsNothing);
    expect(find.text('Personal'), findsWidgets);

    for (final label in ['Budget', 'Add', 'Ledger', 'Reports', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'tab $label threw');
      expect(find.textContaining('coming soon'), findsNothing);
    }

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsOneWidget);
    await tester.ensureVisible(find.text('About'));
    await tester.pump();
    await tester.tap(find.text('About'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Md. Babul Akter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
