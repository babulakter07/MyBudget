// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FinancialProfilesTable extends FinancialProfiles
    with TableInfo<$FinancialProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('BDT'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currencyCode,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FinancialProfilesTable createAlias(String alias) {
    return $FinancialProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String name;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProfileRow({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialProfilesCompanion toCompanion(bool nullToAbsent) {
    return FinancialProfilesCompanion(
      id: Value(id),
      name: Value(name),
      currencyCode: Value(currencyCode),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? name,
    String? currencyCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    currencyCode: currencyCode ?? this.currencyCode,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileRow copyWithCompanion(FinancialProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, currencyCode, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.currencyCode == this.currencyCode &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> currencyCode;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.currencyCode = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? currencyCode,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? currencyCode,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FinancialProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_profiles (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    description,
    icon,
    color,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
  ];
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final int profileId;
  final String name;
  final String? description;
  final String? icon;
  final int? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<int?>(color),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    int? id,
    int? profileId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<int?> color = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    name,
    description,
    icon,
    color,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<int?> color;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? icon,
    Value<int?>? color,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubCategoriesTable extends SubCategories
    with TableInfo<$SubCategoriesTable, SubCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    categoryId,
    name,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
  ];
  @override
  SubCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubCategoriesTable createAlias(String alias) {
    return $SubCategoriesTable(attachedDatabase, alias);
  }
}

class SubCategoryRow extends DataClass implements Insertable<SubCategoryRow> {
  final int id;
  final int profileId;
  final int categoryId;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubCategoryRow({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubCategoriesCompanion toCompanion(bool nullToAbsent) {
    return SubCategoriesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      categoryId: Value(categoryId),
      name: Value(name),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubCategoryRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubCategoryRow copyWith({
    int? id,
    int? profileId,
    int? categoryId,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubCategoryRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubCategoryRow copyWithCompanion(SubCategoriesCompanion data) {
    return SubCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubCategoryRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    categoryId,
    name,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubCategoryRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubCategoriesCompanion extends UpdateCompanion<SubCategoryRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SubCategoriesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int categoryId,
    required String name,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       categoryId = Value(categoryId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubCategoryRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubCategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? categoryId,
    Value<String>? name,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SubCategoriesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CostItemsTable extends CostItems
    with TableInfo<$CostItemsTable, CostItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CostItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryIdMeta = const VerificationMeta(
    'subCategoryId',
  );
  @override
  late final GeneratedColumn<int> subCategoryId = GeneratedColumn<int>(
    'sub_category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultAmountMinorMeta =
      const VerificationMeta('defaultAmountMinor');
  @override
  late final GeneratedColumn<int> defaultAmountMinor = GeneratedColumn<int>(
    'default_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    subCategoryId,
    name,
    description,
    defaultAmountMinor,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cost_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CostItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('sub_category_id')) {
      context.handle(
        _subCategoryIdMeta,
        subCategoryId.isAcceptableOrUnknown(
          data['sub_category_id']!,
          _subCategoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('default_amount_minor')) {
      context.handle(
        _defaultAmountMinorMeta,
        defaultAmountMinor.isAcceptableOrUnknown(
          data['default_amount_minor']!,
          _defaultAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
  ];
  @override
  CostItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CostItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      subCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      defaultAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_amount_minor'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CostItemsTable createAlias(String alias) {
    return $CostItemsTable(attachedDatabase, alias);
  }
}

class CostItemRow extends DataClass implements Insertable<CostItemRow> {
  final int id;
  final int profileId;
  final int subCategoryId;
  final String name;
  final String? description;

  /// Minor units (paisa). Never a floating-point value.
  final int? defaultAmountMinor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CostItemRow({
    required this.id,
    required this.profileId,
    required this.subCategoryId,
    required this.name,
    this.description,
    this.defaultAmountMinor,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['sub_category_id'] = Variable<int>(subCategoryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || defaultAmountMinor != null) {
      map['default_amount_minor'] = Variable<int>(defaultAmountMinor);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CostItemsCompanion toCompanion(bool nullToAbsent) {
    return CostItemsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      subCategoryId: Value(subCategoryId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      defaultAmountMinor: defaultAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAmountMinor),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CostItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CostItemRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      subCategoryId: serializer.fromJson<int>(json['subCategoryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      defaultAmountMinor: serializer.fromJson<int?>(json['defaultAmountMinor']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'subCategoryId': serializer.toJson<int>(subCategoryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'defaultAmountMinor': serializer.toJson<int?>(defaultAmountMinor),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CostItemRow copyWith({
    int? id,
    int? profileId,
    int? subCategoryId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> defaultAmountMinor = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CostItemRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    subCategoryId: subCategoryId ?? this.subCategoryId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    defaultAmountMinor: defaultAmountMinor.present
        ? defaultAmountMinor.value
        : this.defaultAmountMinor,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CostItemRow copyWithCompanion(CostItemsCompanion data) {
    return CostItemRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      subCategoryId: data.subCategoryId.present
          ? data.subCategoryId.value
          : this.subCategoryId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      defaultAmountMinor: data.defaultAmountMinor.present
          ? data.defaultAmountMinor.value
          : this.defaultAmountMinor,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CostItemRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('defaultAmountMinor: $defaultAmountMinor, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    subCategoryId,
    name,
    description,
    defaultAmountMinor,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CostItemRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.subCategoryId == this.subCategoryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.defaultAmountMinor == this.defaultAmountMinor &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CostItemsCompanion extends UpdateCompanion<CostItemRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> subCategoryId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> defaultAmountMinor;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CostItemsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.defaultAmountMinor = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CostItemsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int subCategoryId,
    required String name,
    this.description = const Value.absent(),
    this.defaultAmountMinor = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       subCategoryId = Value(subCategoryId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CostItemRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? subCategoryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? defaultAmountMinor,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (defaultAmountMinor != null)
        'default_amount_minor': defaultAmountMinor,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CostItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? subCategoryId,
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? defaultAmountMinor,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CostItemsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultAmountMinor: defaultAmountMinor ?? this.defaultAmountMinor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (subCategoryId.present) {
      map['sub_category_id'] = Variable<int>(subCategoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (defaultAmountMinor.present) {
      map['default_amount_minor'] = Variable<int>(defaultAmountMinor.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CostItemsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('defaultAmountMinor: $defaultAmountMinor, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ApplicationSettingsTable extends ApplicationSettings
    with TableInfo<$ApplicationSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApplicationSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'application_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ApplicationSettingsTable createAlias(String alias) {
    return $ApplicationSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ApplicationSettingsCompanion toCompanion(bool nullToAbsent) {
    return ApplicationSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(ApplicationSettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class ApplicationSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ApplicationSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApplicationSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApplicationSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ApplicationSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApplicationSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyBudgetsTable extends MonthlyBudgets
    with TableInfo<$MonthlyBudgetsTable, MonthlyBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBudgetMinorMeta = const VerificationMeta(
    'totalBudgetMinor',
  );
  @override
  late final GeneratedColumn<int> totalBudgetMinor = GeneratedColumn<int>(
    'total_budget_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    year,
    month,
    totalBudgetMinor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyBudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('total_budget_minor')) {
      context.handle(
        _totalBudgetMinorMeta,
        totalBudgetMinor.isAcceptableOrUnknown(
          data['total_budget_minor']!,
          _totalBudgetMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalBudgetMinorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
    {profileId, year, month},
  ];
  @override
  MonthlyBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyBudgetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      totalBudgetMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_budget_minor'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MonthlyBudgetsTable createAlias(String alias) {
    return $MonthlyBudgetsTable(attachedDatabase, alias);
  }
}

class MonthlyBudgetRow extends DataClass
    implements Insertable<MonthlyBudgetRow> {
  final int id;
  final int profileId;
  final int year;
  final int month;

  /// Minor units (paisa).
  final int totalBudgetMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MonthlyBudgetRow({
    required this.id,
    required this.profileId,
    required this.year,
    required this.month,
    required this.totalBudgetMinor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['total_budget_minor'] = Variable<int>(totalBudgetMinor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MonthlyBudgetsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyBudgetsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      year: Value(year),
      month: Value(month),
      totalBudgetMinor: Value(totalBudgetMinor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonthlyBudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyBudgetRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      totalBudgetMinor: serializer.fromJson<int>(json['totalBudgetMinor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'totalBudgetMinor': serializer.toJson<int>(totalBudgetMinor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MonthlyBudgetRow copyWith({
    int? id,
    int? profileId,
    int? year,
    int? month,
    int? totalBudgetMinor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MonthlyBudgetRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    year: year ?? this.year,
    month: month ?? this.month,
    totalBudgetMinor: totalBudgetMinor ?? this.totalBudgetMinor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MonthlyBudgetRow copyWithCompanion(MonthlyBudgetsCompanion data) {
    return MonthlyBudgetRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      totalBudgetMinor: data.totalBudgetMinor.present
          ? data.totalBudgetMinor.value
          : this.totalBudgetMinor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyBudgetRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalBudgetMinor: $totalBudgetMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    year,
    month,
    totalBudgetMinor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyBudgetRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.year == this.year &&
          other.month == this.month &&
          other.totalBudgetMinor == this.totalBudgetMinor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MonthlyBudgetsCompanion extends UpdateCompanion<MonthlyBudgetRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> year;
  final Value<int> month;
  final Value<int> totalBudgetMinor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MonthlyBudgetsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.totalBudgetMinor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MonthlyBudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int year,
    required int month,
    required int totalBudgetMinor,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       year = Value(year),
       month = Value(month),
       totalBudgetMinor = Value(totalBudgetMinor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MonthlyBudgetRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? totalBudgetMinor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (totalBudgetMinor != null) 'total_budget_minor': totalBudgetMinor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MonthlyBudgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? year,
    Value<int>? month,
    Value<int>? totalBudgetMinor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MonthlyBudgetsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalBudgetMinor: totalBudgetMinor ?? this.totalBudgetMinor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (totalBudgetMinor.present) {
      map['total_budget_minor'] = Variable<int>(totalBudgetMinor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalBudgetMinor: $totalBudgetMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoryBudgetsTable extends CategoryBudgets
    with TableInfo<$CategoryBudgetsTable, CategoryBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyBudgetIdMeta = const VerificationMeta(
    'monthlyBudgetId',
  );
  @override
  late final GeneratedColumn<int> monthlyBudgetId = GeneratedColumn<int>(
    'monthly_budget_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    monthlyBudgetId,
    categoryId,
    amountMinor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryBudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('monthly_budget_id')) {
      context.handle(
        _monthlyBudgetIdMeta,
        monthlyBudgetId.isAcceptableOrUnknown(
          data['monthly_budget_id']!,
          _monthlyBudgetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyBudgetIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
    {monthlyBudgetId, categoryId},
  ];
  @override
  CategoryBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudgetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      monthlyBudgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_budget_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoryBudgetsTable createAlias(String alias) {
    return $CategoryBudgetsTable(attachedDatabase, alias);
  }
}

class CategoryBudgetRow extends DataClass
    implements Insertable<CategoryBudgetRow> {
  final int id;
  final int profileId;
  final int monthlyBudgetId;
  final int categoryId;

  /// Allocation inside the monthly total (never added to it). Minor units.
  final int amountMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryBudgetRow({
    required this.id,
    required this.profileId,
    required this.monthlyBudgetId,
    required this.categoryId,
    required this.amountMinor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['monthly_budget_id'] = Variable<int>(monthlyBudgetId);
    map['category_id'] = Variable<int>(categoryId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoryBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      monthlyBudgetId: Value(monthlyBudgetId),
      categoryId: Value(categoryId),
      amountMinor: Value(amountMinor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryBudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudgetRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      monthlyBudgetId: serializer.fromJson<int>(json['monthlyBudgetId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'monthlyBudgetId': serializer.toJson<int>(monthlyBudgetId),
      'categoryId': serializer.toJson<int>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryBudgetRow copyWith({
    int? id,
    int? profileId,
    int? monthlyBudgetId,
    int? categoryId,
    int? amountMinor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryBudgetRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    monthlyBudgetId: monthlyBudgetId ?? this.monthlyBudgetId,
    categoryId: categoryId ?? this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryBudgetRow copyWithCompanion(CategoryBudgetsCompanion data) {
    return CategoryBudgetRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      monthlyBudgetId: data.monthlyBudgetId.present
          ? data.monthlyBudgetId.value
          : this.monthlyBudgetId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('monthlyBudgetId: $monthlyBudgetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    monthlyBudgetId,
    categoryId,
    amountMinor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudgetRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.monthlyBudgetId == this.monthlyBudgetId &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoryBudgetsCompanion extends UpdateCompanion<CategoryBudgetRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> monthlyBudgetId;
  final Value<int> categoryId;
  final Value<int> amountMinor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoryBudgetsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.monthlyBudgetId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoryBudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int monthlyBudgetId,
    required int categoryId,
    required int amountMinor,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       monthlyBudgetId = Value(monthlyBudgetId),
       categoryId = Value(categoryId),
       amountMinor = Value(amountMinor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryBudgetRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? monthlyBudgetId,
    Expression<int>? categoryId,
    Expression<int>? amountMinor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (monthlyBudgetId != null) 'monthly_budget_id': monthlyBudgetId,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoryBudgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? monthlyBudgetId,
    Value<int>? categoryId,
    Value<int>? amountMinor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoryBudgetsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      monthlyBudgetId: monthlyBudgetId ?? this.monthlyBudgetId,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (monthlyBudgetId.present) {
      map['monthly_budget_id'] = Variable<int>(monthlyBudgetId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('monthlyBudgetId: $monthlyBudgetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openingDateMeta = const VerificationMeta(
    'openingDate',
  );
  @override
  late final GeneratedColumn<String> openingDate = GeneratedColumn<String>(
    'opening_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    type,
    openingBalanceMinor,
    openingDate,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('opening_date')) {
      context.handle(
        _openingDateMeta,
        openingDate.isAcceptableOrUnknown(
          data['opening_date']!,
          _openingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingDateMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
  ];
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      openingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_date'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;
  final int profileId;
  final String name;

  /// 'cash' | 'bank' | 'mobile' | 'other'
  final String type;
  final int openingBalanceMinor;

  /// Local date as 'yyyy-MM-dd'.
  final String openingDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AccountRow({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.openingDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['opening_date'] = Variable<String>(openingDate);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      type: Value(type),
      openingBalanceMinor: Value(openingBalanceMinor),
      openingDate: Value(openingDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      openingDate: serializer.fromJson<String>(json['openingDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'openingDate': serializer.toJson<String>(openingDate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AccountRow copyWith({
    int? id,
    int? profileId,
    String? name,
    String? type,
    int? openingBalanceMinor,
    String? openingDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccountRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    openingDate: openingDate ?? this.openingDate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      openingDate: data.openingDate.present
          ? data.openingDate.value
          : this.openingDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('openingDate: $openingDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    name,
    type,
    openingBalanceMinor,
    openingDate,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.type == this.type &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.openingDate == this.openingDate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> openingBalanceMinor;
  final Value<String> openingDate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    this.type = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    required String openingDate,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       name = Value(name),
       openingDate = Value(openingDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? openingBalanceMinor,
    Expression<String>? openingDate,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (openingDate != null) 'opening_date': openingDate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? name,
    Value<String>? type,
    Value<int>? openingBalanceMinor,
    Value<String>? openingDate,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      openingDate: openingDate ?? this.openingDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (openingDate.present) {
      map['opening_date'] = Variable<String>(openingDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('openingDate: $openingDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FinancialTransactionsTable extends FinancialTransactions
    with TableInfo<$FinancialTransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subCategoryIdMeta = const VerificationMeta(
    'subCategoryId',
  );
  @override
  late final GeneratedColumn<int> subCategoryId = GeneratedColumn<int>(
    'sub_category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costItemIdMeta = const VerificationMeta(
    'costItemId',
  );
  @override
  late final GeneratedColumn<int> costItemId = GeneratedColumn<int>(
    'cost_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNameSnapshotMeta =
      const VerificationMeta('accountNameSnapshot');
  @override
  late final GeneratedColumn<String> accountNameSnapshot =
      GeneratedColumn<String>(
        'account_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _toAccountNameSnapshotMeta =
      const VerificationMeta('toAccountNameSnapshot');
  @override
  late final GeneratedColumn<String> toAccountNameSnapshot =
      GeneratedColumn<String>(
        'to_account_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryNameSnapshotMeta =
      const VerificationMeta('categoryNameSnapshot');
  @override
  late final GeneratedColumn<String> categoryNameSnapshot =
      GeneratedColumn<String>(
        'category_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _subCategoryNameSnapshotMeta =
      const VerificationMeta('subCategoryNameSnapshot');
  @override
  late final GeneratedColumn<String> subCategoryNameSnapshot =
      GeneratedColumn<String>(
        'sub_category_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _costItemNameSnapshotMeta =
      const VerificationMeta('costItemNameSnapshot');
  @override
  late final GeneratedColumn<String> costItemNameSnapshot =
      GeneratedColumn<String>(
        'cost_item_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _incomeSourceMeta = const VerificationMeta(
    'incomeSource',
  );
  @override
  late final GeneratedColumn<String> incomeSource = GeneratedColumn<String>(
    'income_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _txnDateMeta = const VerificationMeta(
    'txnDate',
  );
  @override
  late final GeneratedColumn<String> txnDate = GeneratedColumn<String>(
    'txn_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    type,
    accountId,
    toAccountId,
    categoryId,
    subCategoryId,
    costItemId,
    accountNameSnapshot,
    toAccountNameSnapshot,
    categoryNameSnapshot,
    subCategoryNameSnapshot,
    costItemNameSnapshot,
    incomeSource,
    amountMinor,
    txnDate,
    title,
    remarks,
    idempotencyKey,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('sub_category_id')) {
      context.handle(
        _subCategoryIdMeta,
        subCategoryId.isAcceptableOrUnknown(
          data['sub_category_id']!,
          _subCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('cost_item_id')) {
      context.handle(
        _costItemIdMeta,
        costItemId.isAcceptableOrUnknown(
          data['cost_item_id']!,
          _costItemIdMeta,
        ),
      );
    }
    if (data.containsKey('account_name_snapshot')) {
      context.handle(
        _accountNameSnapshotMeta,
        accountNameSnapshot.isAcceptableOrUnknown(
          data['account_name_snapshot']!,
          _accountNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameSnapshotMeta);
    }
    if (data.containsKey('to_account_name_snapshot')) {
      context.handle(
        _toAccountNameSnapshotMeta,
        toAccountNameSnapshot.isAcceptableOrUnknown(
          data['to_account_name_snapshot']!,
          _toAccountNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('category_name_snapshot')) {
      context.handle(
        _categoryNameSnapshotMeta,
        categoryNameSnapshot.isAcceptableOrUnknown(
          data['category_name_snapshot']!,
          _categoryNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('sub_category_name_snapshot')) {
      context.handle(
        _subCategoryNameSnapshotMeta,
        subCategoryNameSnapshot.isAcceptableOrUnknown(
          data['sub_category_name_snapshot']!,
          _subCategoryNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('cost_item_name_snapshot')) {
      context.handle(
        _costItemNameSnapshotMeta,
        costItemNameSnapshot.isAcceptableOrUnknown(
          data['cost_item_name_snapshot']!,
          _costItemNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('income_source')) {
      context.handle(
        _incomeSourceMeta,
        incomeSource.isAcceptableOrUnknown(
          data['income_source']!,
          _incomeSourceMeta,
        ),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('txn_date')) {
      context.handle(
        _txnDateMeta,
        txnDate.isAcceptableOrUnknown(data['txn_date']!, _txnDateMeta),
      );
    } else if (isInserting) {
      context.missing(_txnDateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, id},
    {profileId, idempotencyKey},
  ];
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      subCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_category_id'],
      ),
      costItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_item_id'],
      ),
      accountNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name_snapshot'],
      )!,
      toAccountNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_name_snapshot'],
      ),
      categoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_snapshot'],
      ),
      subCategoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category_name_snapshot'],
      ),
      costItemNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_item_name_snapshot'],
      ),
      incomeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_source'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      txnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}txn_date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FinancialTransactionsTable createAlias(String alias) {
    return $FinancialTransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int profileId;

  /// 'expense' | 'income' | 'transfer'
  final String type;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final int? subCategoryId;
  final int? costItemId;
  final String accountNameSnapshot;
  final String? toAccountNameSnapshot;
  final String? categoryNameSnapshot;
  final String? subCategoryNameSnapshot;
  final String? costItemNameSnapshot;

  /// Income only (e.g. Salary, Freelance).
  final String? incomeSource;

  /// Strictly positive, minor units.
  final int amountMinor;

  /// Local date as 'yyyy-MM-dd' (sorts and groups correctly as text).
  final String txnDate;
  final String? title;
  final String? remarks;

  /// Client-generated key so a retried save cannot create a duplicate.
  final String? idempotencyKey;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.profileId,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.subCategoryId,
    this.costItemId,
    required this.accountNameSnapshot,
    this.toAccountNameSnapshot,
    this.categoryNameSnapshot,
    this.subCategoryNameSnapshot,
    this.costItemNameSnapshot,
    this.incomeSource,
    required this.amountMinor,
    required this.txnDate,
    this.title,
    this.remarks,
    this.idempotencyKey,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || subCategoryId != null) {
      map['sub_category_id'] = Variable<int>(subCategoryId);
    }
    if (!nullToAbsent || costItemId != null) {
      map['cost_item_id'] = Variable<int>(costItemId);
    }
    map['account_name_snapshot'] = Variable<String>(accountNameSnapshot);
    if (!nullToAbsent || toAccountNameSnapshot != null) {
      map['to_account_name_snapshot'] = Variable<String>(toAccountNameSnapshot);
    }
    if (!nullToAbsent || categoryNameSnapshot != null) {
      map['category_name_snapshot'] = Variable<String>(categoryNameSnapshot);
    }
    if (!nullToAbsent || subCategoryNameSnapshot != null) {
      map['sub_category_name_snapshot'] = Variable<String>(
        subCategoryNameSnapshot,
      );
    }
    if (!nullToAbsent || costItemNameSnapshot != null) {
      map['cost_item_name_snapshot'] = Variable<String>(costItemNameSnapshot);
    }
    if (!nullToAbsent || incomeSource != null) {
      map['income_source'] = Variable<String>(incomeSource);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['txn_date'] = Variable<String>(txnDate);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialTransactionsCompanion toCompanion(bool nullToAbsent) {
    return FinancialTransactionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      type: Value(type),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subCategoryId: subCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategoryId),
      costItemId: costItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(costItemId),
      accountNameSnapshot: Value(accountNameSnapshot),
      toAccountNameSnapshot: toAccountNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountNameSnapshot),
      categoryNameSnapshot: categoryNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryNameSnapshot),
      subCategoryNameSnapshot: subCategoryNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategoryNameSnapshot),
      costItemNameSnapshot: costItemNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(costItemNameSnapshot),
      incomeSource: incomeSource == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeSource),
      amountMinor: Value(amountMinor),
      txnDate: Value(txnDate),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<int>(json['accountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      subCategoryId: serializer.fromJson<int?>(json['subCategoryId']),
      costItemId: serializer.fromJson<int?>(json['costItemId']),
      accountNameSnapshot: serializer.fromJson<String>(
        json['accountNameSnapshot'],
      ),
      toAccountNameSnapshot: serializer.fromJson<String?>(
        json['toAccountNameSnapshot'],
      ),
      categoryNameSnapshot: serializer.fromJson<String?>(
        json['categoryNameSnapshot'],
      ),
      subCategoryNameSnapshot: serializer.fromJson<String?>(
        json['subCategoryNameSnapshot'],
      ),
      costItemNameSnapshot: serializer.fromJson<String?>(
        json['costItemNameSnapshot'],
      ),
      incomeSource: serializer.fromJson<String?>(json['incomeSource']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      txnDate: serializer.fromJson<String>(json['txnDate']),
      title: serializer.fromJson<String?>(json['title']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<int>(accountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'subCategoryId': serializer.toJson<int?>(subCategoryId),
      'costItemId': serializer.toJson<int?>(costItemId),
      'accountNameSnapshot': serializer.toJson<String>(accountNameSnapshot),
      'toAccountNameSnapshot': serializer.toJson<String?>(
        toAccountNameSnapshot,
      ),
      'categoryNameSnapshot': serializer.toJson<String?>(categoryNameSnapshot),
      'subCategoryNameSnapshot': serializer.toJson<String?>(
        subCategoryNameSnapshot,
      ),
      'costItemNameSnapshot': serializer.toJson<String?>(costItemNameSnapshot),
      'incomeSource': serializer.toJson<String?>(incomeSource),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'txnDate': serializer.toJson<String>(txnDate),
      'title': serializer.toJson<String?>(title),
      'remarks': serializer.toJson<String?>(remarks),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? profileId,
    String? type,
    int? accountId,
    Value<int?> toAccountId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> subCategoryId = const Value.absent(),
    Value<int?> costItemId = const Value.absent(),
    String? accountNameSnapshot,
    Value<String?> toAccountNameSnapshot = const Value.absent(),
    Value<String?> categoryNameSnapshot = const Value.absent(),
    Value<String?> subCategoryNameSnapshot = const Value.absent(),
    Value<String?> costItemNameSnapshot = const Value.absent(),
    Value<String?> incomeSource = const Value.absent(),
    int? amountMinor,
    String? txnDate,
    Value<String?> title = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> idempotencyKey = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    subCategoryId: subCategoryId.present
        ? subCategoryId.value
        : this.subCategoryId,
    costItemId: costItemId.present ? costItemId.value : this.costItemId,
    accountNameSnapshot: accountNameSnapshot ?? this.accountNameSnapshot,
    toAccountNameSnapshot: toAccountNameSnapshot.present
        ? toAccountNameSnapshot.value
        : this.toAccountNameSnapshot,
    categoryNameSnapshot: categoryNameSnapshot.present
        ? categoryNameSnapshot.value
        : this.categoryNameSnapshot,
    subCategoryNameSnapshot: subCategoryNameSnapshot.present
        ? subCategoryNameSnapshot.value
        : this.subCategoryNameSnapshot,
    costItemNameSnapshot: costItemNameSnapshot.present
        ? costItemNameSnapshot.value
        : this.costItemNameSnapshot,
    incomeSource: incomeSource.present ? incomeSource.value : this.incomeSource,
    amountMinor: amountMinor ?? this.amountMinor,
    txnDate: txnDate ?? this.txnDate,
    title: title.present ? title.value : this.title,
    remarks: remarks.present ? remarks.value : this.remarks,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(FinancialTransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subCategoryId: data.subCategoryId.present
          ? data.subCategoryId.value
          : this.subCategoryId,
      costItemId: data.costItemId.present
          ? data.costItemId.value
          : this.costItemId,
      accountNameSnapshot: data.accountNameSnapshot.present
          ? data.accountNameSnapshot.value
          : this.accountNameSnapshot,
      toAccountNameSnapshot: data.toAccountNameSnapshot.present
          ? data.toAccountNameSnapshot.value
          : this.toAccountNameSnapshot,
      categoryNameSnapshot: data.categoryNameSnapshot.present
          ? data.categoryNameSnapshot.value
          : this.categoryNameSnapshot,
      subCategoryNameSnapshot: data.subCategoryNameSnapshot.present
          ? data.subCategoryNameSnapshot.value
          : this.subCategoryNameSnapshot,
      costItemNameSnapshot: data.costItemNameSnapshot.present
          ? data.costItemNameSnapshot.value
          : this.costItemNameSnapshot,
      incomeSource: data.incomeSource.present
          ? data.incomeSource.value
          : this.incomeSource,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      txnDate: data.txnDate.present ? data.txnDate.value : this.txnDate,
      title: data.title.present ? data.title.value : this.title,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('costItemId: $costItemId, ')
          ..write('accountNameSnapshot: $accountNameSnapshot, ')
          ..write('toAccountNameSnapshot: $toAccountNameSnapshot, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('subCategoryNameSnapshot: $subCategoryNameSnapshot, ')
          ..write('costItemNameSnapshot: $costItemNameSnapshot, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('txnDate: $txnDate, ')
          ..write('title: $title, ')
          ..write('remarks: $remarks, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    profileId,
    type,
    accountId,
    toAccountId,
    categoryId,
    subCategoryId,
    costItemId,
    accountNameSnapshot,
    toAccountNameSnapshot,
    categoryNameSnapshot,
    subCategoryNameSnapshot,
    costItemNameSnapshot,
    incomeSource,
    amountMinor,
    txnDate,
    title,
    remarks,
    idempotencyKey,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.subCategoryId == this.subCategoryId &&
          other.costItemId == this.costItemId &&
          other.accountNameSnapshot == this.accountNameSnapshot &&
          other.toAccountNameSnapshot == this.toAccountNameSnapshot &&
          other.categoryNameSnapshot == this.categoryNameSnapshot &&
          other.subCategoryNameSnapshot == this.subCategoryNameSnapshot &&
          other.costItemNameSnapshot == this.costItemNameSnapshot &&
          other.incomeSource == this.incomeSource &&
          other.amountMinor == this.amountMinor &&
          other.txnDate == this.txnDate &&
          other.title == this.title &&
          other.remarks == this.remarks &&
          other.idempotencyKey == this.idempotencyKey &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialTransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> type;
  final Value<int> accountId;
  final Value<int?> toAccountId;
  final Value<int?> categoryId;
  final Value<int?> subCategoryId;
  final Value<int?> costItemId;
  final Value<String> accountNameSnapshot;
  final Value<String?> toAccountNameSnapshot;
  final Value<String?> categoryNameSnapshot;
  final Value<String?> subCategoryNameSnapshot;
  final Value<String?> costItemNameSnapshot;
  final Value<String?> incomeSource;
  final Value<int> amountMinor;
  final Value<String> txnDate;
  final Value<String?> title;
  final Value<String?> remarks;
  final Value<String?> idempotencyKey;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialTransactionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.costItemId = const Value.absent(),
    this.accountNameSnapshot = const Value.absent(),
    this.toAccountNameSnapshot = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.subCategoryNameSnapshot = const Value.absent(),
    this.costItemNameSnapshot = const Value.absent(),
    this.incomeSource = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.txnDate = const Value.absent(),
    this.title = const Value.absent(),
    this.remarks = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String type,
    required int accountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.costItemId = const Value.absent(),
    required String accountNameSnapshot,
    this.toAccountNameSnapshot = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.subCategoryNameSnapshot = const Value.absent(),
    this.costItemNameSnapshot = const Value.absent(),
    this.incomeSource = const Value.absent(),
    required int amountMinor,
    required String txnDate,
    this.title = const Value.absent(),
    this.remarks = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : profileId = Value(profileId),
       type = Value(type),
       accountId = Value(accountId),
       accountNameSnapshot = Value(accountNameSnapshot),
       amountMinor = Value(amountMinor),
       txnDate = Value(txnDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? type,
    Expression<int>? accountId,
    Expression<int>? toAccountId,
    Expression<int>? categoryId,
    Expression<int>? subCategoryId,
    Expression<int>? costItemId,
    Expression<String>? accountNameSnapshot,
    Expression<String>? toAccountNameSnapshot,
    Expression<String>? categoryNameSnapshot,
    Expression<String>? subCategoryNameSnapshot,
    Expression<String>? costItemNameSnapshot,
    Expression<String>? incomeSource,
    Expression<int>? amountMinor,
    Expression<String>? txnDate,
    Expression<String>? title,
    Expression<String>? remarks,
    Expression<String>? idempotencyKey,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (costItemId != null) 'cost_item_id': costItemId,
      if (accountNameSnapshot != null)
        'account_name_snapshot': accountNameSnapshot,
      if (toAccountNameSnapshot != null)
        'to_account_name_snapshot': toAccountNameSnapshot,
      if (categoryNameSnapshot != null)
        'category_name_snapshot': categoryNameSnapshot,
      if (subCategoryNameSnapshot != null)
        'sub_category_name_snapshot': subCategoryNameSnapshot,
      if (costItemNameSnapshot != null)
        'cost_item_name_snapshot': costItemNameSnapshot,
      if (incomeSource != null) 'income_source': incomeSource,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (txnDate != null) 'txn_date': txnDate,
      if (title != null) 'title': title,
      if (remarks != null) 'remarks': remarks,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialTransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? type,
    Value<int>? accountId,
    Value<int?>? toAccountId,
    Value<int?>? categoryId,
    Value<int?>? subCategoryId,
    Value<int?>? costItemId,
    Value<String>? accountNameSnapshot,
    Value<String?>? toAccountNameSnapshot,
    Value<String?>? categoryNameSnapshot,
    Value<String?>? subCategoryNameSnapshot,
    Value<String?>? costItemNameSnapshot,
    Value<String?>? incomeSource,
    Value<int>? amountMinor,
    Value<String>? txnDate,
    Value<String?>? title,
    Value<String?>? remarks,
    Value<String?>? idempotencyKey,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FinancialTransactionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      costItemId: costItemId ?? this.costItemId,
      accountNameSnapshot: accountNameSnapshot ?? this.accountNameSnapshot,
      toAccountNameSnapshot:
          toAccountNameSnapshot ?? this.toAccountNameSnapshot,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      subCategoryNameSnapshot:
          subCategoryNameSnapshot ?? this.subCategoryNameSnapshot,
      costItemNameSnapshot: costItemNameSnapshot ?? this.costItemNameSnapshot,
      incomeSource: incomeSource ?? this.incomeSource,
      amountMinor: amountMinor ?? this.amountMinor,
      txnDate: txnDate ?? this.txnDate,
      title: title ?? this.title,
      remarks: remarks ?? this.remarks,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (subCategoryId.present) {
      map['sub_category_id'] = Variable<int>(subCategoryId.value);
    }
    if (costItemId.present) {
      map['cost_item_id'] = Variable<int>(costItemId.value);
    }
    if (accountNameSnapshot.present) {
      map['account_name_snapshot'] = Variable<String>(
        accountNameSnapshot.value,
      );
    }
    if (toAccountNameSnapshot.present) {
      map['to_account_name_snapshot'] = Variable<String>(
        toAccountNameSnapshot.value,
      );
    }
    if (categoryNameSnapshot.present) {
      map['category_name_snapshot'] = Variable<String>(
        categoryNameSnapshot.value,
      );
    }
    if (subCategoryNameSnapshot.present) {
      map['sub_category_name_snapshot'] = Variable<String>(
        subCategoryNameSnapshot.value,
      );
    }
    if (costItemNameSnapshot.present) {
      map['cost_item_name_snapshot'] = Variable<String>(
        costItemNameSnapshot.value,
      );
    }
    if (incomeSource.present) {
      map['income_source'] = Variable<String>(incomeSource.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (txnDate.present) {
      map['txn_date'] = Variable<String>(txnDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('costItemId: $costItemId, ')
          ..write('accountNameSnapshot: $accountNameSnapshot, ')
          ..write('toAccountNameSnapshot: $toAccountNameSnapshot, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('subCategoryNameSnapshot: $subCategoryNameSnapshot, ')
          ..write('costItemNameSnapshot: $costItemNameSnapshot, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('txnDate: $txnDate, ')
          ..write('title: $title, ')
          ..write('remarks: $remarks, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionAuditLogsTable extends TransactionAuditLogs
    with TableInfo<$TransactionAuditLogsTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionAuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousJsonMeta = const VerificationMeta(
    'previousJson',
  );
  @override
  late final GeneratedColumn<String> previousJson = GeneratedColumn<String>(
    'previous_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newJsonMeta = const VerificationMeta(
    'newJson',
  );
  @override
  late final GeneratedColumn<String> newJson = GeneratedColumn<String>(
    'new_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    transactionId,
    action,
    previousJson,
    newJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('previous_json')) {
      context.handle(
        _previousJsonMeta,
        previousJson.isAcceptableOrUnknown(
          data['previous_json']!,
          _previousJsonMeta,
        ),
      );
    }
    if (data.containsKey('new_json')) {
      context.handle(
        _newJsonMeta,
        newJson.isAcceptableOrUnknown(data['new_json']!, _newJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      previousJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_json'],
      ),
      newJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionAuditLogsTable createAlias(String alias) {
    return $TransactionAuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final int id;
  final int profileId;
  final int transactionId;

  /// 'create' | 'update' | 'delete' | 'restore'
  final String action;

  /// JSON snapshots of the row before/after the action (null when n/a).
  final String? previousJson;
  final String? newJson;
  final DateTime createdAt;
  const AuditLogRow({
    required this.id,
    required this.profileId,
    required this.transactionId,
    required this.action,
    this.previousJson,
    this.newJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['transaction_id'] = Variable<int>(transactionId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || previousJson != null) {
      map['previous_json'] = Variable<String>(previousJson);
    }
    if (!nullToAbsent || newJson != null) {
      map['new_json'] = Variable<String>(newJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionAuditLogsCompanion toCompanion(bool nullToAbsent) {
    return TransactionAuditLogsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      transactionId: Value(transactionId),
      action: Value(action),
      previousJson: previousJson == null && nullToAbsent
          ? const Value.absent()
          : Value(previousJson),
      newJson: newJson == null && nullToAbsent
          ? const Value.absent()
          : Value(newJson),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      action: serializer.fromJson<String>(json['action']),
      previousJson: serializer.fromJson<String?>(json['previousJson']),
      newJson: serializer.fromJson<String?>(json['newJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'transactionId': serializer.toJson<int>(transactionId),
      'action': serializer.toJson<String>(action),
      'previousJson': serializer.toJson<String?>(previousJson),
      'newJson': serializer.toJson<String?>(newJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLogRow copyWith({
    int? id,
    int? profileId,
    int? transactionId,
    String? action,
    Value<String?> previousJson = const Value.absent(),
    Value<String?> newJson = const Value.absent(),
    DateTime? createdAt,
  }) => AuditLogRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    transactionId: transactionId ?? this.transactionId,
    action: action ?? this.action,
    previousJson: previousJson.present ? previousJson.value : this.previousJson,
    newJson: newJson.present ? newJson.value : this.newJson,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditLogRow copyWithCompanion(TransactionAuditLogsCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      action: data.action.present ? data.action.value : this.action,
      previousJson: data.previousJson.present
          ? data.previousJson.value
          : this.previousJson,
      newJson: data.newJson.present ? data.newJson.value : this.newJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('transactionId: $transactionId, ')
          ..write('action: $action, ')
          ..write('previousJson: $previousJson, ')
          ..write('newJson: $newJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    transactionId,
    action,
    previousJson,
    newJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.transactionId == this.transactionId &&
          other.action == this.action &&
          other.previousJson == this.previousJson &&
          other.newJson == this.newJson &&
          other.createdAt == this.createdAt);
}

class TransactionAuditLogsCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> transactionId;
  final Value<String> action;
  final Value<String?> previousJson;
  final Value<String?> newJson;
  final Value<DateTime> createdAt;
  const TransactionAuditLogsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.action = const Value.absent(),
    this.previousJson = const Value.absent(),
    this.newJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionAuditLogsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int transactionId,
    required String action,
    this.previousJson = const Value.absent(),
    this.newJson = const Value.absent(),
    required DateTime createdAt,
  }) : profileId = Value(profileId),
       transactionId = Value(transactionId),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<AuditLogRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? transactionId,
    Expression<String>? action,
    Expression<String>? previousJson,
    Expression<String>? newJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (action != null) 'action': action,
      if (previousJson != null) 'previous_json': previousJson,
      if (newJson != null) 'new_json': newJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionAuditLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? transactionId,
    Value<String>? action,
    Value<String?>? previousJson,
    Value<String?>? newJson,
    Value<DateTime>? createdAt,
  }) {
    return TransactionAuditLogsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      transactionId: transactionId ?? this.transactionId,
      action: action ?? this.action,
      previousJson: previousJson ?? this.previousJson,
      newJson: newJson ?? this.newJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (previousJson.present) {
      map['previous_json'] = Variable<String>(previousJson.value);
    }
    if (newJson.present) {
      map['new_json'] = Variable<String>(newJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionAuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('transactionId: $transactionId, ')
          ..write('action: $action, ')
          ..write('previousJson: $previousJson, ')
          ..write('newJson: $newJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FinancialProfilesTable financialProfiles =
      $FinancialProfilesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SubCategoriesTable subCategories = $SubCategoriesTable(this);
  late final $CostItemsTable costItems = $CostItemsTable(this);
  late final $ApplicationSettingsTable applicationSettings =
      $ApplicationSettingsTable(this);
  late final $MonthlyBudgetsTable monthlyBudgets = $MonthlyBudgetsTable(this);
  late final $CategoryBudgetsTable categoryBudgets = $CategoryBudgetsTable(
    this,
  );
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $FinancialTransactionsTable financialTransactions =
      $FinancialTransactionsTable(this);
  late final $TransactionAuditLogsTable transactionAuditLogs =
      $TransactionAuditLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    financialProfiles,
    categories,
    subCategories,
    costItems,
    applicationSettings,
    monthlyBudgets,
    categoryBudgets,
    accounts,
    financialTransactions,
    transactionAuditLogs,
  ];
}

typedef $$FinancialProfilesTableCreateCompanionBuilder =
    FinancialProfilesCompanion Function({
      Value<int> id,
      required String name,
      Value<String> currencyCode,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$FinancialProfilesTableUpdateCompanionBuilder =
    FinancialProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> currencyCode,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$FinancialProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $FinancialProfilesTable, ProfileRow> {
  $$FinancialProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRow>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'financial_profiles__id__categories__profile_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinancialProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinancialProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinancialProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinancialProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialProfilesTable,
          ProfileRow,
          $$FinancialProfilesTableFilterComposer,
          $$FinancialProfilesTableOrderingComposer,
          $$FinancialProfilesTableAnnotationComposer,
          $$FinancialProfilesTableCreateCompanionBuilder,
          $$FinancialProfilesTableUpdateCompanionBuilder,
          (ProfileRow, $$FinancialProfilesTableReferences),
          ProfileRow,
          PrefetchHooks Function({bool categoriesRefs})
        > {
  $$FinancialProfilesTableTableManager(
    _$AppDatabase db,
    $FinancialProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FinancialProfilesCompanion(
                id: id,
                name: name,
                currencyCode: currencyCode,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => FinancialProfilesCompanion.insert(
                id: id,
                name: name,
                currencyCode: currencyCode,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinancialProfilesTable, ProfileRow>(table),
                  $$FinancialProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (categoriesRefs) db.categories],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (categoriesRefs)
                    await $_getPrefetchedDataByColumns<
                      ProfileRow,
                      $FinancialProfilesTable,
                      CategoryRow,
                      $CategoriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$FinancialProfilesTableReferences
                          ._categoriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FinancialProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).categoriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'profile_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FinancialProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialProfilesTable,
      ProfileRow,
      $$FinancialProfilesTableFilterComposer,
      $$FinancialProfilesTableOrderingComposer,
      $$FinancialProfilesTableAnnotationComposer,
      $$FinancialProfilesTableCreateCompanionBuilder,
      $$FinancialProfilesTableUpdateCompanionBuilder,
      (ProfileRow, $$FinancialProfilesTableReferences),
      ProfileRow,
      PrefetchHooks Function({bool categoriesRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required int profileId,
  required String name,
  Value<String?> description,
  Value<String?> icon,
  Value<int?> color,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> name,
  Value<String?> description,
  Value<String?> icon,
  Value<int?> color,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FinancialProfilesTable _profileIdTable(_$AppDatabase db) => db
      .financialProfiles
      .createAlias('categories__profile_id__financial_profiles__id');

  $$FinancialProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$FinancialProfilesTableTableManager(
      $_db,
      $_db.financialProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialProfilesTableFilterComposer get profileId {
    final $$FinancialProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.financialProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialProfilesTableFilterComposer(
            $db: $db,
            $table: $db.financialProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialProfilesTableOrderingComposer get profileId {
    final $$FinancialProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.financialProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.financialProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FinancialProfilesTableAnnotationComposer get profileId {
    final $$FinancialProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.profileId,
          referencedTable: $db.financialProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.financialProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool profileId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                profileId: profileId,
                name: name,
                description: description,
                icon: icon,
                color: color,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CategoriesCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                description: description,
                icon: icon,
                color: color,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$CategoriesTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$CategoriesTableReferences
                            ._profileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$SubCategoriesTableCreateCompanionBuilder =
    SubCategoriesCompanion Function({
      Value<int> id,
      required int profileId,
      required int categoryId,
      required String name,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SubCategoriesTableUpdateCompanionBuilder =
    SubCategoriesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> categoryId,
      Value<String> name,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SubCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SubCategoriesTable> {
  $$SubCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubCategoriesTable> {
  $$SubCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubCategoriesTable> {
  $$SubCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubCategoriesTable,
          SubCategoryRow,
          $$SubCategoriesTableFilterComposer,
          $$SubCategoriesTableOrderingComposer,
          $$SubCategoriesTableAnnotationComposer,
          $$SubCategoriesTableCreateCompanionBuilder,
          $$SubCategoriesTableUpdateCompanionBuilder,
          (
            SubCategoryRow,
            BaseReferences<_$AppDatabase, $SubCategoriesTable, SubCategoryRow>,
          ),
          SubCategoryRow,
          PrefetchHooks Function()
        > {
  $$SubCategoriesTableTableManager(_$AppDatabase db, $SubCategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubCategoriesCompanion(
                id: id,
                profileId: profileId,
                categoryId: categoryId,
                name: name,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int categoryId,
                required String name,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SubCategoriesCompanion.insert(
                id: id,
                profileId: profileId,
                categoryId: categoryId,
                name: name,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubCategoriesTable, SubCategoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SubCategoriesTable,
                    SubCategoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubCategoriesTable,
      SubCategoryRow,
      $$SubCategoriesTableFilterComposer,
      $$SubCategoriesTableOrderingComposer,
      $$SubCategoriesTableAnnotationComposer,
      $$SubCategoriesTableCreateCompanionBuilder,
      $$SubCategoriesTableUpdateCompanionBuilder,
      (
        SubCategoryRow,
        BaseReferences<_$AppDatabase, $SubCategoriesTable, SubCategoryRow>,
      ),
      SubCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$CostItemsTableCreateCompanionBuilder = CostItemsCompanion Function({
  Value<int> id,
  required int profileId,
  required int subCategoryId,
  required String name,
  Value<String?> description,
  Value<int?> defaultAmountMinor,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$CostItemsTableUpdateCompanionBuilder = CostItemsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<int> subCategoryId,
  Value<String> name,
  Value<String?> description,
  Value<int?> defaultAmountMinor,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CostItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CostItemsTable> {
  $$CostItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultAmountMinor => $composableBuilder(
    column: $table.defaultAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CostItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CostItemsTable> {
  $$CostItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultAmountMinor => $composableBuilder(
    column: $table.defaultAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CostItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CostItemsTable> {
  $$CostItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultAmountMinor => $composableBuilder(
    column: $table.defaultAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CostItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CostItemsTable,
          CostItemRow,
          $$CostItemsTableFilterComposer,
          $$CostItemsTableOrderingComposer,
          $$CostItemsTableAnnotationComposer,
          $$CostItemsTableCreateCompanionBuilder,
          $$CostItemsTableUpdateCompanionBuilder,
          (
            CostItemRow,
            BaseReferences<_$AppDatabase, $CostItemsTable, CostItemRow>,
          ),
          CostItemRow,
          PrefetchHooks Function()
        > {
  $$CostItemsTableTableManager(_$AppDatabase db, $CostItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CostItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CostItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CostItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> subCategoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> defaultAmountMinor = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CostItemsCompanion(
                id: id,
                profileId: profileId,
                subCategoryId: subCategoryId,
                name: name,
                description: description,
                defaultAmountMinor: defaultAmountMinor,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int subCategoryId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int?> defaultAmountMinor = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CostItemsCompanion.insert(
                id: id,
                profileId: profileId,
                subCategoryId: subCategoryId,
                name: name,
                description: description,
                defaultAmountMinor: defaultAmountMinor,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CostItemsTable, CostItemRow>(table),
                  BaseReferences<_$AppDatabase, $CostItemsTable, CostItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CostItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CostItemsTable,
      CostItemRow,
      $$CostItemsTableFilterComposer,
      $$CostItemsTableOrderingComposer,
      $$CostItemsTableAnnotationComposer,
      $$CostItemsTableCreateCompanionBuilder,
      $$CostItemsTableUpdateCompanionBuilder,
      (
        CostItemRow,
        BaseReferences<_$AppDatabase, $CostItemsTable, CostItemRow>,
      ),
      CostItemRow,
      PrefetchHooks Function()
    >;
typedef $$ApplicationSettingsTableCreateCompanionBuilder =
    ApplicationSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ApplicationSettingsTableUpdateCompanionBuilder =
    ApplicationSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ApplicationSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ApplicationSettingsTable> {
  $$ApplicationSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApplicationSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApplicationSettingsTable> {
  $$ApplicationSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApplicationSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApplicationSettingsTable> {
  $$ApplicationSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ApplicationSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApplicationSettingsTable,
          SettingRow,
          $$ApplicationSettingsTableFilterComposer,
          $$ApplicationSettingsTableOrderingComposer,
          $$ApplicationSettingsTableAnnotationComposer,
          $$ApplicationSettingsTableCreateCompanionBuilder,
          $$ApplicationSettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<
              _$AppDatabase,
              $ApplicationSettingsTable,
              SettingRow
            >,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$ApplicationSettingsTableTableManager(
    _$AppDatabase db,
    $ApplicationSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApplicationSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApplicationSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ApplicationSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApplicationSettingsCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ApplicationSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ApplicationSettingsTable, SettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ApplicationSettingsTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApplicationSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApplicationSettingsTable,
      SettingRow,
      $$ApplicationSettingsTableFilterComposer,
      $$ApplicationSettingsTableOrderingComposer,
      $$ApplicationSettingsTableAnnotationComposer,
      $$ApplicationSettingsTableCreateCompanionBuilder,
      $$ApplicationSettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $ApplicationSettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$MonthlyBudgetsTableCreateCompanionBuilder =
    MonthlyBudgetsCompanion Function({
      Value<int> id,
      required int profileId,
      required int year,
      required int month,
      required int totalBudgetMinor,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$MonthlyBudgetsTableUpdateCompanionBuilder =
    MonthlyBudgetsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> year,
      Value<int> month,
      Value<int> totalBudgetMinor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$MonthlyBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBudgetMinor => $composableBuilder(
    column: $table.totalBudgetMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlyBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBudgetMinor => $composableBuilder(
    column: $table.totalBudgetMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlyBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get totalBudgetMinor => $composableBuilder(
    column: $table.totalBudgetMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MonthlyBudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyBudgetsTable,
          MonthlyBudgetRow,
          $$MonthlyBudgetsTableFilterComposer,
          $$MonthlyBudgetsTableOrderingComposer,
          $$MonthlyBudgetsTableAnnotationComposer,
          $$MonthlyBudgetsTableCreateCompanionBuilder,
          $$MonthlyBudgetsTableUpdateCompanionBuilder,
          (
            MonthlyBudgetRow,
            BaseReferences<
              _$AppDatabase,
              $MonthlyBudgetsTable,
              MonthlyBudgetRow
            >,
          ),
          MonthlyBudgetRow,
          PrefetchHooks Function()
        > {
  $$MonthlyBudgetsTableTableManager(
    _$AppDatabase db,
    $MonthlyBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> totalBudgetMinor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MonthlyBudgetsCompanion(
                id: id,
                profileId: profileId,
                year: year,
                month: month,
                totalBudgetMinor: totalBudgetMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int year,
                required int month,
                required int totalBudgetMinor,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => MonthlyBudgetsCompanion.insert(
                id: id,
                profileId: profileId,
                year: year,
                month: month,
                totalBudgetMinor: totalBudgetMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthlyBudgetsTable, MonthlyBudgetRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MonthlyBudgetsTable,
                    MonthlyBudgetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlyBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyBudgetsTable,
      MonthlyBudgetRow,
      $$MonthlyBudgetsTableFilterComposer,
      $$MonthlyBudgetsTableOrderingComposer,
      $$MonthlyBudgetsTableAnnotationComposer,
      $$MonthlyBudgetsTableCreateCompanionBuilder,
      $$MonthlyBudgetsTableUpdateCompanionBuilder,
      (
        MonthlyBudgetRow,
        BaseReferences<_$AppDatabase, $MonthlyBudgetsTable, MonthlyBudgetRow>,
      ),
      MonthlyBudgetRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryBudgetsTableCreateCompanionBuilder =
    CategoryBudgetsCompanion Function({
      Value<int> id,
      required int profileId,
      required int monthlyBudgetId,
      required int categoryId,
      required int amountMinor,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CategoryBudgetsTableUpdateCompanionBuilder =
    CategoryBudgetsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> monthlyBudgetId,
      Value<int> categoryId,
      Value<int> amountMinor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CategoryBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyBudgetId => $composableBuilder(
    column: $table.monthlyBudgetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyBudgetId => $composableBuilder(
    column: $table.monthlyBudgetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get monthlyBudgetId => $composableBuilder(
    column: $table.monthlyBudgetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoryBudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryBudgetsTable,
          CategoryBudgetRow,
          $$CategoryBudgetsTableFilterComposer,
          $$CategoryBudgetsTableOrderingComposer,
          $$CategoryBudgetsTableAnnotationComposer,
          $$CategoryBudgetsTableCreateCompanionBuilder,
          $$CategoryBudgetsTableUpdateCompanionBuilder,
          (
            CategoryBudgetRow,
            BaseReferences<
              _$AppDatabase,
              $CategoryBudgetsTable,
              CategoryBudgetRow
            >,
          ),
          CategoryBudgetRow,
          PrefetchHooks Function()
        > {
  $$CategoryBudgetsTableTableManager(
    _$AppDatabase db,
    $CategoryBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> monthlyBudgetId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoryBudgetsCompanion(
                id: id,
                profileId: profileId,
                monthlyBudgetId: monthlyBudgetId,
                categoryId: categoryId,
                amountMinor: amountMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int monthlyBudgetId,
                required int categoryId,
                required int amountMinor,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CategoryBudgetsCompanion.insert(
                id: id,
                profileId: profileId,
                monthlyBudgetId: monthlyBudgetId,
                categoryId: categoryId,
                amountMinor: amountMinor,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoryBudgetsTable, CategoryBudgetRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CategoryBudgetsTable,
                    CategoryBudgetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryBudgetsTable,
      CategoryBudgetRow,
      $$CategoryBudgetsTableFilterComposer,
      $$CategoryBudgetsTableOrderingComposer,
      $$CategoryBudgetsTableAnnotationComposer,
      $$CategoryBudgetsTableCreateCompanionBuilder,
      $$CategoryBudgetsTableUpdateCompanionBuilder,
      (
        CategoryBudgetRow,
        BaseReferences<_$AppDatabase, $CategoryBudgetsTable, CategoryBudgetRow>,
      ),
      CategoryBudgetRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required int profileId,
  required String name,
  Value<String> type,
  Value<int> openingBalanceMinor,
  required String openingDate,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> name,
  Value<String> type,
  Value<int> openingBalanceMinor,
  Value<String> openingDate,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<String> openingDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                profileId: profileId,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                openingDate: openingDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String name,
                Value<String> type = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                required String openingDate,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AccountsCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                openingDate: openingDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$FinancialTransactionsTableCreateCompanionBuilder =
    FinancialTransactionsCompanion Function({
      Value<int> id,
      required int profileId,
      required String type,
      required int accountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
      Value<int?> subCategoryId,
      Value<int?> costItemId,
      required String accountNameSnapshot,
      Value<String?> toAccountNameSnapshot,
      Value<String?> categoryNameSnapshot,
      Value<String?> subCategoryNameSnapshot,
      Value<String?> costItemNameSnapshot,
      Value<String?> incomeSource,
      required int amountMinor,
      required String txnDate,
      Value<String?> title,
      Value<String?> remarks,
      Value<String?> idempotencyKey,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$FinancialTransactionsTableUpdateCompanionBuilder =
    FinancialTransactionsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> type,
      Value<int> accountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
      Value<int?> subCategoryId,
      Value<int?> costItemId,
      Value<String> accountNameSnapshot,
      Value<String?> toAccountNameSnapshot,
      Value<String?> categoryNameSnapshot,
      Value<String?> subCategoryNameSnapshot,
      Value<String?> costItemNameSnapshot,
      Value<String?> incomeSource,
      Value<int> amountMinor,
      Value<String> txnDate,
      Value<String?> title,
      Value<String?> remarks,
      Value<String?> idempotencyKey,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$FinancialTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costItemId => $composableBuilder(
    column: $table.costItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNameSnapshot => $composableBuilder(
    column: $table.accountNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountNameSnapshot => $composableBuilder(
    column: $table.toAccountNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategoryNameSnapshot => $composableBuilder(
    column: $table.subCategoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costItemNameSnapshot => $composableBuilder(
    column: $table.costItemNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeSource => $composableBuilder(
    column: $table.incomeSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get txnDate => $composableBuilder(
    column: $table.txnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinancialTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costItemId => $composableBuilder(
    column: $table.costItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNameSnapshot => $composableBuilder(
    column: $table.accountNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountNameSnapshot => $composableBuilder(
    column: $table.toAccountNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategoryNameSnapshot => $composableBuilder(
    column: $table.subCategoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costItemNameSnapshot => $composableBuilder(
    column: $table.costItemNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeSource => $composableBuilder(
    column: $table.incomeSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get txnDate => $composableBuilder(
    column: $table.txnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinancialTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialTransactionsTable> {
  $$FinancialTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costItemId => $composableBuilder(
    column: $table.costItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountNameSnapshot => $composableBuilder(
    column: $table.accountNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toAccountNameSnapshot => $composableBuilder(
    column: $table.toAccountNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategoryNameSnapshot => $composableBuilder(
    column: $table.subCategoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costItemNameSnapshot => $composableBuilder(
    column: $table.costItemNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get incomeSource => $composableBuilder(
    column: $table.incomeSource,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get txnDate =>
      $composableBuilder(column: $table.txnDate, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialTransactionsTable,
          TransactionRow,
          $$FinancialTransactionsTableFilterComposer,
          $$FinancialTransactionsTableOrderingComposer,
          $$FinancialTransactionsTableAnnotationComposer,
          $$FinancialTransactionsTableCreateCompanionBuilder,
          $$FinancialTransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<
              _$AppDatabase,
              $FinancialTransactionsTable,
              TransactionRow
            >,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$FinancialTransactionsTableTableManager(
    _$AppDatabase db,
    $FinancialTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialTransactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinancialTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinancialTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subCategoryId = const Value.absent(),
                Value<int?> costItemId = const Value.absent(),
                Value<String> accountNameSnapshot = const Value.absent(),
                Value<String?> toAccountNameSnapshot = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<String?> subCategoryNameSnapshot = const Value.absent(),
                Value<String?> costItemNameSnapshot = const Value.absent(),
                Value<String?> incomeSource = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> txnDate = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FinancialTransactionsCompanion(
                id: id,
                profileId: profileId,
                type: type,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                costItemId: costItemId,
                accountNameSnapshot: accountNameSnapshot,
                toAccountNameSnapshot: toAccountNameSnapshot,
                categoryNameSnapshot: categoryNameSnapshot,
                subCategoryNameSnapshot: subCategoryNameSnapshot,
                costItemNameSnapshot: costItemNameSnapshot,
                incomeSource: incomeSource,
                amountMinor: amountMinor,
                txnDate: txnDate,
                title: title,
                remarks: remarks,
                idempotencyKey: idempotencyKey,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String type,
                required int accountId,
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subCategoryId = const Value.absent(),
                Value<int?> costItemId = const Value.absent(),
                required String accountNameSnapshot,
                Value<String?> toAccountNameSnapshot = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<String?> subCategoryNameSnapshot = const Value.absent(),
                Value<String?> costItemNameSnapshot = const Value.absent(),
                Value<String?> incomeSource = const Value.absent(),
                required int amountMinor,
                required String txnDate,
                Value<String?> title = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => FinancialTransactionsCompanion.insert(
                id: id,
                profileId: profileId,
                type: type,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                costItemId: costItemId,
                accountNameSnapshot: accountNameSnapshot,
                toAccountNameSnapshot: toAccountNameSnapshot,
                categoryNameSnapshot: categoryNameSnapshot,
                subCategoryNameSnapshot: subCategoryNameSnapshot,
                costItemNameSnapshot: costItemNameSnapshot,
                incomeSource: incomeSource,
                amountMinor: amountMinor,
                txnDate: txnDate,
                title: title,
                remarks: remarks,
                idempotencyKey: idempotencyKey,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinancialTransactionsTable, TransactionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $FinancialTransactionsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinancialTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialTransactionsTable,
      TransactionRow,
      $$FinancialTransactionsTableFilterComposer,
      $$FinancialTransactionsTableOrderingComposer,
      $$FinancialTransactionsTableAnnotationComposer,
      $$FinancialTransactionsTableCreateCompanionBuilder,
      $$FinancialTransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<
          _$AppDatabase,
          $FinancialTransactionsTable,
          TransactionRow
        >,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionAuditLogsTableCreateCompanionBuilder =
    TransactionAuditLogsCompanion Function({
      Value<int> id,
      required int profileId,
      required int transactionId,
      required String action,
      Value<String?> previousJson,
      Value<String?> newJson,
      required DateTime createdAt,
    });
typedef $$TransactionAuditLogsTableUpdateCompanionBuilder =
    TransactionAuditLogsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> transactionId,
      Value<String> action,
      Value<String?> previousJson,
      Value<String?> newJson,
      Value<DateTime> createdAt,
    });

class $$TransactionAuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionAuditLogsTable> {
  $$TransactionAuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousJson => $composableBuilder(
    column: $table.previousJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newJson => $composableBuilder(
    column: $table.newJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionAuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionAuditLogsTable> {
  $$TransactionAuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousJson => $composableBuilder(
    column: $table.previousJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newJson => $composableBuilder(
    column: $table.newJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionAuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionAuditLogsTable> {
  $$TransactionAuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get previousJson => $composableBuilder(
    column: $table.previousJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get newJson =>
      $composableBuilder(column: $table.newJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionAuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionAuditLogsTable,
          AuditLogRow,
          $$TransactionAuditLogsTableFilterComposer,
          $$TransactionAuditLogsTableOrderingComposer,
          $$TransactionAuditLogsTableAnnotationComposer,
          $$TransactionAuditLogsTableCreateCompanionBuilder,
          $$TransactionAuditLogsTableUpdateCompanionBuilder,
          (
            AuditLogRow,
            BaseReferences<
              _$AppDatabase,
              $TransactionAuditLogsTable,
              AuditLogRow
            >,
          ),
          AuditLogRow,
          PrefetchHooks Function()
        > {
  $$TransactionAuditLogsTableTableManager(
    _$AppDatabase db,
    $TransactionAuditLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionAuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionAuditLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionAuditLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> previousJson = const Value.absent(),
                Value<String?> newJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransactionAuditLogsCompanion(
                id: id,
                profileId: profileId,
                transactionId: transactionId,
                action: action,
                previousJson: previousJson,
                newJson: newJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int transactionId,
                required String action,
                Value<String?> previousJson = const Value.absent(),
                Value<String?> newJson = const Value.absent(),
                required DateTime createdAt,
              }) => TransactionAuditLogsCompanion.insert(
                id: id,
                profileId: profileId,
                transactionId: transactionId,
                action: action,
                previousJson: previousJson,
                newJson: newJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionAuditLogsTable, AuditLogRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionAuditLogsTable,
                    AuditLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionAuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionAuditLogsTable,
      AuditLogRow,
      $$TransactionAuditLogsTableFilterComposer,
      $$TransactionAuditLogsTableOrderingComposer,
      $$TransactionAuditLogsTableAnnotationComposer,
      $$TransactionAuditLogsTableCreateCompanionBuilder,
      $$TransactionAuditLogsTableUpdateCompanionBuilder,
      (
        AuditLogRow,
        BaseReferences<_$AppDatabase, $TransactionAuditLogsTable, AuditLogRow>,
      ),
      AuditLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FinancialProfilesTableTableManager get financialProfiles =>
      $$FinancialProfilesTableTableManager(_db, _db.financialProfiles);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SubCategoriesTableTableManager get subCategories =>
      $$SubCategoriesTableTableManager(_db, _db.subCategories);
  $$CostItemsTableTableManager get costItems =>
      $$CostItemsTableTableManager(_db, _db.costItems);
  $$ApplicationSettingsTableTableManager get applicationSettings =>
      $$ApplicationSettingsTableTableManager(_db, _db.applicationSettings);
  $$MonthlyBudgetsTableTableManager get monthlyBudgets =>
      $$MonthlyBudgetsTableTableManager(_db, _db.monthlyBudgets);
  $$CategoryBudgetsTableTableManager get categoryBudgets =>
      $$CategoryBudgetsTableTableManager(_db, _db.categoryBudgets);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$FinancialTransactionsTableTableManager get financialTransactions =>
      $$FinancialTransactionsTableTableManager(_db, _db.financialTransactions);
  $$TransactionAuditLogsTableTableManager get transactionAuditLogs =>
      $$TransactionAuditLogsTableTableManager(_db, _db.transactionAuditLogs);
}
