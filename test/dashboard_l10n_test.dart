import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/dashboard/presentation/dashboard_view.dart';
import 'package:my_budget/features/dashboard/providers/dashboard_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, {required bool bangla}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() => addProfile(db, 'Family'));
  const home = Scaffold(body: DashboardView());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        dashboardClockProvider.overrideWithValue(() => DateTime(2026, 3, 10)),
      ],
      child: bangla ? localizedApp(home: home) : const MaterialApp(home: home),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('dashboard renders in Bangla', (tester) async {
    await _pump(tester, bangla: true);
    expect(find.text('মাসিক বাজেট'), findsOneWidget);
    expect(find.text('মাসের খরচ'), findsOneWidget);
    expect(find.text('চলতি মাস'), findsOneWidget);
    expect(find.text('বার্ষিক সারসংক্ষেপ'), findsOneWidget);
    expect(find.text('বছর 2026'), findsOneWidget);
    expect(find.text('Monthly budget'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard still renders in English by default', (tester) async {
    await _pump(tester, bangla: false);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('Yearly overview'), findsOneWidget);
    expect(find.text('Year 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
