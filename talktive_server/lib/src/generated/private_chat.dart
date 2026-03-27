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

abstract class PrivateChat
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PrivateChat._({
    this.id,
    required this.channelId,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory PrivateChat({
    int? id,
    required int channelId,
    required _i1.UuidValue participant1Id,
    required _i1.UuidValue participant2Id,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) = _PrivateChatImpl;

  factory PrivateChat.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrivateChat(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      participant1Id: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['participant1Id'],
      ),
      participant2Id: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['participant2Id'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastMessage: jsonSerialization['lastMessage'] as String?,
    );
  }

  static final t = PrivateChatTable();

  static const db = PrivateChatRepository._();

  @override
  int? id;

  int channelId;

  _i1.UuidValue participant1Id;

  _i1.UuidValue participant2Id;

  DateTime createdAt;

  DateTime? lastMessageAt;

  String? lastMessage;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PrivateChat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrivateChat copyWith({
    int? id,
    int? channelId,
    _i1.UuidValue? participant1Id,
    _i1.UuidValue? participant2Id,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrivateChat',
      if (id != null) 'id': id,
      'channelId': channelId,
      'participant1Id': participant1Id.toJson(),
      'participant2Id': participant2Id.toJson(),
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrivateChat',
      if (id != null) 'id': id,
      'channelId': channelId,
      'participant1Id': participant1Id.toJson(),
      'participant2Id': participant2Id.toJson(),
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
    };
  }

  static PrivateChatInclude include() {
    return PrivateChatInclude._();
  }

  static PrivateChatIncludeList includeList({
    _i1.WhereExpressionBuilder<PrivateChatTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PrivateChatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PrivateChatTable>? orderByList,
    PrivateChatInclude? include,
  }) {
    return PrivateChatIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PrivateChat.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PrivateChat.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrivateChatImpl extends PrivateChat {
  _PrivateChatImpl({
    int? id,
    required int channelId,
    required _i1.UuidValue participant1Id,
    required _i1.UuidValue participant2Id,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) : super._(
         id: id,
         channelId: channelId,
         participant1Id: participant1Id,
         participant2Id: participant2Id,
         createdAt: createdAt,
         lastMessageAt: lastMessageAt,
         lastMessage: lastMessage,
       );

  /// Returns a shallow copy of this [PrivateChat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrivateChat copyWith({
    Object? id = _Undefined,
    int? channelId,
    _i1.UuidValue? participant1Id,
    _i1.UuidValue? participant2Id,
    DateTime? createdAt,
    Object? lastMessageAt = _Undefined,
    Object? lastMessage = _Undefined,
  }) {
    return PrivateChat(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      lastMessage: lastMessage is String? ? lastMessage : this.lastMessage,
    );
  }
}

class PrivateChatUpdateTable extends _i1.UpdateTable<PrivateChatTable> {
  PrivateChatUpdateTable(super.table);

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> participant1Id(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.participant1Id,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> participant2Id(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.participant2Id,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
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
}

class PrivateChatTable extends _i1.Table<int?> {
  PrivateChatTable({super.tableRelation}) : super(tableName: 'private_chat') {
    updateTable = PrivateChatUpdateTable(this);
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    participant1Id = _i1.ColumnUuid(
      'participant1Id',
      this,
    );
    participant2Id = _i1.ColumnUuid(
      'participant2Id',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    lastMessageAt = _i1.ColumnDateTime(
      'lastMessageAt',
      this,
    );
    lastMessage = _i1.ColumnString(
      'lastMessage',
      this,
    );
  }

  late final PrivateChatUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnUuid participant1Id;

  late final _i1.ColumnUuid participant2Id;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime lastMessageAt;

  late final _i1.ColumnString lastMessage;

  @override
  List<_i1.Column> get columns => [
    id,
    channelId,
    participant1Id,
    participant2Id,
    createdAt,
    lastMessageAt,
    lastMessage,
  ];
}

class PrivateChatInclude extends _i1.IncludeObject {
  PrivateChatInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PrivateChat.t;
}

class PrivateChatIncludeList extends _i1.IncludeList {
  PrivateChatIncludeList._({
    _i1.WhereExpressionBuilder<PrivateChatTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PrivateChat.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PrivateChat.t;
}

class PrivateChatRepository {
  const PrivateChatRepository._();

  /// Returns a list of [PrivateChat]s matching the given query parameters.
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
  Future<List<PrivateChat>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PrivateChatTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PrivateChatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PrivateChatTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PrivateChat>(
      where: where?.call(PrivateChat.t),
      orderBy: orderBy?.call(PrivateChat.t),
      orderByList: orderByList?.call(PrivateChat.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PrivateChat] matching the given query parameters.
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
  Future<PrivateChat?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PrivateChatTable>? where,
    int? offset,
    _i1.OrderByBuilder<PrivateChatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PrivateChatTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PrivateChat>(
      where: where?.call(PrivateChat.t),
      orderBy: orderBy?.call(PrivateChat.t),
      orderByList: orderByList?.call(PrivateChat.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PrivateChat] by its [id] or null if no such row exists.
  Future<PrivateChat?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PrivateChat>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PrivateChat]s in the list and returns the inserted rows.
  ///
  /// The returned [PrivateChat]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PrivateChat>> insert(
    _i1.DatabaseSession session,
    List<PrivateChat> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PrivateChat>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PrivateChat] and returns the inserted row.
  ///
  /// The returned [PrivateChat] will have its `id` field set.
  Future<PrivateChat> insertRow(
    _i1.DatabaseSession session,
    PrivateChat row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PrivateChat>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PrivateChat]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PrivateChat>> update(
    _i1.DatabaseSession session,
    List<PrivateChat> rows, {
    _i1.ColumnSelections<PrivateChatTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PrivateChat>(
      rows,
      columns: columns?.call(PrivateChat.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PrivateChat]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PrivateChat> updateRow(
    _i1.DatabaseSession session,
    PrivateChat row, {
    _i1.ColumnSelections<PrivateChatTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PrivateChat>(
      row,
      columns: columns?.call(PrivateChat.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PrivateChat] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PrivateChat?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PrivateChatUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PrivateChat>(
      id,
      columnValues: columnValues(PrivateChat.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PrivateChat]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PrivateChat>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PrivateChatUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<PrivateChatTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PrivateChatTable>? orderBy,
    _i1.OrderByListBuilder<PrivateChatTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PrivateChat>(
      columnValues: columnValues(PrivateChat.t.updateTable),
      where: where(PrivateChat.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PrivateChat.t),
      orderByList: orderByList?.call(PrivateChat.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PrivateChat]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PrivateChat>> delete(
    _i1.DatabaseSession session,
    List<PrivateChat> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PrivateChat>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PrivateChat].
  Future<PrivateChat> deleteRow(
    _i1.DatabaseSession session,
    PrivateChat row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PrivateChat>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PrivateChat>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PrivateChatTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PrivateChat>(
      where: where(PrivateChat.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PrivateChatTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PrivateChat>(
      where: where?.call(PrivateChat.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PrivateChat] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PrivateChatTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PrivateChat>(
      where: where(PrivateChat.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
