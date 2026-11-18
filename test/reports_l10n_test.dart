import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_providers.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/presentation/backup_screen.dart';
import 'package:my_budget/features/import/data/csv_file_gateway.dart';
import 'package:my_budget/features/import/domain/csv_import_models.dart';
import 'package:my_budget/features/import/presentation/csv_import_screen.dart';
import 'package:my_budget/features/import/providers/import_providers.dart';
import 'package:my_budget/features/reports/presentation/monthly_report_screen.dart';
import 'package:my_budget/features/reports/presentation/reports_view.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'reports_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

class _FakeGateway implements CsvFileGateway {
  @override
  Future<PickedCsv?> pick() async =>
      PickedCsv(name: 'bank.csv', text: 'Date,Amount\n01/05/2024,-500\n');
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _teardown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() => db.close());
}

void main() {
  testWidgets('reports hub and monthly screen render in Bangla', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.memory();
    await tester.runAsync(() => addProfile(db, 'Home'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: localizedApp(home: const Scaffold(body: ReportsView())),
      ),
    );
    expect(find.text('মাসিক রিপোর্ট'), findsOneWidget);
    expect(find.text('বার্ষিক রিপোর্ট'), findsOneWidget);
    expect(find.text('Monthly report'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: localizedApp(
          home: const MonthlyReportScreen(year: 2026, month: 3),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('মার্চ 2026'), findsOneWidget);
    expect(find.text('এই মাসের কোনো তথ্য নেই।'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _teardown(tester, db);
  });

  testWidgets('reports English smoke', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => addProfile(db, 'Home'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ],
        child: const MaterialApp(
          home: MonthlyReportScreen(year: 2026, month: 3),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('No data for this month.'), findsOneWidget);
    await _teardown(tester, db);
  });

  testWidgets('backup screen renders in Bangla', (tester) async {
    final db = AppDatabase.memory();
    final dir = Directory.systemTemp.createTempSync('mybudget_backup_l10n_');
    final service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupServiceProvider.overrideWith((ref) async => service)],
        child: localizedApp(home: const BackupScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('ব্যাকআপ ও রিস্টোর'), findsOneWidget);
    expect(find.text('ব্যাকআপ তৈরি করুন'), findsOneWidget);
    expect(find.text('স্বয়ংক্রিয় ব্যাকআপ'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ব্যাকআপ তৈরি করুন'));
    await _settle(tester);
    expect(find.text('পাসওয়ার্ড দিয়ে এনক্রিপ্ট করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _teardown(tester, db);
    dir.deleteSync(recursive: true);
  });

  testWidgets('csv import screen renders in Bangla', (tester) async {
    final db = AppDatabase.memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(_FixedProfile.new),
          csvFileGatewayProvider.overrideWithValue(_FakeGateway()),
        ],
        child: localizedApp(home: const CsvImportScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('সিএসভি ইম্পোর্ট'), findsOneWidget);
    expect(find.text('১. ফাইল বেছে নিন'), findsOneWidget);
    expect(find.text('সিএসভি ফাইল বেছে নিন'), findsOneWidget);
    expect(find.text('Import CSV'), findsNothing);
    expect(tester.takeException(), isNull);
    await _teardown(tester, db);
  });
}
