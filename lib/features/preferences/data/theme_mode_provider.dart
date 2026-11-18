import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../../../shared/providers/core_providers.dart';

const themeModeKey = 'theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final v = ref.watch(sharedPreferencesProvider).getString(themeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(themeModeKey, mode.name);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
