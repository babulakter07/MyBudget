import 'package:material_ui/material_ui.dart';

class AppTypography {
  AppTypography._();

  /// Light tweaks on top of the Material 3 default text theme.
  static TextTheme adjust(TextTheme base) => base.copyWith(
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}
