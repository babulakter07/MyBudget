import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/import/data/csv_file_gateway.dart';
import 'package:my_budget/features/import/domain/csv_import_models.dart';
import 'package:my_budget/features/import/presentation/csv_import_screen.dart';
import 'package:my_budget/features/import/providers/import_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

const _ts = 1700000000;

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

class _FakeGateway implements CsvFileGateway {
  _FakeGateway(this.text);
  final String text;
  @override
  Future<PickedCsv?> pick() async => PickedCsv(name: 'bank.csv', text: text);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  const csvText =
      'Date,Description,Amount,Category\n'
      '01/05/2024,Rice,-500,Food\n'
      '02/05/2024,Salary,"50,000",\n'
      '99/99/2024,Broken,-5,Food\n';

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await db.customStatement(
      "INSERT INTO financial_profiles (id,name,currency_code,is_active,created_at,updated_at) VALUES (1,'P','BDT',1,$_ts,$_ts)",
    );
    await db.customStatement(
      "INSERT INTO accounts (id,profile_id,name,type,opening_balance_minor,opening_date,is_active,created_at,updated_at) VALUES (1,1,'Cash','cash',0,'2024-01-01',1,$_ts,$_ts)",
    );
    await db.customStatement(
      "INSERT INTO categories (id,profile_id,name,is_active,created_at,updated_at) VALUES (1,1,'Food',1,$_ts,$_ts)",
    );
  });

  Future<void> pump(WidgetTester tester, String text) async {
    // Tall viewport so the lazily-built list renders the preview rows.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
          csvFileGatewayProvider.overrideWithValue(_FakeGateway(text)),
        ],
        child: const MaterialApp(home: CsvImportScreen()),
      ),
    );
    await _settle(tester);
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  }

  testWidgets('pick -> auto-mapped columns -> preview -> import -> result', (
    tester,
  ) async {
    await pump(tester, csvText);
    expect(find.text('Import CSV'), findsOneWidget);
    expect(find.text('Choose CSV file'), findsOneWidget);
    expect(find.textContaining('2. Map the columns'), findsNothing);

    await tester.tap(find.text('Choose CSV file'));
    await _settle(tester);

    expect(find.textContaining('2. Map the columns'), findsOneWidget);
    // Auto-guessed from header names.
    expect(find.text('Date *'), findsOneWidget);
    expect(find.text('Amount *'), findsOneWidget);

    expect(
      find.text(
        '2 to import · 0 already imported · 1 invalid (showing first 3 rows)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Invalid date "99/99/2024"'), findsOneWidget);
    expect(find.textContaining('Row 1: Expense'), findsOneWidget);
    expect(find.textContaining('Row 2: Income'), findsOneWidget);

    final importBtn = find.text('Import 2 rows');
    await tester.ensureVisible(importBtn);
    await tester.tap(importBtn);
    await _settle(tester);

    expect(find.byKey(const Key('import-result')), findsOneWidget);
    expect(find.text('Imported: 2'), findsOneWidget);
    expect(find.text('Invalid rows: 1'), findsOneWidget);

    final c = await tester.runAsync(
      () => db
          .customSelect('SELECT COUNT(*) c FROM financial_transactions')
          .getSingle(),
    );
    expect(c!.data['c'], 2);

    // Same file again: everything valid is now a duplicate.
    expect(find.textContaining('2 already imported'), findsOneWidget);
    expect(find.textContaining('Import 0 rows'), findsOneWidget);
    await teardown(tester);
  });

  testWidgets('unreadable file shows an error and no mapping', (tester) async {
    await pump(tester, '   \n');
    await tester.tap(find.text('Choose CSV file'));
    await _settle(tester);
    expect(find.byKey(const Key('import-error')), findsOneWidget);
    expect(find.textContaining('2. Map the columns'), findsNothing);
    await teardown(tester);
  });

  testWidgets('expense without a category is flagged until a default is set', (
    tester,
  ) async {
    await pump(tester, 'Date,Description,Amount\n01/05/2024,Rice,-500\n');
    await tester.tap(find.text('Choose CSV file'));
    await _settle(tester);
    expect(find.textContaining('No category: pick a default'), findsOneWidget);
    expect(find.text('Import 0 rows'), findsOneWidget);
    await teardown(tester);
  });
}
