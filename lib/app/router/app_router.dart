import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/categories/presentation/category_list_screen.dart';
import '../../features/cost_items/presentation/cost_item_list_screen.dart';
import '../shell/home_shell.dart';
import '../../features/profiles/data/profile_providers.dart';
import '../../features/profiles/presentation/profile_create_screen.dart';
import '../../features/profiles/presentation/profile_selection_screen.dart';
import '../shell/settings_screen.dart';
import '../../features/sub_categories/presentation/sub_category_list_screen.dart';
import '../../shared/providers/core_providers.dart';

/// Pure redirect decision, exposed for testing.
String? profileRedirect({
  required String location,
  required int? activeId,
  required bool profilesLoaded,
  required bool activeIsValid,
}) {
  final onProfileRoute = location == '/profiles' || location == '/profiles/new';
  if (onProfileRoute) return null;
  if (activeId == null) return '/profiles';
  // While profiles are loading we cannot judge validity yet.
  if (!profilesLoaded) return null;
  if (!activeIsValid) return '/profiles';
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(activeProfileIdProvider, (_, _) => refresh.value++);
  ref.listen(profilesStreamProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final activeId = ref.read(activeProfileIdProvider);
      final profiles = ref.read(profilesStreamProvider);
      final list = profiles.asData?.value;
      final valid =
          list != null &&
          activeId != null &&
          list.any((p) => p.id == activeId && p.isActive);
      return profileRedirect(
        location: state.matchedLocation,
        activeId: activeId,
        profilesLoaded: list != null,
        activeIsValid: valid,
      );
    },
    routes: [
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const ProfileSelectionScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const ProfileCreateScreen()),
        ],
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/config/categories',
        builder: (_, _) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/config/sub-categories',
        builder: (_, _) => const SubCategoryListScreen(),
      ),
      GoRoute(
        path: '/config/cost-items',
        builder: (_, _) => const CostItemListScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
