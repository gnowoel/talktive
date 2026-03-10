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

abstract class UserNotification
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserNotification._({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    bool? read,
    required this.createdAt,
  }) : read = read ?? false;

  factory UserNotification({
    int? id,
    required _i1.UuidValue userId,
    required String type,
    required String title,
    required String body,
    String? data,
    bool? read,
    required DateTime createdAt,
  }) = _UserNotificationImpl;

  factory UserNotification.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserNotification(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      type: jsonSerialization['type'] as String,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
      data: jsonSerialization['data'] as String?,
      read: jsonSerialization['read'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['read']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = UserNotificationTable();

  static const db = UserNotificationRepository._();

  @override
  int? id;

  _i1.UuidValue userId;

  String type;

  String title;

  String body;

  String? data;

  bool read;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserNotification copyWith({
    int? id,
    _i1.UuidValue? userId,
    String? type,
    String? title,
    String? body,
    String? data,
    bool? read,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserNotification',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'type': type,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      'read': read,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserNotification',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'type': type,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      'read': read,
      'createdAt': createdAt.toJson(),
    };
  }

  static UserNotificationInclude include() {
    return UserNotificationInclude._();
  }

  static UserNotificationIncludeList includeList({
    _i1.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserNotificationTable>? orderByList,
    UserNotificationInclude? include,
  }) {
    return UserNotificationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserNotification.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserNotificationImpl extends UserNotification {
  _UserNotificationImpl({
    int? id,
    required _i1.UuidValue userId,
    required String type,
    required String title,
    required String body,
    String? data,
    bool? read,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         type: type,
         title: title,
         body: body,
         data: data,
         read: read,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserNotification copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    String? type,
    String? title,
    String? body,
    Object? data = _Undefined,
    bool? read,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data is String? ? data : this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserNotificationUpdateTable
    extends _i1.UpdateTable<UserNotificationTable> {
  UserNotificationUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<String, String> type(String value) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> body(String value) => _i1.ColumnValue(
    table.body,
    value,
  );

  _i1.ColumnValue<String, String> data(String? value) => _i1.ColumnValue(
    table.data,
    value,
  );

  _i1.ColumnValue<bool, bool> read(bool value) => _i1.ColumnValue(
    table.read,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class UserNotificationTable extends _i1.Table<int?> {
  UserNotificationTable({super.tableRelation})
    : super(tableName: 'user_notifications') {
    updateTable = UserNotificationUpdateTable(this);
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    body = _i1.ColumnString(
      'body',
      this,
    );
    data = _i1.ColumnString(
      'data',
      this,
    );
    read = _i1.ColumnBool(
      'read',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final UserNotificationUpdateTable updateTable;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnString type;

  late final _i1.ColumnString title;

  late final _i1.ColumnString body;

  late final _i1.ColumnString data;

  late final _i1.ColumnBool read;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    type,
    title,
    body,
    data,
    read,
    createdAt,
  ];
}

class UserNotificationInclude extends _i1.IncludeObject {
  UserNotificationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserNotification.t;
}

class UserNotificationIncludeList extends _i1.IncludeList {
  UserNotificationIncludeList._({
    _i1.WhereExpressionBuilder<UserNotificationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserNotification.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserNotification.t;
}

class UserNotificationRepository {
  const UserNotificationRepository._();

  /// Returns a list of [UserNotification]s matching the given query parameters.
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
  Future<List<UserNotification>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserNotificationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserNotification] matching the given query parameters.
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
  Future<UserNotification?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserNotificationTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserNotificationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserNotification] by its [id] or null if no such row exists.
  Future<UserNotification?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserNotification>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserNotification]s in the list and returns the inserted rows.
  ///
  /// The returned [UserNotification]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<UserNotification>> insert(
    _i1.Session session,
    List<UserNotification> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<UserNotification>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [UserNotification] and returns the inserted row.
  ///
  /// The returned [UserNotification] will have its `id` field set.
  Future<UserNotification> insertRow(
    _i1.Session session,
    UserNotification row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserNotification>> update(
    _i1.Session session,
    List<UserNotification> rows, {
    _i1.ColumnSelections<UserNotificationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserNotification>(
      rows,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserNotification]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserNotification> updateRow(
    _i1.Session session,
    UserNotification row, {
    _i1.ColumnSelections<UserNotificationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserNotification>(
      row,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserNotification] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserNotification?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserNotification>(
      id,
      columnValues: columnValues(UserNotification.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserNotification>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<UserNotificationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserNotificationTable>? orderBy,
    _i1.OrderByListBuilder<UserNotificationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserNotification>(
      columnValues: columnValues(UserNotification.t.updateTable),
      where: where(UserNotification.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserNotification]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserNotification>> delete(
    _i1.Session session,
    List<UserNotification> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserNotification>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserNotification].
  Future<UserNotification> deleteRow(
    _i1.Session session,
    UserNotification row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserNotification>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserNotificationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserNotification>(
      where: where(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserNotification>(
      where: where?.call(UserNotification.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserNotification] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserNotificationTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserNotification>(
      where: where(UserNotification.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
