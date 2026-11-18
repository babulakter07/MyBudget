import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/onboarding/data/setup_progress.dart';
import 'package:my_budget/features/onboarding/presentation/setup_guide_card.dart';
import 'package:my_budget/features/onboarding/presentation/setup_guide_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_test_helpers.dart';

Future<SetupProgress?> _progress(ProviderContainer c) async {
  // Let Drift's stream deliver the latest value.
  final sub = c.listen(setupProgressProvider, (_, _) {});
  await Future<void>.delayed(const Duration(milliseconds: 50));
  final v = c.read(setupProgressProvider).value;
  sub.close();
  return v;
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late int profileId;
  late int otherProfileId;

  Future<ProviderContainer> make() async {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(c.dispose);
    await c.read(activeProfileIdProvider.notifier).select(profileId);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.memory();
    profileId = await addProfile(db, 'Mine');
    otherProfileId = await addProfile(db, 'Other');
  });
  tearDown(() => db.close());

  test('progress starts empty and ticks off each step', () async {
    final c = await make();
    var p = (await _progress(c))!;
    expect(p.doneCount, 0);
    expect(p.complete, isFalse);

    final acc = await addAccount(db, profileId, 'Cash');
    p = (await _progress(c))!;
    expect(p.hasAccount, isTrue);
    expect(p.doneCount, 1);

    await addCategory(db, profileId, 'Food');
    final now = DateTime.now();
    await addBudget(db, profileId, now.year, now.month, 500000);
    p = (await _progress(c))!;
    expect([p.hasCategory, p.hasBudget, p.hasTransaction], [true, true, false]);

    await addTxn(
      db,
      profileId: profileId,
      type: 'income',
      accountId: acc,
      amount: 1000,
      date: '2026-01-02',
    );
    p = (await _progress(c))!;
    expect(p.complete, isTrue);
  });

  test(
    'other profiles, deleted txns, inactive and old budgets ignored',
    () async {
      final c = await make();
      final otherAcc = await addAccount(db, otherProfileId, 'Theirs');
      await addCategory(db, otherProfileId, 'Theirs');
      await addAccount(db, profileId, 'Closed', active: false);
      final mine = await addAccount(db, profileId, 'Open');
      await addBudget(db, profileId, 2000, 1, 100);
      await addTxn(
        db,
        profileId: otherProfileId,
        type: 'income',
        accountId: otherAcc,
        amount: 5,
        date: '2026-01-02',
      );
      await addTxn(
        db,
        profileId: profileId,
        type: 'income',
        accountId: mine,
        amount: 5,
        date: '2026-01-02',
        deleted: true,
      );
      final p = (await _progress(c))!;
      expect(p.hasAccount, isTrue); // only the open one
      expect(p.hasCategory, isFalse);
      expect(p.hasBudget, isFalse);
      expect(p.hasTransaction, isFalse);
    },
  );

  test('dismissal persists', () async {
    final c = await make();
    expect(c.read(setupGuideDismissedProvider), isFalse);
    await c.read(setupGuideDismissedProvider.notifier).set(true);
    expect(prefs.getBool('setup_guide_dismissed'), isTrue);
    expect((await make()).read(setupGuideDismissedProvider), isTrue);
  });

  testWidgets('screen lists steps; card hides after dismiss', (tester) async {
    await tester.runAsync(() async {
      await addAccount(db, profileId, 'Cash');
    });
    final c = await make();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SetupGuideCard(),
                Expanded(child: SetupGuideScreen()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('setup-card')), findsOneWidget);
    expect(find.text('1 of 4 steps done'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('setup-go-account')), findsNothing);
    expect(find.byKey(const ValueKey('setup-go-category')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup-go-budget')), findsOneWidget);
    expect(find.byKey(const ValueKey('setup-go-transaction')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('setup-dismiss')));
    await tester.pump();
    expect(find.byKey(const ValueKey('setup-card')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
