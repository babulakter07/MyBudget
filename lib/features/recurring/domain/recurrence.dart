import '../../../core/utils/date_keys.dart';

/// Allowed values of `recurring_rules.frequency`.
class RecurrenceFrequency {
  RecurrenceFrequency._();
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const yearly = 'yearly';
  static const all = [daily, weekly, monthly, yearly];

  static String label(String f) => switch (f) {
    daily => 'Daily',
    weekly => 'Weekly',
    monthly => 'Monthly',
    yearly => 'Yearly',
    _ => f,
  };
}

/// Pure date arithmetic for recurring rules (no DB, no Flutter).
///
/// Occurrence n (n >= 0) of a rule is always computed from the ANCHOR
/// [start], never from the previous occurrence, so clamping never drifts:
/// monthly from Jan 31 gives Jan 31, Feb 28/29, Mar 31, Apr 30, ...
DateTime occurrenceAt(DateTime start, String frequency, int interval, int n) {
  if (interval < 1) throw ArgumentError('interval must be >= 1');
  if (n < 0) throw ArgumentError('n must be >= 0');
  final s = DateTime(start.year, start.month, start.day);
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return DateTime(s.year, s.month, s.day + n * interval);
    case RecurrenceFrequency.weekly:
      return DateTime(s.year, s.month, s.day + 7 * n * interval);
    case RecurrenceFrequency.monthly:
      return _addMonthsClamped(s, n * interval);
    case RecurrenceFrequency.yearly:
      return _addMonthsClamped(s, 12 * n * interval);
    default:
      throw ArgumentError('Unknown frequency: $frequency');
  }
}

DateTime _addMonthsClamped(DateTime anchor, int months) {
  final total = anchor.year * 12 + (anchor.month - 1) + months;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  final dim = daysInMonth(y, m);
  return DateTime(y, m, anchor.day <= dim ? anchor.day : dim);
}

/// Conservative index estimate for [d] (at or below the true index).
int _estimateIndex(DateTime start, String frequency, int interval, DateTime d) {
  int est;
  switch (frequency) {
    case RecurrenceFrequency.daily:
      est = _dayDiff(start, d) ~/ interval;
    case RecurrenceFrequency.weekly:
      est = _dayDiff(start, d) ~/ (7 * interval);
    case RecurrenceFrequency.monthly:
      est = ((d.year - start.year) * 12 + d.month - start.month) ~/ interval;
    case RecurrenceFrequency.yearly:
      est = (d.year - start.year) ~/ interval;
    default:
      throw ArgumentError('Unknown frequency: $frequency');
  }
  return est < 1 ? 0 : est - 1;
}

int _dayDiff(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Smallest occurrence strictly after [current] (current need not itself be
/// an occurrence). Never earlier than [start].
DateTime nextOccurrenceAfter(
  DateTime start,
  String frequency,
  int interval,
  DateTime current,
) {
  final c = DateTime(current.year, current.month, current.day);
  var n = _estimateIndex(start, frequency, interval, c);
  while (!occurrenceAt(start, frequency, interval, n).isAfter(c)) {
    n++;
  }
  return occurrenceAt(start, frequency, interval, n);
}

/// Smallest occurrence on or after [date].
DateTime firstOccurrenceOnOrAfter(
  DateTime start,
  String frequency,
  int interval,
  DateTime date,
) {
  final d = DateTime(date.year, date.month, date.day);
  var n = _estimateIndex(start, frequency, interval, d);
  while (occurrenceAt(start, frequency, interval, n).isBefore(d)) {
    n++;
  }
  return occurrenceAt(start, frequency, interval, n);
}

/// 'yyyy-MM-dd' wrapper around [nextOccurrenceAfter].
String nextDueKeyAfter(
  String startKey,
  String frequency,
  int interval,
  String currentKey,
) => dateKey(
  nextOccurrenceAfter(
    parseDateKey(startKey),
    frequency,
    interval,
    parseDateKey(currentKey),
  ),
);

/// 'yyyy-MM-dd' wrapper around [firstOccurrenceOnOrAfter].
String firstDueKeyOnOrAfter(
  String startKey,
  String frequency,
  int interval,
  String date,
) => dateKey(
  firstOccurrenceOnOrAfter(
    parseDateKey(startKey),
    frequency,
    interval,
    parseDateKey(date),
  ),
);
