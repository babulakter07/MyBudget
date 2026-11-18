import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_lock_providers.dart';
import 'app_lock_screen.dart';

/// Wraps the app. While locked, shows [AppLockScreen] over an opaque surface;
/// [child] stays mounted (navigation state is kept) but is not painted,
/// hit-testable or exposed to accessibility. While the app is not in the
/// foreground and a lock is configured, an opaque cover hides the content from
/// the app switcher.
///
/// Place it in `MaterialApp.builder`: `builder: (c, child) =>
/// AppLockGate(child: child!)`.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLockControllerProvider.notifier).onLifecycle(state);
    final covered =
        state != AppLifecycleState.resumed &&
        ref.read(appLockSettingsProvider).enabled;
    if (covered != _covered) setState(() => _covered = covered);
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockControllerProvider).locked;
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: locked, child: widget.child),
        if (locked)
          const Positioned.fill(child: AppLockScreen())
        else if (_covered)
          Positioned.fill(
            child: ColoredBox(
              key: const ValueKey('privacy-cover'),
              color: surface,
            ),
          ),
      ],
    );
  }
}
