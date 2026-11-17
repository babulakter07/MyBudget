import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/backup/data/backup_providers.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/presentation/backup_screen.dart';

void main() {
  testWidgets('BackupScreen shows empty state and automatic section', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final dir = Directory.systemTemp.createTempSync('mybudget_backup_ui_');
    final service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupServiceProvider.overrideWith((ref) async => service)],
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

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
    dir.deleteSync(recursive: true);
  });
}
