import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/currency/data/exchange_rate_repository.dart';
import 'package:my_budget/features/currency/presentation/exchange_rates_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _Fixed extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<AppDatabase> _open(
  WidgetTester tester,
  Widget app, {
  bool withRate = false,
}) async {
  final db = AppDatabase.memory();
  final now = DateTime.now();
  await tester.runAsync(() async {
    await db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: 'Main',
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (withRate) {
      await ExchangeRateRepository(db)
          .upsert(profileId: 1, currencyCode: 'USD', rateMicro: 122500000);
    }
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_Fixed.new),
      ],
      child: app,
    ),
  );
  await _settle(tester);
  return db;
}

void main() {
  testWidgets('exchange rates render in Bangla', (tester) async {
    await _open(
      tester,
      localizedApp(home: const ExchangeRatesScreen()),
      withRate: true,
    );
    expect(find.text('বিনিময় হার'), findsOneWidget);
    expect(find.textContaining('মূল মুদ্রা: BDT'), findsOneWidget);
    expect(find.textContaining('অনলাইন থেকে আনা হয় না'), findsOneWidget);
    expect(find.text('১ USD = ৳122.5'), findsOneWidget);
    expect(find.textContaining('হালনাগাদ'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('বিনিময় হার যোগ করুন'), findsOneWidget);
    expect(find.text('মুদ্রা'), findsOneWidget);
    expect(find.text('হার (BDT এ)'), findsOneWidget);
    expect(find.text('সংরক্ষণ করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exchange rates English smoke', (tester) async {
    await _open(tester, const MaterialApp(home: ExchangeRatesScreen()));
    expect(find.text('Exchange rates'), findsOneWidget);
    expect(find.text('No exchange rates yet'), findsOneWidget);
    expect(find.textContaining('Base currency: BDT'), findsOneWidget);
  });
}
