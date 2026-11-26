import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/data/backup_reminder.dart';
import '../data/backup_crypto.dart';
import '../data/backup_folder_gateway.dart';
import '../data/backup_providers.dart';
import '../data/folder_backup_service.dart';

/// "Backup folder" card on the Backup screen: encrypted copies in a folder the
/// user chose.
class FolderBackupSection extends ConsumerStatefulWidget {
  const FolderBackupSection({super.key});

  @override
  ConsumerState<FolderBackupSection> createState() =>
      _FolderBackupSectionState();
}

class _FolderBackupSectionState extends ConsumerState<FolderBackupSection> {
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _guard(
    Future<void> Function(FolderBackupService service) body,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body(await ref.read(folderBackupServiceProvider.future));
    } on AppException catch (e) {
      _toast(e.message);
    } on PlatformException catch (e) {
      _toast(e.message ?? e.code);
    } catch (e) {
      if (mounted) _toast(context.l10n.backupSomethingWrong('$e'));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(folderBackupConfigProvider);
        ref.invalidate(backupReminderProvider);
      }
    }
  }

  void _report(FolderSyncResult result) {
    if (!mounted) return;
    final l = context.l10n;
    _toast(switch (result) {
      FolderSyncResult.saved => l.backupFolderSaved,
      FolderSyncResult.nothingToSave => l.backupFolderNothing,
      FolderSyncResult.unchanged => l.backupFolderSaved,
      FolderSyncResult.disabled ||
      FolderSyncResult.failed => l.backupFolderFailed,
    });
  }

  Future<_FolderPassword?> _askPassword({required bool askPhotos}) =>
      showDialog<_FolderPassword>(
        context: context,
        builder: (_) => _FolderPasswordDialog(askPhotos: askPhotos),
      );

  Future<void> _choose() => _guard((service) async {
    final folder = await ref.read(backupFolderGatewayProvider).pickFolder();
    if (folder == null || !mounted) return;
    final options = await _askPassword(askPhotos: true);
    if (options == null) {
      if (service.config?.folderUri != folder.uri) {
        await ref.read(backupFolderGatewayProvider).releaseFolder(folder.uri);
      }
      return;
    }
    _report(
      await service.enable(
        folder: folder,
        password: options.password,
        includePhotos: options.includePhotos,
      ),
    );
  });

  Future<void> _changePassword() => _guard((service) async {
    final options = await _askPassword(askPhotos: false);
    if (options == null) return;
    _report(await service.changePassword(options.password));
  });

  Future<void> _saveNow() => _guard((service) async {
    _report(await service.sync(force: true));
  });

  Future<void> _turnOff() async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.backupFolderOffTitle,
      message: context.l10n.backupFolderOffMessage,
      confirmLabel: context.l10n.backupFolderTurnOff,
    );
    if (!ok) return;
    await _guard((service) => service.disable());
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(folderBackupConfigProvider);
    final theme = Theme.of(context);
    final l = context.l10n;
    final lastCopy = config?.lastCopyAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (config == null) ...[
              Text(l.backupFolderIntro),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _choose,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l.backupFolderChoose),
              ),
            ] else ...[
              Text(
                l.backupFolderCurrent(config.folderName),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                lastCopy == null
                    ? l.backupFolderNoCopy
                    : l.backupFolderLastCopy(
                        DateFormat('yyyy-MM-dd HH:mm').format(lastCopy),
                      ),
              ),
              if (config.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.backupFolderError(config.lastError!),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy ? null : _saveNow,
                    child: Text(l.backupFolderSaveNow),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _choose,
                    child: Text(l.backupFolderChange),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _changePassword,
                    child: Text(l.backupFolderNewPassword),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _turnOff,
                    child: Text(l.backupFolderTurnOff),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(l.backupFolderNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FolderPassword {
  const _FolderPassword(this.password, this.includePhotos);
  final String password;
  final bool includePhotos;
}

class _FolderPasswordDialog extends StatefulWidget {
  const _FolderPasswordDialog({required this.askPhotos});
  final bool askPhotos;

  @override
  State<_FolderPasswordDialog> createState() => _FolderPasswordDialogState();
}

class _FolderPasswordDialogState extends State<_FolderPasswordDialog> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _photos = true;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() {
    final l = context.l10n;
    final error = _pw.text.length < minBackupPasswordLength
        ? l.backupPasswordTooShort(minBackupPasswordLength)
        : _pw.text != _pw2.text
        ? l.backupPasswordMismatch
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_FolderPassword(_pw.text, _photos));
  }

  Widget _field(TextEditingController controller, String label) => TextField(
    controller: controller,
    obscureText: !_show,
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.backupFolderPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.backupFolderPasswordWarning,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            _field(_pw, l.backupPasswordMinLabel(minBackupPasswordLength)),
            const SizedBox(height: 8),
            _field(_pw2, l.backupConfirmPassword),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _show,
              onChanged: (v) => setState(() => _show = v ?? false),
              title: Text(l.backupShow),
            ),
            if (widget.askPhotos)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _photos,
                onChanged: (v) => setState(() => _photos = v ?? true),
                title: Text(l.backupIncludePhotos),
              ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.backupFolderSavePassword),
        ),
      ],
    );
  }
}
