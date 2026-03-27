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

abstract class UserLike
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserLike._({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });

  factory UserLike({
    int? id,
    required _i1.UuidValue senderId,
    required _i1.UuidValue receiverId,
    required DateTime createdAt,
  }) = _UserLikeImpl;

  factory UserLike.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserLike(
      id: jsonSerialization['id'] as int?,
      senderId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['senderId'],
      ),
      receiverId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['receiverId'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = UserLikeTable();

  static const db = UserLikeRepository._();

  @override
  int? id;

  _i1.UuidValue senderId;

  _i1.UuidValue receiverId;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserLike copyWith({
    int? id,
    _i1.UuidValue? senderId,
    _i1.UuidValue? receiverId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserLike',
      if (id != null) 'id': id,
      'senderId': senderId.toJson(),
      'receiverId': receiverId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserLike',
      if (id != null) 'id': id,
      'senderId': senderId.toJson(),
      'receiverId': receiverId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static UserLikeInclude include() {
    return UserLikeInclude._();
  }

  static UserLikeIncludeList includeList({
    _i1.WhereExpressionBuilder<UserLikeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLikeTable>? orderByList,
    UserLikeInclude? include,
  }) {
    return UserLikeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserLike.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserLike.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserLikeImpl extends UserLike {
  _UserLikeImpl({
    int? id,
    required _i1.UuidValue senderId,
    required _i1.UuidValue receiverId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         senderId: senderId,
         receiverId: receiverId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserLike copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? senderId,
    _i1.UuidValue? receiverId,
    DateTime? createdAt,
  }) {
    return UserLike(
      id: id is int? ? id : this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserLikeUpdateTable extends _i1.UpdateTable<UserLikeTable> {
  UserLikeUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> senderId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.senderId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> receiverId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.receiverId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class UserLikeTable extends _i1.Table<int?> {
  UserLikeTable({super.tableRelation}) : super(tableName: 'user_like') {
    updateTable = UserLikeUpdateTable(this);
    senderId = _i1.ColumnUuid(
      'senderId',
      this,
    );
    receiverId = _i1.ColumnUuid(
      'receiverId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final UserLikeUpdateTable updateTable;

  late final _i1.ColumnUuid senderId;

  late final _i1.ColumnUuid receiverId;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    senderId,
    receiverId,
    createdAt,
  ];
}

class UserLikeInclude extends _i1.IncludeObject {
  UserLikeInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserLike.t;
}

class UserLikeIncludeList extends _i1.IncludeList {
  UserLikeIncludeList._({
    _i1.WhereExpressionBuilder<UserLikeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserLike.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserLike.t;
}

class UserLikeRepository {
  const UserLikeRepository._();

  /// Returns a list of [UserLike]s matching the given query parameters.
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
  Future<List<UserLike>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserLikeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLikeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserLike>(
      where: where?.call(UserLike.t),
      orderBy: orderBy?.call(UserLike.t),
      orderByList: orderByList?.call(UserLike.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserLike] matching the given query parameters.
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
  Future<UserLike?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserLikeTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLikeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserLike>(
      where: where?.call(UserLike.t),
      orderBy: orderBy?.call(UserLike.t),
      orderByList: orderByList?.call(UserLike.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserLike] by its [id] or null if no such row exists.
  Future<UserLike?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserLike>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserLike]s in the list and returns the inserted rows.
  ///
  /// The returned [UserLike]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<UserLike>> insert(
    _i1.DatabaseSession session,
    List<UserLike> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<UserLike>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [UserLike] and returns the inserted row.
  ///
  /// The returned [UserLike] will have its `id` field set.
  Future<UserLike> insertRow(
    _i1.DatabaseSession session,
    UserLike row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserLike>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserLike]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserLike>> update(
    _i1.DatabaseSession session,
    List<UserLike> rows, {
    _i1.ColumnSelections<UserLikeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserLike>(
      rows,
      columns: columns?.call(UserLike.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserLike]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserLike> updateRow(
    _i1.DatabaseSession session,
    UserLike row, {
    _i1.ColumnSelections<UserLikeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserLike>(
      row,
      columns: columns?.call(UserLike.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserLike] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserLike?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<UserLikeUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserLike>(
      id,
      columnValues: columnValues(UserLike.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserLike]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserLike>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<UserLikeUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserLikeTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLikeTable>? orderBy,
    _i1.OrderByListBuilder<UserLikeTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserLike>(
      columnValues: columnValues(UserLike.t.updateTable),
      where: where(UserLike.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserLike.t),
      orderByList: orderByList?.call(UserLike.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserLike]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserLike>> delete(
    _i1.DatabaseSession session,
    List<UserLike> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserLike>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserLike].
  Future<UserLike> deleteRow(
    _i1.DatabaseSession session,
    UserLike row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserLike>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserLike>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserLikeTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserLike>(
      where: where(UserLike.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserLikeTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserLike>(
      where: where?.call(UserLike.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserLike] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserLikeTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserLike>(
      where: where(UserLike.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
