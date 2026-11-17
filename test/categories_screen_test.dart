import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/categories/domain/category.dart';
import 'package:my_budget/features/categories/presentation/category_list_screen.dart';
import 'package:my_budget/features/categories/providers/category_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Category _cat(int id, String name, {bool active = true}) => Category(
  id: id,
  profileId: 1,
  name: name,
  isActive: active,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _pump(WidgetTester tester, List<Category> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        categoriesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: const MaterialApp(home: CategoryListScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('list screen shows categories, fab and toggle', (tester) async {
    await _pump(tester, [_cat(1, 'Groceries'), _cat(2, 'Rent', active: false)]);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Show inactive'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
  });

  testWidgets('list screen shows empty state', (tester) async {
    await _pump(tester, []);
    expect(find.textContaining('No categories'), findsOneWidget);
  });
}
