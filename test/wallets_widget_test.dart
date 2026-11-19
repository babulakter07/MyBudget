import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/features/wallets/presentation/wallet_detail_screen.dart';
import 'package:my_budget/features/wallets/presentation/wallets_screen.dart';
import 'package:my_budget/features/wallets/providers/wallet_providers.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'l10n_test_helpers.dart';
import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

final _now = DateTime(2026, 3, 15);

Future<int> _acc(AppDatabase db, String name, String type, {int opening = 0}) =>
    db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: 1,
            name: name,
            type: Value(type),
            openingBalanceMinor: Value(opening),
            openingDate: '2026-01-01',
            createdAt: _now,
            updatedAt: _now,
          ),
        );

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<AppDatabase> _pump(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed, {
  String initial = '/',
  bool bangla = false,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  await tester.runAsync(() async {
    await addProfile(db);
    await seed(db);
  });
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WalletsScreen()),
      GoRoute(
        path: '/wallets/:id',
        builder: (_, s) =>
            WalletDetailScreen(accountId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/config/accounts',
        builder: (_, _) => const Scaffold(body: Text('accounts page')),
      ),
      GoRoute(
        path: '/help',
        builder: (_, _) => const Scaffold(body: Text('help page')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeProfileIdProvider.overrideWith(_FixedProfile.new),
        walletClockProvider.overrideWithValue(() => _now),
      ],
      child: bangla
          ? _BnRouter(router)
          : MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return db;
}

class _BnRouter extends StatelessWidget {
  const _BnRouter(this.router);
  final GoRouter router;
  @override
  Widget build(BuildContext context) {
    final base = localizedApp(home: const SizedBox()) as MaterialApp;
    return MaterialApp.router(
      routerConfig: router,
      locale: base.locale,
      supportedLocales: base.supportedLocales,
      localizationsDelegates: base.localizationsDelegates,
    );
  }
}

void main() {
  testWidgets('overview empty state links to accounts', (tester) async {
    await _pump(tester, (_) async {});
    expect(find.text('Add account'), findsOneWidget);
    await tester.tap(find.text('Add account'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('accounts page'), findsOneWidget);
  });

  testWidgets('overview shows total, groups and opens detail', (tester) async {
    await _pump(tester, (db) async {
      await _acc(db, 'Wallet', 'cash', opening: 10000);
      await _acc(db, 'DBBL', 'bank', opening: 250000);
      await _acc(db, 'Visa', 'credit_card', opening: -50000);
    });
    expect(find.byKey(const ValueKey('wallets-total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('wallets-total'))).data,
      '৳2,600.00',
    );
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Credit card'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('wallets-subtotal-credit_card')),
          )
          .data,
      '-৳500.00',
    );
    await tester.tap(find.text('DBBL'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await _settle(tester);
    expect(find.byKey(const ValueKey('wallet-balance')), findsOneWidget);
  });

  testWidgets('detail shows balance + ledger and Add money updates live', (
    tester,
  ) async {
    late int bank;
    await _pump(tester, (db) async {
      bank = await _acc(db, 'DBBL', 'bank', opening: 1000000);
    }, initial: '/wallets/1');
    expect(bank, 1);
    String balance() =>
        tester.widget<Text>(find.byKey(const ValueKey('wallet-balance'))).data!;
    expect(balance(), '৳10,000.00');
    expect(find.text('Opening balance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wallet-add-money')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('wallet-amount')), '2000');
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('wallet-preview'))).data,
      'Current ৳10,000.00 + ৳2,000.00 = ৳12,000.00 after',
    );

    // source is required
    await tester.tap(find.byKey(const ValueKey('wallet-save')));
    await tester.pump();
    expect(find.text('Enter the source of this money'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wallet-source-salary')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wallet-save')));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);

    expect(balance(), '৳12,000.00');
    expect(find.text('Salary'), findsWidgets);
    expect(find.text('+৳2,000.00'), findsOneWidget);
    expect(find.textContaining('Balance after: ৳12,000.00'), findsOneWidget);
    expect(find.text('Money added'), findsOneWidget);
  });

  testWidgets('transfer dialog previews both balances and saves', (
    tester,
  ) async {
    await _pump(tester, (db) async {
      await _acc(db, 'DBBL', 'bank', opening: 500000);
      await _acc(db, 'Wallet', 'cash', opening: 1000);
    }, initial: '/wallets/1');
    await tester.tap(find.byKey(const ValueKey('wallet-transfer')));
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('wallet-amount')), '1000');
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('wallet-preview-from')))
          .data,
      'DBBL: ৳5,000.00 → ৳4,000.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('wallet-preview-to'))).data,
      'Wallet: ৳10.00 → ৳1,010.00',
    );
    await tester.tap(find.byKey(const ValueKey('wallet-save')));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('wallet-balance'))).data,
      '৳4,000.00',
    );
    expect(find.text('Transfer to Wallet'), findsOneWidget);
  });

  testWidgets('invalid amount shows an error and keeps the dialog', (
    tester,
  ) async {
    await _pump(tester, (db) async {
      await _acc(db, 'DBBL', 'bank');
    }, initial: '/wallets/1');
    await tester.tap(find.byKey(const ValueKey('wallet-add-money')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('wallet-amount')), '0');
    await tester.tap(find.byKey(const ValueKey('wallet-source-gift')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wallet-save')));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('wallet-save')), findsOneWidget);
  });

  testWidgets('screens render in Bangla', (tester) async {
    await _pump(tester, (db) async {
      await _acc(db, 'Wallet', 'cash', opening: 10000);
    }, bangla: true);
    expect(find.text('ওয়ালেট ও ব্যালেন্স'), findsOneWidget);
    expect(find.text('মোট ব্যালেন্স'), findsOneWidget);
    expect(find.text('নগদ'), findsOneWidget);
    await tester.tap(find.text('Wallet'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await _settle(tester);
    expect(find.text('বর্তমান ব্যালেন্স'), findsOneWidget);
    expect(find.text('টাকা যোগ করুন'), findsOneWidget);
    expect(find.text('ট্রান্সফার / উত্তোলন'), findsOneWidget);
    expect(find.text('খতিয়ান'), findsOneWidget);
    expect(find.text('প্রারম্ভিক ব্যালেন্স'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wallet-add-money')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('উৎস'), findsOneWidget);
  });
}
