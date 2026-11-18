import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:my_budget/l10n/l10n.dart';
import 'package:my_budget/features/help/domain/manual_content.dart';
import 'package:my_budget/features/help/domain/manual_content_bn.dart';
import 'package:my_budget/features/help/presentation/user_manual_screen.dart';

void main() {
  test('manual topics have unique ids and content', () {
    final ids = manualTopics.map((t) => t.id).toSet();
    expect(ids.length, manualTopics.length);
    for (final t in manualTopics) {
      expect(t.steps, isNotEmpty, reason: t.id);
      expect(t.summary, isNotEmpty);
    }
  });

  test('every topic has a Bangla translation with matching structure', () {
    for (final t in manualTopics) {
      final b = manualTopicsBn[t.id];
      expect(b, isNotNull, reason: t.id);
      expect(b!.steps.length, t.steps.length, reason: t.id);
      expect(b.tips.length, t.tips.length, reason: t.id);
    }
    expect(manualTopicsBn.length, manualTopics.length);
  });

  testWidgets('manual shows Bangla for bn locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('bn'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: UserManualScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ব্যবহার নির্দেশিকা'), findsOneWidget);
    expect(find.text('শুরু করুন'), findsOneWidget);
    expect(find.text('Getting started'), findsNothing);
  });

  testWidgets('initialTopicId opens that topic expanded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserManualScreen(initialTopicId: 'security')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Settings > Security'), findsWidgets);
    expect(find.textContaining('Create a profile'), findsNothing);
  });

  testWidgets('manual lists topics, expands and searches', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserManualScreen()));
    expect(find.text('User manual'), findsOneWidget);
    expect(find.text('Getting started'), findsOneWidget);

    await tester.tap(find.text('Getting started'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Create a profile'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('manual-search')), 'PIN');
    await tester.pumpAndSettle();
    expect(find.text('App lock (PIN and biometrics)'), findsOneWidget);
    expect(find.text('Getting started'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('manual-search')),
      'zzzzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching topics'), findsOneWidget);
  });
}
