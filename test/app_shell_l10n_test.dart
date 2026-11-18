import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/app/shell/about_screen.dart';
import 'package:my_budget/app/shell/settings_screen.dart';

import 'app_shell_localized_app.dart';

void main() {
  void tall(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
  }

  testWidgets('settings screen in Bangla', (tester) async {
    tall(tester);
    await tester.pumpWidget(localizedApp(home: const SettingsScreen()));
    for (final t in [
      'সেটিংস',
      'মূল কনফিগারেশন',
      'বিনিময় হার',
      'পুনরাবৃত্ত লেনদেন',
      'সঞ্চয়ের লক্ষ্য',
      'ঋণ ও ধার',
      'নিরাপত্তা',
      'ব্যাকআপ ও রিস্টোর',
      'ত্রুটির লগ শেয়ার করুন',
      'সম্পর্কে',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Security'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about screen in Bangla', (tester) async {
    tall(tester);
    await tester.pumpWidget(localizedApp(home: const AboutScreen()));
    expect(find.text('সম্পর্কে'), findsOneWidget);
    expect(find.text('যোগাযোগ'), findsOneWidget);
    expect(find.text('Md. Babul Akter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English smoke', (tester) async {
    tall(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Share error log'), findsOneWidget);
  });
}
