import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/l10n/l10n.dart';

/// A `MaterialApp` with the app's localization delegates, defaulting to
/// Bangla. Wrap in a `ProviderScope` yourself when the screen needs providers:
///
///     await tester.pumpWidget(ProviderScope(
///       overrides: [...],
///       child: localizedApp(home: const MyScreen()),
///     ));
Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('bn'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}
