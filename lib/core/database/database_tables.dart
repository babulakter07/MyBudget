import 'package:drift/drift.dart';

/// All profile-owned tables carry `profile_id`. Child tables use composite
/// foreign keys (profile_id, parent_id) so a child can never reference a
/// parent belonging to another profile.

@DataClassName('ProfileRow')
class FinancialProfiles extends Table {
  @override
  String get tableName => 'financial_profiles';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get currencyCode => text().withDefault(const Constant('BDT'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(FinancialProfiles, #id)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, id},
      ];
}

@DataClassName('SubCategoryRow')
class SubCategories extends Table {
  @override
  String get tableName => 'sub_categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get categoryId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, id},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
        'FOREIGN KEY (profile_id, category_id) REFERENCES categories (profile_id, id)',
      ];
}

@DataClassName('CostItemRow')
class CostItems extends Table {
  @override
  String get tableName => 'cost_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  IntColumn get subCategoryId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();

  /// Minor units (paisa). Never a floating-point value.
  IntColumn get defaultAmountMinor => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, id},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (profile_id) REFERENCES financial_profiles (id)',
        'FOREIGN KEY (profile_id, sub_category_id) REFERENCES sub_categories (profile_id, id)',
        'CHECK (default_amount_minor IS NULL OR default_amount_minor >= 0)',
      ];
}

@DataClassName('SettingRow')
class ApplicationSettings extends Table {
  @override
  String get tableName => 'application_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
