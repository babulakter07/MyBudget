import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FinancialProfiles,
    Categories,
    SubCategories,
    CostItems,
    ApplicationSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Add stepwise migrations here, e.g. `if (from < 2) {...}`.
      // Never rewrite earlier steps.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Case-insensitive uniqueness rules (names are unique per parent).
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX uq_profiles_name ON financial_profiles (name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_categories_profile_name ON categories (profile_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_sub_categories_cat_name ON sub_categories (profile_id, category_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_cost_items_sub_name ON cost_items (profile_id, sub_category_id, name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX idx_sub_categories_category ON sub_categories (profile_id, category_id)',
    );
    await customStatement(
      'CREATE INDEX idx_cost_items_sub ON cost_items (profile_id, sub_category_id)',
    );
  }
}

/// Opens the app database in application-private storage.
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'mybudget.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
