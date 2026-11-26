import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_providers.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/presentation/backup_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BackupScreen shows empty state and automatic section', (
    tester,
  ) async {
    // Tall viewport so every lazily built section of the list exists.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    final dir = Directory.systemTemp.createTempSync('mybudget_backup_ui_');
    final service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWith((ref) async => service),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Create backup'), findsOneWidget);
    expect(find.text('Restore from file'), findsOneWidget);
    expect(find.textContaining('No backups yet'), findsOneWidget);
    expect(find.text('Automatic backup'), findsOneWidget);
    expect(
      find.textContaining('No automatic backup has run yet'),
      findsOneWidget,
    );

    expect(find.text('Backup folder'), findsOneWidget);
    expect(find.text('Choose folder'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
    dir.deleteSync(recursive: true);
  });
}
