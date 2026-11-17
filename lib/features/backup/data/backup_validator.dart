import 'dart:convert';

import '../../../core/utils/date_keys.dart';
import '../domain/backup_models.dart';
import 'backup_schema.dart';

/// Highest database schema version this build can restore.
const int maxSupportedSchemaVersion = 3;

/// Pure validation of a backup file (no database access). Mirrors every
/// constraint the database enforces so a bad file is rejected *before* any
/// data is touched.
class BackupValidator {
  const BackupValidator({this.maxErrors = 40});

  final int maxErrors;

  BackupValidationResult validate(String json) {
    final errors = <String>[];
    var overflow = 0;
    void err(String m) {
      if (errors.length < maxErrors) {
        errors.add(m);
      } else {
        overflow++;
      }
    }

    BackupValidationResult finish({
      Map<String, int> counts = const {},
      DateTime? createdAt,
      int? schemaVersion,
    }) {
      if (overflow > 0) errors.add('...and $overflow more problem(s).');
      return BackupValidationResult(
        errors: errors,
        counts: errors.isEmpty ? counts : const {},
        createdAt: createdAt,
        schemaVersion: schemaVersion,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      err('The file is not valid JSON (${e.message}).');
      return finish();
    }
    if (decoded is! Map<String, dynamic>) {
      err('The file is not a MyBudget backup (top level is not an object).');
      return finish();
    }
    final root = decoded;

    if (root['format'] != backupFormatName) {
      err('This is not a MyBudget backup file (unknown format).');
      return finish();
    }
    final version = root['version'];
    if (version is! int) {
      err('Backup version is missing or not a number.');
      return finish();
    }
    if (version > backupFormatVersion) {
      err(
        'This backup was made by a newer version of the app '
        '(format version $version). Update the app to restore it.',
      );
      return finish();
    }
    if (version < 1) {
      err('Unsupported backup format version $version.');
      return finish();
    }
    final schemaVersion = root['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
      err('Backup schemaVersion is missing or invalid.');
      return finish();
    }
    if (schemaVersion > maxSupportedSchemaVersion) {
      err(
        'This backup uses database schema $schemaVersion, which is newer '
        'than this app supports ($maxSupportedSchemaVersion).',
      );
      return finish();
    }
    DateTime? createdAt;
    final createdRaw = root['createdAt'];
    if (createdRaw is String) createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) err('Backup createdAt is missing or invalid.');

    final tablesRaw = root['tables'];
    if (tablesRaw is! Map<String, dynamic>) {
      err('The backup has no "tables" section.');
      return finish(createdAt: createdAt, schemaVersion: schemaVersion);
    }

    // ---- Structure and field types -------------------------------------
    final rows = <String, List<Map<String, dynamic>>>{};
    var structureOk = true;
    for (final spec in backupTables) {
      final raw = tablesRaw[spec.name];
      if (raw == null) {
        err('Required table "${spec.name}" is missing.');
        structureOk = false;
        continue;
      }
      if (raw is! List) {
        err('Table "${spec.name}" must be a list of records.');
        structureOk = false;
        continue;
      }
      final valid = <Map<String, dynamic>>[];
      for (var i = 0; i < raw.length; i++) {
        final r = raw[i];
        final label = '${spec.name} record #${i + 1}';
        if (r is! Map<String, dynamic>) {
          err('$label is not an object.');
          structureOk = false;
          continue;
        }
        var ok = true;
        for (final c in spec.columns) {
          final v = r[c.name];
          if (v == null) {
            if (!c.nullable) {
              err('$label: "${c.name}" is required.');
              ok = false;
            }
            continue;
          }
          final typeOk = switch (c.kind) {
            ColKind.int_ => v is int,
            ColKind.text => v is String,
            ColKind.bool_ => v is bool,
            ColKind.dateTime => v is String && DateTime.tryParse(v) != null,
          };
          if (!typeOk) {
            err('$label: "${c.name}" has an invalid value.');
            ok = false;
          }
        }
        if (ok) {
          valid.add(r);
        } else {
          structureOk = false;
        }
      }
      rows[spec.name] = valid;
    }
    if (!structureOk) {
      return finish(createdAt: createdAt, schemaVersion: schemaVersion);
    }

    // ---- Duplicate ids ---------------------------------------------------
    final byId = <String, Map<int, Map<String, dynamic>>>{};
    for (final spec in backupTables) {
      if (spec.name == 'application_settings') continue;
      final map = <int, Map<String, dynamic>>{};
      for (final r in rows[spec.name]!) {
        final id = r['id'] as int;
        if (id <= 0) err('${spec.name}: id $id must be positive.');
        if (map.containsKey(id)) {
          err('${spec.name}: duplicate id $id.');
        } else {
          map[id] = r;
        }
      }
      byId[spec.name] = map;
    }
    final seenKeys = <String>{};
    for (final r in rows['application_settings']!) {
      final k = r['key'] as String;
      if (!seenKeys.add(k)) err('application_settings: duplicate key "$k".');
    }

    // ---- Reference helpers ----------------------------------------------
    // Verifies r[col] points to an existing row of [target] belonging to the
    // same profile as r. Returns the parent row (or null).
    Map<String, dynamic>? ref(
      String table,
      Map<String, dynamic> r,
      String col,
      String target, {
      bool profileScoped = true,
    }) {
      final v = r[col];
      if (v == null) return null;
      final parent = byId[target]![v as int];
      if (parent == null) {
        err('$table id ${r['id']}: $col $v does not exist in $target.');
        return null;
      }
      if (profileScoped && parent['profile_id'] != r['profile_id']) {
        err(
          '$table id ${r['id']}: $col $v belongs to a different profile '
          '(cross-profile reference).',
        );
        return null;
      }
      return parent;
    }

    void name(String table, Map<String, dynamic> r) {
      final n = r['name'] as String;
      if (n.isEmpty || n.length > 80) {
        err('$table id ${r['id']}: name must be 1-80 characters.');
      }
    }

    void unique(String table, Set<String> seen, String key, Object id) {
      if (!seen.add(key)) {
        err('$table id $id: duplicate name (names are unique, ignoring case).');
      }
    }

    // ---- Per-table rules -------------------------------------------------
    var seen = <String>{};
    for (final r in rows['financial_profiles']!) {
      name('financial_profiles', r);
      unique(
        'financial_profiles',
        seen,
        _nocase(r['name'] as String),
        r['id']!,
      );
    }

    seen = {};
    for (final r in rows['categories']!) {
      ref(
        'categories',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      name('categories', r);
      unique(
        'categories',
        seen,
        '${r['profile_id']}|${_nocase(r['name'] as String)}',
        r['id']!,
      );
    }

    seen = {};
    for (final r in rows['sub_categories']!) {
      ref(
        'sub_categories',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      ref('sub_categories', r, 'category_id', 'categories');
      name('sub_categories', r);
      unique(
        'sub_categories',
        seen,
        '${r['profile_id']}|${r['category_id']}|${_nocase(r['name'] as String)}',
        r['id']!,
      );
    }

    seen = {};
    for (final r in rows['cost_items']!) {
      ref(
        'cost_items',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      ref('cost_items', r, 'sub_category_id', 'sub_categories');
      name('cost_items', r);
      final d = r['default_amount_minor'];
      if (d is int && d < 0) {
        err('cost_items id ${r['id']}: default amount must not be negative.');
      }
      unique(
        'cost_items',
        seen,
        '${r['profile_id']}|${r['sub_category_id']}|${_nocase(r['name'] as String)}',
        r['id']!,
      );
    }

    seen = {};
    for (final r in rows['monthly_budgets']!) {
      ref(
        'monthly_budgets',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      final y = r['year'] as int, m = r['month'] as int;
      if (m < 1 || m > 12) {
        err('monthly_budgets id ${r['id']}: month $m is invalid.');
      }
      if (y < 1970 || y > 9999) {
        err('monthly_budgets id ${r['id']}: year $y is invalid.');
      }
      if ((r['total_budget_minor'] as int) < 0) {
        err('monthly_budgets id ${r['id']}: budget must not be negative.');
      }
      if (!seen.add('${r['profile_id']}|$y|$m')) {
        err(
          'monthly_budgets id ${r['id']}: more than one budget for $y-$m in the same profile.',
        );
      }
    }

    seen = {};
    for (final r in rows['category_budgets']!) {
      ref(
        'category_budgets',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      ref('category_budgets', r, 'monthly_budget_id', 'monthly_budgets');
      ref('category_budgets', r, 'category_id', 'categories');
      if ((r['amount_minor'] as int) < 0) {
        err('category_budgets id ${r['id']}: amount must not be negative.');
      }
      if (!seen.add('${r['monthly_budget_id']}|${r['category_id']}')) {
        err(
          'category_budgets id ${r['id']}: duplicate allocation for the same category and month.',
        );
      }
    }

    seen = {};
    const accountTypes = {
      'cash',
      'bank',
      'mobile',
      'savings',
      'credit_card',
      'other',
    };
    for (final r in rows['accounts']!) {
      ref(
        'accounts',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      name('accounts', r);
      if (!accountTypes.contains(r['type'])) {
        err('accounts id ${r['id']}: unknown account type "${r['type']}".');
      }
      if (!isValidDateKey(r['opening_date'] as String)) {
        err(
          'accounts id ${r['id']}: opening_date must be a valid yyyy-MM-dd date.',
        );
      }
      unique(
        'accounts',
        seen,
        '${r['profile_id']}|${_nocase(r['name'] as String)}',
        r['id']!,
      );
    }

    seen = {};
    const txnTypes = {'expense', 'income', 'transfer'};
    for (final r in rows['financial_transactions']!) {
      final id = r['id'];
      ref(
        'financial_transactions',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      final type = r['type'];
      if (!txnTypes.contains(type)) {
        err('financial_transactions id $id: unknown type "$type".');
      }
      if ((r['amount_minor'] as int) <= 0) {
        err('financial_transactions id $id: amount must be greater than zero.');
      }
      if (!isValidDateKey(r['txn_date'] as String)) {
        err(
          'financial_transactions id $id: txn_date must be a valid yyyy-MM-dd date.',
        );
      }
      ref('financial_transactions', r, 'account_id', 'accounts');
      ref('financial_transactions', r, 'to_account_id', 'accounts');
      ref('financial_transactions', r, 'category_id', 'categories');
      ref('financial_transactions', r, 'sub_category_id', 'sub_categories');
      ref('financial_transactions', r, 'cost_item_id', 'cost_items');
      if (type == 'transfer') {
        final to = r['to_account_id'];
        if (to == null) {
          err(
            'financial_transactions id $id: a transfer needs a destination account.',
          );
        } else if (to == r['account_id']) {
          err(
            'financial_transactions id $id: a transfer cannot go to the same account.',
          );
        }
      } else if (r['to_account_id'] != null) {
        err(
          'financial_transactions id $id: only transfers may have a destination account.',
        );
      }
      if (type == 'expense' && r['category_id'] == null) {
        err('financial_transactions id $id: an expense needs a category.');
      }
      final key = r['idempotency_key'];
      if (key is String && !seen.add('${r['profile_id']}|$key')) {
        err('financial_transactions id $id: duplicate idempotency key "$key".');
      }
    }

    const actions = {'create', 'update', 'delete', 'restore'};
    for (final r in rows['transaction_audit_logs']!) {
      ref(
        'transaction_audit_logs',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      ref(
        'transaction_audit_logs',
        r,
        'transaction_id',
        'financial_transactions',
      );
      if (!actions.contains(r['action'])) {
        err(
          'transaction_audit_logs id ${r['id']}: unknown action "${r['action']}".',
        );
      }
    }

    return finish(
      counts: {for (final s in backupTables) s.name: rows[s.name]!.length},
      createdAt: createdAt,
      schemaVersion: schemaVersion,
    );
  }

  /// Mirrors SQLite's NOCASE collation (ASCII-only case folding).
  static String _nocase(String s) =>
      s.replaceAllMapped(RegExp('[A-Z]'), (m) => m[0]!.toLowerCase());
}
