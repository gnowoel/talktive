/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:talktive_server/src/generated/protocol.dart' as _i2;

abstract class Lounge implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Lounge._({
    this.id,
    required this.channelId,
    required this.name,
    this.description,
    this.emoji,
    required this.creatorId,
    required this.createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
    this.lastMessageAt,
    this.lastMessage,
    this.interests,
    this.languages,
    this.country,
    bool? isStaffLocked,
  }) : memberCount = memberCount ?? 1,
       isPublic = isPublic ?? false,
       maxMembers = maxMembers ?? 50,
       isStaffLocked = isStaffLocked ?? false;

  factory Lounge({
    int? id,
    required int channelId,
    required String name,
    String? description,
    String? emoji,
    required _i1.UuidValue creatorId,
    required DateTime createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
    DateTime? lastMessageAt,
    String? lastMessage,
    List<String>? interests,
    List<String>? languages,
    String? country,
    bool? isStaffLocked,
  }) = _LoungeImpl;

  factory Lounge.fromJson(Map<String, dynamic> jsonSerialization) {
    return Lounge(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      emoji: jsonSerialization['emoji'] as String?,
      creatorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['creatorId'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      memberCount: jsonSerialization['memberCount'] as int?,
      isPublic: jsonSerialization['isPublic'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isPublic']),
      maxMembers: jsonSerialization['maxMembers'] as int?,
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastMessage: jsonSerialization['lastMessage'] as String?,
      interests: jsonSerialization['interests'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['interests'],
            ),
      languages: jsonSerialization['languages'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['languages'],
            ),
      country: jsonSerialization['country'] as String?,
      isStaffLocked: jsonSerialization['isStaffLocked'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isStaffLocked']),
    );
  }

  static final t = LoungeTable();

  static const db = LoungeRepository._();

  @override
  int? id;

  int channelId;

  String name;

  String? description;

  String? emoji;

  _i1.UuidValue creatorId;

  DateTime createdAt;

  int memberCount;

  bool isPublic;

  int maxMembers;

  DateTime? lastMessageAt;

  String? lastMessage;

  List<String>? interests;

  List<String>? languages;

  String? country;

  bool isStaffLocked;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Lounge]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Lounge copyWith({
    int? id,
    int? channelId,
    String? name,
    String? description,
    String? emoji,
    _i1.UuidValue? creatorId,
    DateTime? createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
    DateTime? lastMessageAt,
    String? lastMessage,
    List<String>? interests,
    List<String>? languages,
    String? country,
    bool? isStaffLocked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Lounge',
      if (id != null) 'id': id,
      'channelId': channelId,
      'name': name,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      'creatorId': creatorId.toJson(),
      'createdAt': createdAt.toJson(),
      'memberCount': memberCount,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (country != null) 'country': country,
      'isStaffLocked': isStaffLocked,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Lounge',
      if (id != null) 'id': id,
      'channelId': channelId,
      'name': name,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      'creatorId': creatorId.toJson(),
      'createdAt': createdAt.toJson(),
      'memberCount': memberCount,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (country != null) 'country': country,
      'isStaffLocked': isStaffLocked,
    };
  }

  static LoungeInclude include() {
    return LoungeInclude._();
  }

  static LoungeIncludeList includeList({
    _i1.WhereExpressionBuilder<LoungeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LoungeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoungeTable>? orderByList,
    LoungeInclude? include,
  }) {
    return LoungeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Lounge.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Lounge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LoungeImpl extends Lounge {
  _LoungeImpl({
    int? id,
    required int channelId,
    required String name,
    String? description,
    String? emoji,
    required _i1.UuidValue creatorId,
    required DateTime createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
    DateTime? lastMessageAt,
    String? lastMessage,
    List<String>? interests,
    List<String>? languages,
    String? country,
    bool? isStaffLocked,
  }) : super._(
         id: id,
         channelId: channelId,
         name: name,
         description: description,
         emoji: emoji,
         creatorId: creatorId,
         createdAt: createdAt,
         memberCount: memberCount,
         isPublic: isPublic,
         maxMembers: maxMembers,
         lastMessageAt: lastMessageAt,
         lastMessage: lastMessage,
         interests: interests,
         languages: languages,
         country: country,
         isStaffLocked: isStaffLocked,
       );

  /// Returns a shallow copy of this [Lounge]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Lounge copyWith({
    Object? id = _Undefined,
    int? channelId,
    String? name,
    Object? description = _Undefined,
    Object? emoji = _Undefined,
    _i1.UuidValue? creatorId,
    DateTime? createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
    Object? lastMessageAt = _Undefined,
    Object? lastMessage = _Undefined,
    Object? interests = _Undefined,
    Object? languages = _Undefined,
    Object? country = _Undefined,
    bool? isStaffLocked,
  }) {
    return Lounge(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      emoji: emoji is String? ? emoji : this.emoji,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      lastMessage: lastMessage is String? ? lastMessage : this.lastMessage,
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      country: country is String? ? country : this.country,
      isStaffLocked: isStaffLocked ?? this.isStaffLocked,
    );
  }
}

class LoungeUpdateTable extends _i1.UpdateTable<LoungeTable> {
  LoungeUpdateTable(super.table);

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> emoji(String? value) => _i1.ColumnValue(
    table.emoji,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> creatorId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.creatorId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<int, int> memberCount(int value) => _i1.ColumnValue(
    table.memberCount,
    value,
  );

  _i1.ColumnValue<bool, bool> isPublic(bool value) => _i1.ColumnValue(
    table.isPublic,
    value,
  );

  _i1.ColumnValue<int, int> maxMembers(int value) => _i1.ColumnValue(
    table.maxMembers,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastMessageAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastMessageAt,
        value,
      );

  _i1.ColumnValue<String, String> lastMessage(String? value) => _i1.ColumnValue(
    table.lastMessage,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> interests(List<String>? value) =>
      _i1.ColumnValue(
        table.interests,
        value,
      );

  _i1.ColumnValue<List<String>, List<String>> languages(List<String>? value) =>
      _i1.ColumnValue(
        table.languages,
        value,
      );

  _i1.ColumnValue<String, String> country(String? value) => _i1.ColumnValue(
    table.country,
    value,
  );

  _i1.ColumnValue<bool, bool> isStaffLocked(bool value) => _i1.ColumnValue(
    table.isStaffLocked,
    value,
  );
}

class LoungeTable extends _i1.Table<int?> {
  LoungeTable({super.tableRelation}) : super(tableName: 'lounge') {
    updateTable = LoungeUpdateTable(this);
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    emoji = _i1.ColumnString(
      'emoji',
      this,
    );
    creatorId = _i1.ColumnUuid(
      'creatorId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    memberCount = _i1.ColumnInt(
      'memberCount',
      this,
      hasDefault: true,
    );
    isPublic = _i1.ColumnBool(
      'isPublic',
      this,
      hasDefault: true,
    );
    maxMembers = _i1.ColumnInt(
      'maxMembers',
      this,
      hasDefault: true,
    );
    lastMessageAt = _i1.ColumnDateTime(
      'lastMessageAt',
      this,
    );
    lastMessage = _i1.ColumnString(
      'lastMessage',
      this,
    );
    interests = _i1.ColumnSerializable<List<String>>(
      'interests',
      this,
    );
    languages = _i1.ColumnSerializable<List<String>>(
      'languages',
      this,
    );
    country = _i1.ColumnString(
      'country',
      this,
    );
    isStaffLocked = _i1.ColumnBool(
      'isStaffLocked',
      this,
      hasDefault: true,
    );
  }

  late final LoungeUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString emoji;

  late final _i1.ColumnUuid creatorId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt memberCount;

  late final _i1.ColumnBool isPublic;

  late final _i1.ColumnInt maxMembers;

  late final _i1.ColumnDateTime lastMessageAt;

  late final _i1.ColumnString lastMessage;

  late final _i1.ColumnSerializable<List<String>> interests;

  late final _i1.ColumnSerializable<List<String>> languages;

  late final _i1.ColumnString country;

  late final _i1.ColumnBool isStaffLocked;

  @override
  List<_i1.Column> get columns => [
    id,
    channelId,
    name,
    description,
    emoji,
    creatorId,
    createdAt,
    memberCount,
    isPublic,
    maxMembers,
    lastMessageAt,
    lastMessage,
    interests,
    languages,
    country,
    isStaffLocked,
  ];
}

class LoungeInclude extends _i1.IncludeObject {
  LoungeInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Lounge.t;
}

class LoungeIncludeList extends _i1.IncludeList {
  LoungeIncludeList._({
    _i1.WhereExpressionBuilder<LoungeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Lounge.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Lounge.t;
}

class LoungeRepository {
  const LoungeRepository._();

  /// Returns a list of [Lounge]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Lounge>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoungeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LoungeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoungeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Lounge>(
      where: where?.call(Lounge.t),
      orderBy: orderBy?.call(Lounge.t),
      orderByList: orderByList?.call(Lounge.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Lounge] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Lounge?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoungeTable>? where,
    int? offset,
    _i1.OrderByBuilder<LoungeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LoungeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Lounge>(
      where: where?.call(Lounge.t),
      orderBy: orderBy?.call(Lounge.t),
      orderByList: orderByList?.call(Lounge.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Lounge] by its [id] or null if no such row exists.
  Future<Lounge?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Lounge>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Lounge]s in the list and returns the inserted rows.
  ///
  /// The returned [Lounge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Lounge>> insert(
    _i1.Session session,
    List<Lounge> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Lounge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Lounge] and returns the inserted row.
  ///
  /// The returned [Lounge] will have its `id` field set.
  Future<Lounge> insertRow(
    _i1.Session session,
    Lounge row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Lounge>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Lounge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Lounge>> update(
    _i1.Session session,
    List<Lounge> rows, {
    _i1.ColumnSelections<LoungeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Lounge>(
      rows,
      columns: columns?.call(Lounge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Lounge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Lounge> updateRow(
    _i1.Session session,
    Lounge row, {
    _i1.ColumnSelections<LoungeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Lounge>(
      row,
      columns: columns?.call(Lounge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Lounge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Lounge?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<LoungeUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Lounge>(
      id,
      columnValues: columnValues(Lounge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Lounge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Lounge>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<LoungeUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<LoungeTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LoungeTable>? orderBy,
    _i1.OrderByListBuilder<LoungeTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Lounge>(
      columnValues: columnValues(Lounge.t.updateTable),
      where: where(Lounge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Lounge.t),
      orderByList: orderByList?.call(Lounge.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Lounge]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Lounge>> delete(
    _i1.Session session,
    List<Lounge> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Lounge>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Lounge].
  Future<Lounge> deleteRow(
    _i1.Session session,
    Lounge row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Lounge>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Lounge>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LoungeTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Lounge>(
      where: where(Lounge.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LoungeTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Lounge>(
      where: where?.call(Lounge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Lounge] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LoungeTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Lounge>(
      where: where(Lounge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
