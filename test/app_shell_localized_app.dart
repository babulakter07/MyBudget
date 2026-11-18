import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:my_budget/l10n/l10n.dart';

/// Delegates incl. `GlobalCupertinoLocalizations`: material_ui's MaterialApp
/// appends an English-only cupertino default, which makes Flutter report
/// "locale bn is not supported by all of its localization delegates".
const appTestDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('bn'),
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appTestDelegates,
  home: home,
);
