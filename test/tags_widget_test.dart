import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/tags/data/tag_repository.dart';
import 'package:my_budget/features/tags/presentation/tag_chips.dart';
import 'package:my_budget/features/tags/presentation/tag_list_screen.dart';
import 'package:my_budget/features/tags/presentation/tag_picker.dart';
import 'package:my_budget/features/tags/presentation/tag_report_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'ledger_test_helpers.dart';

class _Fixed extends ActiveProfileIdNotifier {
  _Fixed(this.id);
  final int id;
  @override
  int? build() => id;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
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
  testWidgets('TagPicker creates a tag inline and selects it', (tester) async {
    final db = AppDatabase.memory();
    final pid = await tester.runAsync(() => addProfile(db));
    var selected = <int>{};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(() => _Fixed(pid!)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagPicker(
                selectedIds: selected,
                onChanged: (s) => setState(() => selected = s),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('New tag'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Eid');
    await tester.tap(find.byTooltip('Add tag'));
    await _settle(tester);
    expect(selected, hasLength(1));
    expect(find.widgetWithText(FilterChip, 'Eid'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Eid'))
          .selected,
      isTrue,
    );
    await _teardown(tester, db);
  });

  testWidgets('TagListScreen lists tags and TagChips shows txn tags', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final repo = TagRepository(db);
    late int pid, txn;
    await tester.runAsync(() async {
      pid = await addProfile(db);
      final acc = await addAccount(db, pid, 'Cash');
      final cat = await addCategory(db, pid, 'Food');
      txn = await addTxn(
        db,
        profileId: pid,
        type: 'expense',
        accountId: acc,
        amount: 100,
        date: '2026-03-01',
        categoryId: cat,
        category: 'Food',
      );
      final a = await repo.create(profileId: pid, name: 'Groceries');
      await repo.create(profileId: pid, name: 'Old');
      await repo.setTagsForTransaction(pid, txn, [a.id]);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(() => _Fixed(pid)),
        ],
        child: MaterialApp(
          home: Column(
            children: [
              const Expanded(child: TagListScreen()),
              Material(
                child: SizedBox(
                  height: 60,
                  child: TagChips(transactionId: txn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Groceries'), findsNWidgets(2));
    expect(find.text('Old'), findsOneWidget);
    await _teardown(tester, db);
  });

  testWidgets('TagReportScreen shows totals', (tester) async {
    final db = AppDatabase.memory();
    final repo = TagRepository(db);
    late int pid;
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    await tester.runAsync(() async {
      pid = await addProfile(db);
      final acc = await addAccount(db, pid, 'Cash', openingDate: '2000-01-01');
      final cat = await addCategory(db, pid, 'Food');
      final txn = await addTxn(
        db,
        profileId: pid,
        type: 'expense',
        accountId: acc,
        amount: 150000,
        date: date,
        categoryId: cat,
        category: 'Food',
      );
      final a = await repo.create(profileId: pid, name: 'Trip');
      await repo.setTagsForTransaction(pid, txn, [a.id]);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith(() => _Fixed(pid)),
        ],
        child: const MaterialApp(home: TagReportScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('-৳1,500.00'), findsOneWidget);
    expect(find.text('1 transaction'), findsOneWidget);
    expect(find.byKey(const Key('none')), findsNothing);
    await _teardown(tester, db);
  });
}
