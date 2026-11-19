import '../../../core/utils/date_keys.dart';
import 'credit_card.dart';

/// Credit card billing policy (pure Dart, no Flutter/Drift; every function
/// takes the evaluation date `asOf` so it is fully testable).
///
/// All amounts are integer minor units; no floating point is used. Rates are
/// basis points (1 bp = 0.01 %).
///
/// BILL: one row per statement month holding the NEW charges of that cycle
/// (never the unpaid balance of earlier bills; those stay on their own bill
/// and keep accruing their own interest).
///
/// DATES: statement date = the card's statement day in the bill month; due
/// date = statement date + `dueDays`.
///
/// MINIMUM PAYMENT = min(bill, max(floor, bill * minPaymentBp / 10000)),
/// rounded half up. It is stored on the bill and can be edited.
///
/// PAYMENTS: all non-voided payments dated on/before `asOf` reduce the bill
/// principal. `paidByDue` = payments dated on/before the due date.
///
/// LATE FEE: charged once, only after the due date has passed (asOf > due),
/// when `paidByDue < minimum`: fee = max(lateFeeFloor,
/// round(lateFeeBp% * (minimum - paidByDue))). Otherwise 0.
///
/// INTEREST: simple (not compounded), daily rate = APR / 365, on the unpaid
/// bill principal only. None when the bill is fully paid by the due date.
/// Otherwise accrual starts after `start`, where start = statement date if the
/// card is set to "interest from statement" (the grace period is lost), else
/// the due date. Each day d in (start, asOf] is charged on
/// `amount - payments dated before d`; accrual stops once the principal is 0.
/// Interest is only charged once the due date has passed (before that the
/// grace period is still open, even with "interest from statement").
///
/// TOTALS: totalPayable = amount + interest + lateFee;
/// remaining = max(0, totalPayable - paid).
///
/// STATUS: paid (remaining = 0) | before the due date: partial (paid > 0) or
/// unpaid | after the due date: minPaid (paidByDue >= minimum, balance left)
/// or overdue (minimum not paid by the due date).

const int _bpScale = 10000;

/// 'yyyy-MM-dd' for [days] after [key] (negative allowed).
String addDaysKey(String key, int days) {
  final d = parseDateKey(key);
  return dateKey(DateTime(d.year, d.month, d.day + days));
}

/// Whole days from [from] to [to] (to - from), DST-safe.
int daysBetween(String from, String to) {
  final a = parseDateKey(from);
  final b = parseDateKey(to);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Statement date of [billMonth] ('yyyy-MM') for a card.
String statementDateFor(String billMonth, int statementDay) {
  final y = int.parse(billMonth.substring(0, 4));
  final m = int.parse(billMonth.substring(5, 7));
  return dateKey(DateTime(y, m, statementDay));
}

String dueDateFor(String statementDate, int dueDays) =>
    addDaysKey(statementDate, dueDays);

/// Rounded half-up `amount * bp / 10000`.
int percentOf(int amountMinor, int bp) =>
    (amountMinor * bp + _bpScale ~/ 2) ~/ _bpScale;

/// min(bill, max(floor, bill * pct)).
int minimumPayment({
  required int billMinor,
  required int minPaymentBp,
  required int floorMinor,
}) {
  final pct = percentOf(billMinor, minPaymentBp);
  final m = pct > floorMinor ? pct : floorMinor;
  return m > billMinor ? billMinor : m;
}

/// Parses "12", "12.5" or "12.50" into basis points (0..10000 allowed by the
/// caller); null when malformed or more than 2 decimals.
int? parsePercentToBp(String input) {
  final s = input.trim().replaceAll('%', '').trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > 100000) return null;
  final frac = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
  return whole * 100 + int.parse(frac);
}

/// 1250 -> "12.5%", 1200 -> "12%", 1225 -> "12.25%".
String formatBp(int bp) {
  final whole = bp ~/ 100;
  final frac = bp % 100;
  if (frac == 0) return '$whole%';
  final f = frac.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
  return '$whole.$f%';
}

/// 1250 -> "12.5" (for editing in a text field).
String bpToInput(int bp) => formatBp(bp).replaceAll('%', '');

int _paidOn(Iterable<CardPayment> payments, String lastDate) {
  var sum = 0;
  for (final p in payments) {
    if (!p.isDeleted && p.paymentDate.compareTo(lastDate) <= 0) {
      sum += p.amountMinor;
    }
  }
  return sum;
}

/// Late fee as of [asOf] (see the policy above).
int lateFeeAsOf({
  required CreditCard card,
  required CreditCardBill bill,
  required List<CardPayment> payments,
  required String asOf,
}) {
  if (asOf.compareTo(bill.dueDate) <= 0) return 0;
  final paidByDue = _paidOn(payments, bill.dueDate);
  final shortfall = bill.minPaymentMinor - paidByDue;
  if (shortfall <= 0) return 0;
  final pct = percentOf(shortfall, card.lateFeeBp);
  return pct > card.lateFeeFloorMinor ? pct : card.lateFeeFloorMinor;
}

