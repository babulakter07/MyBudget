import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/core/logging/app_logger.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('logger_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('writes errors and info lines', () {
    final log = AppLogger.forFile(File('${dir.path}/logs/a.log'));
    log.info('hello');
    log.logError(StateError('boom'), StackTrace.current, context: 'test');
    final text = log.file.readAsStringSync();
    expect(text, contains('INFO hello'));
    expect(text, contains('boom'));
  });

  test('rotates when over the size limit and clear removes files', () {
    final log = AppLogger.forFile(File('${dir.path}/a.log'), maxBytes: 100);
    for (var i = 0; i < 20; i++) {
      log.info('line number $i with some padding text');
    }
    expect(File('${dir.path}/a.log.1').existsSync(), isTrue);
    expect(log.files().length, 2);
    log.clear();
    expect(log.files(), isEmpty);
  });

  test('never throws on an unwritable path', () {
    final log = AppLogger.forFile(File('Z:/nope/\u0000/x.log'));
    expect(() => log.info('x'), returnsNormally);
  });
}
