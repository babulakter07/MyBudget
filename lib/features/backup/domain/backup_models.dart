// Backup domain types (no Flutter, no Drift).

const String backupFormatName = 'mybudget-backup';

/// Format history: 1 = schema <= 3 tables; 2 = adds v4 tables/columns and the
/// optional `attachmentFiles` map (older files restore with defaults);
/// 3 = adds schema v5 multi-currency (`exchange_rates` table and the
/// `original_amount_minor`/`original_currency`/`rate_micro` transaction
/// columns; older files restore with an empty table and NULL columns).
const int backupFormatVersion = 3;

/// Origin of a backup file. Encoded in the file name prefix.
enum BackupKind {
  manual,
  auto,

  /// Created automatically right before a restore (an undo point).
  safety;

  static BackupKind? fromPrefix(String s) {
    for (final k in values) {
      if (k.name == s) return k;
    }
    return null;
  }
}

enum BackupFrequency {
  off,
  daily,
  weekly;

  String get label => switch (this) {
    BackupFrequency.off => 'Off',
    BackupFrequency.daily => 'Daily',
    BackupFrequency.weekly => 'Weekly',
  };

  static BackupFrequency parse(String? s) =>
      values.firstWhere((f) => f.name == s, orElse: () => BackupFrequency.off);
}

class BackupSettings {
  const BackupSettings({
    this.frequency = BackupFrequency.off,
    this.retention = defaultRetention,
    this.lastBackupAt,
    this.lastSuccess,
    this.lastMessage,
  });

  static const int minRetention = 3;
  static const int maxRetention = 30;
  static const int defaultRetention = 7;

  final BackupFrequency frequency;

  /// Number of automatic backups kept (3..30).
  final int retention;
  final DateTime? lastBackupAt;

  /// `null` when no automatic run has been recorded yet.
  final bool? lastSuccess;
  final String? lastMessage;
}

class BackupFileInfo {
  const BackupFileInfo({
    required this.path,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.sizeBytes,
  });
  final String path;
  final String name;
  final BackupKind kind;
  final DateTime createdAt;
  final int sizeBytes;

  /// Only manual/auto files may be deleted from the UI; safety files are
  /// pruned automatically.
  bool get deletable => kind != BackupKind.safety;
}

class BackupValidationResult {
  const BackupValidationResult({
    required this.errors,
    this.counts = const {},
    this.createdAt,
    this.schemaVersion,
  });

  /// Human-readable problems. Empty when the file is valid.
  final List<String> errors;

  /// Row count per table (only meaningful when valid).
  final Map<String, int> counts;
  final DateTime? createdAt;
  final int? schemaVersion;

  bool get isValid => errors.isEmpty;
}

class RestoreResult {
  const RestoreResult({
    required this.counts,
    required this.safetyBackupPath,
    required this.activeProfileCleared,
    this.photosRestored = 0,
    this.photosFailed = 0,
  });
  final Map<String, int> counts;
  final String safetyBackupPath;
  final bool activeProfileCleared;

  /// Receipt photos written back into the attachments directory.
  final int photosRestored;

  /// Photos that could not be written (the data itself is restored).
  final int photosFailed;
}

/// Result of an export: the JSON text plus photo statistics.
class BackupExport {
  const BackupExport({
    required this.json,
    this.photosEmbedded = 0,
    this.photosMissing = 0,
    this.photoBytes = 0,
  });
  final String json;
  final int photosEmbedded;

  /// Referenced photos whose file was not found (skipped, not an error).
  final int photosMissing;
  final int photoBytes;
}

/// Approximate size of the receipt photos a backup could embed.
class PhotoEstimate {
  const PhotoEstimate({
    required this.count,
    required this.bytes,
    required this.missing,
  });
  final int count;
  final int bytes;
  final int missing;

  /// Embedded as base64 (+~33%).
  int get approxBackupBytes => (bytes * 4 / 3).ceil();
}
