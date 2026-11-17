/// A financial profile (isolated budget workspace).
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
