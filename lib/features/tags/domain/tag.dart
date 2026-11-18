class Tag {
  const Tag({
    required this.id,
    required this.profileId,
    required this.name,
    required this.color,
    required this.isActive,
    required this.createdAt,
  });
  final int id;
  final int profileId;
  final String name;

  /// ARGB int, or null for the default chip color.
  final int? color;
  final bool isActive;
  final DateTime createdAt;
}

/// Per-tag totals over a date range (non-deleted expense/income only).
class TagTotal {
  const TagTotal({
    required this.tagId,
    required this.name,
    required this.color,
    required this.expenseMinor,
    required this.incomeMinor,
    required this.count,
  });
  final int tagId;
  final String name;
  final int? color;
  final int expenseMinor;
  final int incomeMinor;
  final int count;
}

const tagNameMaxLength = 40;

/// Colors offered when creating/editing a tag.
const tagPalette = <int>[
  0xFF1B7F5C,
  0xFF1565C0,
  0xFF6A1B9A,
  0xFFC62828,
  0xFFEF6C00,
  0xFFF9A825,
  0xFF00838F,
  0xFF5D4037,
  0xFF546E7A,
];
