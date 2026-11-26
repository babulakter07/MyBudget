import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/dps/data/dps_repository.dart';
import 'package:my_budget/features/dps/domain/dps.dart';
import 'package:my_budget/features/dps/presentation/dps_detail_screen.dart';
import 'package:my_budget/features/dps/presentation/dps_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  late AppDatabase db;

  Future<void> start(
    WidgetTester tester,
    Widget home, {
    Locale locale = const Locale('en'),
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: localizedApp(home: home, locale: locale),
      ),
    );
    await _settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  }

  Future<void> seedProfile(WidgetTester tester) async {
    db = AppDatabase.memory();
    await tester.runAsync(
      () => db
          .into(db.financialProfiles)
          .insert(
            FinancialProfilesCompanion.insert(
              name: 'Home',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
    );
  }

  Future<DpsPosition> seedDps(WidgetTester tester) async {
    final p = await tester.runAsync(
      () => DpsRepository(db).create(
        profileId: 1,
        terms: const DpsTerms(
          bankName: 'A bank with a rather long name for a phone',
          accountNumber: '1234567890123',
          installmentMinor: 1000000,
          tenureMonths: 120,
          openDate: '2024-01-31',
          firstDueDate: '2024-01-31',
          rateBp: 950,
          lateFeeMinor: 50000,
        ),
      ),
    );
    return p!;
  }

  testWidgets('adds a DPS from the list screen', (tester) async {
    await seedProfile(tester);
    await start(tester, const DpsListScreen());
    expect(find.textContaining('No DPS yet'), findsOneWidget);

    await _tap(tester, find.byType(FloatingActionButton));
    Future<void> type(String key, String text) async {
      final field = find.byKey(ValueKey('dps-$key'));
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      await tester.pump();
    }

    await type('bank', 'City Bank');
    await type('installment', '1000');
    await _tap(tester, find.text('5 years'));
    await type('rate', '10');
    expect(find.textContaining('78,082'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('dps-save')));

    expect(find.text('City Bank'), findsOneWidget);
    expect(find.textContaining('0 of 60 installments paid'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('records a deposit and closes early', (tester) async {
    await seedProfile(tester);
    final p = await seedDps(tester);
    await start(tester, DpsDetailScreen(dpsId: p.account.id));
    expect(find.textContaining('Your bank may close'), findsOneWidget);

    await _tap(tester, find.text('Record deposit'));
    // Prefilled with every overdue installment and its late fees.
    await tester.enterText(find.byKey(const ValueKey('dps-count')), '2');
    await tester.pump();
    expect(find.text('1000.00'), findsOneWidget); // two late fees of 500
    await _tap(tester, find.byKey(const ValueKey('dps-deposit-save')));
    expect(find.textContaining('2 of 120 installments paid'), findsOneWidget);

    await _tap(tester, find.text('Close or encash'));
    expect(find.textContaining('20,000.00'), findsWidgets);
    await _tap(tester, find.byKey(const ValueKey('dps-close-save')));
    await _tap(tester, find.text('Close DPS').last); // confirm
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Amount received'), findsOneWidget);
    expect(find.text('Record deposit'), findsNothing);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('fits a narrow phone in Bangla', (tester) async {
    await seedProfile(tester);
    final p = await seedDps(tester);
    const narrow = Size(320, 640);
    await start(
      tester,
      const DpsListScreen(),
      locale: const Locale('bn'),
      size: narrow,
    );
    expect(find.text('ডিপিএস (মাসিক সঞ্চয়)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.byType(FloatingActionButton));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());

    await start(
      tester,
      DpsDetailScreen(dpsId: p.account.id),
      locale: const Locale('bn'),
      size: narrow,
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
