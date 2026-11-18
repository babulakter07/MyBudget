import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';

/// Shows a confirm/cancel dialog. Returns true only when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel ?? ctx.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel ?? ctx.l10n.commonConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
