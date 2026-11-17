import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/sub_category.dart';

class SubCategoryRepository {
  SubCategoryRepository(this._db);
  final AppDatabase _db;

  static const _dupMessage =
      'A sub-category with this name already exists in this category.';

  SubCategory _map(SubCategoryRow r) => SubCategory(
    id: r.id,
    profileId: r.profileId,
    categoryId: r.categoryId,
    name: r.name,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _cleanName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Name is required.');
    if (n.length > 80) {
      throw ValidationException('Name must be 80 characters or fewer.');
    }
    return n;
  }

  Future<CategoryRow> _requireCategory(int profileId, int categoryId) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (row == null) throw NotFoundException('Category not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Category does not belong to the active profile.',
      );
    }
    return row;
  }

  Future<bool> _duplicateExists(
    int profileId,
    int categoryId,
    String name,
    int? excludeId,
  ) async {
    final q = _db.select(_db.subCategories)
      ..where(
        (s) =>
            s.profileId.equals(profileId) &
            s.categoryId.equals(categoryId) &
            s.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((s) => s.id.equals(excludeId).not());
    return (await q.get()).isNotEmpty;
  }

  bool _isUnique(Object e) => e.toString().toUpperCase().contains('UNIQUE');

  Future<SubCategory> create({
    required int profileId,
    required int categoryId,
    required String name,
  }) async {
    final n = _cleanName(name);
    final cat = await _requireCategory(profileId, categoryId);
    if (!cat.isActive) {
      throw ValidationException(
        'Sub-categories can only be added under active categories.',
      );
    }
    if (await _duplicateExists(profileId, categoryId, n, null)) {
      throw DuplicateNameException(_dupMessage);
    }
    final now = DateTime.now();
    try {
      final id = await _db
          .into(_db.subCategories)
          .insert(
            SubCategoriesCompanion.insert(
              profileId: profileId,
              categoryId: categoryId,
              name: n,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _map(await _get(profileId, id));
    } catch (e) {
      if (_isUnique(e)) throw DuplicateNameException(_dupMessage);
      rethrow;
    }
  }

  Future<SubCategoryRow> _get(int profileId, int id) async {
    final row =
        await (_db.select(_db.subCategories)
              ..where((s) => s.profileId.equals(profileId) & s.id.equals(id)))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('Sub-category not found.');
    return row;
  }

  Future<SubCategory?> getById(int profileId, int id) async {
    final row =
        await (_db.select(_db.subCategories)
              ..where((s) => s.profileId.equals(profileId) & s.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<SubCategory> update({
    required int profileId,
    required int id,
    required String name,
    int? categoryId,
  }) async {
    final n = _cleanName(name);
    final existing = await _get(profileId, id);
    final targetCat = categoryId ?? existing.categoryId;
    if (targetCat != existing.categoryId) {
      final cat = await _requireCategory(profileId, targetCat);
      if (!cat.isActive) {
        throw ValidationException('Cannot move into an inactive category.');
      }
    }
    if (await _duplicateExists(profileId, targetCat, n, id)) {
      throw DuplicateNameException(_dupMessage);
    }
    try {
      await (_db.update(
        _db.subCategories,
      )..where((s) => s.profileId.equals(profileId) & s.id.equals(id))).write(
        SubCategoriesCompanion(
          name: Value(n),
          categoryId: Value(targetCat),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      if (_isUnique(e)) throw DuplicateNameException(_dupMessage);
      rethrow;
    }
    return _map(await _get(profileId, id));
  }

  Future<void> setActive({
    required int profileId,
    required int id,
    required bool isActive,
  }) async {
    await _get(profileId, id);
    await (_db.update(
      _db.subCategories,
    )..where((s) => s.profileId.equals(profileId) & s.id.equals(id))).write(
      SubCategoriesCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<SubCategoryView>> watchAll(
    int profileId, {
    int? categoryId,
    String search = '',
    bool includeInactive = false,
  }) {
    final s = _db.subCategories;
    final c = _db.categories;
    final q = _db.select(s).join([
      innerJoin(
        c,
        c.id.equalsExp(s.categoryId) & c.profileId.equalsExp(s.profileId),
      ),
    ])..where(s.profileId.equals(profileId));
    if (categoryId != null) q.where(s.categoryId.equals(categoryId));
    final term = search.trim();
    if (term.isNotEmpty) q.where(s.name.like('%${_escape(term)}%'));
    if (!includeInactive) q.where(s.isActive.equals(true));
    q.orderBy([OrderingTerm.asc(c.name), OrderingTerm.asc(s.name)]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => SubCategoryView(
              subCategory: _map(r.readTable(s)),
              categoryName: r.readTable(c).name,
              categoryActive: r.readTable(c).isActive,
            ),
          )
          .toList(),
    );
  }

  String _escape(String v) => v.replaceAll('%', '').replaceAll('_', '');

  /// Categories of a profile (for the form dropdown / filter).
  Stream<List<({int id, String name, bool isActive})>> watchCategoryOptions(
    int profileId,
  ) {
    final c = _db.categories;
    final q = _db.select(c)
      ..where((t) => t.profileId.equals(profileId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map(
      (rows) => rows
          .map((r) => (id: r.id, name: r.name, isActive: r.isActive))
          .toList(),
    );
  }
}
