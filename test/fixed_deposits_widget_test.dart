import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/core/database/app_database.dart';
import 'package:my_budget/core/utils/date_keys.dart';
import 'package:my_budget/features/fixed_deposits/data/fixed_deposit_repository.dart';
import 'package:my_budget/features/fixed_deposits/presentation/fd_detail_screen.dart';
import 'package:my_budget/features/fixed_deposits/presentation/fd_list_screen.dart';
import 'package:my_budget/l10n/l10n.dart';
import 'package:my_budget/shared/providers/core_providers.dart';

import 'ledger_test_helpers.dart';

class _FixedProfile extends ActiveProfileIdNotifier {
  @override
  int? build() => 1;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Opens a sheet / route transition.
Future<void> _transition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
}

Future<FixedDepositRepository> _pump(
  WidgetTester tester,
  Future<void> Function(FixedDepositRepository repo) seed, {
  bool bangla = false,
}) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
  final repo = FixedDepositRepository(db);
  await tester.runAsync(() async {
    await addProfile(db);
    await seed(repo);
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const FdListScreen(),
        routes: [
          GoRoute(
            path: 'fd/:id',
            builder: (_, s) =>
                FdDetailScreen(depositId: int.parse(s.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/fd/:id',
        builder: (_, s) =>
            FdDetailScreen(depositId: int.parse(s.pathParameters['id']!)),
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
      ],
      child: bangla
          ? _BnRouter(router)
          : MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return repo;
}

class _BnRouter extends StatelessWidget {
  const _BnRouter(this.router);
  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    locale: const Locale('bn'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

/// 10,00,000.00 at 10 % for 365 days. Started long ago => matured.
Future<void> _matured(
  FixedDepositRepository repo, {
  String number = 'FDR-001',
  String bank = 'City Bank',
}) => repo.create(
  profileId: 1,
  bankName: bank,
  instrumentNumber: number,
  startDate: '2020-01-01',
  tenureDays: 365,
  rateBp: 1000,
  principalMinor: 100000000,
);

/// Started today => running for a year.
Future<void> _running(
  FixedDepositRepository repo, {
  String number = 'DPS-9',
  String bank = 'Brac Bank',
}) => repo.create(
  profileId: 1,
  schemeType: 'DPS',
  bankName: bank,
  instrumentNumber: number,
  startDate: dateKey(DateTime.now()),
  tenureDays: 365,
  rateBp: 800,
  principalMinor: 50000000,
);

void main() {
  testWidgets('list shows summary, tiles and status chips', (tester) async {
    await _pump(tester, (repo) async {
      await _matured(repo);
      await _running(repo);
    });
    expect(find.text('Fixed deposits'), findsOneWidget);
    expect(find.text('FDR • City Bank'), findsOneWidget);
    expect(find.text('DPS • Brac Bank'), findsOneWidget);
    expect(find.text('Matured'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining('Instrument FDR-001'), findsOneWidget);
    expect(find.textContaining('1 matured'), findsOneWidget);
    expect(find.textContaining('Next maturity 2020-12-31'), findsOneWidget);
    expect(find.text('৳1,000,000.00'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-fixed_deposits')), findsOneWidget);
    expect(find.textContaining('days left'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, (_) async {});
    expect(find.textContaining('No deposits yet'), findsOneWidget);
  });

  testWidgets('list renders in Bangla', (tester) async {
    await _pump(tester, (repo) async => _matured(repo), bangla: true);
    expect(find.text('ফিক্সড ডিপোজিট'), findsOneWidget);
    expect(find.text('মেয়াদ পূর্ণ'), findsOneWidget);
  });

  testWidgets('form validates, then creates a deposit', (tester) async {
    final repo = await _pump(tester, (_) async {});
    await tester.tap(find.byType(FloatingActionButton));
    await _transition(tester);
    expect(find.text('Add deposit'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(4), '180');
    await tester.pump();
    expect(find.textContaining('≈ 6 months'), findsOneWidget);
    expect(find.textContaining('Maturity date:'), findsOneWidget);

    await _tap(tester, find.text('Save'));
    await tester.pump();
    expect(find.text('Enter the bank name'), findsOneWidget);
    expect(find.text('Enter the instrument number'), findsOneWidget);

    final fields = find.byType(TextFormField);
    // scheme, bank, beneficiary, instrument no, tenure, rate, principal, note
    await tester.enterText(fields.at(1), 'Sonali Bank');
    await tester.enterText(fields.at(2), 'Karim');
    await tester.enterText(fields.at(3), 'FDR-777');
    await tester.enterText(fields.at(5), '9.5');
    await tester.enterText(fields.at(6), '250000');
    await tester.pump();
    await _tap(tester, find.text('Save'));
    await tester.pump();
    await _settle(tester);
    await _transition(tester);

    final saved = await tester.runAsync(() => repo.watchAll(1).first);
    expect(saved, hasLength(1));
    final d = saved!.single;
    expect(d.deposit.bankName, 'Sonali Bank');
    expect(d.deposit.schemeType, 'FDR');
    expect(d.deposit.beneficiaryName, 'Karim');
    expect(d.current.instrumentNumber, 'FDR-777');
    expect(d.current.tenureDays, 180);
    expect(d.current.rateBp, 950);
    expect(d.current.principalMinor, 25000000);
    expect(find.text('Add deposit'), findsNothing);
    expect(find.text('FDR • Sonali Bank'), findsOneWidget);
  });

  testWidgets('scheme chip fills the scheme type', (tester) async {
    final repo = await _pump(tester, (_) async {});
    await tester.tap(find.byType(FloatingActionButton));
    await _transition(tester);
    await _tap(tester, find.byKey(const ValueKey('scheme-DPS')));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'AB Bank');
    await tester.enterText(fields.at(3), 'D-1');
    await tester.enterText(fields.at(4), '365');
    await tester.enterText(fields.at(5), '8');
    await tester.enterText(fields.at(6), '1000');
    await _tap(tester, find.text('Save'));
    await tester.pump();
    await _settle(tester);
    final saved = await tester.runAsync(() => repo.watchAll(1).first);
    expect(saved!.single.deposit.schemeType, 'DPS');
  });

  testWidgets('reissue a matured deposit: both instruments in the history', (
    tester,
  ) async {
    final repo = await _pump(tester, (r) async => _matured(r));
    await tester.tap(find.text('FDR • City Bank'));
    await _transition(tester);
    await _settle(tester);
    expect(find.textContaining('has matured'), findsOneWidget);
    expect(find.byKey(const ValueKey('term-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fab-reissue')));
    await _transition(tester);
    expect(find.text('Reissue deposit'), findsOneWidget);
    // Interest prefilled with 365 days at 10 % of 10,00,000.00.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('close-interest')))
          .controller!
          .text,
      '100000.00',
    );
    await tester.enterText(find.byKey(const ValueKey('close-tax')), '10000');
    await tester.enterText(find.byKey(const ValueKey('close-charge')), '500');
    await tester.pump();
    expect(find.text('Calculated net: ৳1,089,500.00'), findsOneWidget);
    expect(
      find.text('New principal = net received: ৳1,089,500.00'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const ValueKey('new-number')), 'FDR-002');
    await tester.enterText(find.byKey(const ValueKey('new-tenure')), '180');
    await tester.enterText(find.byKey(const ValueKey('new-rate')), '9');
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('close-save')));
    await tester.pump();
    await _settle(tester);
    await _transition(tester);

    final d = (await tester.runAsync(() => repo.getById(1, 1)))!;
    expect(d.terms.length, 2);
    expect(d.current.instrumentNumber, 'FDR-002');
    expect(d.current.principalMinor, 108950000);
    expect(d.terms.first.outcome, 'reissued');

    expect(find.byKey(const ValueKey('term-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('term-2')), findsOneWidget);
    expect(find.text('Reissued from #1'), findsOneWidget);
    expect(find.text('Reissued'), findsWidgets); // badge + outcome chips
    expect(find.textContaining('FDR-001'), findsWidgets);
    expect(find.textContaining('FDR-002'), findsWidgets);
    expect(find.textContaining('has matured'), findsNothing);
  });

  testWidgets('reissue shows the repository error for a reused number', (
    tester,
  ) async {
    await _pump(tester, (r) async => _matured(r));
    await tester.tap(find.text('FDR • City Bank'));
    await _transition(tester);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('fab-reissue')));
    await _transition(tester);
    await tester.enterText(find.byKey(const ValueKey('new-number')), 'fdr-001');
    await _tap(tester, find.byKey(const ValueKey('close-save')));
    await tester.pump();
    await _settle(tester);
    expect(find.text('This instrument number already exists.'), findsOneWidget);
    expect(find.byKey(const ValueKey('term-2')), findsNothing);
  });

  testWidgets('encash a deposit closes it', (tester) async {
    final repo = await _pump(tester, (r) async => _matured(r));
    await tester.tap(find.text('FDR • City Bank'));
    await _transition(tester);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('btn-encash')));
    await _transition(tester);
    expect(find.text('Encash deposit'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-number')), findsNothing);
    // The bank paid a different amount: override the net.
    await tester.enterText(
      find.byKey(const ValueKey('close-final-net')),
      '1080000',
    );
    await _tap(tester, find.byKey(const ValueKey('close-save')));
    await tester.pump();
    await _settle(tester);
    await _transition(tester);

    final d = (await tester.runAsync(() => repo.getById(1, 1)))!;
    expect(d.current.outcome, 'encashed');
    expect(d.current.netReceivedMinor, 108000000);
    expect(find.text('This deposit is closed (encashed).'), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-encash')), findsNothing);
    expect(find.text('Encashed'), findsOneWidget);
    expect(find.text('৳1,080,000.00'), findsOneWidget);
  });

  testWidgets('running deposit offers reissue and encash buttons', (
    tester,
  ) async {
    await _pump(tester, (r) async => _running(r));
    await tester.tap(find.text('DPS • Brac Bank'));
    await _transition(tester);
    await _settle(tester);
    expect(find.byKey(const ValueKey('btn-reissue')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-encash')), findsOneWidget);
    expect(find.byKey(const ValueKey('fab-reissue')), findsNothing);
    expect(find.textContaining('has matured'), findsNothing);
  });

  testWidgets('archive hides the deposit from the list', (tester) async {
    await _pump(tester, (r) async => _running(r));
    await tester.tap(find.text('DPS • Brac Bank'));
    await _transition(tester);
    await _settle(tester);
    await tester.tap(find.byTooltip('Archive'));
    await _settle(tester);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-encash')), findsNothing);
  });
}
