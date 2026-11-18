import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/ledger/presentation/ledger_view.dart';
import 'package:my_budget/features/ledger/providers/ledger_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, {required bool bangla}) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db);
    await addAccount(db, 1, 'Cash', opening: 100000);
  });
  const home = Scaffold(body: LedgerView());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ledgerClockProvider.overrideWithValue(() => DateTime(2026, 3, 15)),
      ],
      child: bangla ? localizedApp(home: home) : const MaterialApp(home: home),
    ),
  );
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('ledger renders in Bangla', (tester) async {
    await _pump(tester, bangla: true);
    expect(find.text('হিসাব লেজার'), findsOneWidget);
    expect(find.text('বাজেট লেজার'), findsOneWidget);
    expect(find.text('প্রারম্ভিক ব্যালেন্স'), findsOneWidget);
    expect(find.text('মোট'), findsOneWidget);
    expect(find.text('ব্যালেন্স'), findsOneWidget);
    expect(find.text('Opening Balance'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('বাজেট লেজার'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(find.text('এই মাসে কোনো বাজেট নির্ধারিত নেই।'), findsOneWidget);
    expect(find.byTooltip('আগের মাস'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ledger still renders in English by default', (tester) async {
    await _pump(tester, bangla: false);
    expect(find.text('Account Ledger'), findsOneWidget);
    expect(find.text('Opening Balance'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
