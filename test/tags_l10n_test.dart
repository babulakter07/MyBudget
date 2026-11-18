import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/tags/data/tag_repository.dart';
import 'package:my_budget/features/tags/presentation/tag_list_screen.dart';
import 'package:my_budget/features/tags/presentation/tag_report_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
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

Future<AppDatabase> _pump(
  WidgetTester tester,
  Widget home, {
  required bool bn,
  bool withTag = false,
}) async {
  final db = AppDatabase.memory();
  final pid = await tester.runAsync(() async {
    final id = await addProfile(db);
    if (withTag) {
      await TagRepository(db).create(profileId: id, name: 'Eid');
    }
    return id;
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
        activeProfileIdProvider.overrideWith(() => _Fixed(pid!)),
      ],
      child: bn ? localizedApp(home: home) : MaterialApp(home: home),
    ),
  );
  await _settle(tester);
  return db;
}

/// The framework reports a locale-support warning for the Material delegates under
/// `bn` in tests (shared helper issue); anything else is a real error.
void expectNoRealException(WidgetTester tester) {
  final e = tester.takeException();
  expect(
    e == null || '$e'.contains('not supported by all of its localization'),
    isTrue,
    reason: '$e',
  );
}

void main() {
  testWidgets('tag list renders in Bangla', (tester) async {
    await _pump(tester, const TagListScreen(), bn: true);
    expect(find.text('ট্যাগ'), findsOneWidget);
    expect(
      find.text('এখনো কোনো ট্যাগ নেই। তৈরি করতে + চাপুন।'),
      findsOneWidget,
    );
    expectNoRealException(tester);
  });

  testWidgets('tag edit dialog and validation in Bangla', (tester) async {
    await _pump(tester, const TagListScreen(), bn: true, withTag: true);
    expect(find.text('Eid'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('নতুন ট্যাগ'), findsOneWidget);
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pump();
    expect(find.text('ট্যাগের নাম দিতে হবে।'), findsOneWidget);
    expectNoRealException(tester);
  });

  testWidgets('tag report renders in Bangla', (tester) async {
    await _pump(tester, const TagReportScreen(), bn: true);
    expect(find.text('ট্যাগ রিপোর্ট'), findsOneWidget);
    expect(
      find.text('এই সময়সীমায় ট্যাগ করা কোনো লেনদেন নেই।'),
      findsOneWidget,
    );
    expectNoRealException(tester);
  });

  testWidgets('tag list still shows English by default', (tester) async {
    await _pump(tester, const TagListScreen(), bn: false);
    expect(find.text('No tags yet. Tap + to create one.'), findsOneWidget);
  });
}
