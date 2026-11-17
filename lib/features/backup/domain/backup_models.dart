// Backup domain types (no Flutter, no Drift).

const String backupFormatName = 'mybudget-backup';
const int backupFormatVersion = 1;

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
  });
  final Map<String, int> counts;
  final String safetyBackupPath;
  final bool activeProfileCleared;
}
