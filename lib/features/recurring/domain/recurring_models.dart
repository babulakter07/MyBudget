/// Reminder lead-time choices offered by the UI (null = no reminder).
const recurringReminderChoices = <int?>[null, 0, 1, 2, 3, 7];

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.profileId,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.subCategoryId,
    this.costItemId,
    this.incomeSource,
    required this.amountMinor,
    required this.title,
    this.remarks,
    required this.frequency,
    required this.intervalCount,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.remindDaysBefore,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final String type;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final String? incomeSource;
  final int amountMinor;
  final String title;
  final String? remarks;
  final String frequency;
  final int intervalCount;
  final String startDate;
  final String? endDate;
  final String nextDueDate;
  final int? remindDaysBefore;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// All occurrences up to the end date were generated.
  bool get isCompleted =>
      endDate != null && nextDueDate.compareTo(endDate!) > 0;

  /// Next date a transaction will be generated; null when paused/ended.
  String? get nextDue => (isActive && !isCompleted) ? nextDueDate : null;
}

/// User-editable fields of a rule.
class RecurringInput {
  const RecurringInput({
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.subCategoryId,
    this.costItemId,
    this.incomeSource,
    required this.amountMinor,
    required this.title,
    this.remarks,
    required this.frequency,
    this.intervalCount = 1,
    required this.startDate,
    this.endDate,
    this.remindDaysBefore,
  });

  final String type;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final String? incomeSource;
  final int amountMinor;
  final String title;
  final String? remarks;
  final String frequency;
  final int intervalCount;
  final String startDate;
  final String? endDate;
  final int? remindDaysBefore;
}

class PostedOccurrence {
  const PostedOccurrence({
    required this.ruleId,
    required this.title,
    required this.date,
    required this.transactionId,
  });
  final int ruleId;
  final String title;
  final String date;
  final int transactionId;
}

class SkippedOccurrence {
  const SkippedOccurrence({
    required this.ruleId,
    required this.title,
    required this.date,
    required this.reason,
  });
  final int ruleId;
  final String title;
  final String date;
  final String reason;
}

class GenerationResult {
  const GenerationResult({
    this.posted = const [],
    this.skipped = const [],
    this.completedRuleIds = const [],
  });
  final List<PostedOccurrence> posted;
  final List<SkippedOccurrence> skipped;

  /// Rules auto-deactivated because their final occurrence was posted.
  final List<int> completedRuleIds;

  bool get isEmpty => posted.isEmpty && skipped.isEmpty;
}
