import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'features/backup/data/backup_scheduler.dart';
import 'features/backup/data/backup_service.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppDatabase db;
  final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    db = await openAppDatabase();
    // Force the database to open now so a failure is reported, not a blank screen.
    await db.customSelect('SELECT 1').get();
  } catch (e, st) {
    debugPrint('Startup failure: $e\n$st');
    runApp(_StartupError(error: e));
    return;
  }

  // Automatic backups are best-effort; never block app start on them.
  try {
    await BackupScheduler().initialize();
    final service = BackupService(
      db,
      backupsDirectory: await defaultBackupsDirectory(),
    );
    final settings = await service.loadSettings();
    await BackupScheduler().schedule(settings.frequency);
  } catch (e, st) {
    debugPrint('Backup scheduler setup failed: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MyBudgetApp(),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'MyBudget could not open its data.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app. If this keeps happening, free up '
                  'storage space or reinstall from a backup.\n\n$error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
