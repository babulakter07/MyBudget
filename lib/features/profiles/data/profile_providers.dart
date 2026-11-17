import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../domain/profile.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

final profilesStreamProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchAll(),
);

/// The active profile entity (null when none selected / missing).
final activeProfileProvider = Provider<AsyncValue<Profile?>>((ref) {
  final id = ref.watch(activeProfileIdProvider);
  return ref
      .watch(profilesStreamProvider)
      .whenData(
        (list) => id == null
            ? null
            : list.cast<Profile?>().firstWhere(
                (p) => p!.id == id,
                orElse: () => null,
              ),
      );
});
