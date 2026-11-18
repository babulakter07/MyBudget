import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../help/presentation/help_button.dart';
import '../data/locale_provider.dart';
import '../data/theme_mode_provider.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.preferencesTitle),
        actions: const [HelpButton(topicId: 'prefs')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.preferencesTheme,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('theme-selector'),
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.preferencesThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.preferencesThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.preferencesThemeSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.preferencesLanguage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // `null` = follow the device language. Language names are shown in
          // their own language and are intentionally not translated.
          SegmentedButton<String>(
            key: const ValueKey('language-selector'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: '',
                label: Text(l10n.preferencesLanguageSystem),
              ),
              const ButtonSegment(value: 'en', label: Text('English')),
              const ButtonSegment(value: 'bn', label: Text('বাংলা')),
            ],
            selected: {locale?.languageCode ?? ''},
            onSelectionChanged: (s) => ref
                .read(localeProvider.notifier)
                .set(s.first.isEmpty ? null : Locale(s.first)),
          ),
        ],
      ),
    );
  }
}
