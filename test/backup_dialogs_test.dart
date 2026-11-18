import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/storage/app_paths.dart';
import 'package:my_budget/features/backup/data/backup_crypto.dart';
import 'package:my_budget/features/backup/data/backup_providers.dart';
import 'package:my_budget/features/backup/data/backup_service.dart';
import 'package:my_budget/features/backup/domain/backup_models.dart';
import 'package:my_budget/features/backup/presentation/backup_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _until(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 60 && f.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BackupService service;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('mybudget_backup_dlg_');
    attachmentsDirectoryOverride = Directory('${dir.path}/att');
    service = BackupService(
      db,
      backupsDirectory: Directory('${dir.path}/backups'),
      crypto: const BackupCrypto(iterations: 1000),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupServiceProvider.overrideWith((ref) async => service)],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await _settle(tester);
  }

  Future<void> teardown(WidgetTester tester) async {
    attachmentsDirectoryOverride = null;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  testWidgets('export dialog validates the encryption password', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('NOT password protected'), findsOneWidget);
    await tester.tap(find.text('Create backup'));
    await _settle(tester);

    expect(find.text('Encrypt with a password'), findsOneWidget);
    expect(find.text('No receipt photos to include.'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.textContaining('at least 6 characters'), findsOneWidget);

    await tester.enterText(fields.at(0), 'secret1');
    await tester.enterText(fields.at(1), 'secret2');
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.textContaining('do not match'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(find.text('Encrypt with a password'), findsNothing);
    final files = await tester.runAsync(service.listBackups);
    expect(files, isEmpty);
    await teardown(tester);
  });

  testWidgets('export dialog creates an encrypted backup', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Create backup'));
    await _settle(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'secret1');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.tap(find.text('Create'));
    var files = <BackupFileInfo>[];
    for (var i = 0; i < 50 && files.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      files = (await tester.runAsync(service.listBackups))!;
    }
    expect(files.single.kind, BackupKind.manual);
    final text = (await tester.runAsync(
      () => service.readBackup(files.single),
    ))!;
    expect(BackupCrypto.isEncrypted(text), isTrue);
    await teardown(tester);
  });

  testWidgets('restoring an encrypted backup asks for the password', (
    tester,
  ) async {
    await tester.runAsync(
      () => service.createBackupFile(
        kind: BackupKind.manual,
        password: 'secret1',
      ),
    );
    await pump(tester);
    await _until(tester, find.byTooltip('Restore'));
    await tester.tap(find.byTooltip('Restore'));
    await _until(tester, find.text('Password required'));

    expect(find.text('Password required'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'wrong-pass');
    await tester.tap(find.text('Unlock'));
    await _until(tester, find.textContaining('Wrong password'));
    // Re-prompted with a clear error; nothing restored.
    expect(find.textContaining('Wrong password'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(find.text('Password required'), findsNothing);
    await teardown(tester);
  });
}
