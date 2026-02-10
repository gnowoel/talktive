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

abstract class RateLimit
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  RateLimit._({
    this.id,
    required this.userInfoId,
    required this.channelId,
    required this.messageCount,
    required this.windowStart,
    required this.lastMessageAt,
  });

  factory RateLimit({
    int? id,
    required _i1.UuidValue userInfoId,
    required int channelId,
    required int messageCount,
    required DateTime windowStart,
    required DateTime lastMessageAt,
  }) = _RateLimitImpl;

  factory RateLimit.fromJson(Map<String, dynamic> jsonSerialization) {
    return RateLimit(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      channelId: jsonSerialization['channelId'] as int,
      messageCount: jsonSerialization['messageCount'] as int,
      windowStart: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['windowStart'],
      ),
      lastMessageAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastMessageAt'],
      ),
    );
  }

  static final t = RateLimitTable();

  static const db = RateLimitRepository._();

  @override
  int? id;

  _i1.UuidValue userInfoId;

  int channelId;

  int messageCount;

  DateTime windowStart;

  DateTime lastMessageAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [RateLimit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RateLimit copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? channelId,
    int? messageCount,
    DateTime? windowStart,
    DateTime? lastMessageAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RateLimit',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'channelId': channelId,
      'messageCount': messageCount,
      'windowStart': windowStart.toJson(),
      'lastMessageAt': lastMessageAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RateLimit',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'channelId': channelId,
      'messageCount': messageCount,
      'windowStart': windowStart.toJson(),
      'lastMessageAt': lastMessageAt.toJson(),
    };
  }

  static RateLimitInclude include() {
    return RateLimitInclude._();
  }

  static RateLimitIncludeList includeList({
    _i1.WhereExpressionBuilder<RateLimitTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RateLimitTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RateLimitTable>? orderByList,
    RateLimitInclude? include,
  }) {
    return RateLimitIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RateLimit.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(RateLimit.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RateLimitImpl extends RateLimit {
  _RateLimitImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    required int channelId,
    required int messageCount,
    required DateTime windowStart,
    required DateTime lastMessageAt,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         channelId: channelId,
         messageCount: messageCount,
         windowStart: windowStart,
         lastMessageAt: lastMessageAt,
       );

  /// Returns a shallow copy of this [RateLimit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RateLimit copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? channelId,
    int? messageCount,
    DateTime? windowStart,
    DateTime? lastMessageAt,
  }) {
    return RateLimit(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      channelId: channelId ?? this.channelId,
      messageCount: messageCount ?? this.messageCount,
      windowStart: windowStart ?? this.windowStart,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class RateLimitUpdateTable extends _i1.UpdateTable<RateLimitTable> {
  RateLimitUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userInfoId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<int, int> messageCount(int value) => _i1.ColumnValue(
    table.messageCount,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> windowStart(DateTime value) =>
      _i1.ColumnValue(
        table.windowStart,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastMessageAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastMessageAt,
        value,
      );
}

class RateLimitTable extends _i1.Table<int?> {
  RateLimitTable({super.tableRelation}) : super(tableName: 'rate_limit') {
    updateTable = RateLimitUpdateTable(this);
    userInfoId = _i1.ColumnUuid(
      'userInfoId',
      this,
    );
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    messageCount = _i1.ColumnInt(
      'messageCount',
      this,
    );
    windowStart = _i1.ColumnDateTime(
      'windowStart',
      this,
    );
    lastMessageAt = _i1.ColumnDateTime(
      'lastMessageAt',
      this,
    );
  }

  late final RateLimitUpdateTable updateTable;

  late final _i1.ColumnUuid userInfoId;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnInt messageCount;

  late final _i1.ColumnDateTime windowStart;

  late final _i1.ColumnDateTime lastMessageAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userInfoId,
    channelId,
    messageCount,
    windowStart,
    lastMessageAt,
  ];
}

class RateLimitInclude extends _i1.IncludeObject {
  RateLimitInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => RateLimit.t;
}

class RateLimitIncludeList extends _i1.IncludeList {
  RateLimitIncludeList._({
    _i1.WhereExpressionBuilder<RateLimitTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RateLimit.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => RateLimit.t;
}

class RateLimitRepository {
  const RateLimitRepository._();

  /// Returns a list of [RateLimit]s matching the given query parameters.
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
  Future<List<RateLimit>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<RateLimitTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RateLimitTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RateLimitTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<RateLimit>(
      where: where?.call(RateLimit.t),
      orderBy: orderBy?.call(RateLimit.t),
      orderByList: orderByList?.call(RateLimit.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [RateLimit] matching the given query parameters.
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
  Future<RateLimit?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<RateLimitTable>? where,
    int? offset,
    _i1.OrderByBuilder<RateLimitTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RateLimitTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<RateLimit>(
      where: where?.call(RateLimit.t),
      orderBy: orderBy?.call(RateLimit.t),
      orderByList: orderByList?.call(RateLimit.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [RateLimit] by its [id] or null if no such row exists.
  Future<RateLimit?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<RateLimit>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [RateLimit]s in the list and returns the inserted rows.
  ///
  /// The returned [RateLimit]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<RateLimit>> insert(
    _i1.Session session,
    List<RateLimit> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<RateLimit>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [RateLimit] and returns the inserted row.
  ///
  /// The returned [RateLimit] will have its `id` field set.
  Future<RateLimit> insertRow(
    _i1.Session session,
    RateLimit row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<RateLimit>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [RateLimit]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<RateLimit>> update(
    _i1.Session session,
    List<RateLimit> rows, {
    _i1.ColumnSelections<RateLimitTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<RateLimit>(
      rows,
      columns: columns?.call(RateLimit.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RateLimit]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RateLimit> updateRow(
    _i1.Session session,
    RateLimit row, {
    _i1.ColumnSelections<RateLimitTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<RateLimit>(
      row,
      columns: columns?.call(RateLimit.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RateLimit] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RateLimit?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<RateLimitUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<RateLimit>(
      id,
      columnValues: columnValues(RateLimit.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RateLimit]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<RateLimit>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<RateLimitUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<RateLimitTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RateLimitTable>? orderBy,
    _i1.OrderByListBuilder<RateLimitTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<RateLimit>(
      columnValues: columnValues(RateLimit.t.updateTable),
      where: where(RateLimit.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RateLimit.t),
      orderByList: orderByList?.call(RateLimit.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [RateLimit]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<RateLimit>> delete(
    _i1.Session session,
    List<RateLimit> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<RateLimit>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [RateLimit].
  Future<RateLimit> deleteRow(
    _i1.Session session,
    RateLimit row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RateLimit>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<RateLimit>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<RateLimitTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<RateLimit>(
      where: where(RateLimit.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<RateLimitTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<RateLimit>(
      where: where?.call(RateLimit.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
