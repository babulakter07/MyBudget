import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/backup_crypto.dart';
import '../data/backup_providers.dart';
import '../data/backup_service.dart';
import '../domain/backup_models.dart';
import 'folder_backup_section.dart';

String _fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);

String _tableLabel(AppLocalizations l, String t) => switch (t) {
  'financial_profiles' => l.backupTableFinancialProfiles,
  'exchange_rates' => l.backupTableExchangeRates,
  'categories' => l.backupTableCategories,
  'sub_categories' => l.backupTableSubCategories,
  'cost_items' => l.backupTableCostItems,
  'monthly_budgets' => l.backupTableMonthlyBudgets,
  'category_budgets' => l.backupTableCategoryBudgets,
  'accounts' => l.backupTableAccounts,
  'recurring_rules' => l.backupTableRecurringRules,
  'savings_goals' => l.backupTableSavingsGoals,
  'debts' => l.backupTableDebts,
  'debt_payments' => l.backupTableDebtPayments,
  'financial_transactions' => l.backupTableFinancialTransactions,
  'transaction_audit_logs' => l.backupTableTransactionAuditLogs,
  'tags' => l.backupTableTags,
  'transaction_attachments' => l.backupTableTransactionAttachments,
  _ => t.replaceAll('_', ' '),
};

