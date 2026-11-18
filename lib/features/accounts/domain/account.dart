import '../../../l10n/generated/app_localizations.dart';

const accountTypes = [
  'cash',
  'bank',
  'mobile',
  'savings',
  'credit_card',
  'other',
];

/// Localized display label; the stored [type] value is unchanged.
String accountTypeLabel(AppLocalizations l, String type) => switch (type) {
  'cash' => l.accountsTypeCash,
  'bank' => l.accountsTypeBank,
  'mobile' => l.accountsTypeMobile,
  'savings' => l.accountsTypeSavings,
  'credit_card' => l.accountsTypeCreditCard,
  _ => l.accountsTypeOther,
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
