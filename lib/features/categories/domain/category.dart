class Category {
  const Category({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String name;
  final String? description;

  /// Key from the curated icon set (see category_visuals.dart).
  final String? icon;

  /// ARGB color value.
  final int? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