String _frequencyLabel(AppLocalizations l, BackupFrequency f) => switch (f) {
  BackupFrequency.off => l.backupFreqOff,
  BackupFrequency.daily => l.backupFreqDaily,
  BackupFrequency.weekly => l.backupFreqWeekly,
};

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
      if (mounted) _toast(context.l10n.backupSomethingWrong('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(backupListProvider);
      ref.invalidate(backupSettingsProvider);
    }
  }

  Future<void> _create({required bool share}) => _guard(() async {
    final service = await ref.read(backupServiceProvider.future);
    final estimate = await service.estimatePhotos();
    if (!mounted) return;
    final options = await showDialog<_ExportOptions>(
      context: context,
      builder: (_) => _ExportDialog(estimate: estimate),
    );
    if (options == null) return;
    BackupExport? stats;
    final info = await service.createBackupFile(
      kind: BackupKind.manual,
      includePhotos: options.includePhotos,
      password: options.password,
      onExport: (e) => stats = e,
    );
    final missing = stats?.photosMissing ?? 0;
    if (!mounted) return;
    final l = context.l10n;
    _toast(
      l.backupSavedToast(info.name) +
          (options.password != null ? l.backupEncryptedSuffix : '') +
          (missing > 0 ? l.backupMissingPhotosSuffix(missing) : ''),
    );
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
      if (mounted) _toast(context.l10n.backupUnreadableFile);
      return;
    }
    final service = await ref.read(backupServiceProvider.future);
    await _restoreJson(service, text);
  });

  Future<String?> _askPassword({String? error}) => showDialog<String>(
    context: context,
    builder: (_) => _PasswordPromptDialog(error: error),
  );

  /// validate -> summary/errors -> explicit confirmation -> restore.
  Future<void> _restoreJson(BackupService service, String text) async {
    var json = text;
    if (BackupCrypto.isEncrypted(text)) {
      String? error;
      while (true) {
        if (!mounted) return;
        final pw = await _askPassword(error: error);
        if (pw == null) return; // cancelled, nothing changed
        try {
          json = await service.decryptIfNeeded(text, password: pw);
          break;
        } on ValidationException catch (e) {
          error = e.message;
        }
      }
    }
    final v = service.validate(json);
    if (!mounted) return;
    final l10n = context.l10n;
    if (!v.isValid) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupCannotRestoreTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(l10n.backupNothingChanged),
                const SizedBox(height: 8),
                for (final e in v.errors) Text('• $e'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupReplaceAllTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (v.createdAt != null)
                Text(l10n.backupCreatedAt(_fmtDate(v.createdAt!.toLocal()))),
              const SizedBox(height: 8),
              Text(l10n.backupContains),
              for (final e in v.counts.entries)
                if (e.key != 'application_settings')
                  Text(
                    l10n.backupContainsRow(e.value, _tableLabel(l10n, e.key)),
                  ),
              const SizedBox(height: 12),
              Text(
                l10n.backupReplaceWarning,
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
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.backupReplaceData),
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
          ? l10n.backupRestoreCompleteCleared
          : l10n.backupRestoreComplete,
    );
  }

  Future<void> _delete(BackupFileInfo info) async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.backupDeleteTitle,
      message: context.l10n.backupDeleteMessage(info.name),
      confirmLabel: context.l10n.commonDelete,
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
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.backupBackUpNow, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _create(share: false),
                      icon: const Icon(Icons.save_alt),
                      label: Text(l.backupCreateBackup),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _create(share: true),
                      icon: const Icon(Icons.share),
                      label: Text(l.backupCreateAndShare),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickAndRestore,
                      icon: const Icon(Icons.upload_file),
                      label: Text(l.backupRestoreFromFile),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(l.backupAutoBackup, style: theme.textTheme.titleMedium),
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
                Text(l.backupFolderTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const FolderBackupSection(),
                const SizedBox(height: 24),
                Text(l.backupSavedBackups, style: theme.textTheme.titleMedium),
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
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: EmptyState(
                            message: l.backupNoBackupsYet,
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
    final l = context.l10n;
    final status = settings.lastSuccess == null
        ? l.backupNoAutoRun
        : (settings.lastSuccess!
                  ? l.backupLastRunSucceeded
                  : l.backupLastRunFailed) +
              (settings.lastBackupAt != null
                  ? l.backupStatusAt(_fmtDate(settings.lastBackupAt!))
                  : '') +
              (settings.lastMessage != null
                  ? l.backupStatusMessage(settings.lastMessage!)
                  : '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.backupFrequency)),
                DropdownButton<BackupFrequency>(
                  value: settings.frequency,
                  onChanged: busy
                      ? null
                      : (v) => v == null ? null : onFrequency(v),
                  items: [
                    for (final f in BackupFrequency.values)
                      DropdownMenuItem(
                        value: f,
                        child: Text(_frequencyLabel(l, f)),
                      ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text(l.backupKeepLast)),
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
            Text(l.backupAutoNote, style: theme.textTheme.bodySmall),
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
    final l = context.l10n;
    final kind = switch (info.kind) {
      BackupKind.manual => l.backupKindManual,
      BackupKind.auto => l.backupKindAuto,
      BackupKind.safety => l.backupKindSafety,
    };
    return Card(
      child: ListTile(
        title: Text(_fmtDate(info.createdAt)),
        subtitle: Text('$kind · ${_fmtSize(info.sizeBytes)}'),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: l.commonShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: busy ? null : onShare,
            ),
            IconButton(
              tooltip: l.commonRestore,
              icon: const Icon(Icons.restore),
              onPressed: busy ? null : onRestore,
            ),
            if (onDelete != null)
              IconButton(
                tooltip: l.commonDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: busy ? null : onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportOptions {
  const _ExportOptions({required this.includePhotos, this.password});
  final bool includePhotos;

  /// Non-null => encrypt the file with this password.
  final String? password;
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.estimate});
  final PhotoEstimate estimate;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  bool _photos = true;
  bool _encrypt = false;
  bool _show = false;
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() {
    if (_encrypt) {
      if (_pw.text.length < minBackupPasswordLength) {
        setState(
          () => _error = context.l10n.backupPasswordTooShort(
            minBackupPasswordLength,
          ),
        );
        return;
      }
      if (_pw.text != _pw2.text) {
        setState(() => _error = context.l10n.backupPasswordMismatch);
        return;
      }
    }
    Navigator.of(context).pop(
      _ExportOptions(
        includePhotos: _photos,
        password: _encrypt ? _pw.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.estimate;
    final theme = Theme.of(context);
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.backupCreateBackup),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.count + e.missing > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _photos,
                onChanged: (v) => setState(() => _photos = v ?? true),
                title: Text(l.backupIncludePhotos),
                subtitle: Text(
                  l.backupPhotoCount(e.count, _fmtSize(e.approxBackupBytes)) +
                      (e.missing > 0 ? l.backupMissingSkipped(e.missing) : ''),
                ),
              )
            else
              Text(l.backupNoPhotos, style: theme.textTheme.bodySmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _encrypt,
              onChanged: (v) => setState(() {
                _encrypt = v;
                _error = null;
              }),
              title: Text(l.backupEncrypt),
              subtitle: Text(l.backupEncryptNote),
            ),
            if (_encrypt) ...[
              TextField(
                controller: _pw,
                obscureText: !_show,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l.backupPasswordMinLabel(minBackupPasswordLength),
                  suffixIcon: IconButton(
                    tooltip: _show ? l.backupHide : l.backupShow,
                    icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pw2,
                obscureText: !_show,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.backupConfirmPassword),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.commonCreate)),
      ],
    );
  }
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({this.error});
  final String? error;

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _pw = TextEditingController();

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.backupPasswordRequired),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.backupEncryptedPrompt),
          const SizedBox(height: 8),
          TextField(
            controller: _pw,
            obscureText: true,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l.backupPassword),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_pw.text),
          child: Text(l.backupUnlock),
        ),
      ],
    );
  }
}
