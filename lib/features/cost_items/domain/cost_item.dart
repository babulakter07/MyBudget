class CostItem {
  const CostItem({
    required this.id,
    required this.profileId,
    required this.subCategoryId,
    required this.name,
    this.description,
    this.defaultAmountMinor,
    required this.isActive,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final int subCategoryId;
  final String name;
  final String? description;
  final int? defaultAmountMinor;
  final bool isActive;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Cost item joined with its sub-category and category names.
class CostItemView {
  const CostItemView({
    required this.item,
    required this.subCategoryName,
    required this.categoryId,
    required this.categoryName,
  });

  final CostItem item;
  final String subCategoryName;
  final int categoryId;
  final String categoryName;
}

class CostItemFilter {
  const CostItemFilter({
    this.categoryId,
    this.subCategoryId,
    this.search = '',
    this.includeInactive = false,
  });

  final int? categoryId;
  final int? subCategoryId;
  final String search;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is CostItemFilter &&
      other.categoryId == categoryId &&
      other.subCategoryId == subCategoryId &&
      other.search == search &&
      other.includeInactive == includeInactive;

  @override
  int get hashCode =>
      Object.hash(categoryId, subCategoryId, search, includeInactive);
}
