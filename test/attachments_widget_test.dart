import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/storage/app_paths.dart';
import 'package:my_budget/features/attachments/domain/attachment.dart';
import 'package:my_budget/features/attachments/presentation/attachment_viewer_screen.dart';
import 'package:my_budget/features/attachments/presentation/attachments_section.dart';
import 'package:my_budget/features/attachments/providers/attachment_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:path/path.dart' as p;

import 'ledger_test_helpers.dart';

class _Fixed extends ActiveProfileIdNotifier {
  _Fixed(this.id);
  final int id;
  @override
  int? build() => id;
}

class _FakePicker implements ImagePickerGateway {
  _FakePicker(this.file);
  final File file;
  int gallery = 0;
  int camera = 0;
  @override
  Future<File?> pickFromCamera() async {
    camera++;
    return file;
  }

  @override
  Future<File?> pickFromGallery() async {
    gallery++;
    return file;
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory tmp;
  late File picked;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('att_widget');
    attachmentsDirectoryOverride = Directory(p.join(tmp.path, 'att'));
    picked = File(p.join(tmp.path, 'pick.jpg'))
      ..writeAsBytesSync(List.filled(20, 1));
  });
  tearDown(() {
    attachmentsDirectoryOverride = null;
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> teardown(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  }

  testWidgets('persisted mode: add via gallery, then delete with confirm', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final picker = _FakePicker(picked);
    late int pid, txn;
    await tester.runAsync(() async {
      pid = await addProfile(db);
      final acc = await addAccount(db, pid, 'Cash');
      final cat = await addCategory(db, pid, 'C');
      txn = await addTxn(
        db,
        profileId: pid,
        type: 'expense',
        accountId: acc,
        amount: 100,
        date: '2026-03-01',
        categoryId: cat,
        category: 'C',
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(() => _Fixed(pid)),
          imagePickerGatewayProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          home: Scaffold(body: AttachmentsSection(transactionId: txn)),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Attachments (0/5)'), findsOneWidget);
    await tester.tap(find.text('Add photo'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Gallery'));
    await _settle(tester);
    expect(picker.gallery, 1);
    expect(find.text('Attachments (1/5)'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete attachment'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Delete'));
    await _settle(tester);
    expect(find.text('Attachments (0/5)'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('pending mode collects files without a transaction', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final picker = _FakePicker(picked);
    final pending = PendingAttachments();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          imagePickerGatewayProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          home: Scaffold(body: AttachmentsSection(pending: pending)),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Add photo'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Camera'));
    await _settle(tester);
    expect(picker.camera, 1);
    expect(pending.length, 1);
    expect(find.text('Attachments (1/5)'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('viewer shows an InteractiveViewer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AttachmentViewerScreen(file: picked)),
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
