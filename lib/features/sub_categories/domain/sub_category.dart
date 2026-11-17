class SubCategory {
  const SubCategory({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final int categoryId;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Sub-category plus parent category info for list display.
class SubCategoryView {
  const SubCategoryView({
    required this.subCategory,
    required this.categoryName,
    required this.categoryActive,
  });

  final SubCategory subCategory;
  final String categoryName;
  final bool categoryActive;

  int get id => subCategory.id;
  String get name => subCategory.name;
  bool get isActive => subCategory.isActive;
  int get categoryId => subCategory.categoryId;
}

class SubCategoryFilter {
  const SubCategoryFilter({
    this.categoryId,
    this.search = '',
    this.includeInactive = false,
  });

  final int? categoryId;
  final String search;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is SubCategoryFilter &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.includeInactive == includeInactive;

  @override
  int get hashCode => Object.hash(categoryId, search, includeInactive);
}
