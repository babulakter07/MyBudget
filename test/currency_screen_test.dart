import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/currency/data/exchange_rate_repository.dart';
import 'package:my_budget/features/currency/presentation/exchange_rates_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _Fixed extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

late AppDatabase db;
late ExchangeRateRepository repo;

const _taka = '৳';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_Fixed.new),
      ],
      child: const MaterialApp(home: ExchangeRatesScreen()),
    ),
  );
  await _settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() => db.close());
}

Future<void> _pickUsd(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(find.byKey(const Key('currencyDropdown')));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(find.text('USD - US Dollar').last);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() async {
    db = AppDatabase.memory();
    final now = DateTime.now();
    await db
        .into(db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: 'Main',
            createdAt: now,
            updatedAt: now,
          ),
        );
    repo = ExchangeRateRepository(db);
  });

  testWidgets('empty state', (tester) async {
    await _open(tester);
    expect(find.text('No exchange rates yet'), findsOneWidget);
    expect(find.text('Add exchange rate'), findsOneWidget);
    expect(find.textContaining('Base currency: BDT'), findsOneWidget);
    expect(find.textContaining('never fetched online'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('lists rates and marks inactive ones', (tester) async {
    await tester.runAsync(() async {
      final usd = await repo.upsert(
        profileId: 1,
        currencyCode: 'USD',
        rateMicro: 122500000,
      );
      await repo.upsert(
        profileId: 1,
        currencyCode: 'EUR',
        rateMicro: 130000000,
      );
      await repo.setActive(1, usd.id, false);
    });
    await _open(tester);
    expect(find.text('1 USD = ${_taka}122.5'), findsOneWidget);
    expect(find.text('1 EUR = ${_taka}130'), findsOneWidget);
    expect(find.textContaining('inactive'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('add flow creates a rate with live helper text', (tester) async {
    await _open(tester);
    await _pickUsd(tester);
    await tester.enterText(find.byKey(const Key('rateField')), '122.5');
    await tester.pump();
    expect(find.text('1 USD = ${_taka}122.5'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final rows = await tester.runAsync(
      () => repo.watchRates(1, includeInactive: true).first,
    );
    expect(rows!.single.currencyCode, 'USD');
    expect(rows.single.rateMicro, 122500000);
    expect(find.text('1 USD = ${_taka}122.5'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('other code option maps base-currency error to the form', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('currencyDropdown')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.scrollUntilVisible(
      find.text('Other code'),
      60,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Other code').last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byKey(const Key('otherCode')), 'bdt');
    await tester.enterText(find.byKey(const Key('rateField')), '1');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(
      find.textContaining('base currency of this profile'),
      findsOneWidget,
    );
    await _close(tester);
  });

  testWidgets('invalid rate shows an error and saves nothing', (tester) async {
    await _open(tester);
    await _pickUsd(tester);
    await tester.enterText(find.byKey(const Key('rateField')), '1.1234567');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('up to 6 decimals'), findsOneWidget);
    final rows = await tester.runAsync(
      () => repo.watchRates(1, includeInactive: true).first,
    );
    expect(rows, isEmpty);
    await _close(tester);
  });

  testWidgets('toggle active deactivates the rate', (tester) async {
    await tester.runAsync(
      () =>
          repo.upsert(profileId: 1, currencyCode: 'USD', rateMicro: 122500000),
    );
    await _open(tester);
    await tester.tap(find.byType(Switch));
    await _settle(tester);
    expect(await tester.runAsync(() => repo.getActiveRate(1, 'USD')), isNull);
    expect(find.textContaining('inactive'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('edit locks the currency and changes only the rate', (
    tester,
  ) async {
    await tester.runAsync(
      () =>
          repo.upsert(profileId: 1, currencyCode: 'USD', rateMicro: 122500000),
    );
    await _open(tester);
    await tester.tap(find.text('1 USD = ${_taka}122.5'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Edit exchange rate'), findsOneWidget);
    expect(find.byKey(const Key('currencyDropdown')), findsNothing);
    expect(find.text('USD (\$)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rateField')), '124');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final r = await tester.runAsync(() => repo.getActiveRate(1, 'USD'));
    expect(r!.rateMicro, 124000000);
    expect(find.text('1 USD = ${_taka}124'), findsOneWidget);
    await _close(tester);
  });
}
