import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/categories/domain/category.dart';
import 'package:my_budget/features/categories/presentation/category_list_screen.dart';
import 'package:my_budget/features/categories/providers/category_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _pump(
  WidgetTester tester,
  Widget app,
  List<Category> items,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        categoriesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: app,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('categories screen renders in Bangla', (tester) async {
    await _pump(tester, localizedApp(home: const CategoryListScreen()), []);
    expect(find.text('ক্যাটাগরি'), findsOneWidget);
    expect(find.text('নিষ্ক্রিয় দেখান'), findsOneWidget);
    expect(find.textContaining('এখনও কোনো ক্যাটাগরি নেই'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ক্যাটাগরি যোগ করুন'), findsOneWidget);
    expect(find.text('বিবরণ'), findsOneWidget);
    expect(find.text('আইকন'), findsOneWidget);
    expect(find.text('রঙ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categories English smoke', (tester) async {
    await _pump(tester, const MaterialApp(home: CategoryListScreen()), []);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.textContaining('No categories yet'), findsOneWidget);
  });
}
