// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AgendasTable extends Agendas with TableInfo<$AgendasTable, Agenda> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgendasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverStyleMeta = const VerificationMeta(
    'coverStyle',
  );
  @override
  late final GeneratedColumn<String> coverStyle = GeneratedColumn<String>(
    'cover_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('honey'),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    coverStyle,
    pageCount,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agendas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Agenda> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_style')) {
      context.handle(
        _coverStyleMeta,
        coverStyle.isAcceptableOrUnknown(data['cover_style']!, _coverStyleMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Agenda map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Agenda(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_style'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AgendasTable createAlias(String alias) {
    return $AgendasTable(attachedDatabase, alias);
  }
}

class Agenda extends DataClass implements Insertable<Agenda> {
  /// UUID v4 unique identifier.
  final String id;

  /// User-facing title for the agenda.
  final String title;

  /// Aesthetic cover design token (e.g., 'honey', 'lavender', 'sage', 'rose', 'slate').
  final String coverStyle;

  /// Current number of pages in the agenda.
  final int pageCount;

  /// Creation timestamp in UTC.
  final DateTime createdAt;

  /// Modification timestamp in UTC.
  final DateTime updatedAt;

  /// Soft-delete indicator for synchronization conflict resolution.
  final bool isDeleted;
  const Agenda({
    required this.id,
    required this.title,
    required this.coverStyle,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['cover_style'] = Variable<String>(coverStyle);
    map['page_count'] = Variable<int>(pageCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AgendasCompanion toCompanion(bool nullToAbsent) {
    return AgendasCompanion(
      id: Value(id),
      title: Value(title),
      coverStyle: Value(coverStyle),
      pageCount: Value(pageCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Agenda.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Agenda(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      coverStyle: serializer.fromJson<String>(json['coverStyle']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'coverStyle': serializer.toJson<String>(coverStyle),
      'pageCount': serializer.toJson<int>(pageCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Agenda copyWith({
    String? id,
    String? title,
    String? coverStyle,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Agenda(
    id: id ?? this.id,
    title: title ?? this.title,
    coverStyle: coverStyle ?? this.coverStyle,
    pageCount: pageCount ?? this.pageCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Agenda copyWithCompanion(AgendasCompanion data) {
    return Agenda(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      coverStyle: data.coverStyle.present
          ? data.coverStyle.value
          : this.coverStyle,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Agenda(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverStyle: $coverStyle, ')
          ..write('pageCount: $pageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    coverStyle,
    pageCount,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Agenda &&
          other.id == this.id &&
          other.title == this.title &&
          other.coverStyle == this.coverStyle &&
          other.pageCount == this.pageCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class AgendasCompanion extends UpdateCompanion<Agenda> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> coverStyle;
  final Value<int> pageCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AgendasCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.coverStyle = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgendasCompanion.insert({
    required String id,
    required String title,
    this.coverStyle = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Agenda> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? coverStyle,
    Expression<int>? pageCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (coverStyle != null) 'cover_style': coverStyle,
      if (pageCount != null) 'page_count': pageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgendasCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? coverStyle,
    Value<int>? pageCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AgendasCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      coverStyle: coverStyle ?? this.coverStyle,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverStyle.present) {
      map['cover_style'] = Variable<String>(coverStyle.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgendasCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverStyle: $coverStyle, ')
          ..write('pageCount: $pageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PagesTable extends Pages with TableInfo<$PagesTable, Page> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agendaIdMeta = const VerificationMeta(
    'agendaId',
  );
  @override
  late final GeneratedColumn<String> agendaId = GeneratedColumn<String>(
    'agenda_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agendas (id)',
    ),
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backgroundStyleMeta = const VerificationMeta(
    'backgroundStyle',
  );
  @override
  late final GeneratedColumn<String> backgroundStyle = GeneratedColumn<String>(
    'background_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dotted'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agendaId,
    pageNumber,
    backgroundStyle,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Page> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agenda_id')) {
      context.handle(
        _agendaIdMeta,
        agendaId.isAcceptableOrUnknown(data['agenda_id']!, _agendaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agendaIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('background_style')) {
      context.handle(
        _backgroundStyleMeta,
        backgroundStyle.isAcceptableOrUnknown(
          data['background_style']!,
          _backgroundStyleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Page map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Page(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agendaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agenda_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      backgroundStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_style'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class Page extends DataClass implements Insertable<Page> {
  /// UUID v4 unique identifier.
  final String id;

  /// Foreign key linking the page to its parent agenda.
  final String agendaId;

  /// 0-indexed or 1-indexed order sequence of this page within the agenda.
  final int pageNumber;

  /// Paper texture style (e.g., 'blank', 'dotted', 'lined', 'grid').
  final String backgroundStyle;

  /// Creation timestamp in UTC.
  final DateTime createdAt;

  /// Modification timestamp in UTC.
  final DateTime updatedAt;

  /// Soft-delete indicator.
  final bool isDeleted;
  const Page({
    required this.id,
    required this.agendaId,
    required this.pageNumber,
    required this.backgroundStyle,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agenda_id'] = Variable<String>(agendaId);
    map['page_number'] = Variable<int>(pageNumber);
    map['background_style'] = Variable<String>(backgroundStyle);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      agendaId: Value(agendaId),
      pageNumber: Value(pageNumber),
      backgroundStyle: Value(backgroundStyle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Page.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<String>(json['id']),
      agendaId: serializer.fromJson<String>(json['agendaId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      backgroundStyle: serializer.fromJson<String>(json['backgroundStyle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agendaId': serializer.toJson<String>(agendaId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'backgroundStyle': serializer.toJson<String>(backgroundStyle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Page copyWith({
    String? id,
    String? agendaId,
    int? pageNumber,
    String? backgroundStyle,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Page(
    id: id ?? this.id,
    agendaId: agendaId ?? this.agendaId,
    pageNumber: pageNumber ?? this.pageNumber,
    backgroundStyle: backgroundStyle ?? this.backgroundStyle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      agendaId: data.agendaId.present ? data.agendaId.value : this.agendaId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      backgroundStyle: data.backgroundStyle.present
          ? data.backgroundStyle.value
          : this.backgroundStyle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('agendaId: $agendaId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('backgroundStyle: $backgroundStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agendaId,
    pageNumber,
    backgroundStyle,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.agendaId == this.agendaId &&
          other.pageNumber == this.pageNumber &&
          other.backgroundStyle == this.backgroundStyle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<String> id;
  final Value<String> agendaId;
  final Value<int> pageNumber;
  final Value<String> backgroundStyle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.agendaId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.backgroundStyle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    required String agendaId,
    required int pageNumber,
    this.backgroundStyle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agendaId = Value(agendaId),
       pageNumber = Value(pageNumber);
  static Insertable<Page> custom({
    Expression<String>? id,
    Expression<String>? agendaId,
    Expression<int>? pageNumber,
    Expression<String>? backgroundStyle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agendaId != null) 'agenda_id': agendaId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (backgroundStyle != null) 'background_style': backgroundStyle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesCompanion copyWith({
    Value<String>? id,
    Value<String>? agendaId,
    Value<int>? pageNumber,
    Value<String>? backgroundStyle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      agendaId: agendaId ?? this.agendaId,
      pageNumber: pageNumber ?? this.pageNumber,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agendaId.present) {
      map['agenda_id'] = Variable<String>(agendaId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (backgroundStyle.present) {
      map['background_style'] = Variable<String>(backgroundStyle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('agendaId: $agendaId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('backgroundStyle: $backgroundStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasElementsTable extends CanvasElements
    with TableInfo<$CanvasElementsTable, CanvasElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasElementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id)',
    ),
  );
  static const VerificationMeta _widgetTypeMeta = const VerificationMeta(
    'widgetType',
  );
  @override
  late final GeneratedColumn<String> widgetType = GeneratedColumn<String>(
    'widget_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posXMeta = const VerificationMeta('posX');
  @override
  late final GeneratedColumn<double> posX = GeneratedColumn<double>(
    'pos_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _posYMeta = const VerificationMeta('posY');
  @override
  late final GeneratedColumn<double> posY = GeneratedColumn<double>(
    'pos_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(220.0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(180.0),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    widgetType,
    posX,
    posY,
    width,
    height,
    rotation,
    configJson,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_elements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasElement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('widget_type')) {
      context.handle(
        _widgetTypeMeta,
        widgetType.isAcceptableOrUnknown(data['widget_type']!, _widgetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_widgetTypeMeta);
    }
    if (data.containsKey('pos_x')) {
      context.handle(
        _posXMeta,
        posX.isAcceptableOrUnknown(data['pos_x']!, _posXMeta),
      );
    }
    if (data.containsKey('pos_y')) {
      context.handle(
        _posYMeta,
        posY.isAcceptableOrUnknown(data['pos_y']!, _posYMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CanvasElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasElement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      widgetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}widget_type'],
      )!,
      posX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_x'],
      )!,
      posY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CanvasElementsTable createAlias(String alias) {
    return $CanvasElementsTable(attachedDatabase, alias);
  }
}

class CanvasElement extends DataClass implements Insertable<CanvasElement> {
  /// UUID v4 unique identifier.
  final String id;

  /// Foreign key referencing the page this element is placed upon.
  final String pageId;

  /// Modular widget type discriminator (e.g. 'calendar_grid', 'budget_calculator', 'journal_block', 'text_box').
  final String widgetType;

  /// X coordinate in the unscaled page coordinate system.
  final double posX;

  /// Y coordinate in the unscaled page coordinate system.
  final double posY;

  /// Rendered width of the widget container.
  final double width;

  /// Rendered height of the widget container.
  final double height;

  /// Rotation angle around center in radians.
  final double rotation;

  /// JSON payload storing widget-specific contents (e.g., checklist items, budget entries, text body).
  final String configJson;

  /// Creation timestamp in UTC.
  final DateTime createdAt;

  /// Modification timestamp in UTC.
  final DateTime updatedAt;

  /// Soft-delete indicator.
  final bool isDeleted;
  const CanvasElement({
    required this.id,
    required this.pageId,
    required this.widgetType,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.rotation,
    required this.configJson,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['widget_type'] = Variable<String>(widgetType);
    map['pos_x'] = Variable<double>(posX);
    map['pos_y'] = Variable<double>(posY);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['rotation'] = Variable<double>(rotation);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CanvasElementsCompanion toCompanion(bool nullToAbsent) {
    return CanvasElementsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      widgetType: Value(widgetType),
      posX: Value(posX),
      posY: Value(posY),
      width: Value(width),
      height: Value(height),
      rotation: Value(rotation),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory CanvasElement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasElement(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      widgetType: serializer.fromJson<String>(json['widgetType']),
      posX: serializer.fromJson<double>(json['posX']),
      posY: serializer.fromJson<double>(json['posY']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      rotation: serializer.fromJson<double>(json['rotation']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'widgetType': serializer.toJson<String>(widgetType),
      'posX': serializer.toJson<double>(posX),
      'posY': serializer.toJson<double>(posY),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'rotation': serializer.toJson<double>(rotation),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CanvasElement copyWith({
    String? id,
    String? pageId,
    String? widgetType,
    double? posX,
    double? posY,
    double? width,
    double? height,
    double? rotation,
    String? configJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => CanvasElement(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    widgetType: widgetType ?? this.widgetType,
    posX: posX ?? this.posX,
    posY: posY ?? this.posY,
    width: width ?? this.width,
    height: height ?? this.height,
    rotation: rotation ?? this.rotation,
    configJson: configJson ?? this.configJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CanvasElement copyWithCompanion(CanvasElementsCompanion data) {
    return CanvasElement(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      widgetType: data.widgetType.present
          ? data.widgetType.value
          : this.widgetType,
      posX: data.posX.present ? data.posX.value : this.posX,
      posY: data.posY.present ? data.posY.value : this.posY,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasElement(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('widgetType: $widgetType, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    widgetType,
    posX,
    posY,
    width,
    height,
    rotation,
    configJson,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasElement &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.widgetType == this.widgetType &&
          other.posX == this.posX &&
          other.posY == this.posY &&
          other.width == this.width &&
          other.height == this.height &&
          other.rotation == this.rotation &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class CanvasElementsCompanion extends UpdateCompanion<CanvasElement> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> widgetType;
  final Value<double> posX;
  final Value<double> posY;
  final Value<double> width;
  final Value<double> height;
  final Value<double> rotation;
  final Value<String> configJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CanvasElementsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.widgetType = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotation = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasElementsCompanion.insert({
    required String id,
    required String pageId,
    required String widgetType,
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotation = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       widgetType = Value(widgetType);
  static Insertable<CanvasElement> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? widgetType,
    Expression<double>? posX,
    Expression<double>? posY,
    Expression<double>? width,
    Expression<double>? height,
    Expression<double>? rotation,
    Expression<String>? configJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (widgetType != null) 'widget_type': widgetType,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotation != null) 'rotation': rotation,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasElementsCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? widgetType,
    Value<double>? posX,
    Value<double>? posY,
    Value<double>? width,
    Value<double>? height,
    Value<double>? rotation,
    Value<String>? configJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CanvasElementsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      widgetType: widgetType ?? this.widgetType,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (widgetType.present) {
      map['widget_type'] = Variable<String>(widgetType.value);
    }
    if (posX.present) {
      map['pos_x'] = Variable<double>(posX.value);
    }
    if (posY.present) {
      map['pos_y'] = Variable<double>(posY.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasElementsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('widgetType: $widgetType, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrokesTable extends Strokes with TableInfo<$StrokesTable, Stroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id)',
    ),
  );
  static const VerificationMeta _brushTypeMeta = const VerificationMeta(
    'brushType',
  );
  @override
  late final GeneratedColumn<String> brushType = GeneratedColumn<String>(
    'brush_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pen'),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#1E293B'),
  );
  static const VerificationMeta _strokeWidthMeta = const VerificationMeta(
    'strokeWidth',
  );
  @override
  late final GeneratedColumn<double> strokeWidth = GeneratedColumn<double>(
    'stroke_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(3.0),
  );
  static const VerificationMeta _pointsJsonMeta = const VerificationMeta(
    'pointsJson',
  );
  @override
  late final GeneratedColumn<String> pointsJson = GeneratedColumn<String>(
    'points_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    brushType,
    colorHex,
    strokeWidth,
    pointsJson,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('brush_type')) {
      context.handle(
        _brushTypeMeta,
        brushType.isAcceptableOrUnknown(data['brush_type']!, _brushTypeMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('stroke_width')) {
      context.handle(
        _strokeWidthMeta,
        strokeWidth.isAcceptableOrUnknown(
          data['stroke_width']!,
          _strokeWidthMeta,
        ),
      );
    }
    if (data.containsKey('points_json')) {
      context.handle(
        _pointsJsonMeta,
        pointsJson.isAcceptableOrUnknown(data['points_json']!, _pointsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stroke(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      brushType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brush_type'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      strokeWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stroke_width'],
      )!,
      pointsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $StrokesTable createAlias(String alias) {
    return $StrokesTable(attachedDatabase, alias);
  }
}

class Stroke extends DataClass implements Insertable<Stroke> {
  /// UUID v4 unique identifier.
  final String id;

  /// Foreign key referencing the page this stroke belongs to.
  final String pageId;

  /// Brush style profile (e.g. 'pen', 'highlighter', 'eraser').
  final String brushType;

  /// 8-character or 6-character hex representation of the stroke color (e.g. '#1E293B', '#FFD97706').
  final String colorHex;

  /// Base thickness of the brush stroke in virtual points.
  final double strokeWidth;

  /// Serialized JSON array of vector points with coordinates and pressure `[{"x":10,"y":20,"p":0.8}]`.
  final String pointsJson;

  /// Creation timestamp in UTC.
  final DateTime createdAt;

  /// Modification timestamp in UTC.
  final DateTime updatedAt;

  /// Soft-delete indicator.
  final bool isDeleted;
  const Stroke({
    required this.id,
    required this.pageId,
    required this.brushType,
    required this.colorHex,
    required this.strokeWidth,
    required this.pointsJson,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['brush_type'] = Variable<String>(brushType);
    map['color_hex'] = Variable<String>(colorHex);
    map['stroke_width'] = Variable<double>(strokeWidth);
    map['points_json'] = Variable<String>(pointsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  StrokesCompanion toCompanion(bool nullToAbsent) {
    return StrokesCompanion(
      id: Value(id),
      pageId: Value(pageId),
      brushType: Value(brushType),
      colorHex: Value(colorHex),
      strokeWidth: Value(strokeWidth),
      pointsJson: Value(pointsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Stroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stroke(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      brushType: serializer.fromJson<String>(json['brushType']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      strokeWidth: serializer.fromJson<double>(json['strokeWidth']),
      pointsJson: serializer.fromJson<String>(json['pointsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'brushType': serializer.toJson<String>(brushType),
      'colorHex': serializer.toJson<String>(colorHex),
      'strokeWidth': serializer.toJson<double>(strokeWidth),
      'pointsJson': serializer.toJson<String>(pointsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Stroke copyWith({
    String? id,
    String? pageId,
    String? brushType,
    String? colorHex,
    double? strokeWidth,
    String? pointsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Stroke(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    brushType: brushType ?? this.brushType,
    colorHex: colorHex ?? this.colorHex,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    pointsJson: pointsJson ?? this.pointsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Stroke copyWithCompanion(StrokesCompanion data) {
    return Stroke(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      brushType: data.brushType.present ? data.brushType.value : this.brushType,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      strokeWidth: data.strokeWidth.present
          ? data.strokeWidth.value
          : this.strokeWidth,
      pointsJson: data.pointsJson.present
          ? data.pointsJson.value
          : this.pointsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stroke(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('brushType: $brushType, ')
          ..write('colorHex: $colorHex, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    brushType,
    colorHex,
    strokeWidth,
    pointsJson,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stroke &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.brushType == this.brushType &&
          other.colorHex == this.colorHex &&
          other.strokeWidth == this.strokeWidth &&
          other.pointsJson == this.pointsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class StrokesCompanion extends UpdateCompanion<Stroke> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> brushType;
  final Value<String> colorHex;
  final Value<double> strokeWidth;
  final Value<String> pointsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const StrokesCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.brushType = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.pointsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrokesCompanion.insert({
    required String id,
    required String pageId,
    this.brushType = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.pointsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId);
  static Insertable<Stroke> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? brushType,
    Expression<String>? colorHex,
    Expression<double>? strokeWidth,
    Expression<String>? pointsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (brushType != null) 'brush_type': brushType,
      if (colorHex != null) 'color_hex': colorHex,
      if (strokeWidth != null) 'stroke_width': strokeWidth,
      if (pointsJson != null) 'points_json': pointsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrokesCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? brushType,
    Value<String>? colorHex,
    Value<double>? strokeWidth,
    Value<String>? pointsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return StrokesCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      brushType: brushType ?? this.brushType,
      colorHex: colorHex ?? this.colorHex,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      pointsJson: pointsJson ?? this.pointsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (brushType.present) {
      map['brush_type'] = Variable<String>(brushType.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (strokeWidth.present) {
      map['stroke_width'] = Variable<double>(strokeWidth.value);
    }
    if (pointsJson.present) {
      map['points_json'] = Variable<String>(pointsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('brushType: $brushType, ')
          ..write('colorHex: $colorHex, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AgendasTable agendas = $AgendasTable(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $CanvasElementsTable canvasElements = $CanvasElementsTable(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    agendas,
    pages,
    canvasElements,
    strokes,
  ];
}

typedef $$AgendasTableCreateCompanionBuilder = AgendasCompanion Function({
  required String id,
  required String title,
  Value<String> coverStyle,
  Value<int> pageCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$AgendasTableUpdateCompanionBuilder = AgendasCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> coverStyle,
  Value<int> pageCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$AgendasTableReferences
    extends BaseReferences<_$AppDatabase, $AgendasTable, Agenda> {
  $$AgendasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PagesTable, List<Page>> _pagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pages,
    aliasName: 'agendas__id__pages__agenda_id',
  );

  $$PagesTableProcessedTableManager get pagesRefs {
    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.agendaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AgendasTableFilterComposer
    extends Composer<_$AppDatabase, $AgendasTable> {
  $$AgendasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverStyle => $composableBuilder(
    column: $table.coverStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pagesRefs(
    Expression<bool> Function($$PagesTableFilterComposer f) f,
  ) {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.agendaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgendasTableOrderingComposer
    extends Composer<_$AppDatabase, $AgendasTable> {
  $$AgendasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverStyle => $composableBuilder(
    column: $table.coverStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgendasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgendasTable> {
  $$AgendasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverStyle => $composableBuilder(
    column: $table.coverStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> pagesRefs<T extends Object>(
    Expression<T> Function($$PagesTableAnnotationComposer a) f,
  ) {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.agendaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgendasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgendasTable,
          Agenda,
          $$AgendasTableFilterComposer,
          $$AgendasTableOrderingComposer,
          $$AgendasTableAnnotationComposer,
          $$AgendasTableCreateCompanionBuilder,
          $$AgendasTableUpdateCompanionBuilder,
          (Agenda, $$AgendasTableReferences),
          Agenda,
          PrefetchHooks Function({bool pagesRefs})
        > {
  $$AgendasTableTableManager(_$AppDatabase db, $AgendasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgendasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgendasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgendasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverStyle = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendasCompanion(
                id: id,
                title: title,
                coverStyle: coverStyle,
                pageCount: pageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> coverStyle = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgendasCompanion.insert(
                id: id,
                title: title,
                coverStyle: coverStyle,
                pageCount: pageCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgendasTable, Agenda>(table),
                  $$AgendasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pagesRefs) db.pages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pagesRefs)
                    await $_getPrefetchedData<Agenda, $AgendasTable, Page>(
                      currentTable: table,
                      referencedTable: $$AgendasTableReferences._pagesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$AgendasTableReferences(db, table, p0).pagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.agendaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AgendasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgendasTable,
      Agenda,
      $$AgendasTableFilterComposer,
      $$AgendasTableOrderingComposer,
      $$AgendasTableAnnotationComposer,
      $$AgendasTableCreateCompanionBuilder,
      $$AgendasTableUpdateCompanionBuilder,
      (Agenda, $$AgendasTableReferences),
      Agenda,
      PrefetchHooks Function({bool pagesRefs})
    >;
typedef $$PagesTableCreateCompanionBuilder = PagesCompanion Function({
  required String id,
  required String agendaId,
  required int pageNumber,
  Value<String> backgroundStyle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$PagesTableUpdateCompanionBuilder = PagesCompanion Function({
  Value<String> id,
  Value<String> agendaId,
  Value<int> pageNumber,
  Value<String> backgroundStyle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$PagesTableReferences
    extends BaseReferences<_$AppDatabase, $PagesTable, Page> {
  $$PagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AgendasTable _agendaIdTable(_$AppDatabase db) =>
      db.agendas.createAlias('pages__agenda_id__agendas__id');

  $$AgendasTableProcessedTableManager get agendaId {
    final $_column = $_itemColumn<String>('agenda_id')!;

    final manager = $$AgendasTableTableManager(
      $_db,
      $_db.agendas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agendaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CanvasElementsTable, List<CanvasElement>>
  _canvasElementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.canvasElements,
    aliasName: 'pages__id__canvas_elements__page_id',
  );

  $$CanvasElementsTableProcessedTableManager get canvasElementsRefs {
    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canvasElementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StrokesTable, List<Stroke>> _strokesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.strokes,
    aliasName: 'pages__id__strokes__page_id',
  );

  $$StrokesTableProcessedTableManager get strokesRefs {
    final manager = $$StrokesTableTableManager(
      $_db,
      $_db.strokes,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_strokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundStyle => $composableBuilder(
    column: $table.backgroundStyle,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$AgendasTableFilterComposer get agendaId {
    final $$AgendasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agendaId,
      referencedTable: $db.agendas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgendasTableFilterComposer(
            $db: $db,
            $table: $db.agendas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> canvasElementsRefs(
    Expression<bool> Function($$CanvasElementsTableFilterComposer f) f,
  ) {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> strokesRefs(
    Expression<bool> Function($$StrokesTableFilterComposer f) f,
  ) {
    final $$StrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableFilterComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundStyle => $composableBuilder(
    column: $table.backgroundStyle,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgendasTableOrderingComposer get agendaId {
    final $$AgendasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agendaId,
      referencedTable: $db.agendas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgendasTableOrderingComposer(
            $db: $db,
            $table: $db.agendas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundStyle => $composableBuilder(
    column: $table.backgroundStyle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$AgendasTableAnnotationComposer get agendaId {
    final $$AgendasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agendaId,
      referencedTable: $db.agendas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgendasTableAnnotationComposer(
            $db: $db,
            $table: $db.agendas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> canvasElementsRefs<T extends Object>(
    Expression<T> Function($$CanvasElementsTableAnnotationComposer a) f,
  ) {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> strokesRefs<T extends Object>(
    Expression<T> Function($$StrokesTableAnnotationComposer a) f,
  ) {
    final $$StrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagesTable,
          Page,
          $$PagesTableFilterComposer,
          $$PagesTableOrderingComposer,
          $$PagesTableAnnotationComposer,
          $$PagesTableCreateCompanionBuilder,
          $$PagesTableUpdateCompanionBuilder,
          (Page, $$PagesTableReferences),
          Page,
          PrefetchHooks Function({
            bool agendaId,
            bool canvasElementsRefs,
            bool strokesRefs,
          })
        > {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agendaId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> backgroundStyle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                agendaId: agendaId,
                pageNumber: pageNumber,
                backgroundStyle: backgroundStyle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agendaId,
                required int pageNumber,
                Value<String> backgroundStyle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                agendaId: agendaId,
                pageNumber: pageNumber,
                backgroundStyle: backgroundStyle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PagesTable, Page>(table),
                  $$PagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                agendaId = false,
                canvasElementsRefs = false,
                strokesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (canvasElementsRefs) db.canvasElements,
                    if (strokesRefs) db.strokes,
                  ],
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
                        if (agendaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.agendaId,
                            referencedTable: $$PagesTableReferences
                                ._agendaIdTable(db),
                            referencedColumn: $$PagesTableReferences
                                ._agendaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (canvasElementsRefs)
                        await $_getPrefetchedData<
                          Page,
                          $PagesTable,
                          CanvasElement
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableReferences
                              ._canvasElementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasElementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (strokesRefs)
                        await $_getPrefetchedData<Page, $PagesTable, Stroke>(
                          currentTable: table,
                          referencedTable: $$PagesTableReferences
                              ._strokesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableReferences(db, table, p0).strokesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagesTable,
      Page,
      $$PagesTableFilterComposer,
      $$PagesTableOrderingComposer,
      $$PagesTableAnnotationComposer,
      $$PagesTableCreateCompanionBuilder,
      $$PagesTableUpdateCompanionBuilder,
      (Page, $$PagesTableReferences),
      Page,
      PrefetchHooks Function({
        bool agendaId,
        bool canvasElementsRefs,
        bool strokesRefs,
      })
    >;
typedef $$CanvasElementsTableCreateCompanionBuilder =
    CanvasElementsCompanion Function({
      required String id,
      required String pageId,
      required String widgetType,
      Value<double> posX,
      Value<double> posY,
      Value<double> width,
      Value<double> height,
      Value<double> rotation,
      Value<String> configJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CanvasElementsTableUpdateCompanionBuilder =
    CanvasElementsCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> widgetType,
      Value<double> posX,
      Value<double> posY,
      Value<double> width,
      Value<double> height,
      Value<double> rotation,
      Value<String> configJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$CanvasElementsTableReferences
    extends BaseReferences<_$AppDatabase, $CanvasElementsTable, CanvasElement> {
  $$CanvasElementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias('canvas_elements__page_id__pages__id');

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CanvasElementsTableFilterComposer
    extends Composer<_$AppDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasElementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasElementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get posX =>
      $composableBuilder(column: $table.posX, builder: (column) => column);

  GeneratedColumn<double> get posY =>
      $composableBuilder(column: $table.posY, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasElementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CanvasElementsTable,
          CanvasElement,
          $$CanvasElementsTableFilterComposer,
          $$CanvasElementsTableOrderingComposer,
          $$CanvasElementsTableAnnotationComposer,
          $$CanvasElementsTableCreateCompanionBuilder,
          $$CanvasElementsTableUpdateCompanionBuilder,
          (CanvasElement, $$CanvasElementsTableReferences),
          CanvasElement,
          PrefetchHooks Function({bool pageId})
        > {
  $$CanvasElementsTableTableManager(
    _$AppDatabase db,
    $CanvasElementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasElementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasElementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasElementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> widgetType = const Value.absent(),
                Value<double> posX = const Value.absent(),
                Value<double> posY = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasElementsCompanion(
                id: id,
                pageId: pageId,
                widgetType: widgetType,
                posX: posX,
                posY: posY,
                width: width,
                height: height,
                rotation: rotation,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String widgetType,
                Value<double> posX = const Value.absent(),
                Value<double> posY = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasElementsCompanion.insert(
                id: id,
                pageId: pageId,
                widgetType: widgetType,
                posX: posX,
                posY: posY,
                width: width,
                height: height,
                rotation: rotation,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CanvasElementsTable, CanvasElement>(table),
                  $$CanvasElementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
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
                    if (pageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.pageId,
                        referencedTable: $$CanvasElementsTableReferences
                            ._pageIdTable(db),
                        referencedColumn: $$CanvasElementsTableReferences
                            ._pageIdTable(db)
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

typedef $$CanvasElementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CanvasElementsTable,
      CanvasElement,
      $$CanvasElementsTableFilterComposer,
      $$CanvasElementsTableOrderingComposer,
      $$CanvasElementsTableAnnotationComposer,
      $$CanvasElementsTableCreateCompanionBuilder,
      $$CanvasElementsTableUpdateCompanionBuilder,
      (CanvasElement, $$CanvasElementsTableReferences),
      CanvasElement,
      PrefetchHooks Function({bool pageId})
    >;
typedef $$StrokesTableCreateCompanionBuilder = StrokesCompanion Function({
  required String id,
  required String pageId,
  Value<String> brushType,
  Value<String> colorHex,
  Value<double> strokeWidth,
  Value<String> pointsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$StrokesTableUpdateCompanionBuilder = StrokesCompanion Function({
  Value<String> id,
  Value<String> pageId,
  Value<String> brushType,
  Value<String> colorHex,
  Value<double> strokeWidth,
  Value<String> pointsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$StrokesTableReferences
    extends BaseReferences<_$AppDatabase, $StrokesTable, Stroke> {
  $$StrokesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias('strokes__page_id__pages__id');

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StrokesTableFilterComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brushType => $composableBuilder(
    column: $table.brushType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brushType => $composableBuilder(
    column: $table.brushType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brushType =>
      $composableBuilder(column: $table.brushType, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pointsJson => $composableBuilder(
    column: $table.pointsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrokesTable,
          Stroke,
          $$StrokesTableFilterComposer,
          $$StrokesTableOrderingComposer,
          $$StrokesTableAnnotationComposer,
          $$StrokesTableCreateCompanionBuilder,
          $$StrokesTableUpdateCompanionBuilder,
          (Stroke, $$StrokesTableReferences),
          Stroke,
          PrefetchHooks Function({bool pageId})
        > {
  $$StrokesTableTableManager(_$AppDatabase db, $StrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> brushType = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<double> strokeWidth = const Value.absent(),
                Value<String> pointsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion(
                id: id,
                pageId: pageId,
                brushType: brushType,
                colorHex: colorHex,
                strokeWidth: strokeWidth,
                pointsJson: pointsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                Value<String> brushType = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<double> strokeWidth = const Value.absent(),
                Value<String> pointsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion.insert(
                id: id,
                pageId: pageId,
                brushType: brushType,
                colorHex: colorHex,
                strokeWidth: strokeWidth,
                pointsJson: pointsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StrokesTable, Stroke>(table),
                  $$StrokesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
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
                    if (pageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.pageId,
                        referencedTable: $$StrokesTableReferences._pageIdTable(
                          db,
                        ),
                        referencedColumn: $$StrokesTableReferences
                            ._pageIdTable(db)
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

typedef $$StrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrokesTable,
      Stroke,
      $$StrokesTableFilterComposer,
      $$StrokesTableOrderingComposer,
      $$StrokesTableAnnotationComposer,
      $$StrokesTableCreateCompanionBuilder,
      $$StrokesTableUpdateCompanionBuilder,
      (Stroke, $$StrokesTableReferences),
      Stroke,
      PrefetchHooks Function({bool pageId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AgendasTableTableManager get agendas =>
      $$AgendasTableTableManager(_db, _db.agendas);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$CanvasElementsTableTableManager get canvasElements =>
      $$CanvasElementsTableTableManager(_db, _db.canvasElements);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
}
