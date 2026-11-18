import '../../../core/utils/date_keys.dart';

/// A savings goal row (no computed progress).
class Goal {
  const Goal({
    required this.id,
    required this.profileId,
    required this.name,
    required this.accountId,
    required this.targetMinor,
    required this.targetDate,
    required this.note,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String name;
  final int accountId;
  final int targetMinor;

  /// 'yyyy-MM-dd' or null.
  final String? targetDate;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Computed progress. Never stored; derived from the linked account balance.
class GoalProgress {
  const GoalProgress({
    required this.currentMinor,
    required this.targetMinor,
    required this.percent,
    required this.remainingMinor,
    required this.achieved,
    required this.daysLeft,
    required this.requiredPerMonthMinor,
  });

  /// Raw linked-account balance (may be negative).
  final int currentMinor;
  final int targetMinor;

  /// Floor percent of max(balance,0)/target. 0..100+ (can exceed 100).
  final int percent;

  /// Amount still missing (>= 0; 0 when achieved).
  final int remainingMinor;
  final bool achieved;

  /// Days from today to target date (negative = past). Null without a date.
  final int? daysLeft;

  /// Ceil(remaining / months left), months >= 1. Null when no deadline or
  /// already achieved.
  final int? requiredPerMonthMinor;

  /// Percent capped at 100 for display.
  int get displayPercent => percent > 100 ? 100 : percent;

  bool get overdue => !achieved && daysLeft != null && daysLeft! < 0;
}

/// Goal + its account info + progress.
class GoalWithProgress {
  const GoalWithProgress({
    required this.goal,
    required this.accountName,
    required this.accountActive,
    required this.progress,
  });
  final Goal goal;
  final String accountName;
  final bool accountActive;
  final GoalProgress progress;
}

/// Minimal account info for the goal form's account picker.
class GoalAccountOption {
  const GoalAccountOption({
    required this.id,
    required this.name,
    required this.type,
  });
  final int id;
  final String name;
  final String type;
}

/// Whole days from [today] to [targetDate] (calendar days, DST-safe).
int daysBetweenKeys(String today, String targetDate) {
  final a = parseDateKey(today);
  final b = parseDateKey(targetDate);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Months left until the deadline, ceil(days/30), minimum 1.
int monthsLeftFor(int daysLeft) {
  if (daysLeft <= 0) return 1;
  final m = (daysLeft + 29) ~/ 30;
  return m < 1 ? 1 : m;
}

/// Ceil division for non-negative numerator and positive denominator.
int ceilDiv(int a, int b) => (a + b - 1) ~/ b;

/// Pure progress computation. Integer math only.
/// [today] and [targetDate] are 'yyyy-MM-dd'.
GoalProgress computeGoalProgress({
  required int balanceMinor,
  required int targetMinor,
  required String today,
  String? targetDate,
}) {
  assert(targetMinor > 0);
  final clamped = balanceMinor < 0 ? 0 : balanceMinor;
  final percent = (clamped * 100) ~/ targetMinor;
  final achieved = balanceMinor >= targetMinor;
  final remaining = achieved ? 0 : targetMinor - balanceMinor;
  final daysLeft = targetDate == null
      ? null
      : daysBetweenKeys(today, targetDate);
  int? perMonth;
  if (daysLeft != null && !achieved) {
    perMonth = ceilDiv(remaining, monthsLeftFor(daysLeft));
  }
  return GoalProgress(
    currentMinor: balanceMinor,
    targetMinor: targetMinor,
    percent: percent,
    remainingMinor: remaining,
    achieved: achieved,
    daysLeft: daysLeft,
    requiredPerMonthMinor: perMonth,
  );
}
