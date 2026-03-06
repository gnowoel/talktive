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

abstract class Group implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Group._({
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
    this.interests,
  }) : memberCount = memberCount ?? 1,
       isPublic = isPublic ?? false,
       maxMembers = maxMembers ?? 50;

  factory Group({
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
    List<String>? interests,
  }) = _GroupImpl;

  factory Group.fromJson(Map<String, dynamic> jsonSerialization) {
    return Group(
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
      isPublic: jsonSerialization['isPublic'] as bool?,
      maxMembers: jsonSerialization['maxMembers'] as int?,
      interests: jsonSerialization['interests'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['interests'],
            ),
    );
  }

  static final t = GroupTable();

  static const db = GroupRepository._();

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

  List<String>? interests;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Group]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Group copyWith({
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
    List<String>? interests,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Group',
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
      if (interests != null) 'interests': interests?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Group',
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
      if (interests != null) 'interests': interests?.toJson(),
    };
  }

  static GroupInclude include() {
    return GroupInclude._();
  }

  static GroupIncludeList includeList({
    _i1.WhereExpressionBuilder<GroupTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GroupTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GroupTable>? orderByList,
    GroupInclude? include,
  }) {
    return GroupIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Group.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Group.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupImpl extends Group {
  _GroupImpl({
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
    List<String>? interests,
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
         interests: interests,
       );

  /// Returns a shallow copy of this [Group]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Group copyWith({
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
    Object? interests = _Undefined,
  }) {
    return Group(
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
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
    );
  }
}

class GroupUpdateTable extends _i1.UpdateTable<GroupTable> {
  GroupUpdateTable(super.table);

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

  _i1.ColumnValue<List<String>, List<String>> interests(List<String>? value) =>
      _i1.ColumnValue(
        table.interests,
        value,
      );
}

class GroupTable extends _i1.Table<int?> {
  GroupTable({super.tableRelation}) : super(tableName: 'groups') {
    updateTable = GroupUpdateTable(this);
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
    interests = _i1.ColumnSerializable<List<String>>(
      'interests',
      this,
    );
  }

  late final GroupUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString emoji;

  late final _i1.ColumnUuid creatorId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt memberCount;

  late final _i1.ColumnBool isPublic;

  late final _i1.ColumnInt maxMembers;

  late final _i1.ColumnSerializable<List<String>> interests;

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
    interests,
  ];
}

class GroupInclude extends _i1.IncludeObject {
  GroupInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Group.t;
}

class GroupIncludeList extends _i1.IncludeList {
  GroupIncludeList._({
    _i1.WhereExpressionBuilder<GroupTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Group.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Group.t;
}

class GroupRepository {
  const GroupRepository._();

  /// Returns a list of [Group]s matching the given query parameters.
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
  Future<List<Group>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GroupTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GroupTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GroupTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Group>(
      where: where?.call(Group.t),
      orderBy: orderBy?.call(Group.t),
      orderByList: orderByList?.call(Group.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Group] matching the given query parameters.
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
  Future<Group?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GroupTable>? where,
    int? offset,
    _i1.OrderByBuilder<GroupTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GroupTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Group>(
      where: where?.call(Group.t),
      orderBy: orderBy?.call(Group.t),
      orderByList: orderByList?.call(Group.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Group] by its [id] or null if no such row exists.
  Future<Group?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Group>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Group]s in the list and returns the inserted rows.
  ///
  /// The returned [Group]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Group>> insert(
    _i1.Session session,
    List<Group> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Group>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Group] and returns the inserted row.
  ///
  /// The returned [Group] will have its `id` field set.
  Future<Group> insertRow(
    _i1.Session session,
    Group row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Group>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Group]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Group>> update(
    _i1.Session session,
    List<Group> rows, {
    _i1.ColumnSelections<GroupTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Group>(
      rows,
      columns: columns?.call(Group.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Group]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Group> updateRow(
    _i1.Session session,
    Group row, {
    _i1.ColumnSelections<GroupTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Group>(
      row,
      columns: columns?.call(Group.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Group] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Group?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<GroupUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Group>(
      id,
      columnValues: columnValues(Group.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Group]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Group>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<GroupUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GroupTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GroupTable>? orderBy,
    _i1.OrderByListBuilder<GroupTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Group>(
      columnValues: columnValues(Group.t.updateTable),
      where: where(Group.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Group.t),
      orderByList: orderByList?.call(Group.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Group]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Group>> delete(
    _i1.Session session,
    List<Group> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Group>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Group].
  Future<Group> deleteRow(
    _i1.Session session,
    Group row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Group>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Group>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<GroupTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Group>(
      where: where(Group.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GroupTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Group>(
      where: where?.call(Group.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
