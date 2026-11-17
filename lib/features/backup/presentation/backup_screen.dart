import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/backup_providers.dart';
import '../data/backup_service.dart';
import '../domain/backup_models.dart';

String _fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);

String _tableLabel(String t) => t.replaceAll('_', ' ');

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _guard(Future<void> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
    } on AppException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(backupListProvider);
      ref.invalidate(backupSettingsProvider);
    }
  }

  Future<void> _create({required bool share}) => _guard(() async {
    final service = await ref.read(backupServiceProvider.future);
    final info = await service.createBackupFile(kind: BackupKind.manual);
    _toast('Backup saved: ${info.name}');
    if (share) await _share(info);
  });

  Future<void> _share(BackupFileInfo info) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(info.path, mimeType: 'application/json')],
        subject: 'MyBudget backup',
      ),
    );
  }

  Future<void> _restoreFromInfo(BackupFileInfo info) => _guard(() async {
    final service = await ref.read(backupServiceProvider.future);
    await _restoreJson(service, await service.readBackup(info));
  });

  Future<void> _pickAndRestore() => _guard(() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;
    final String text;
    try {
      text = utf8.decode(await file.readAsBytes());
    } on FormatException {
      throw ValidationException('That file is not a readable JSON backup.');
    }
    final service = await ref.read(backupServiceProvider.future);
    await _restoreJson(service, text);
  });

  /// validate -> summary/errors -> explicit confirmation -> restore.
  Future<void> _restoreJson(BackupService service, String json) async {
    final v = service.validate(json);
    if (!mounted) return;
    if (!v.isValid) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup cannot be restored'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('Nothing was changed. Problems found:'),
                const SizedBox(height: 8),
                for (final e in v.errors) Text('• $e'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (v.createdAt != null)
                Text('Backup created: ${_fmtDate(v.createdAt!.toLocal())}'),
              const SizedBox(height: 8),
              const Text('Contains:'),
              for (final e in v.counts.entries)
                if (e.key != 'application_settings')
                  Text('• ${e.value} ${_tableLabel(e.key)}'),
              const SizedBox(height: 12),
              Text(
                'Restoring will REPLACE all current data in the app with '
                'this backup. A safety backup of your current data is '
                'created first, so you can go back.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final profileNotifier = ref.read(activeProfileIdProvider.notifier);
    final result = await service.restore(
      json,
      activeProfileId: ref.read(activeProfileIdProvider),
      clearActiveProfile: () => profileNotifier.select(null),
    );
    // Re-apply the restored schedule preference.
    final settings = await service.loadSettings();
    await ref.read(backupSchedulerProvider).schedule(settings.frequency);
    _toast(
      result.activeProfileCleared
          ? 'Restore complete. Your previous profile is not in this backup; '
                'please choose a profile.'
          : 'Restore complete. A safety backup of the previous data was saved.',
    );
  }

  Future<void> _delete(BackupFileInfo info) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete backup?',
      message: 'Delete ${info.name}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await _guard(() async {
      final service = await ref.read(backupServiceProvider.future);
      await service.deleteBackup(info);
    });
  }

  Future<void> _setFrequency(BackupFrequency f) => _guard(() async {
    final service = await ref.read(backupServiceProvider.future);
    await service.setFrequency(f);
    await ref.read(backupSchedulerProvider).schedule(f);
  });

  Future<void> _setRetention(int n) => _guard(() async {
    final service = await ref.read(backupServiceProvider.future);
    await service.setRetention(n);
  });

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(backupListProvider);
    final settings = ref.watch(backupSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Back up now', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _create(share: false),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Create backup'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _create(share: true),
                      icon: const Icon(Icons.share),
                      label: const Text('Create & share'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickAndRestore,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Restore from file'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Automatic backup', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                settings.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingView(),
                  ),
                  error: (e, _) => ErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(backupSettingsProvider),
                  ),
                  data: (s) => _AutoSection(
                    settings: s,
                    busy: _busy,
                    onFrequency: _setFrequency,
                    onRetention: _setRetention,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Saved backups', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                list.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: LoadingView(),
                  ),
                  error: (e, _) => ErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(backupListProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: EmptyState(
                            message:
                                'No backups yet. Tap "Create backup" to make '
                                'the first one.',
                            icon: Icons.backup_outlined,
                          ),
                        )
                      : Column(
                          children: [
                            for (final b in items)
                              _BackupTile(
                                info: b,
                                busy: _busy,
                                onShare: () => _guard(() => _share(b)),
                                onRestore: () => _restoreFromInfo(b),
                                onDelete: b.deletable ? () => _delete(b) : null,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSection extends StatelessWidget {
  const _AutoSection({
    required this.settings,
    required this.busy,
    required this.onFrequency,
    required this.onRetention,
  });
  final BackupSettings settings;
  final bool busy;
  final ValueChanged<BackupFrequency> onFrequency;
  final ValueChanged<int> onRetention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = settings.lastSuccess == null
        ? 'No automatic backup has run yet.'
        : '${settings.lastSuccess! ? 'Last run succeeded' : 'Last run failed'}'
              '${settings.lastBackupAt != null ? ' at ${_fmtDate(settings.lastBackupAt!)}' : ''}'
              '${settings.lastMessage != null ? ' (${settings.lastMessage})' : ''}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Frequency')),
                DropdownButton<BackupFrequency>(
                  value: settings.frequency,
                  onChanged: busy
                      ? null
                      : (v) => v == null ? null : onFrequency(v),
                  items: [
                    for (final f in BackupFrequency.values)
                      DropdownMenuItem(value: f, child: Text(f.label)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const Expanded(child: Text('Keep last automatic backups')),
                DropdownButton<int>(
                  value: settings.retention,
                  onChanged: busy
                      ? null
                      : (v) => v == null ? null : onRetention(v),
                  items: [
                    for (
                      var n = BackupSettings.minRetention;
                      n <= BackupSettings.maxRetention;
                      n++
                    )
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: settings.lastSuccess == false
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Android decides when background work runs, so automatic '
              'backups may be delayed by hours (battery saver, Doze). '
              'Backups stay on this device. Manual and safety backups are '
              'never removed automatically.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({
    required this.info,
    required this.busy,
    required this.onShare,
    required this.onRestore,
    required this.onDelete,
  });
  final BackupFileInfo info;
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onRestore;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final kind = switch (info.kind) {
      BackupKind.manual => 'Manual',
      BackupKind.auto => 'Automatic',
      BackupKind.safety => 'Safety (before restore)',
    };
    return Card(
      child: ListTile(
        title: Text(_fmtDate(info.createdAt)),
        subtitle: Text('$kind · ${_fmtSize(info.sizeBytes)}'),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: busy ? null : onShare,
            ),
            IconButton(
              tooltip: 'Restore',
              icon: const Icon(Icons.restore),
              onPressed: busy ? null : onRestore,
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: busy ? null : onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
