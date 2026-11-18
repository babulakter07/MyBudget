import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/storage/app_paths.dart';
import 'package:my_budget/features/attachments/domain/attachment.dart';
import 'package:my_budget/features/attachments/providers/attachment_providers.dart';
import 'package:my_budget/features/tags/data/tag_repository.dart';
import 'package:my_budget/features/tags/providers/tag_providers.dart';
import 'package:my_budget/features/transactions/data/transaction_repository.dart';
import 'package:my_budget/features/transactions/presentation/add_transaction_view.dart';
import 'package:my_budget/features/transactions/presentation/edit_transaction_screen.dart';
import 'package:my_budget/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';
import 'package:path/path.dart' as p;

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

class _FakePicker implements ImagePickerGateway {
  _FakePicker(this.file);
  final File file;
  @override
  Future<File?> pickFromCamera() async => file;
  @override
  Future<File?> pickFromGallery() async => file;
}

class _FailingTags extends TagRepository {
  _FailingTags(super.db);
  @override
  Future<void> setTagsForTransaction(
    int profileId,
    int transactionId,
    Iterable<int> tagIds,
  ) async => throw StateError('boom');
}

final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db, {bool favourite = false}) async {
  await db
      .into(db.financialProfiles)
      .insert(
        FinancialProfilesCompanion.insert(
          name: 'P',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          profileId: 1,
          name: 'Cash',
          openingDate: '2020-01-01',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          profileId: 1,
          name: 'Food',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.subCategories)
      .insert(
        SubCategoriesCompanion.insert(
          profileId: 1,
          categoryId: 1,
          name: 'Groceries',
          createdAt: _now,
          updatedAt: _now,
        ),
      );
  await db
      .into(db.costItems)
      .insert(
        CostItemsCompanion.insert(
          profileId: 1,
          subCategoryId: 1,
          name: 'Rice',
          defaultAmountMinor: const Value(45000),
          isFavorite: Value(favourite),
          createdAt: _now,
          updatedAt: _now,
        ),
      );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  AppDatabase db,
  Widget child, {
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        ...extra,
      ],
      child: MaterialApp(home: child),
    ),
  );
  await _settle(tester);
}

String _amountText(WidgetTester tester) => tester
    .widget<TextFormField>(find.byKey(const ValueKey('amount-field')))
    .controller!
    .text;

