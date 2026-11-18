import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/onboarding/data/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 6, 30, 12);

  test('no reminder before the user has any data', () {
    expect(
      evaluateBackupReminder(
        now: now,
        hasData: false,
        newestBackup: null,
        snoozedUntil: null,
      ),
      isNull,
    );
  });

  test('no backup at all -> reminder without a day count', () {
    final r = evaluateBackupReminder(
      now: now,
      hasData: true,
      newestBackup: null,
      snoozedUntil: null,
    );
    expect(r, isNotNull);
    expect(r!.daysSince, isNull);
  });

  test('recent backup -> no reminder; 30+ days -> reminder with days', () {
    expect(
      evaluateBackupReminder(
        now: now,
        hasData: true,
        newestBackup: now.subtract(const Duration(days: 29)),
        snoozedUntil: null,
      ),
      isNull,
    );
    final r = evaluateBackupReminder(
      now: now,
      hasData: true,
      newestBackup: now.subtract(const Duration(days: 45)),
      snoozedUntil: null,
    );
    expect(r?.daysSince, 45);
  });

  test('snooze hides it until it expires', () {
    final old = now.subtract(const Duration(days: 90));
    expect(
      evaluateBackupReminder(
        now: now,
        hasData: true,
        newestBackup: old,
        snoozedUntil: now.add(const Duration(days: 3)),
      ),
      isNull,
    );
    expect(
      evaluateBackupReminder(
        now: now,
        hasData: true,
        newestBackup: old,
        snoozedUntil: now.subtract(const Duration(days: 1)),
      ),
      isNotNull,
    );
  });
}
