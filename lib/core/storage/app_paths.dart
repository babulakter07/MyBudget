import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Overridable in tests so no real platform channel is needed.
Directory? attachmentsDirectoryOverride;

/// Private directory that holds receipt photos. Rows in
/// `transaction_attachments.relative_path` are relative to this directory.
Future<Directory> attachmentsDirectory() async {
  final override = attachmentsDirectoryOverride;
  final Directory dir;
  if (override != null) {
    dir = override;
  } else {
    final base = await getApplicationSupportDirectory();
    dir = Directory(p.join(base.path, 'attachments'));
  }
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}
