import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesStreamProvider);
    final activeId = ref.watch(activeProfileIdProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilesSelectTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profiles/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.profilesNew),
      ),
      body: profiles.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(profilesStreamProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: l10n.profilesEmpty,
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
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: activate
          ? l10n.profilesReactivateTitle
          : l10n.profilesDeactivateTitle,
      message: activate
          ? l10n.profilesReactivateMessage(profile.name)
          : l10n.profilesDeactivateMessage(profile.name),
      confirmLabel: activate
          ? l10n.profilesReactivate
          : l10n.profilesDeactivate,
      cancelLabel: l10n.commonCancel,
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
    final l10n = context.l10n;
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
            : l10n.profilesInactiveSubtitle(profile.currencyCode),
      ),
      selected: isSelected,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) const Icon(Icons.check_circle),
          IconButton(
            tooltip: profile.isActive
                ? l10n.profilesDeactivate
                : l10n.profilesReactivate,
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
