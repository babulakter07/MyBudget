const accountTypes = [
  'cash',
  'bank',
  'mobile',
  'savings',
  'credit_card',
  'other',
];

String accountTypeLabel(String type) => switch (type) {
  'cash' => 'Cash',
  'bank' => 'Bank',
  'mobile' => 'Mobile banking',
  'savings' => 'Savings account',
  'credit_card' => 'Credit card',
  _ => 'Other',
};

class Account {
  const Account({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.openingDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String name;

  /// cash | bank | mobile | other
  final String type;
  final int openingBalanceMinor;

  /// 'yyyy-MM-dd'
  final String openingDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// An account with its balance computed at query time (never stored).
/// balance = opening + income - expense + transfersIn - transfersOut over
/// non-deleted transactions dated on/after the opening date.
class AccountBalance {
  const AccountBalance({required this.account, required this.balanceMinor});
  final Account account;
  final int balanceMinor;
}
