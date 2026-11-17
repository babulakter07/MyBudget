import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);
  final AppDatabase _db;

  Profile _map(ProfileRow r) => Profile(
    id: r.id,
    name: r.name,
    currencyCode: r.currencyCode,
    isActive: r.isActive,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  String _validName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Name is required');
    if (n.length > 80) {
      throw ValidationException('Name must be 80 characters or fewer');
    }
    return n;
  }

  Future<void> _assertUnique(String name, {int? exceptId}) async {
    final rows = await _db.select(_db.financialProfiles).get();
    final lower = name.toLowerCase();
    final clash = rows.any(
      (r) => r.id != exceptId && r.name.trim().toLowerCase() == lower,
    );
    if (clash) {
      throw DuplicateNameException('A profile named "$name" already exists');
    }
  }

  Stream<List<Profile>> watchAll() {
    final q = _db.select(_db.financialProfiles)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  Future<Profile?> getById(int id) async {
    final row = await (_db.select(
      _db.financialProfiles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<Profile> create(String name, {String currencyCode = 'BDT'}) async {
    final n = _validName(name);
    await _assertUnique(n);
    final now = DateTime.now();
    final id = await _db
        .into(_db.financialProfiles)
        .insert(
          FinancialProfilesCompanion.insert(
            name: n,
            currencyCode: Value(currencyCode),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(id))!;
  }

  Future<void> rename(int id, String name) async {
    final n = _validName(name);
    await _assertUnique(n, exceptId: id);
    final count =
        await (_db.update(
          _db.financialProfiles,
        )..where((t) => t.id.equals(id))).write(
          FinancialProfilesCompanion(
            name: Value(n),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (count == 0) throw NotFoundException('Profile not found');
  }

  /// Deactivate/reactivate. Never deletes data. [activeProfileId] is the
  /// currently selected profile; it cannot be deactivated without switching.
  Future<void> setActive(int id, bool isActive, {int? activeProfileId}) async {
    if (!isActive && activeProfileId == id) {
      throw ValidationException(
        'Switch to another profile before deactivating the active one',
      );
    }
    final count =
        await (_db.update(
          _db.financialProfiles,
        )..where((t) => t.id.equals(id))).write(
          FinancialProfilesCompanion(
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (count == 0) throw NotFoundException('Profile not found');
  }
}
