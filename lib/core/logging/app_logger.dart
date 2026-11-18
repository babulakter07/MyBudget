import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Offline crash/error log. Nothing leaves the device: the user can attach the
/// file to a support email from Settings. Rotates at [maxBytes].
class AppLogger {
  AppLogger._(this.file, {this.maxBytes = 512 * 1024});

  /// For tests / explicit paths.
  AppLogger.forFile(File file, {int maxBytes = 512 * 1024})
    : this._(file, maxBytes: maxBytes);

  final File file;
  final int maxBytes;

  static AppLogger? _instance;
  static AppLogger? get instance => _instance;

  static Future<AppLogger> init() async {
    final dir = await getApplicationSupportDirectory();
    final logger = AppLogger._(File(p.join(dir.path, 'logs', 'mybudget.log')));
    _instance = logger;
    return logger;
  }

  /// Routes Flutter framework and uncaught async errors into the log.
  void installGlobalHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      logError(details.exception, details.stack, context: 'flutter');
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logError(error, stack, context: 'platform');
      return false;
    };
  }

  void logError(Object error, StackTrace? stack, {String? context}) {
    final b = StringBuffer()
      ..writeln('[${DateTime.now().toIso8601String()}] ERROR ${context ?? ''}')
      ..writeln(error);
    if (stack != null) b.writeln(stack);
    b.writeln();
    _append(b.toString());
  }

  void info(String message) =>
      _append('[${DateTime.now().toIso8601String()}] INFO $message\n');

  void _append(String text) {
    try {
      file.parent.createSync(recursive: true);
      if (file.existsSync() && file.lengthSync() > maxBytes) {
        final old = File('${file.path}.1');
        if (old.existsSync()) old.deleteSync();
        file.renameSync(old.path);
      }
      file.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } catch (_) {
      // Logging must never throw.
    }
  }

  /// Log files to attach to a support email (current + rotated).
  List<File> files() => [
    if (File('${file.path}.1').existsSync()) File('${file.path}.1'),
    if (file.existsSync()) file,
  ];

  void clear() {
    for (final f in [file, File('${file.path}.1')]) {
      try {
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }
}