/// Interest accrued as of [asOf] (see the policy above).
int interestAsOf({
  required CreditCard card,
  required CreditCardBill bill,
  required List<CardPayment> payments,
  required String asOf,
}) {
  if (card.aprBp == 0) return 0;
  if (asOf.compareTo(bill.dueDate) <= 0) return 0;
  if (_paidOn(payments, bill.dueDate) >= bill.amountMinor) return 0;
  final start = card.interestFromStatement ? bill.statementDate : bill.dueDate;
  final days = daysBetween(start, asOf);
  if (days <= 0) return 0;

  final active =
      payments
          .where((p) => !p.isDeleted && p.paymentDate.compareTo(asOf) < 0)
          .toList()
        ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
  var idx = 0;
  var paid = 0;
  var numerator = 0; // sum(balance * aprBp) over the charged days
  for (var i = 1; i <= days; i++) {
    final day = addDaysKey(start, i);
    // payments dated strictly before this day have reduced the balance
    while (idx < active.length && active[idx].paymentDate.compareTo(day) < 0) {
      paid += active[idx].amountMinor;
      idx++;
    }
    final balance = bill.amountMinor - paid;
    if (balance <= 0) break;
    numerator += balance * card.aprBp;
  }
  // Round half up once at the end: numerator / (10000 * 365).
  const denom = _bpScale * 365;
  return (numerator + denom ~/ 2) ~/ denom;
}

/// Everything derived for [bill] as of [asOf].
BillStatement computeStatement({
  required CreditCard card,
  required CreditCardBill bill,
  required List<CardPayment> payments,
  required String asOf,
}) {
  final paid = _paidOn(payments, asOf);
  final interest = interestAsOf(
    card: card,
    bill: bill,
    payments: payments,
    asOf: asOf,
  );
  final fee = lateFeeAsOf(
    card: card,
    bill: bill,
    payments: payments,
    asOf: asOf,
  );
  final payable = bill.amountMinor + interest + fee;
  final remaining = payable - paid;
  final pastDue = asOf.compareTo(bill.dueDate) > 0;
  final paidByDue = _paidOn(payments, bill.dueDate);

  final BillStatus status;
  if (remaining <= 0) {
    status = BillStatus.paid;
  } else if (!pastDue) {
    status = paid > 0 ? BillStatus.partial : BillStatus.unpaid;
  } else {
    status = paidByDue >= bill.minPaymentMinor
        ? BillStatus.minPaid
        : BillStatus.overdue;
  }

  final charges = interest + fee;
  var effective = 0;
  if (charges > 0) {
    final start = card.interestFromStatement
        ? bill.statementDate
        : bill.dueDate;
    final d = daysBetween(start, asOf);
    if (d > 0) {
      final den = bill.amountMinor * d;
      effective = (charges * _bpScale * 365 + den ~/ 2) ~/ den;
    }
  }
  return BillStatement(
    bill: bill,
    asOf: asOf,
    paidMinor: paid,
    interestMinor: interest,
    lateFeeMinor: fee,
    status: status,
    daysOverdue: pastDue && remaining > 0 ? daysBetween(bill.dueDate, asOf) : 0,
    effectiveAnnualBp: effective,
  );
}

/// Charges expected [horizonDays] after the later of [asOf] and the due date
/// if nothing more is paid, and if only the missing minimum is paid on
/// [asOf]. Hypothetical payments are never stored.
BillProjection projectCharges({
  required CreditCard card,
  required CreditCardBill bill,
  required List<CardPayment> payments,
  required String asOf,
  int horizonDays = 30,
}) {
  final base = asOf.compareTo(bill.dueDate) > 0 ? asOf : bill.dueDate;
  final horizon = addDaysKey(base, horizonDays);
  final current = computeStatement(
    card: card,
    bill: bill,
    payments: payments,
    asOf: asOf,
  );
  final minNeeded = current.minDueRemainingMinor;

  int chargesAt(List<CardPayment> ps) => computeStatement(
    card: card,
    bill: bill,
    payments: ps,
    asOf: horizon,
  ).totalChargesMinor;

  final withMin = <CardPayment>[
    ...payments,
    if (minNeeded > 0)
      CardPayment(
        id: -1,
        profileId: bill.profileId,
        billId: bill.id,
        amountMinor: minNeeded,
        paymentDate: asOf,
        note: null,
        isDeleted: false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
  ];
  return BillProjection(
    horizon: horizon,
    chargesIfNothingMinor: chargesAt(payments),
    chargesIfMinimumMinor: chargesAt(withMin),
    minimumMinor: minNeeded,
  );
}
