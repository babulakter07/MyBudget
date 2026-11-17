import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/cost_item.dart';

class CostItemRepository {
  CostItemRepository(this._db);
  final AppDatabase _db;

  static const _dupMsg =
      'A cost item with this name already exists in the selected sub-category.';

  CostItem _map(CostItemRow r) => CostItem(
    id: r.id,
    profileId: r.profileId,
    subCategoryId: r.subCategoryId,
    name: r.name,
    description: r.description,
    defaultAmountMinor: r.defaultAmountMinor,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Name is required.');
    if (n.length > 80) {
      throw ValidationException('Name must be 80 characters or fewer.');
    }
    return n;
  }

  void _validAmount(int? a) {
    if (a != null && a < 0) {
      throw ValidationException('Default amount cannot be negative.');
    }
  }

  String? _cleanDesc(String? d) {
    final t = d?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<SubCategoryRow> _subCategory(int profileId, int subCategoryId) async {
    final row = await (_db.select(
      _db.subCategories,
    )..where((s) => s.id.equals(subCategoryId))).getSingleOrNull();
    if (row == null) throw NotFoundException('Sub-category not found.');
    if (row.profileId != profileId) {
      throw ProfileMismatchException(
        'Sub-category belongs to a different profile.',
      );
    }
    return row;
  }

  Future<bool> _duplicateExists(
    int profileId,
    int subCategoryId,
    String name,
    int? excludeId,
  ) async {
    final q = _db.select(_db.costItems)
      ..where(
        (c) =>
            c.profileId.equals(profileId) &
            c.subCategoryId.equals(subCategoryId) &
            c.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((c) => c.id.isNotValue(excludeId));
    return (await q.get()).isNotEmpty;
  }

  Future<int> create({
    required int profileId,
    required int subCategoryId,
    required String name,
    String? description,
    int? defaultAmountMinor,
  }) async {
    final n = _validName(name);
    _validAmount(defaultAmountMinor);
    final sub = await _subCategory(profileId, subCategoryId);
    if (!sub.isActive) {
      throw ValidationException(
        'Cost items can only be added under active sub-categories.',
      );
    }
    if (await _duplicateExists(profileId, subCategoryId, n, null)) {
      throw DuplicateNameException(_dupMsg);
    }
    final now = DateTime.now();
    try {
      return await _db
          .into(_db.costItems)
          .insert(
            CostItemsCompanion.insert(
              profileId: profileId,
              subCategoryId: subCategoryId,
              name: n,
              description: Value(_cleanDesc(description)),
              defaultAmountMinor: Value(defaultAmountMinor),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Exception catch (e) {
      throw _translate(e);
    }
  }

  Future<void> update({
    required int profileId,
    required int id,
    required int subCategoryId,
    required String name,
    String? description,
    int? defaultAmountMinor,
  }) async {
    final n = _validName(name);
    _validAmount(defaultAmountMinor);
    final existing = await _get(profileId, id);
    final sub = await _subCategory(profileId, subCategoryId);
    if (subCategoryId != existing.subCategoryId && !sub.isActive) {
      throw ValidationException(
        'Cost items can only be moved to active sub-categories.',
      );
    }
    if (await _duplicateExists(profileId, subCategoryId, n, id)) {
      throw DuplicateNameException(_dupMsg);
    }
    try {
      await (_db.update(
        _db.costItems,
      )..where((c) => c.id.equals(id) & c.profileId.equals(profileId))).write(
        CostItemsCompanion(
          subCategoryId: Value(subCategoryId),
          name: Value(n),
          description: Value(_cleanDesc(description)),
          defaultAmountMinor: Value(defaultAmountMinor),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } on Exception catch (e) {
      throw _translate(e);
    }
  }

  Future<void> setActive(int profileId, int id, bool active) async {
    await _get(profileId, id);
    await (_db.update(
      _db.costItems,
    )..where((c) => c.id.equals(id) & c.profileId.equals(profileId))).write(
      CostItemsCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<CostItemRow> _get(int profileId, int id) async {
    final row =
        await (_db.select(_db.costItems)
              ..where((c) => c.id.equals(id) & c.profileId.equals(profileId)))
            .getSingleOrNull();
    if (row == null) throw NotFoundException('Cost item not found.');
    return row;
  }

  Future<CostItem?> getById(int profileId, int id) async {
    final row =
        await (_db.select(_db.costItems)
              ..where((c) => c.id.equals(id) & c.profileId.equals(profileId)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Object _translate(Exception e) {
    final msg = e.toString();
    if (msg.contains('UNIQUE')) return DuplicateNameException(_dupMsg);
    if (msg.contains('FOREIGN KEY')) {
      return ProfileMismatchException(
        'Sub-category does not belong to this profile.',
      );
    }
    if (msg.contains('CHECK')) {
      return ValidationException('Default amount cannot be negative.');
    }
    return e;
  }

  Stream<List<CostItemView>> watchAll(
    int profileId, {
    int? categoryId,
    int? subCategoryId,
    String search = '',
    bool includeInactive = false,
  }) {
    final ci = _db.costItems;
    final sc = _db.subCategories;
    final cat = _db.categories;
    final q = _db.select(ci).join([
      innerJoin(
        sc,
        sc.id.equalsExp(ci.subCategoryId) &
            sc.profileId.equalsExp(ci.profileId),
      ),
      innerJoin(
        cat,
        cat.id.equalsExp(sc.categoryId) & cat.profileId.equalsExp(sc.profileId),
      ),
    ]);
    Expression<bool> where = ci.profileId.equals(profileId);
    if (!includeInactive) where = where & ci.isActive.equals(true);
    if (categoryId != null) where = where & cat.id.equals(categoryId);
    if (subCategoryId != null) where = where & sc.id.equals(subCategoryId);
    final term = search.trim();
    if (term.isNotEmpty) {
      final esc = term
          .toLowerCase()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final pattern = '%$esc%';
      where =
          where &
          (_EscapedLike(ci.name.lower(), pattern) |
              _EscapedLike(ci.description.lower(), pattern));
    }
    q.where(where);
    q.orderBy([
      OrderingTerm.asc(cat.name.lower()),
      OrderingTerm.asc(sc.name.lower()),
      OrderingTerm.asc(ci.name.lower()),
    ]);
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => CostItemView(
              item: _map(r.readTable(ci)),
              subCategoryName: r.readTable(sc).name,
              categoryId: r.readTable(cat).id,
              categoryName: r.readTable(cat).name,
            ),
          )
          .toList(),
    );
  }

  /// Active categories of a profile (for form/filter dropdowns).
  Future<List<CategoryRow>> activeCategories(int profileId) =>
      (_db.select(_db.categories)
            ..where(
              (c) => c.profileId.equals(profileId) & c.isActive.equals(true),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

  /// Sub-categories of a category; [onlyActive] for the add/edit form.
  Future<List<SubCategoryRow>> subCategoriesOf(
    int profileId,
    int categoryId, {
    bool onlyActive = true,
  }) =>
      (_db.select(_db.subCategories)
            ..where((s) {
              var e =
                  s.profileId.equals(profileId) &
                  s.categoryId.equals(categoryId);
              if (onlyActive) e = e & s.isActive.equals(true);
              return e;
            })
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .get();

  /// Category id for a sub-category (used to prefill the edit form).
  Future<int?> categoryIdOf(int profileId, int subCategoryId) async {
    final row =
        await (_db.select(_db.subCategories)..where(
              (s) => s.id.equals(subCategoryId) & s.profileId.equals(profileId),
            ))
            .getSingleOrNull();
    return row?.categoryId;
  }
}

class _EscapedLike extends Expression<bool> {
  _EscapedLike(this.target, this.pattern);
  final Expression<String> target;
  final String pattern;

  @override
  Precedence get precedence => Precedence.comparison;

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    Variable<String>(pattern).writeInto(context);
    context.buffer.write(r" ESCAPE '\'");
  }
}

