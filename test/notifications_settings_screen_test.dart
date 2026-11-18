import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/notifications/data/notification_gateway.dart';
import 'package:my_budget/features/notifications/data/notification_providers.dart';
import 'package:my_budget/features/notifications/domain/notification_settings.dart';
import 'package:my_budget/features/notifications/presentation/notification_settings_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db,
  SharedPreferences prefs,
  FakeNotificationGateway gateway,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(gateway),
      ],
      child: const MaterialApp(home: NotificationSettingsScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _teardown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() => db.close());
}

void main() {
  testWidgets('toggle on requests permission and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    final gateway = FakeNotificationGateway();
    await _pump(tester, db, prefs, gateway);

    expect(find.text('Notifications'), findsOneWidget);
    expect(gateway.permissionRequests, 0);

    await tester.tap(find.text('Bill & debt reminders'));
    await tester.pump();
    await tester.pump();
    expect(gateway.permissionRequests, 1);
    expect(NotificationSettings.load(prefs).remindersEnabled, isTrue);

    await tester.tap(find.text('Send test notification'));
    await tester.pump();
    await tester.pump();
    expect(gateway.shown.length, 1);

    await _teardown(tester, db);
  });

  testWidgets('denied permission keeps toggle off and explains', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    final gateway = FakeNotificationGateway(permissionGranted: false);
    await _pump(tester, db, prefs, gateway);

    await tester.tap(find.text('Budget alerts'));
    await tester.pump();
    await tester.pump();
    expect(NotificationSettings.load(prefs).budgetAlertsEnabled, isFalse);
    expect(find.textContaining('permission was denied'), findsOneWidget);

    await _teardown(tester, db);
  });
}
