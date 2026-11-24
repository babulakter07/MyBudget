import 'dart:convert';

import '../../../core/utils/currency.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/backup_models.dart';
import 'backup_paths.dart';
import 'backup_schema.dart';

/// Highest database schema version this build can restore.
const int maxSupportedSchemaVersion = 7;

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
      if (raw == null && spec.optional) {
        // Older backup (before schema v4): the table did not exist.
        rows[spec.name] = const [];
        continue;
      }
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
            if (!c.nullable && c.defaultValue == null) {
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
      if (!spec.hasId) continue;
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
    final codeRe = RegExp(r'^[A-Z]{3}$');
    for (final r in rows['exchange_rates']!) {
      final id = r['id'];
      ref(
        'exchange_rates',
        r,
        'profile_id',
        'financial_profiles',
        profileScoped: false,
      );
      final code = r['currency_code'] as String;
      if (!codeRe.hasMatch(code)) {
        err(
          'exchange_rates id $id: currency code "$code" must be 3 upper-case letters.',
        );
      }
      if ((r['rate_micro'] as int) <= 0) {
        err('exchange_rates id $id: rate must be greater than zero.');
      }
      if (!seen.add('${r['profile_id']}|$code')) {
        err(
          'exchange_rates id $id: duplicate rate for $code in the same profile.',
        );
      }
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
      _checkOriginal(r, type, byId['financial_profiles']!, err);
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

    // ---- v4 tables -------------------------------------------------------
    final dateRe = isValidDateKey;
    void profileRef(String table, Map<String, dynamic> r) =>
        ref(table, r, 'profile_id', 'financial_profiles', profileScoped: false);

    const frequencies = {'daily', 'weekly', 'monthly', 'yearly'};
    for (final r in rows['recurring_rules']!) {
      final id = r['id'];
      profileRef('recurring_rules', r);
      final type = r['type'];
      if (!txnTypes.contains(type)) {
        err('recurring_rules id $id: unknown type "$type".');
      }
      if (!frequencies.contains(r['frequency'])) {
        err('recurring_rules id $id: unknown frequency "${r['frequency']}".');
      }
      if ((r['amount_minor'] as int) <= 0) {
        err('recurring_rules id $id: amount must be greater than zero.');
      }
      if ((r['interval_count'] as int) < 1) {
        err('recurring_rules id $id: interval must be at least 1.');
      }
      for (final k in ['start_date', 'next_due_date']) {
        if (!dateRe(r[k] as String)) {
          err('recurring_rules id $id: $k must be a valid yyyy-MM-dd date.');
        }
      }
      final end = r['end_date'];
      if (end != null && !dateRe(end as String)) {
        err(
          'recurring_rules id $id: end_date must be a valid yyyy-MM-dd date.',
        );
      }
      final remind = r['remind_days_before'];
      if (remind is int && remind < 0) {
        err('recurring_rules id $id: reminder days must not be negative.');
      }
      if ((r['title'] as String).isEmpty) {
        err('recurring_rules id $id: title is required.');
      }
      ref('recurring_rules', r, 'account_id', 'accounts');
      ref('recurring_rules', r, 'to_account_id', 'accounts');
      ref('recurring_rules', r, 'category_id', 'categories');
      ref('recurring_rules', r, 'sub_category_id', 'sub_categories');
      ref('recurring_rules', r, 'cost_item_id', 'cost_items');
      if (type == 'transfer') {
        final to = r['to_account_id'];
        if (to == null || to == r['account_id']) {
          err(
            'recurring_rules id $id: a transfer needs a different destination account.',
          );
        }
      } else if (r['to_account_id'] != null) {
        err(
          'recurring_rules id $id: only transfers may have a destination account.',
        );
      }
      if (type == 'expense' && r['category_id'] == null) {
        err('recurring_rules id $id: an expense needs a category.');
      }
    }

    seen = {};
    for (final r in rows['savings_goals']!) {
      profileRef('savings_goals', r);
      name('savings_goals', r);
      ref('savings_goals', r, 'account_id', 'accounts');
      if ((r['target_minor'] as int) <= 0) {
        err('savings_goals id ${r['id']}: target must be greater than zero.');
      }
      final td = r['target_date'];
      if (td != null && !dateRe(td as String)) {
        err(
          'savings_goals id ${r['id']}: target_date must be a valid yyyy-MM-dd date.',
        );
      }
      unique(
        'savings_goals',
        seen,
        '${r['profile_id']}|${_nocase(r['name'] as String)}',
        r['id']!,
      );
    }

    for (final r in rows['debts']!) {
      profileRef('debts', r);
      final pn = r['person_name'] as String;
      if (pn.isEmpty || pn.length > 80) {
        err('debts id ${r['id']}: person name must be 1-80 characters.');
      }
      if (!{'lent', 'borrowed'}.contains(r['direction'])) {
        err('debts id ${r['id']}: unknown direction "${r['direction']}".');
      }
      if ((r['principal_minor'] as int) <= 0) {
        err('debts id ${r['id']}: principal must be greater than zero.');
      }
      if (!dateRe(r['start_date'] as String)) {
        err('debts id ${r['id']}: start_date must be a valid yyyy-MM-dd date.');
      }
      final dd = r['due_date'];
      if (dd != null && !dateRe(dd as String)) {
        err('debts id ${r['id']}: due_date must be a valid yyyy-MM-dd date.');
      }
    }

    for (final r in rows['debt_payments']!) {
      profileRef('debt_payments', r);
      ref('debt_payments', r, 'debt_id', 'debts');
      if ((r['amount_minor'] as int) <= 0) {
        err('debt_payments id ${r['id']}: amount must be greater than zero.');
      }
      if (!dateRe(r['payment_date'] as String)) {
        err(
          'debt_payments id ${r['id']}: payment_date must be a valid yyyy-MM-dd date.',
        );
      }
    }

    for (final r in rows['loans']!) {
      profileRef('loans', r);
      final id = r['id'];
      final lender = r['lender_name'] as String;
      if (lender.isEmpty || lender.length > 80) {
        err('loans id $id: lender name must be 1-80 characters.');
      }
      if (!{
        'personal',
        'home',
        'vehicle',
        'education',
        'business',
        'other',
      }.contains(r['loan_type'])) {
        err('loans id $id: unknown loan type "${r['loan_type']}".');
      }
      if (!{'reducing', 'flat'}.contains(r['interest_method'])) {
        err('loans id $id: unknown interest method "${r['interest_method']}".');
      }
      if (!{'weekly', 'monthly', 'yearly'}.contains(r['frequency'])) {
        err('loans id $id: unknown frequency "${r['frequency']}".');
      }
      if ((r['principal_minor'] as int) <= 0) {
        err('loans id $id: principal must be greater than zero.');
      }
      final rate = r['interest_rate_bp'] as int;
      if (rate < 0 || rate > 10000) {
        err('loans id $id: interest rate must be between 0% and 100%.');
      }
      final tenure = r['tenure_count'] as int;
      if (tenure < 1 || tenure > 1200) {
        err('loans id $id: tenure must be between 1 and 1200 installments.');
      }
      if ((r['installment_minor'] as int) <= 0) {
        err('loans id $id: installment must be greater than zero.');
      }
      if ((r['processing_fee_minor'] as int) < 0) {
        err('loans id $id: processing fee must not be negative.');
      }
      if (!dateRe(r['start_date'] as String)) {
        err('loans id $id: start_date must be a valid yyyy-MM-dd date.');
      }
      if (!dateRe(r['first_due_date'] as String)) {
        err('loans id $id: first_due_date must be a valid yyyy-MM-dd date.');
      }
      final closing = r['closing_type'];
      if (closing != null && !{'early', 'adjusted'}.contains(closing)) {
        err('loans id $id: unknown closing type "$closing".');
      }
      if (closing != null &&
          (r['closed_date'] == null || !dateRe(r['closed_date'] as String))) {
        err('loans id $id: a closed loan needs a valid closed_date.');
      }
      final paid = r['closing_paid_minor'];
      if (paid != null && (paid as int) < 0) {
        err('loans id $id: closing paid amount must not be negative.');
      }
      if (r['parent_loan_id'] != null) {
        ref('loans', r, 'parent_loan_id', 'loans');
        if (r['parent_loan_id'] == r['id']) {
          err('loans id $id: a loan cannot replace itself.');
        }
      }
    }

    for (final r in rows['loan_payments']!) {
      profileRef('loan_payments', r);
      ref('loan_payments', r, 'loan_id', 'loans');
      if ((r['amount_minor'] as int) <= 0) {
        err('loan_payments id ${r['id']}: amount must be greater than zero.');
      }
      if (!dateRe(r['payment_date'] as String)) {
        err(
          'loan_payments id ${r['id']}: payment_date must be a valid yyyy-MM-dd date.',
        );
      }
    }

    seen = {};
    final lastFourRe = RegExp(r'^[0-9]{4}$');
    for (final r in rows['credit_cards']!) {
      final id = r['id'];
      profileRef('credit_cards', r);
      name('credit_cards', r);
      final bank = r['bank_name'] as String;
      if (bank.isEmpty || bank.length > 80) {
        err('credit_cards id $id: bank name must be 1-80 characters.');
      }
      final l4 = r['last_four'];
      if (l4 != null && !lastFourRe.hasMatch(l4 as String)) {
        err('credit_cards id $id: last_four must be exactly 4 digits.');
      }
      if ((r['credit_limit_minor'] as int) <= 0) {
        err('credit_cards id $id: credit limit must be greater than zero.');
      }
      final sd = r['statement_day'] as int;
      if (sd < 1 || sd > 28) {
        err('credit_cards id $id: statement day must be between 1 and 28.');
      }
      final dd = r['due_days'] as int;
      if (dd < 1 || dd > 60) {
        err('credit_cards id $id: due days must be between 1 and 60.');
      }
      for (final col in ['apr_bp', 'min_payment_bp', 'late_fee_bp']) {
        final v = r[col] as int;
        if (v < 0 || v > 10000) {
          err('credit_cards id $id: $col must be between 0 and 10000.');
        }
      }
      for (final col in ['min_payment_floor_minor', 'late_fee_floor_minor']) {
        if ((r[col] as int) < 0) {
          err('credit_cards id $id: $col must not be negative.');
        }
      }
      unique(
        'credit_cards',
        seen,
        '${r['profile_id']}|${_nocase(r['name'] as String)}',
        id!,
      );
    }

    seen = {};
    final monthRe = RegExp(r'^[0-9]{4}-(0[1-9]|1[0-2])$');
    for (final r in rows['credit_card_bills']!) {
      final id = r['id'];
      profileRef('credit_card_bills', r);
      ref('credit_card_bills', r, 'card_id', 'credit_cards');
      final month = r['bill_month'] as String;
      if (!monthRe.hasMatch(month)) {
        err('credit_card_bills id $id: bill_month must be yyyy-MM.');
      }
      if (!dateRe(r['statement_date'] as String)) {
        err(
          'credit_card_bills id $id: statement_date must be a valid yyyy-MM-dd date.',
        );
      }
      if (!dateRe(r['due_date'] as String)) {
        err(
          'credit_card_bills id $id: due_date must be a valid yyyy-MM-dd date.',
        );
      }
      final amount = r['amount_minor'] as int;
      if (amount <= 0) {
        err('credit_card_bills id $id: amount must be greater than zero.');
      }
      final minPay = r['min_payment_minor'] as int;
      if (minPay < 0 || minPay > amount) {
        err(
          'credit_card_bills id $id: minimum payment must be between 0 and the bill amount.',
        );
      }
      if (r['is_active'] == true &&
          !seen.add('${r['profile_id']}|${r['card_id']}|$month')) {
        err(
          'credit_card_bills id $id: duplicate active bill for $month on the same card.',
        );
      }
    }

    for (final r in rows['credit_card_payments']!) {
      profileRef('credit_card_payments', r);
      ref('credit_card_payments', r, 'bill_id', 'credit_card_bills');
      if ((r['amount_minor'] as int) <= 0) {
        err(
          'credit_card_payments id ${r['id']}: amount must be greater than zero.',
        );
      }
      if (!dateRe(r['payment_date'] as String)) {
        err(
          'credit_card_payments id ${r['id']}: payment_date must be a valid yyyy-MM-dd date.',
        );
      }
    }

    for (final r in rows['fixed_deposits']!) {
      profileRef('fixed_deposits', r);
      final id = r['id'];
      final type = r['scheme_type'] as String;
      if (type.isEmpty || type.length > 40) {
        err('fixed_deposits id $id: scheme type must be 1-40 characters.');
      }
      final bank = r['bank_name'] as String;
      if (bank.isEmpty || bank.length > 80) {
        err('fixed_deposits id $id: bank name must be 1-80 characters.');
      }
    }

    final fdTermKeys = <String>{};
    final fdInstruments = <String>{};
    final fdActive = <Object?, int>{};
    for (final r in rows['fixed_deposit_terms']!) {
      final id = r['id'];
      profileRef('fixed_deposit_terms', r);
      ref('fixed_deposit_terms', r, 'deposit_id', 'fixed_deposits');
      if (!fdTermKeys.add('${r['deposit_id']}|${r['term_no']}')) {
        err('fixed_deposit_terms id $id: duplicate term number.');
      }
      if ((r['term_no'] as int) < 1) {
        err('fixed_deposit_terms id $id: term number must be at least 1.');
      }
      final number = r['instrument_number'] as String;
      if (number.isEmpty || number.length > 100) {
        err(
          'fixed_deposit_terms id $id: instrument number must be 1-100 characters.',
        );
      } else if (!fdInstruments.add(
        '${r['profile_id']}|${_nocase(number)}',
      )) {
        err('fixed_deposit_terms id $id: duplicate instrument number.');
      }
      if (!dateRe(r['start_date'] as String)) {
        err(
          'fixed_deposit_terms id $id: start_date must be a valid yyyy-MM-dd date.',
        );
      }
      final tenure = r['tenure_days'] as int;
      if (tenure < 1 || tenure > 36500) {
        err('fixed_deposit_terms id $id: tenure must be 1-36500 days.');
      }
      final rate = r['rate_bp'] as int;
      if (rate < 0 || rate > 10000) {
        err('fixed_deposit_terms id $id: rate must be between 0% and 100%.');
      }
      if ((r['principal_minor'] as int) <= 0) {
        err('fixed_deposit_terms id $id: principal must be greater than zero.');
      }
      final outcome = r['outcome'];
      if (!{'active', 'encashed', 'reissued'}.contains(outcome)) {
        err('fixed_deposit_terms id $id: unknown outcome "$outcome".');
      }
      if (outcome == 'active') {
        fdActive[r['deposit_id']] = (fdActive[r['deposit_id']] ?? 0) + 1;
      } else {
        if (r['settled_date'] == null || !dateRe(r['settled_date'] as String)) {
          err(
            'fixed_deposit_terms id $id: a closed instrument needs a valid settled_date.',
          );
        }
        for (final c in [
          'interest_minor',
          'tax_minor',
          'bank_charge_minor',
          'net_received_minor',
        ]) {
          final v = r[c];
          if (v == null || (v as int) < 0) {
            err('fixed_deposit_terms id $id: $c is required and not negative.');
          }
        }
      }
    }
    for (final e in fdActive.entries) {
      if (e.value > 1) {
        err('fixed_deposits id ${e.key}: more than one running instrument.');
      }
    }

    seen = {};
    for (final r in rows['tags']!) {
      profileRef('tags', r);
      final n = r['name'] as String;
      if (n.isEmpty || n.length > 40) {
        err('tags id ${r['id']}: name must be 1-40 characters.');
      }
      unique('tags', seen, '${r['profile_id']}|${_nocase(n)}', r['id']!);
    }

    seen = {};
    for (final r in rows['transaction_tags']!) {
      profileRef('transaction_tags', r);
      final label = 'transaction_tags (${r['transaction_id']}, ${r['tag_id']})';
      final tx = byId['financial_transactions']![r['transaction_id']];
      if (tx == null) {
        err('$label: transaction does not exist.');
      } else if (tx['profile_id'] != r['profile_id']) {
        err(
          '$label: transaction belongs to a different profile (cross-profile reference).',
        );
      }
      final tg = byId['tags']![r['tag_id']];
      if (tg == null) {
        err('$label: tag does not exist.');
      } else if (tg['profile_id'] != r['profile_id']) {
        err(
          '$label: tag belongs to a different profile (cross-profile reference).',
        );
      }
      if (!seen.add('${r['transaction_id']}|${r['tag_id']}')) {
        err('$label: duplicate tag on the same transaction.');
      }
    }

    for (final r in rows['transaction_attachments']!) {
      profileRef('transaction_attachments', r);
      ref(
        'transaction_attachments',
        r,
        'transaction_id',
        'financial_transactions',
      );
      final rel = r['relative_path'] as String;
      if (!isSafeRelativePath(rel)) {
        err(
          'transaction_attachments id ${r['id']}: unsafe file path "$rel" '
          '(paths must be relative and stay inside the attachments folder).',
        );
      }
      if ((r['size_bytes'] as int) < 0) {
        err(
          'transaction_attachments id ${r['id']}: size must not be negative.',
        );
      }
    }

    // ---- Embedded photo files -------------------------------------------
    final files = root['attachmentFiles'];
    var photoCount = 0;
    if (files != null) {
      if (files is! Map<String, dynamic>) {
        err('"attachmentFiles" must be an object of path to base64 data.');
      } else {
        for (final e in files.entries) {
          if (!isSafeRelativePath(e.key)) {
            err('Embedded photo has an unsafe path "${e.key}".');
            continue;
          }
          final v = e.value;
          if (v is! String) {
            err('Embedded photo "${e.key}" has invalid data.');
            continue;
          }
          try {
            base64Decode(v);
          } on FormatException {
            err('Embedded photo "${e.key}" is not valid base64 data.');
            continue;
          }
          photoCount++;
        }
      }
    }

    return finish(
      counts: {
        for (final s in backupTables) s.name: rows[s.name]!.length,
        if (photoCount > 0) 'photo_files': photoCount,
      },
      createdAt: createdAt,
      schemaVersion: schemaVersion,
    );
  }

  /// Multi-currency columns of a transaction (schema v5): all-or-none, only
  /// expense/income, and amount_minor must equal the rounded conversion.
  static void _checkOriginal(
    Map<String, dynamic> r,
    Object? type,
    Map<int, Map<String, dynamic>> profiles,
    void Function(String) err,
  ) {
    final o = r['original_amount_minor'];
    final c = r['original_currency'];
    final rate = r['rate_micro'];
    final set = [o, c, rate].where((v) => v != null).length;
    if (set == 0) return;
    final id = r['id'];
    final label = 'financial_transactions id $id';
    if (set != 3) {
      err(
        '$label: original_amount_minor, original_currency and rate_micro '
        'must all be set or all be empty.',
      );
      return;
    }
    if (type != 'expense' && type != 'income') {
      err(
        '$label: only expense and income transactions may have an original currency amount.',
      );
    }
    var ok = true;
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(c as String)) {
      err('$label: original_currency "$c" must be 3 upper-case letters.');
    } else {
      final base = profiles[r['profile_id']]?['currency_code'];
      if (base == c) {
        err(
          '$label: original_currency must differ from the profile currency ($base).',
        );
      }
    }
    if ((o as int) <= 0) {
      err('$label: original_amount_minor must be greater than zero.');
      ok = false;
    }
    if ((rate as int) <= 0) {
      err('$label: rate_micro must be greater than zero.');
      ok = false;
    }
    if (ok) {
      final expected = convertToBaseMinor(originalMinor: o, rateMicro: rate);
      if (expected == null || expected != r['amount_minor']) {
        err(
          '$label: amount_minor ${r['amount_minor']} does not match the '
          'converted original amount (expected ${expected ?? 'a valid value'} '
          'from $o x rate $rate).',
        );
      }
    }
  }

  /// Mirrors SQLite's NOCASE collation (ASCII-only case folding).
  static String _nocase(String s) =>
      s.replaceAllMapped(RegExp('[A-Z]'), (m) => m[0]!.toLowerCase());
}
