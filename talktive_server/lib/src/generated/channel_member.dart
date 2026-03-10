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
import 'channel_member_status.dart' as _i2;

abstract class ChannelMember
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ChannelMember._({
    this.id,
    required this.channelId,
    required this.userInfoId,
    required this.joinedAt,
    this.role,
    required this.status,
    this.invitedBy,
  });

  factory ChannelMember({
    int? id,
    required int channelId,
    required _i1.UuidValue userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i2.ChannelMemberStatus status,
    _i1.UuidValue? invitedBy,
  }) = _ChannelMemberImpl;

  factory ChannelMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChannelMember(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      role: jsonSerialization['role'] as String?,
      status: _i2.ChannelMemberStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      invitedBy: jsonSerialization['invitedBy'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['invitedBy']),
    );
  }

  static final t = ChannelMemberTable();

  static const db = ChannelMemberRepository._();

  @override
  int? id;

  int channelId;

  _i1.UuidValue userInfoId;

  DateTime joinedAt;

  String? role;

  _i2.ChannelMemberStatus status;

  _i1.UuidValue? invitedBy;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChannelMember copyWith({
    int? id,
    int? channelId,
    _i1.UuidValue? userInfoId,
    DateTime? joinedAt,
    String? role,
    _i2.ChannelMemberStatus? status,
    _i1.UuidValue? invitedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChannelMember',
      if (id != null) 'id': id,
      'channelId': channelId,
      'userInfoId': userInfoId.toJson(),
      'joinedAt': joinedAt.toJson(),
      if (role != null) 'role': role,
      'status': status.toJson(),
      if (invitedBy != null) 'invitedBy': invitedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChannelMember',
      if (id != null) 'id': id,
      'channelId': channelId,
      'userInfoId': userInfoId.toJson(),
      'joinedAt': joinedAt.toJson(),
      if (role != null) 'role': role,
      'status': status.toJson(),
      if (invitedBy != null) 'invitedBy': invitedBy?.toJson(),
    };
  }

  static ChannelMemberInclude include() {
    return ChannelMemberInclude._();
  }

  static ChannelMemberIncludeList includeList({
    _i1.WhereExpressionBuilder<ChannelMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelMemberTable>? orderByList,
    ChannelMemberInclude? include,
  }) {
    return ChannelMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChannelMember.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ChannelMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelMemberImpl extends ChannelMember {
  _ChannelMemberImpl({
    int? id,
    required int channelId,
    required _i1.UuidValue userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i2.ChannelMemberStatus status,
    _i1.UuidValue? invitedBy,
  }) : super._(
         id: id,
         channelId: channelId,
         userInfoId: userInfoId,
         joinedAt: joinedAt,
         role: role,
         status: status,
         invitedBy: invitedBy,
       );

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChannelMember copyWith({
    Object? id = _Undefined,
    int? channelId,
    _i1.UuidValue? userInfoId,
    DateTime? joinedAt,
    Object? role = _Undefined,
    _i2.ChannelMemberStatus? status,
    Object? invitedBy = _Undefined,
  }) {
    return ChannelMember(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      userInfoId: userInfoId ?? this.userInfoId,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role is String? ? role : this.role,
      status: status ?? this.status,
      invitedBy: invitedBy is _i1.UuidValue? ? invitedBy : this.invitedBy,
    );
  }
}

class ChannelMemberUpdateTable extends _i1.UpdateTable<ChannelMemberTable> {
  ChannelMemberUpdateTable(super.table);

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userInfoId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );

  _i1.ColumnValue<String, String> role(String? value) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<_i2.ChannelMemberStatus, _i2.ChannelMemberStatus> status(
    _i2.ChannelMemberStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invitedBy(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.invitedBy,
    value,
  );
}

class ChannelMemberTable extends _i1.Table<int?> {
  ChannelMemberTable({super.tableRelation})
    : super(tableName: 'channel_member') {
    updateTable = ChannelMemberUpdateTable(this);
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    userInfoId = _i1.ColumnUuid(
      'userInfoId',
      this,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
    );
    invitedBy = _i1.ColumnUuid(
      'invitedBy',
      this,
    );
  }

  late final ChannelMemberUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnUuid userInfoId;

  late final _i1.ColumnDateTime joinedAt;

  late final _i1.ColumnString role;

  late final _i1.ColumnEnum<_i2.ChannelMemberStatus> status;

  late final _i1.ColumnUuid invitedBy;

  @override
  List<_i1.Column> get columns => [
    id,
    channelId,
    userInfoId,
    joinedAt,
    role,
    status,
    invitedBy,
  ];
}

class ChannelMemberInclude extends _i1.IncludeObject {
  ChannelMemberInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ChannelMember.t;
}

class ChannelMemberIncludeList extends _i1.IncludeList {
  ChannelMemberIncludeList._({
    _i1.WhereExpressionBuilder<ChannelMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ChannelMember.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ChannelMember.t;
}

class ChannelMemberRepository {
  const ChannelMemberRepository._();

  /// Returns a list of [ChannelMember]s matching the given query parameters.
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
  Future<List<ChannelMember>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ChannelMember>(
      where: where?.call(ChannelMember.t),
      orderBy: orderBy?.call(ChannelMember.t),
      orderByList: orderByList?.call(ChannelMember.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ChannelMember] matching the given query parameters.
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
  Future<ChannelMember?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelMemberTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChannelMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ChannelMember>(
      where: where?.call(ChannelMember.t),
      orderBy: orderBy?.call(ChannelMember.t),
      orderByList: orderByList?.call(ChannelMember.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ChannelMember] by its [id] or null if no such row exists.
  Future<ChannelMember?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ChannelMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ChannelMember]s in the list and returns the inserted rows.
  ///
  /// The returned [ChannelMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ChannelMember>> insert(
    _i1.Session session,
    List<ChannelMember> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ChannelMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ChannelMember] and returns the inserted row.
  ///
  /// The returned [ChannelMember] will have its `id` field set.
  Future<ChannelMember> insertRow(
    _i1.Session session,
    ChannelMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ChannelMember>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ChannelMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ChannelMember>> update(
    _i1.Session session,
    List<ChannelMember> rows, {
    _i1.ColumnSelections<ChannelMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ChannelMember>(
      rows,
      columns: columns?.call(ChannelMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChannelMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ChannelMember> updateRow(
    _i1.Session session,
    ChannelMember row, {
    _i1.ColumnSelections<ChannelMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ChannelMember>(
      row,
      columns: columns?.call(ChannelMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChannelMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ChannelMember?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ChannelMemberUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ChannelMember>(
      id,
      columnValues: columnValues(ChannelMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ChannelMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ChannelMember>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ChannelMemberUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ChannelMemberTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelMemberTable>? orderBy,
    _i1.OrderByListBuilder<ChannelMemberTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ChannelMember>(
      columnValues: columnValues(ChannelMember.t.updateTable),
      where: where(ChannelMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChannelMember.t),
      orderByList: orderByList?.call(ChannelMember.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ChannelMember]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ChannelMember>> delete(
    _i1.Session session,
    List<ChannelMember> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ChannelMember>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ChannelMember].
  Future<ChannelMember> deleteRow(
    _i1.Session session,
    ChannelMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ChannelMember>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ChannelMember>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChannelMemberTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ChannelMember>(
      where: where(ChannelMember.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelMemberTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ChannelMember>(
      where: where?.call(ChannelMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ChannelMember] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChannelMemberTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ChannelMember>(
      where: where(ChannelMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
