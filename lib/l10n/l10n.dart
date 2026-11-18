import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.someKey` — the app's translated strings.
///
/// Falls back to English when no localization delegate is installed (plain
/// widget tests that build their own `MaterialApp`), so screens never crash
/// for lack of a delegate.
extension AppL10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}
