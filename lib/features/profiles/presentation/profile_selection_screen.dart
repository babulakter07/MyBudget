import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesStreamProvider);
    final activeId = ref.watch(activeProfileIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select profile')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profiles/new'),
        icon: const Icon(Icons.add),
        label: const Text('New profile'),
      ),
      body: profiles.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(profilesStreamProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'No profiles yet.\nCreate one to get started.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            itemBuilder: (context, i) => _ProfileTile(
              profile: list[i],
              isSelected: list[i].id == activeId,
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.profile, required this.isSelected});
  final Profile profile;
  final bool isSelected;

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final activate = !profile.isActive;
    final ok = await showConfirmDialog(
      context,
      title: activate ? 'Reactivate profile?' : 'Deactivate profile?',
      message: activate
          ? '"${profile.name}" will be available again.'
          : '"${profile.name}" will be hidden from selection. '
                'No data is deleted and you can reactivate it anytime.',
      confirmLabel: activate ? 'Reactivate' : 'Deactivate',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .setActive(
            profile.id,
            activate,
            activeProfileId: ref.read(activeProfileIdProvider),
          );
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: profile.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(profile.name.substring(0, 1).toUpperCase()),
      ),
      title: Text(profile.name),
      subtitle: Text(
        profile.isActive
            ? profile.currencyCode
            : '${profile.currencyCode} - Inactive',
      ),
      selected: isSelected,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) const Icon(Icons.check_circle),
          IconButton(
            tooltip: profile.isActive ? 'Deactivate' : 'Reactivate',
            icon: Icon(
              profile.isActive
                  ? Icons.archive_outlined
                  : Icons.unarchive_outlined,
            ),
            onPressed: () => _toggleActive(context, ref),
          ),
        ],
      ),
      onTap: profile.isActive
          ? () async {
              await ref
                  .read(activeProfileIdProvider.notifier)
                  .select(profile.id);
              if (context.mounted) context.go('/home');
            }
          : null,
    );
  }
}
