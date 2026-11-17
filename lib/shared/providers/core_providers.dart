import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';

/// Overridden in main() (and in tests) with real instances.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

const activeProfileKey = 'active_profile_id';

/// Currently selected profile id (persisted). `null` = none selected yet.
/// Every profile-scoped provider must `ref.watch` this so that switching
/// profiles refreshes all dependent data.
class ActiveProfileIdNotifier extends Notifier<int?> {
  @override
  int? build() => ref.watch(sharedPreferencesProvider).getInt(activeProfileKey);

  Future<void> select(int? id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (id == null) {
      await prefs.remove(activeProfileKey);
    } else {
      await prefs.setInt(activeProfileKey, id);
    }
    state = id;
  }
}

final activeProfileIdProvider =
    NotifierProvider<ActiveProfileIdNotifier, int?>(ActiveProfileIdNotifier.new);
