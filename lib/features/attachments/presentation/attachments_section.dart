import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/attachment.dart';
import '../providers/attachment_providers.dart';
import 'attachment_viewer_screen.dart';

/// Embeddable receipt-photo section. With [transactionId] it persists
/// immediately; with [pending] (and no id) it collects files for later
/// `commitPending`.
class AttachmentsSection extends ConsumerStatefulWidget {
  const AttachmentsSection({super.key, this.transactionId, this.pending})
    : assert(
        transactionId != null || pending != null,
        'Provide a transactionId or a PendingAttachments controller.',
      );

  final int? transactionId;
  final PendingAttachments? pending;

  @override
  ConsumerState<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<AttachmentsSection> {
  bool get _persisted => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    widget.pending?.addListener(_onPending);
  }

  @override
  void didUpdateWidget(AttachmentsSection old) {
    super.didUpdateWidget(old);
    if (old.pending != widget.pending) {
      old.pending?.removeListener(_onPending);
      widget.pending?.addListener(_onPending);
    }
  }

  @override
  void dispose() {
    widget.pending?.removeListener(_onPending);
    super.dispose();
  }

  void _onPending() {
    if (mounted) setState(() {});
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(ctx.l10n.attachmentsCamera),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(ctx.l10n.attachmentsGallery),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ref.read(imagePickerGatewayProvider);
    try {
      final file = source
          ? await picker.pickFromCamera()
          : await picker.pickFromGallery();
      if (file == null) return;
      if (_persisted) {
        final pid = ref.read(activeProfileIdProvider);
        if (pid == null) return;
        await ref
            .read(attachmentRepositoryProvider)
            .addFromFile(
              profileId: pid,
              transactionId: widget.transactionId!,
              source: file,
            );
      } else {
        await widget.pending!.add(file);
      }
    } on AppException catch (e) {
      if (mounted) _msg(e.message);
    } catch (_) {
      if (mounted) _msg(context.l10n.attachmentsAddFailed);
    }
  }

  void _open(File file) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttachmentViewerScreen(file: file),
      ),
    );
  }

  Future<void> _deletePersisted(Attachment a) async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.attachmentsDeleteTitle,
      message: context.l10n.attachmentsRemoveMessage,
      confirmLabel: context.l10n.commonDelete,
    );
    if (!ok) return;
    final pid = ref.read(activeProfileIdProvider);
    if (pid == null) return;
    try {
      await ref.read(attachmentRepositoryProvider).delete(pid, a.id);
    } on AppException catch (e) {
      if (mounted) _msg(e.message);
    }
  }

  Future<void> _deletePending(int index) async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.attachmentsDeleteTitle,
      message: context.l10n.attachmentsRemoveMessage,
      confirmLabel: context.l10n.commonDelete,
    );
    if (ok) widget.pending!.removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    var count = 0;
    Widget? status;

    if (_persisted) {
      final async = ref.watch(
        attachmentsForTransactionProvider(widget.transactionId!),
      );
      status = async.whenOrNull(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
      );
      final list = async.value ?? const <Attachment>[];
      count = list.length;
      for (final a in list) {
        tiles.add(
          _Thumb(
            key: ValueKey('att-${a.id}'),
            fileFuture: ref
                .read(attachmentRepositoryProvider)
                .resolve(a.relativePath),
            onTap: _open,
            onDelete: () => _deletePersisted(a),
          ),
        );
      }
    } else {
      final files = widget.pending!.files;
      count = files.length;
      for (var i = 0; i < files.length; i++) {
        tiles.add(
          _Thumb(
            key: ValueKey('pending-${files[i].path}'),
            fileFuture: Future.value(files[i]),
            onTap: _open,
            onDelete: () => _deletePending(i),
          ),
        );
      }
    }

    final canAdd = count < AttachmentLimits.maxPerTransaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.attachmentsHeader(
                count,
                AttachmentLimits.maxPerTransaction,
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: canAdd ? _add : null,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(context.l10n.attachmentsAddPhoto),
            ),
          ],
        ),
        ?status,
        if (tiles.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: tiles)
        else if (status == null)
          Text(
            context.l10n.attachmentsNone,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    super.key,
    required this.fileFuture,
    required this.onTap,
    required this.onDelete,
  });
  final Future<File> fileFuture;
  final void Function(File) onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<File>(
              future: fileFuture,
              builder: (context, snap) {
                final f = snap.data;
                if (f == null) {
                  return const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image_outlined),
                  );
                }
                return InkWell(
                  onTap: () => onTap(f),
                  child: Image.file(
                    f,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: context.l10n.attachmentsDeleteTitle,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
