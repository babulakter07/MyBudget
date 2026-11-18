import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/features/accounts/domain/account.dart';
import 'package:my_budget/features/accounts/presentation/account_list_screen.dart';
import 'package:my_budget/features/accounts/providers/account_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

AccountBalance _acc(int id, String name, String type) => AccountBalance(
  account: Account(
    id: id,
    profileId: 1,
    name: name,
    type: type,
    openingBalanceMinor: 0,
    openingDate: '2026-01-01',
    isActive: true,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  balanceMinor: 150000,
);

Future<void> _pump(
  WidgetTester tester,
  Widget app,
  List<AccountBalance> items,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        accountBalancesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: app,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('accounts screen renders in Bangla', (tester) async {
    await _pump(tester, localizedApp(home: const AccountListScreen()), [
      _acc(1, 'Wallet', 'cash'),
      _acc(2, 'DBBL', 'credit_card'),
    ]);
    expect(find.text('হিসাব'), findsOneWidget);
    expect(find.text('নগদ'), findsOneWidget);
    expect(find.text('ক্রেডিট কার্ড'), findsOneWidget);
    expect(find.text('নিষ্ক্রিয় দেখান'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('হিসাব যোগ করুন'), findsOneWidget);
    expect(find.text('প্রারম্ভিক ব্যালেন্স'), findsOneWidget);
    expect(find.text('প্রারম্ভিক তারিখ'), findsOneWidget);
    expect(find.text('সংরক্ষণ করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accounts empty state in Bangla', (tester) async {
    await _pump(tester, localizedApp(home: const AccountListScreen()), []);
    expect(find.textContaining('এখনও কোনো হিসাব নেই'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accounts English smoke', (tester) async {
    await _pump(tester, const MaterialApp(home: AccountListScreen()), [
      _acc(1, 'Wallet', 'cash'),
    ]);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
  });
}
