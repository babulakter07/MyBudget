import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/notifications/data/budget_alert_service.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_providers.dart';
import 'package:my_budget/features/notifications/domain/notification_settings.dart';
import 'package:my_budget/features/notifications/presentation/notification_settings_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell_localized_app.dart';
import 'ledger_test_helpers.dart';

void main() {
  testWidgets('notification settings render in Bangla', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        child: localizedApp(home: const NotificationSettingsScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('নোটিফিকেশন'), findsOneWidget);
    expect(find.text('বিল ও ঋণের রিমাইন্ডার'), findsOneWidget);
    expect(find.text('টেস্ট নোটিফিকেশন পাঠান'), findsOneWidget);
    expect(find.text('Bill & debt reminders'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });

  test('budget alerts use the saved app language', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'bn'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final gateway = FakeNotificationGateway();
    final pid = await addProfile(db);
    final acc = await addAccount(db, pid, 'Cash');
    final cat = await addCategory(db, pid, 'Food');
    await addBudget(db, pid, 2026, 11, 100000);
    await const NotificationSettings(budgetAlertsEnabled: true).save(prefs);
    await addTxn(
      db,
      profileId: pid,
      type: 'expense',
      accountId: acc,
      amount: 120000,
      date: '2026-11-10',
      categoryId: cat,
      category: 'Food',
    );
    final svc = BudgetAlertService(db: db, prefs: prefs, gateway: gateway);
    await svc.evaluate(pid, now: DateTime(2026, 11, 18));
    expect(gateway.shown, isNotEmpty);
    expect(
      gateway.shown.map((n) => n.title),
      contains('বাজেট ছাড়িয়েছে: মাসিক বাজেট'),
    );
    expect(gateway.shown.every((n) => !n.title.contains('Over budget')), true);
  });
}
