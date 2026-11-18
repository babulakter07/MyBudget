import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'locale_provider.dart';

/// Strings for code that has no `BuildContext` (background notifications,
/// biometric prompt reasons). Uses the saved app language, else the platform
/// language, else English.
AppLocalizations resolveAppLocalizations(
  SharedPreferences prefs, {
  Locale? platformLocale,
}) {
  final code = prefs.getString(localeKey);
  final saved = supportedAppLocales
      .where((l) => l.languageCode == code)
      .firstOrNull;
  final platform = platformLocale ?? PlatformDispatcher.instance.locale;
  final chosen =
      saved ??
      supportedAppLocales
          .where((l) => l.languageCode == platform.languageCode)
          .firstOrNull ??
      const Locale('en');
  return lookupAppLocalizations(chosen);
}
