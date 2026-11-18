import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/goals/domain/goal.dart';

GoalProgress _p(
  int bal,
  int target, {
  String? date,
  String today = '2026-06-01',
}) => computeGoalProgress(
  balanceMinor: bal,
  targetMinor: target,
  today: today,
  targetDate: date,
);

void main() {
  test('partial progress, no deadline', () {
    final p = _p(25000, 100000);
    expect(p.percent, 25);
    expect(p.remainingMinor, 75000);
    expect(p.achieved, isFalse);
    expect(p.daysLeft, isNull);
    expect(p.requiredPerMonthMinor, isNull);
    expect(p.overdue, isFalse);
  });

  test('negative balance clamps percent to 0, remaining exceeds target', () {
    final p = _p(-5000, 100000);
    expect(p.percent, 0);
    expect(p.remainingMinor, 105000);
    expect(p.achieved, isFalse);
  });

  test('over-achieved: percent > 100, display capped, remaining 0', () {
    final p = _p(150000, 100000, date: '2026-12-01');
    expect(p.percent, 150);
    expect(p.displayPercent, 100);
    expect(p.remainingMinor, 0);
    expect(p.achieved, isTrue);
    expect(p.requiredPerMonthMinor, isNull);
  });

  test('exactly at target is achieved', () {
    final p = _p(100000, 100000);
    expect(p.achieved, isTrue);
    expect(p.percent, 100);
  });

  test('percent floors', () {
    expect(_p(999, 1000).percent, 99);
  });

  test('required per month: ceil(remaining / months)', () {
    // 90 days -> 3 months; remaining 100000 -> ceil(33333.33) = 33334
    final p = _p(0, 100000, date: '2026-08-30');
    expect(p.daysLeft, 90);
    expect(p.requiredPerMonthMinor, 33334);
  });

  test('required per month: partial month rounds up, min 1 month', () {
    expect(monthsLeftFor(1), 1);
    expect(monthsLeftFor(30), 1);
    expect(monthsLeftFor(31), 2);
    expect(monthsLeftFor(0), 1);
    expect(monthsLeftFor(-10), 1);
    final p = _p(0, 50000, date: '2026-06-05');
    expect(p.requiredPerMonthMinor, 50000);
  });

  test('past deadline: overdue, whole remaining due in 1 month', () {
    final p = _p(20000, 100000, date: '2026-05-20');
    expect(p.daysLeft, -12);
    expect(p.overdue, isTrue);
    expect(p.requiredPerMonthMinor, 80000);
  });

  test('deadline today', () {
    final p = _p(0, 1000, date: '2026-06-01');
    expect(p.daysLeft, 0);
    expect(p.overdue, isFalse);
    expect(p.requiredPerMonthMinor, 1000);
  });

  test('daysBetweenKeys is DST/leap safe', () {
    expect(daysBetweenKeys('2028-02-28', '2028-03-01'), 2);
    expect(daysBetweenKeys('2026-03-01', '2026-11-01'), 245);
  });
}
