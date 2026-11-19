import '../../accounts/domain/account.dart';
import '../../../core/utils/date_keys.dart';

/// An account with its current balance and this month's movements.
class WalletItem {
  const WalletItem({
    required this.account,
    required this.balanceMinor,
    required this.monthInMinor,
    required this.monthOutMinor,
  });

  final Account account;
  final int balanceMinor;

  /// Income + transfers in, dated in the current month.
  final int monthInMinor;

  /// Expense + transfers out, dated in the current month.
  final int monthOutMinor;
}

/// Wallets of one account type with their subtotal.
class WalletGroup {
  const WalletGroup({required this.type, required this.items});

  final String type;
  final List<WalletItem> items;

  int get subtotalMinor => items.fold(0, (s, i) => s + i.balanceMinor);
}

/// Display order of the groups.
const walletTypeOrder = [
  'cash',
  'bank',
  'mobile',
  'savings',
  'credit_card',
  'other',
];

/// Account types that count towards the total balance.
bool countsInTotal(String type) => type != 'credit_card';

/// Overview of all wallets (groups in [walletTypeOrder], empty groups omitted).
class WalletOverview {
  const WalletOverview(this.groups);

  static const empty = WalletOverview([]);

  final List<WalletGroup> groups;

  bool get isEmpty => groups.isEmpty;

  /// Sum of cash/bank/mobile/savings/other; credit-card accounts excluded.
  int get totalMinor => groups
      .where((g) => countsInTotal(g.type))
      .fold(0, (s, g) => s + g.subtotalMinor);

  factory WalletOverview.fromItems(List<WalletItem> items) {
    final groups = <WalletGroup>[];
    for (final type in walletTypeOrder) {
      final list = items.where((i) => i.account.type == type).toList();
      if (list.isNotEmpty) groups.add(WalletGroup(type: type, items: list));
    }
    return WalletOverview(groups);
  }
}

/// Period choices of the wallet ledger.
enum WalletPeriod { thisMonth, last3Months, thisYear, all }

/// Inclusive 'yyyy-MM-dd' range of [period] relative to [now]; null = open.
({String? from, String? to}) walletPeriodRange(
  WalletPeriod period,
  DateTime now,
) {
  switch (period) {
    case WalletPeriod.thisMonth:
      return (
        from: monthStartKey(now.year, now.month),
        to: monthEndKey(now.year, now.month),
      );
    case WalletPeriod.last3Months:
      final start = DateTime(now.year, now.month - 2, 1);
      return (
        from: monthStartKey(start.year, start.month),
        to: monthEndKey(now.year, now.month),
      );
    case WalletPeriod.thisYear:
      return (from: '${now.year}-01-01', to: '${now.year}-12-31');
    case WalletPeriod.all:
      return (from: null, to: null);
  }
}
