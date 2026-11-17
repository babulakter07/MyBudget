import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final AppDatabase _db;

  Category _map(CategoryRow r) => Category(
    id: r.id,
    profileId: r.profileId,
    name: r.name,
    description: r.description,
    icon: r.icon,
    color: r.color,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Category name is required.');
    if (n.length > 80) {
      throw ValidationException('Category name must be 80 characters or less.');
    }
    return n;
  }

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<bool> _nameTaken(int profileId, String name, {int? excludeId}) async {
    final q = _db.select(_db.categories)
      ..where(
        (c) =>
            c.profileId.equals(profileId) &
            c.name.lower().equals(name.toLowerCase()),
      );
    if (excludeId != null) q.where((c) => c.id.equals(excludeId).not());
    return (await q.get()).isNotEmpty;
  }

  DuplicateNameException _dup(String n) =>
      DuplicateNameException('A category named "$n" already exists.');

  Future<Category> create({
    required int profileId,
    required String name,
    String? description,
    String? icon,
    int? color,
  }) async {
    final n = _validName(name);
    if (await _nameTaken(profileId, n)) throw _dup(n);
    final now = DateTime.now();
    try {
      final id = await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              profileId: profileId,
              name: n,
              description: Value(_clean(description)),
              icon: Value(icon),
              color: Value(color),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return (await getById(profileId, id))!;
    } catch (e) {
      if (_isUnique(e)) throw _dup(n);
      rethrow;
    }
  }

  Future<Category> update({
    required int profileId,
    required int id,
    required String name,
    String? description,
    String? icon,
    int? color,
  }) async {
    final n = _validName(name);
    if (await getById(profileId, id) == null) {
      throw NotFoundException('Category not found.');
    }
    if (await _nameTaken(profileId, n, excludeId: id)) throw _dup(n);
    try {
      await (_db.update(
        _db.categories,
      )..where((c) => c.profileId.equals(profileId) & c.id.equals(id))).write(
        CategoriesCompanion(
          name: Value(n),
          description: Value(_clean(description)),
          icon: Value(icon),
          color: Value(color),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      if (_isUnique(e)) throw _dup(n);
      rethrow;
    }
    return (await getById(profileId, id))!;
  }

  Future<void> setActive(int profileId, int id, bool active) async {
    final n =
        await (_db.update(
          _db.categories,
        )..where((c) => c.profileId.equals(profileId) & c.id.equals(id))).write(
          CategoriesCompanion(
            isActive: Value(active),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (n == 0) throw NotFoundException('Category not found.');
  }

  /// Returns null when the id does not exist in [profileId].
  Future<Category?> getById(int profileId, int id) async {
    final r =
        await (_db.select(_db.categories)
              ..where((c) => c.profileId.equals(profileId) & c.id.equals(id)))
            .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  Stream<List<Category>> watchAll(
    int profileId, {
    String? search,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.categories)
      ..where((c) => c.profileId.equals(profileId))
      ..orderBy([(c) => OrderingTerm(expression: c.name.lower())]);
    if (!includeInactive) q.where((c) => c.isActive.equals(true));
    final s = search?.trim().toLowerCase();
    if (s != null && s.isNotEmpty) {
      final esc = s
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      q.where((c) => c.name.lower().like('%$esc%', escapeChar: r'\'));
    }
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  bool _isUnique(Object e) => e.toString().toUpperCase().contains('UNIQUE');
}
