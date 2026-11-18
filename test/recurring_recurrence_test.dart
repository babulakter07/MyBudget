import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget/features/recurring/domain/recurrence.dart';

String _next(String start, String f, int n, String cur) =>
    nextDueKeyAfter(start, f, n, cur);

void main() {
  group('monthly next-date table', () {
    final cases = <(String, int, String, String)>[
      // start, interval, current, expected
      ('2026-01-31', 1, '2026-01-31', '2026-02-28'),
      ('2026-01-31', 1, '2026-02-28', '2026-03-31'),
      ('2026-01-31', 1, '2026-03-31', '2026-04-30'),
      ('2026-01-31', 1, '2026-04-30', '2026-05-31'),
      ('2028-01-31', 1, '2028-01-31', '2028-02-29'),
      ('2028-01-31', 1, '2028-02-29', '2028-03-31'),
      ('2026-01-30', 1, '2026-01-30', '2026-02-28'),
      ('2026-01-15', 1, '2026-01-15', '2026-02-15'),
      ('2026-12-15', 1, '2026-12-15', '2027-01-15'),
      ('2026-01-31', 2, '2026-01-31', '2026-03-31'),
      ('2026-01-31', 3, '2026-01-31', '2026-04-30'),
      ('2026-01-31', 12, '2026-01-31', '2027-01-31'),
      ('2026-11-30', 3, '2026-11-30', '2027-02-28'),
    ];
    for (final c in cases) {
      test('${c.$1} every ${c.$2}m after ${c.$3} -> ${c.$4}', () {
        expect(_next(c.$1, 'monthly', c.$2, c.$3), c.$4);
      });
    }
  });

  group('yearly', () {
    test('Feb 29 -> Feb 28 -> Feb 29 on next leap year', () {
      expect(_next('2024-02-29', 'yearly', 1, '2024-02-29'), '2025-02-28');
      expect(_next('2024-02-29', 'yearly', 1, '2025-02-28'), '2026-02-28');
      expect(_next('2024-02-29', 'yearly', 1, '2027-02-28'), '2028-02-29');
    });
    test('interval 4 from Feb 29 hits leap years', () {
      expect(_next('2024-02-29', 'yearly', 4, '2024-02-29'), '2028-02-29');
    });
    test('interval 2', () {
      expect(_next('2026-06-10', 'yearly', 2, '2026-06-10'), '2028-06-10');
    });
  });

  group('daily / weekly', () {
    test('daily across month and year end', () {
      expect(_next('2026-12-30', 'daily', 1, '2026-12-30'), '2026-12-31');
      expect(_next('2026-12-30', 'daily', 1, '2026-12-31'), '2027-01-01');
      expect(_next('2028-02-28', 'daily', 1, '2028-02-28'), '2028-02-29');
      expect(_next('2027-02-28', 'daily', 1, '2027-02-28'), '2027-03-01');
    });
    test('daily interval 10', () {
      expect(_next('2026-01-01', 'daily', 10, '2026-01-01'), '2026-01-11');
    });
    test('weekly and bi-weekly', () {
      expect(_next('2026-01-01', 'weekly', 1, '2026-01-01'), '2026-01-08');
      expect(_next('2026-01-01', 'weekly', 2, '2026-01-01'), '2026-01-15');
      expect(_next('2026-12-28', 'weekly', 1, '2026-12-28'), '2027-01-04');
    });
  });

  group('anchor + helpers', () {
    test('long monthly run never drifts from the anchor day', () {
      var cur = '2026-01-31';
      final seen = <String>[];
      for (var i = 0; i < 12; i++) {
        cur = _next('2026-01-31', 'monthly', 1, cur);
        seen.add(cur);
      }
      expect(seen.first, '2026-02-28');
      expect(seen[1], '2026-03-31');
      expect(seen.last, '2027-01-31');
    });
    test('next after a non-occurrence date snaps to the next occurrence', () {
      expect(_next('2026-01-31', 'monthly', 1, '2026-03-05'), '2026-03-31');
      expect(_next('2026-01-01', 'weekly', 1, '2026-01-03'), '2026-01-08');
    });
    test('next after a date before start is the start itself', () {
      expect(_next('2026-05-10', 'monthly', 1, '2026-01-01'), '2026-05-10');
    });
    test('firstDueKeyOnOrAfter', () {
      expect(
        firstDueKeyOnOrAfter('2026-01-31', 'monthly', 1, '2026-02-28'),
        '2026-02-28',
      );
      expect(
        firstDueKeyOnOrAfter('2026-01-31', 'monthly', 1, '2026-03-01'),
        '2026-03-31',
      );
      expect(
        firstDueKeyOnOrAfter('2026-01-01', 'daily', 3, '2026-01-02'),
        '2026-01-04',
      );
      expect(
        firstDueKeyOnOrAfter('2026-05-10', 'weekly', 1, '2026-01-01'),
        '2026-05-10',
      );
    });
    test('far-future estimate is exact', () {
      expect(_next('2000-01-31', 'monthly', 1, '2050-02-28'), '2050-03-31');
      expect(_next('2000-01-01', 'daily', 1, '2050-01-01'), '2050-01-02');
    });
    test('invalid args', () {
      expect(
        () => occurrenceAt(DateTime(2026), 'monthly', 0, 1),
        throwsArgumentError,
      );
      expect(
        () => occurrenceAt(DateTime(2026), 'hourly', 1, 1),
        throwsArgumentError,
      );
    });
  });
}
