import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../data/app_lock_providers.dart';
import '../data/biometric_authenticator.dart';
import '../domain/app_lock_models.dart';

/// Full-screen opaque PIN pad shown by [AppLockGate] while locked.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _recovering = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(appLockSettingsProvider).biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _remaining() {
    final now = ref.read(appLockClockProvider)();
    return ref.read(appLockControllerProvider).lockoutRemaining(now);
  }

  void _syncTicker() {
    if (_remaining() > Duration.zero) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remaining() <= Duration.zero) {
          _ticker?.cancel();
          _ticker = null;
        }
        setState(() {});
      });
    }
  }

  Future<void> _biometric() async {
    await ref.read(appLockControllerProvider.notifier).unlockWithBiometric();
  }

  void _press(String digit) {
    if (_busy || _remaining() > Duration.zero) return;
    final length = ref.read(appLockSettingsProvider).pinLength;
    if (_pin.length >= length) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == length) _submit();
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await ref.read(appLockControllerProvider.notifier).unlock(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
      _error = switch (r) {
        UnlockResult.wrong => context.l10n.securityIncorrectPinShort,
        UnlockResult.lockedOut => null,
        _ => null,
      };
    });
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appLockSettingsProvider);
    ref.watch(appLockControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final remaining = _remaining();
    final bioAvailable = ref.watch(biometricAvailableProvider).value ?? false;
    final showBio = settings.biometricEnabled && bioAvailable;
    _syncTicker();
    if (_recovering) {
      return _RecoveryPanel(onBack: () => setState(() => _recovering = false));
    }

    Widget key(String d) => _PadKey(
      key: ValueKey('pin-key-$d'),
      onTap: () => _press(d),
      child: Text(d, style: Theme.of(context).textTheme.headlineMedium),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 40, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.securityEnterPin,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < settings.pinLength; i++)
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _pin.length
                                ? scheme.primary
                                : Colors.transparent,
                            border: Border.all(color: scheme.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: Text(
                      remaining > Duration.zero
                          ? context.l10n.securityLockoutShort(
                              remaining.inSeconds +
                                  (remaining.inMilliseconds % 1000 > 0 ? 1 : 0),
                            )
                          : (_error ?? ''),
                      key: const ValueKey('pin-message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [for (final d in row) key(d)],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      showBio
                          ? _PadKey(
                              key: const ValueKey('pin-biometric'),
                              onTap: _biometric,
                              child: const Icon(Icons.fingerprint, size: 30),
                            )
                          : const SizedBox(width: 88, height: 72),
                      key('0'),
                      _PadKey(
                        key: const ValueKey('pin-key-backspace'),
                        onTap: _backspace,
                        child: const Icon(Icons.backspace_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('forgot-pin'),
                    onPressed: () => setState(() => _recovering = true),
                    child: Text(context.l10n.securityForgotPin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 72,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Center(child: child),
      ),
    );
  }
}

/// Forgot-PIN panel. Inline (not a dialog) because the gate sits above the
/// app Navigator, so it has its own Overlay for text-selection UI.
class _RecoveryPanel extends ConsumerStatefulWidget {
  const _RecoveryPanel({required this.onBack});
  final VoidCallback onBack;

  @override
  ConsumerState<_RecoveryPanel> createState() => _RecoveryPanelState();
}

class _RecoveryPanelState extends ConsumerState<_RecoveryPanel> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .recoverWithCode(_controller.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = context.l10n.securityRecoverInvalid;
      });
    }
    // On success the controller unlocks and the gate removes this screen.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.key_outlined,
                          size: 40,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.securityRecoverTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.securityRecoverBody),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('recovery-input'),
                          controller: _controller,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: l10n.securityRecoverLabel,
                            errorText: _error,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              key: const ValueKey('recovery-back'),
                              onPressed: _busy ? null : widget.onBack,
                              child: Text(l10n.securityRecoverCancel),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const ValueKey('recovery-submit'),
                              onPressed: _busy ? null : _submit,
                              child: Text(l10n.securityRecoverAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
