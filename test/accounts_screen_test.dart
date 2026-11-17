import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/accounts/domain/account.dart';
import 'package:my_budget/features/accounts/presentation/account_list_screen.dart';
import 'package:my_budget/features/accounts/providers/account_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

AccountBalance _acc(
  int id,
  String name,
  int balance, {
  String type = 'bank',
  bool active = true,
}) => AccountBalance(
  account: Account(
    id: id,
    profileId: 1,
    name: name,
    type: type,
    openingBalanceMinor: 0,
    openingDate: '2026-01-01',
    isActive: active,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  balanceMinor: balance,
);

Future<void> _pump(WidgetTester tester, List<AccountBalance> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        accountBalancesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: const MaterialApp(home: AccountListScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows accounts with balances, fab and inactive switch', (
    tester,
  ) async {
    await _pump(tester, [
      _acc(1, 'Wallet', 150000, type: 'cash'),
      _acc(2, 'Bank', -2500, active: false),
    ]);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('৳1,500.00'), findsOneWidget);
    expect(find.text('-৳25.00'), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Show inactive'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await _pump(tester, []);
    expect(find.textContaining('No accounts'), findsOneWidget);
  });

  testWidgets('fab opens the form sheet', (tester) async {
    await _pump(tester, []);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add account'), findsOneWidget);
    expect(find.text('Opening balance'), findsOneWidget);
    expect(find.text('Opening date'), findsOneWidget);
  });
}
