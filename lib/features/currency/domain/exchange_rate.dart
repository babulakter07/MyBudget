class ExchangeRate {
  const ExchangeRate({
    required this.id,
    required this.profileId,
    required this.currencyCode,
    required this.rateMicro,
    required this.isActive,
    required this.updatedAt,
  });

  final int id;
  final int profileId;

  /// 3 upper-case letters.
  final String currencyCode;

  /// Base major units per 1 foreign major unit, times 1,000,000.
  final int rateMicro;
  final bool isActive;
  final DateTime updatedAt;
}
