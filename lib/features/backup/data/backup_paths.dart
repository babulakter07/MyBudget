import 'package:path/path.dart' as p;

/// True when [path] is a safe path RELATIVE to the attachments directory:
/// non-empty, forward slashes only, no absolute/drive prefix, no `.`/`..`/empty
/// segments, no control characters. Used both when validating a backup and
/// again right before writing a file (defence in depth against traversal).
bool isSafeRelativePath(String path) {
  if (path.isEmpty || path.length > 260) return false;
  if (path.contains('\\') || path.startsWith('/')) return false;
  if (RegExp(r'[\x00-\x1f]').hasMatch(path)) return false;
  if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return false;
  for (final seg in path.split('/')) {
    if (seg.isEmpty || seg == '.' || seg == '..') return false;
    if (seg.contains(':')) return false;
  }
  return true;
}

/// Resolves [relative] under [root] and verifies the result stays inside it.
/// Returns null when unsafe.
String? resolveInside(String root, String relative) {
  if (!isSafeRelativePath(relative)) return null;
  final target = p.normalize(p.join(root, relative));
  return p.isWithin(p.normalize(root), target) ? target : null;
}
