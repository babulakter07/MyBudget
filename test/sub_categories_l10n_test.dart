import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/sub_categories/data/sub_category_providers.dart';
import 'package:my_budget/features/sub_categories/presentation/sub_category_list_screen.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        subCategoriesProvider.overrideWith((ref, f) => Stream.value(const [])),
        subCategoryCategoryOptionsProvider.overrideWith(
          (ref) => Stream.value(const [(id: 1, name: 'Home', isActive: true)]),
        ),
      ],
      child: app,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('sub-categories screen renders in Bangla', (tester) async {
    await _pump(tester, localizedApp(home: const SubCategoryListScreen()));
    expect(find.text('সাব-ক্যাটাগরি'), findsOneWidget);
    expect(find.text('সব'), findsOneWidget);
    expect(find.text('কোনো সাব-ক্যাটাগরি পাওয়া যায়নি।'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('সাব-ক্যাটাগরি যোগ করুন'), findsOneWidget);
    expect(find.text('নাম'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sub-categories English smoke', (tester) async {
    await _pump(tester, const MaterialApp(home: SubCategoryListScreen()));
    expect(find.text('Sub-categories'), findsOneWidget);
    expect(find.text('No sub-categories found.'), findsOneWidget);
  });
}
