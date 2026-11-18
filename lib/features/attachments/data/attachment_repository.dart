import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/app_paths.dart';
import '../domain/attachment.dart';

class AttachmentRepository {
  AttachmentRepository(this._db, {Future<Directory> Function()? directory})
    : _directory = directory ?? attachmentsDirectory;
  final AppDatabase _db;
  final Future<Directory> Function() _directory;

  Attachment _map(AttachmentRow r) => Attachment(
    id: r.id,
    profileId: r.profileId,
    transactionId: r.transactionId,
    relativePath: r.relativePath,
    mimeType: r.mimeType,
    sizeBytes: r.sizeBytes,
    createdAt: r.createdAt,
  );

  Future<void> _checkTxn(int profileId, int transactionId) async {
    final txn = await (_db.select(
      _db.financialTransactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (txn == null) throw NotFoundException('Transaction not found.');
    if (txn.profileId != profileId) {
      throw ProfileMismatchException('Transaction belongs to another profile.');
    }
    if (txn.isDeleted) throw NotFoundException('Transaction has been deleted.');
  }

  Future<int> _count(int profileId, int transactionId) async {
    final rows =
        await (_db.select(_db.transactionAttachments)..where(
              (a) =>
                  a.profileId.equals(profileId) &
                  a.transactionId.equals(transactionId) &
                  a.isDeleted.equals(false),
            ))
            .get();
    return rows.length;
  }

  /// Resolves a stored relative path to an absolute file inside the
  /// attachments directory. Rejects empty, absolute and `..` paths.
  Future<File> resolve(String relativePath) async {
    final rel = relativePath.trim();
    final normalized = rel.replaceAll('\\', '/');
    if (rel.isEmpty ||
        p.isAbsolute(rel) ||
        p.windows.isAbsolute(rel) ||
        normalized.startsWith('/') ||
        normalized.split('/').contains('..')) {
      throw ValidationException('Invalid attachment path.');
    }
    final dir = await _directory();
    final full = p.normalize(p.join(dir.path, rel));
    if (!p.isWithin(p.normalize(dir.path), full)) {
      throw ValidationException('Invalid attachment path.');
    }
    return File(full);
  }

  /// Copies [source] into the attachments directory and records it.
  Future<Attachment> addFromFile({
    required int profileId,
    required int transactionId,
    required File source,
  }) async {
    await _checkTxn(profileId, transactionId);
    if (!await source.exists()) {
      throw ValidationException('The selected file no longer exists.');
    }
    final size = await source.length();
    if (size > AttachmentLimits.maxBytes) {
      throw ValidationException(AttachmentLimits.sizeMessage);
    }
    if (await _count(profileId, transactionId) >=
        AttachmentLimits.maxPerTransaction) {
      throw ValidationException(AttachmentLimits.countMessage);
    }

    final isPng = p.extension(source.path).toLowerCase() == '.png';
    final ext = isPng ? 'png' : 'jpg';
    final mime = isPng ? 'image/png' : 'image/jpeg';
    final dir = await _directory();
    final profileDir = Directory(p.join(dir.path, '$profileId'));
    await profileDir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    var n = 0;
    late String name;
    do {
      name = '${transactionId}_${stamp}_${n++}.$ext';
    } while (await File(p.join(profileDir.path, name)).exists());
    final dest = File(p.join(profileDir.path, name));
    await source.copy(dest.path);

    try {
      return await _db.transaction(() async {
        // Re-check inside the write transaction.
        await _checkTxn(profileId, transactionId);
        if (await _count(profileId, transactionId) >=
            AttachmentLimits.maxPerTransaction) {
          throw ValidationException(AttachmentLimits.countMessage);
        }
        final id = await _db
            .into(_db.transactionAttachments)
            .insert(
              TransactionAttachmentsCompanion.insert(
                profileId: profileId,
                transactionId: transactionId,
                relativePath: '$profileId/$name',
                mimeType: Value(mime),
                sizeBytes: Value(size),
                createdAt: DateTime.now(),
              ),
            );
        final row = await (_db.select(
          _db.transactionAttachments,
        )..where((a) => a.id.equals(id))).getSingle();
        return _map(row);
      });
    } catch (_) {
      try {
        await dest.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Stream<List<Attachment>> watchForTransaction(
    int profileId,
    int transactionId,
  ) {
    final q = _db.select(_db.transactionAttachments)
      ..where(
        (a) =>
            a.profileId.equals(profileId) &
            a.transactionId.equals(transactionId) &
            a.isDeleted.equals(false),
      )
      ..orderBy([(a) => OrderingTerm(expression: a.id)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<List<Attachment>> list(int profileId, int transactionId) =>
      watchForTransaction(profileId, transactionId).first;

  /// Soft-deletes the row and removes the file (best effort).
  Future<void> delete(int profileId, int attachmentId) async {
    final row = await (_db.select(
      _db.transactionAttachments,
    )..where((a) => a.id.equals(attachmentId))).getSingleOrNull();
    if (row == null || row.isDeleted) {
      throw NotFoundException('Attachment not found.');
    }
    if (row.profileId != profileId) {
      throw ProfileMismatchException('Attachment belongs to another profile.');
    }
    await (_db.update(_db.transactionAttachments)
          ..where((a) => a.id.equals(attachmentId)))
        .write(const TransactionAttachmentsCompanion(isDeleted: Value(true)));
    try {
      final f = await resolve(row.relativePath);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best effort only.
    }
  }

  /// Removes receipt files of transactions that were soft-deleted more than
  /// [grace] ago (the undo window stays safe). Marks the attachment rows
  /// deleted and deletes the files best-effort. Covers every profile; returns
  /// the number of attachments purged.
  Future<int> purgeDeletedTransactionAttachments({
    Duration grace = const Duration(days: 30),
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now()).subtract(grace);
    final rows = await _db
        .customSelect(
          'SELECT a.id AS id, a.relative_path AS path '
          'FROM transaction_attachments a '
          'JOIN financial_transactions t '
          'ON t.profile_id = a.profile_id AND t.id = a.transaction_id '
          'WHERE a.is_deleted = 0 AND t.is_deleted = 1 '
          'AND t.deleted_at IS NOT NULL AND t.deleted_at < ?1',
          variables: [Variable.withDateTime(cutoff)],
          readsFrom: {_db.transactionAttachments, _db.financialTransactions},
        )
        .get();
    var purged = 0;
    for (final r in rows) {
      final id = r.read<int>('id');
      await (_db.update(_db.transactionAttachments)
            ..where((a) => a.id.equals(id)))
          .write(const TransactionAttachmentsCompanion(isDeleted: Value(true)));
      try {
        final f = await resolve(r.read<String>('path'));
        if (await f.exists()) await f.delete();
      } catch (_) {
        // Best effort only; the row is already marked deleted.
      }
      purged++;
    }
    return purged;
  }

  /// Attaches every pending file to the freshly saved transaction, then
  /// clears [pending]. Stops at the first failure (already committed files
  /// stay attached and are removed from [pending]).
  Future<List<Attachment>> commitPending({
    required int profileId,
    required int transactionId,
    required PendingAttachments pending,
  }) async {
    final done = <Attachment>[];
    for (final f in pending.files) {
      done.add(
        await addFromFile(
          profileId: profileId,
          transactionId: transactionId,
          source: f,
        ),
      );
      pending.removeAt(0);
    }
    return done;
  }
}
