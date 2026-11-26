/// Where an upcoming payment comes from.
enum UpcomingKind { loan, card, debt, recurring, dps }

/// One unpaid amount on one date, as read from a feature.
class DueEntry {
  const DueEntry({
    required this.kind,
    required this.entityId,
    required this.name,
    required this.amountMinor,
    required this.dueDate,
    this.billId,
    this.graceEnd,
  });

  final UpcomingKind kind;

  /// Loan, card, debt, recurring-rule or DPS id.
  final int entityId;
  final String name;
  final int amountMinor;

  /// 'yyyy-MM-dd'.
  final String dueDate;

  /// Set for credit-card bills only; each bill stays a separate row.
  final int? billId;

  /// Last day it can be paid without being late, when later than [dueDate].
  final String? graceEnd;

  bool isOverdueOn(String today) => (graceEnd ?? dueDate).compareTo(today) < 0;
}

/// One row of the card: the overdue (or the still coming) entries of a single
/// loan, card bill, debt or recurring rule added together.
class UpcomingPayment {
  const UpcomingPayment({
    required this.kind,
    required this.entityId,
    required this.name,
    required this.amountMinor,
    required this.dueDate,
    required this.count,
    required this.overdue,
    this.billId,
  });

  final UpcomingKind kind;
  final int entityId;
  final String name;
  final int amountMinor;

  /// Earliest date among the combined entries.
  final String dueDate;
  final int count;
  final bool overdue;
  final int? billId;

  /// Screen where this payment can be recorded or reviewed.
  String get route => switch (kind) {
    UpcomingKind.loan => '/loans/$entityId',
    UpcomingKind.card => '/cards/$entityId/bills/$billId',
    UpcomingKind.debt => '/debts/$entityId',
    UpcomingKind.recurring => '/config/recurring',
    UpcomingKind.dps => '/dps/$entityId',
  };
}

/// Everything overdue plus everything due from [today] to [lastDay]
/// (both inclusive), grouped, overdue first and then by date.
List<UpcomingPayment> groupUpcoming(
  Iterable<DueEntry> entries, {
  required String today,
  required String lastDay,
}) {
  final groups = <String, List<DueEntry>>{};
  for (final e in entries) {
    if (e.amountMinor <= 0 || e.dueDate.compareTo(lastDay) > 0) continue;
    final overdue = e.isOverdueOn(today);
    groups
        .putIfAbsent(
          '${e.kind.name}|${e.entityId}|${e.billId}|$overdue',
          () => [],
        )
        .add(e);
  }
  final out = [
    for (final g in groups.values)
      UpcomingPayment(
        kind: g.first.kind,
        entityId: g.first.entityId,
        billId: g.first.billId,
        name: g.first.name,
        amountMinor: g.fold(0, (sum, e) => sum + e.amountMinor),
        dueDate: g
            .map((e) => e.dueDate)
            .reduce((a, b) => a.compareTo(b) <= 0 ? a : b),
        count: g.length,
        overdue: g.first.isOverdueOn(today),
      ),
  ];
  out.sort((a, b) {
    if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
    final byDate = a.dueDate.compareTo(b.dueDate);
    return byDate != 0 ? byDate : a.name.compareTo(b.name);
  });
  return out;
}