void main() {
  late Directory tmp;
  late File picked;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('txn_quickadd');
    attachmentsDirectoryOverride = Directory(p.join(tmp.path, 'att'));
    picked = File(p.join(tmp.path, 'r.jpg'))
      ..writeAsBytesSync(List.filled(20, 1));
  });
  tearDown(() {
    attachmentsDirectoryOverride = null;
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('repeat last is hidden with no transactions', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    expect(find.byKey(const ValueKey('repeat-last')), findsNothing);
  });

  testWidgets('repeat last prefills and saves a new row (not a duplicate)', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      await _seed(db);
      await TransactionRepository(db).createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        subCategoryId: 1,
        costItemId: 1,
        amountMinor: 12050,
        date: '2026-02-01',
        title: 'Weekly rice',
        idempotencyKey: 'seed-1',
      );
      // A deleted, more recent one must be ignored.
      final gone = await TransactionRepository(db).createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 999,
        date: '2026-03-01',
        idempotencyKey: 'seed-2',
      );
      await TransactionRepository(db).softDelete(1, gone.id);
    });
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    await tester.tap(find.byKey(const ValueKey('repeat-last')));
    await _settle(tester);
    expect(_amountText(tester), '120.50');
    expect(find.text('Weekly rice'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-button')));
    await _settle(tester);
    final rows = (await tester.runAsync(
      () => (db.select(
        db.financialTransactions,
      )..where((t) => t.isDeleted.equals(false))).get(),
    ))!;
    expect(rows.length, 2);
    final keys = rows.map((r) => r.idempotencyKey).toSet();
    expect(keys.length, 2);
    final newest = rows.reduce((a, b) => a.id > b.id ? a : b);
    expect(newest.amountMinor, 12050);
    expect(newest.title, 'Weekly rice');
    expect(newest.costItemNameSnapshot, 'Rice');
  });

  testWidgets('favourite chips prefill expense with default amount', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db, favourite: true));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    final chip = find.byKey(const ValueKey('fav-chip-1'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await _settle(tester);
    expect(_amountText(tester), '450.00');
    expect(find.text('Groceries'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await _settle(tester);
    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows.single.costItemNameSnapshot, 'Rice');
    expect(rows.single.amountMinor, 45000);
  });

  testWidgets('non-favourite or inactive items do not show chips', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      await _seed(db, favourite: true);
      await (db.update(db.costItems))
          .write(const CostItemsCompanion(isActive: Value(false)));
    });
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    expect(find.byKey(const ValueKey('fav-chip-1')), findsNothing);
  });

  testWidgets('keypad evaluates into the amount field', (tester) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    await tester.tap(find.byKey(const ValueKey('calc-button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    for (final k in ['1', '0', '+', '2', '×', '3']) {
      await tester.tap(find.byKey(ValueKey('key-$k')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('keypad-done')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_amountText(tester), '16.00');
  });

  testWidgets('keypad shows divide by zero error and keeps sheet open', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() => _seed(db));
    await _pumpApp(tester, db, const Scaffold(body: AddTransactionView()));
    await tester.tap(find.byKey(const ValueKey('calc-button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    for (final k in ['5', '÷', '0']) {
      await tester.tap(find.byKey(ValueKey('key-$k')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('key-equals')));
    await tester.pump();
    expect(find.text('Cannot divide by zero.'), findsOneWidget);
    expect(_amountText(tester), isEmpty);
  });

  testWidgets('add: tags and receipts are saved with the new transaction', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      await _seed(db);
      await TagRepository(db).create(profileId: 1, name: 'Eid');
    });
    await _pumpApp(
      tester,
      db,
      const Scaffold(body: AddTransactionView()),
      extra: [
        imagePickerGatewayProvider.overrideWithValue(_FakePicker(picked)),
      ],
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Food').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('amount-field')), '75');
    await tester.tap(find.text('Eid'));
    await tester.pump();
    await tester.ensureVisible(find.text('Add photo'));
    await tester.tap(find.text('Add photo'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Gallery'));
    await _settle(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('save-button')));
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await _settle(tester);
    await _settle(tester);

    final txn = (await tester.runAsync(
      () => db.select(db.financialTransactions).getSingle(),
    ))!;
    final tagLinks = (await tester.runAsync(
      () => db.select(db.transactionTags).get(),
    ))!;
    final atts = (await tester.runAsync(
      () => db.select(db.transactionAttachments).get(),
    ))!;
    expect(tagLinks.single.transactionId, txn.id);
    expect(atts.single.transactionId, txn.id);
    expect(find.text('Transaction saved'), findsOneWidget);
  });

  testWidgets('add: tag failure keeps the saved transaction and warns', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await tester.runAsync(() async {
      await _seed(db);
      await TagRepository(db).create(profileId: 1, name: 'Eid');
    });
    await _pumpApp(
      tester,
      db,
      const Scaffold(body: AddTransactionView()),
      extra: [tagRepositoryProvider.overrideWith((ref) => _FailingTags(db))],
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Food').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('amount-field')), '75');
    await tester.tap(find.text('Eid'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('save-button')));
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await _settle(tester);
    await _settle(tester);

    final rows = (await tester.runAsync(
      () => db.select(db.financialTransactions).get(),
    ))!;
    expect(rows.length, 1);
    expect(find.textContaining('tags could not be saved'), findsOneWidget);
    expect(_amountText(tester), isEmpty); // form reset: not saved twice
  });

  testWidgets('edit preloads tags, saves the new set; detail shows chips', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    late int id;
    await tester.runAsync(() async {
      await _seed(db);
      final tags = TagRepository(db);
      final a = await tags.create(profileId: 1, name: 'Eid');
      await tags.create(profileId: 1, name: 'Gift');
      final t = await TransactionRepository(db).createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 5000,
        date: '2026-02-01',
        idempotencyKey: 'k',
      );
      id = t.id;
      await tags.setTagsForTransaction(1, id, [a.id]);
    });
    await _pumpApp(tester, db, EditTransactionScreen(transactionId: id));
    await _settle(tester);
    // Add Gift, keep Eid.
    await tester.ensureVisible(find.text('Gift'));
    await tester.tap(find.text('Gift'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('save-button')));
    await tester.tap(find.byKey(const ValueKey('save-button')));
    await _settle(tester);
    final links = (await tester.runAsync(
      () => db.select(db.transactionTags).get(),
    ))!;
    expect(links.length, 2);
  });

  testWidgets('detail screen shows tag chips and attachments section', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    late int id;
    await tester.runAsync(() async {
      await _seed(db);
      final tags = TagRepository(db);
      final a = await tags.create(profileId: 1, name: 'Eid');
      final t = await TransactionRepository(db).createExpense(
        profileId: 1,
        accountId: 1,
        categoryId: 1,
        amountMinor: 5000,
        date: '2026-02-01',
        idempotencyKey: 'k',
      );
      id = t.id;
      await tags.setTagsForTransaction(1, id, [a.id]);
    });
    await _pumpApp(tester, db, TransactionDetailScreen(transactionId: id));
    await _settle(tester);
    expect(find.text('Eid'), findsOneWidget);
    expect(find.text('Receipts'), findsOneWidget);
    expect(find.textContaining('Attachments ('), findsOneWidget);
  });
}
