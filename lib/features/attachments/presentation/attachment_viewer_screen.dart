import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

/// Full-screen pinch-zoom viewer for one image file.
class AttachmentViewerScreen extends StatelessWidget {
  const AttachmentViewerScreen({super.key, required this.file, this.title});
  final File file;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title ?? context.l10n.attachmentsViewerTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
