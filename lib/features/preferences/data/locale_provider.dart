import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../shared/providers/core_providers.dart';

const localeKey = 'app_locale';

/// Languages the app is translated into.
const supportedAppLocales = [Locale('en'), Locale('bn')];

/// Selected app language. `null` = follow the device language (falls back to
/// English when the device language is not supported).
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(localeKey);
    final locale = supportedAppLocales
        .where((l) => l.languageCode == code)
        .firstOrNull;
    _applyIntl(locale);
    return locale;
  }

  /// Persists the choice. Pass `null` to follow the system language.
  Future<void> set(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, locale.languageCode);
    }
    _applyIntl(locale);
    state = locale;
  }

  /// Keeps `DateFormat`/`NumberFormat` (which read `Intl.defaultLocale`) in
  /// step with the selected language.
  void _applyIntl(Locale? locale) {
    Intl.defaultLocale = locale?.languageCode;
    initializeDateFormatting(locale?.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
