import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/csv_import_models.dart';
import 'csv_parsing.dart';

/// Validates CSV rows against the active profile and posts them through the
/// public [TransactionRepository] (so snapshots and the audit log apply).
///
/// Duplicate safety: every row gets the idempotency key
/// `import:<sha256(row cells + account)>:<n>` where n is the 1-based
/// occurrence of an IDENTICAL row inside the file. Re-importing the same file
/// therefore finds every key already present and creates nothing, while two
/// genuinely identical lines in one file are still both imported.
/// The account id is part of the hash so the same file can legitimately be
/// imported into a different account.
class CsvImportService {
  CsvImportService(this._db, this._repo);

  final AppDatabase _db;
  final TransactionRepository _repo;

  static const String keyPrefix = 'import:';

  /// Computes the idempotency key of every row ([accountId] included).
  static List<String> rowKeys(List<List<String>> rows, int accountId) {
    final seen = <String, int>{};
    final keys = <String>[];
    for (final r in rows) {
      final digest = sha256
          .convert(utf8.encode('acct:$accountId\u0001${r.join('\u0001')}'))
          .toString();
      final n = (seen[digest] ?? 0) + 1;
      seen[digest] = n;
      keys.add('$keyPrefix$digest:$n');
    }
    return keys;
  }

  /// Dry run over the WHOLE table: classifies every row as valid, duplicate or
  /// invalid without writing anything.
  Future<ImportPlan> plan({
    required int profileId,
    required CsvTable table,
    required ImportSettings settings,
  }) async {
    final m = settings.mapping;
    if (!m.isComplete) {
      throw ValidationException('Choose the date and amount columns first.');
    }
    final account = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(settings.accountId))).getSingleOrNull();
    if (account == null) throw NotFoundException('Account not found.');
    if (account.profileId != profileId) {
      throw ProfileMismatchException('Account belongs to a different profile.');
    }
    if (!account.isActive) {
      throw ValidationException('Account "${account.name}" is inactive.');
    }

    final cats =
        await (_db.select(_db.categories)..where(
              (c) => c.profileId.equals(profileId) & c.isActive.equals(true),
            ))
            .get();
    final byName = <String, CategoryRow>{
      for (final c in cats) c.name.trim().toLowerCase(): c,
    };
    CategoryRow? defaultCat;
    if (settings.defaultCategoryId != null) {
      defaultCat = cats
          .where((c) => c.id == settings.defaultCategoryId)
          .firstOrNull;
      if (defaultCat == null) {
        throw ValidationException(
          'The default category is not an active category of this profile.',
        );
      }
    }

    final keys = rowKeys(table.rows, settings.accountId);
    final existing = await _existingKeys(profileId, keys);

    String cell(List<String> r, int? i) =>
        (i == null || i >= r.length) ? '' : r[i].trim();

    final out = <ImportRowPlan>[];
    for (var i = 0; i < table.rows.length; i++) {
      final r = table.rows[i];
      final errors = <String>[];

      final date = parseCsvDate(cell(r, m.date), m.dateFormat);
      if (date == null) {
        errors.add(
          'Invalid date "${cell(r, m.date)}" (expected ${m.dateFormat.label}).',
        );
      } else if (date.compareTo(account.openingDate) < 0) {
        errors.add(
          'Date $date is before the account opening date '
          '(${account.openingDate}).',
        );
      }

      final signed = parseSignedAmount(cell(r, m.amount));
      if (signed == null) {
        errors.add('Invalid amount "${cell(r, m.amount)}".');
      } else if (signed == 0) {
        errors.add('Amount must be greater than zero.');
      }

      bool? isExpense;
      if (m.type != null) {
        isExpense = parseTypeWord(cell(r, m.type));
        if (isExpense == null) {
          errors.add(
            'Unknown type "${cell(r, m.type)}" (use expense/income, debit/credit).',
          );
        }
      } else if (signed != null && signed != 0) {
        isExpense = signed < 0;
      }

      final desc = cell(r, m.description);
      final catText = cell(r, m.category);
      CategoryRow? cat;
      if (isExpense == true) {
        cat =
            (catText.isEmpty ? null : byName[catText.toLowerCase()]) ??
            defaultCat;
        if (cat == null) {
          errors.add(
            catText.isEmpty
                ? 'No category: pick a default category.'
                : 'Category "$catText" does not exist and no default category '
                      'is selected.',
          );
        }
      }

      if (errors.isNotEmpty) {
        out.add(
          ImportRowPlan(
            number: i + 1,
            cells: r,
            status: ImportRowStatus.invalid,
            errors: errors,
            key: keys[i],
          ),
        );
        continue;
      }
      final dup = existing.contains(keys[i]);
      out.add(
        ImportRowPlan(
          number: i + 1,
          cells: r,
          status: dup ? ImportRowStatus.duplicate : ImportRowStatus.valid,
          isExpense: isExpense,
          amountMinor: signed!.abs(),
          date: date,
          description: desc.isEmpty ? null : desc,
          categoryId: cat?.id,
          categoryName: cat?.name,
          incomeSource: isExpense == false
              ? (catText.isNotEmpty ? catText : 'Imported')
              : null,
          key: keys[i],
        ),
      );
    }
    return ImportPlan(out);
  }

  Future<Set<String>> _existingKeys(int profileId, List<String> keys) async {
    final found = <String>{};
    const chunk = 500;
    for (var i = 0; i < keys.length; i += chunk) {
      final part = keys.sublist(
        i,
        i + chunk > keys.length ? keys.length : i + chunk,
      );
      final rows =
          await (_db.select(_db.financialTransactions)..where(
                (t) =>
                    t.profileId.equals(profileId) & t.idempotencyKey.isIn(part),
              ))
              .get();
      for (final r in rows) {
        if (r.idempotencyKey != null) found.add(r.idempotencyKey!);
      }
    }
    return found;
  }

  /// Plans and imports in ONE database transaction (all or nothing). Invalid
  /// rows and duplicates are skipped (and counted); any unexpected failure
  /// while writing rolls everything back and throws an [AppException].
  Future<CsvImportResult> import({
    required int profileId,
    required CsvTable table,
    required ImportSettings settings,
  }) async {
    final plan = await this.plan(
      profileId: profileId,
      table: table,
      settings: settings,
    );
    final todo = plan.rows
        .where((r) => r.status == ImportRowStatus.valid)
        .toList();
    try {
      await _db.transaction(() async {
        for (final r in todo) {
          final title = r.description;
          if (r.isExpense!) {
            await _repo.createExpense(
              profileId: profileId,
              accountId: settings.accountId,
              categoryId: r.categoryId!,
              amountMinor: r.amountMinor!,
              date: r.date!,
              title: title,
              remarks: 'Imported from CSV',
              idempotencyKey: r.key,
            );
          } else {
            await _repo.createIncome(
              profileId: profileId,
              accountId: settings.accountId,
              incomeSource: r.incomeSource!,
              amountMinor: r.amountMinor!,
              date: r.date!,
              title: title,
              remarks: 'Imported from CSV',
              idempotencyKey: r.key,
            );
          }
        }
      });
    } on Object catch (e) {
      if (e is AppException) {
        throw AppException(
          'Import failed on one row and was rolled back; nothing was '
          'imported. (${e.message})',
        );
      }
      throw AppException(
        'Import failed and was rolled back; nothing was imported. ($e)',
      );
    }
    return CsvImportResult(
      imported: todo.length,
      skippedDuplicates: plan.duplicateCount,
      invalid: plan.invalidCount,
    );
  }
}
