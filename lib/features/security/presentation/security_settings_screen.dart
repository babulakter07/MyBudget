import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/l10n.dart';
import '../../help/presentation/help_button.dart';
import '../data/app_lock_providers.dart';
import '../data/biometric_authenticator.dart';
import '../domain/app_lock_models.dart';

/// Shows a dialog with obscured PIN fields. [onSubmit] receives the values and
/// returns an error message, or null on success (dialog then closes with true).
Future<bool> showPinDialog(
  BuildContext context, {
  required String title,
  required List<String> labels,
  required Future<String?> Function(List<String> values) onSubmit,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _PinDialog(title: title, labels: labels, onSubmit: onSubmit),
  );
  return ok ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.title,
    required this.labels,
    required this.onSubmit,
  });
  final String title;
  final List<String> labels;
  final Future<String?> Function(List<String>) onSubmit;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final _controllers = [
    for (final _ in widget.labels) TextEditingController(),
  ];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final values = [for (final c in _controllers) c.text];
    for (final v in values) {
      if (!AppLockController.isValidPin(v)) {
        setState(() => _error = context.l10n.securityPinInvalid);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    try {
      err = await widget.onSubmit(values);
    } on AppException catch (e) {
      err = e.message;
    }
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              TextField(
                key: ValueKey('pin-field-$i'),
                controller: _controllers[i],
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: i == 0,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: widget.labels[i],
                  counterText: '',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const ValueKey('pin-dialog-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('pin-dialog-ok'),
          onPressed: _busy ? null : _submit,
          child: Text(context.l10n.commonOk),
        ),
      ],
    );
  }
}

String _lockoutMessage(AppLocalizations l10n, AppLockState s, DateTime now) =>
    l10n.securityLockout(s.lockoutRemaining(now).inSeconds + 1);

String _delayLabel(AppLocalizations l10n, AutoLockDelay d) => switch (d) {
  AutoLockDelay.immediately => l10n.securityDelayImmediately,
  AutoLockDelay.seconds30 => l10n.securityDelay30s,
  AutoLockDelay.minute1 => l10n.securityDelay1m,
  AutoLockDelay.minutes5 => l10n.securityDelay5m,
};

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  Future<String?> _result(
    AppLocalizations l10n,
    WidgetRef ref,
    UnlockResult r,
  ) async {
    switch (r) {
      case UnlockResult.success:
        return null;
      case UnlockResult.wrong:
        return l10n.securityIncorrectPin;
      case UnlockResult.notEnabled:
        return l10n.securityNotEnabled;
      case UnlockResult.lockedOut:
        return _lockoutMessage(
          l10n,
          ref.read(appLockControllerProvider),
          ref.read(appLockClockProvider)(),
        );
    }
  }

  Future<void> _showRecoveryCode(BuildContext context, String code) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityRecoveryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.securityRecoveryBody),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(
                code,
                key: const ValueKey('recovery-code'),
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('recovery-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.securityRecoveryCopied)),
                );
              }
            },
            child: Text(l10n.securityRecoveryCopy),
          ),
          FilledButton(
            key: const ValueKey('recovery-saved'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.securityRecoverySaved),
          ),
        ],
      ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    String? code;
    final ok = await showPinDialog(
      context,
      title: l10n.securitySetPin,
      labels: [l10n.securityNewPinLabel, l10n.securityConfirmPinLabel],
      onSubmit: (v) async {
        if (v[0] != v[1]) return l10n.securityPinsMismatch;
        code = await ref.read(appLockControllerProvider.notifier).enable(v[0]);
        return null;
      },
    );
    if (ok && code != null && context.mounted) {
      await _showRecoveryCode(context, code!);
    }
  }

  Future<void> _newRecoveryCode(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    String? code;
    final ok = await showPinDialog(
      context,
      title: l10n.securityNewRecoveryCode,
      labels: [l10n.securityCurrentPinLabel],
      onSubmit: (v) async {
        final (r, c) = await ref
            .read(appLockControllerProvider.notifier)
            .regenerateRecoveryCode(v[0]);
        code = c;
        return _result(l10n, ref, r);
      },
    );
    if (ok && code != null && context.mounted) {
      await _showRecoveryCode(context, code!);
    }
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return showPinDialog(
      context,
      title: l10n.securityTurnOff,
      labels: [l10n.securityCurrentPinLabel],
      onSubmit: (v) async => _result(
        l10n,
        ref,
        await ref.read(appLockControllerProvider.notifier).disable(v[0]),
      ),
    );
  }

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final changed = await showPinDialog(
      context,
      title: l10n.securityChangePin,
      labels: [
        l10n.securityCurrentPinLabel,
        l10n.securityNewPinLabel,
        l10n.securityConfirmNewPinLabel,
      ],
      onSubmit: (v) async {
        if (v[1] != v[2]) return l10n.securityNewPinsMismatch;
        return _result(
          l10n,
          ref,
          await ref
              .read(appLockControllerProvider.notifier)
              .changePin(v[0], v[1]),
        );
      },
    );
    if (changed && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.securityPinChanged)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appLockSettingsProvider);
    final bio = ref.watch(biometricAvailableProvider);
    final bioAvailable = bio.value ?? false;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.securityTitle),
        actions: const [HelpButton(topicId: 'security')],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            key: const ValueKey('app-lock-switch'),
            secondary: const Icon(Icons.lock_outline),
            title: Text(l10n.securityAppLock),
            subtitle: Text(l10n.securityAppLockSubtitle),
            value: settings.enabled,
            onChanged: (on) =>
                on ? _enable(context, ref) : _disable(context, ref),
          ),
          if (settings.enabled) ...[
            ListTile(
              key: const ValueKey('change-pin-tile'),
              leading: const Icon(Icons.pin_outlined),
              title: Text(l10n.securityChangePin),
              onTap: () => _change(context, ref),
            ),
            ListTile(
              key: const ValueKey('new-recovery-tile'),
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.securityNewRecoveryCode),
              subtitle: Text(l10n.securityNewRecoveryCodeSubtitle),
              onTap: () => _newRecoveryCode(context, ref),
            ),
            if (bioAvailable)
              SwitchListTile(
                key: const ValueKey('biometric-switch'),
                secondary: const Icon(Icons.fingerprint),
                title: Text(l10n.securityBiometric),
                value: settings.biometricEnabled,
                onChanged: (v) async {
                  if (v) {
                    final ok = await ref
                        .read(biometricAuthenticatorProvider)
                        .authenticate(l10n.securityBiometricConfirm);
                    if (!ok) return;
                  }
                  await ref
                      .read(appLockSettingsProvider.notifier)
                      .setBiometricEnabled(v);
                },
              ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.securityAutoLock),
              subtitle: Text(l10n.securityAutoLockSubtitle),
              trailing: DropdownButton<AutoLockDelay>(
                key: const ValueKey('auto-lock-dropdown'),
                value: settings.autoLockDelay,
                underline: const SizedBox.shrink(),
                items: [
                  for (final d in AutoLockDelay.values)
                    DropdownMenuItem(
                      value: d,
                      child: Text(_delayLabel(l10n, d)),
                    ),
                ],
                onChanged: (d) {
                  if (d != null) {
                    ref
                        .read(appLockSettingsProvider.notifier)
                        .setAutoLockDelay(d);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
