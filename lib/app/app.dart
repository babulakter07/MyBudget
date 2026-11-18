import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;

import '../features/preferences/preferences.dart';
import '../l10n/l10n.dart';
import '../features/security/security.dart';
import 'app_constants.dart';
import 'startup/app_tasks.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MyBudgetApp extends ConsumerWidget {
  const MyBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // MaterialApp appends English-only Default* delegates; this real one
        // (first of its type wins) keeps `bn` fully supported.
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppLockGate(child: AppTasks(child: child!)),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
