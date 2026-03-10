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
import 'channel_type.dart' as _i2;

abstract class Channel
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Channel._({
    this.id,
    required this.type,
    this.name,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory Channel({
    int? id,
    required _i2.ChannelType type,
    String? name,
    required DateTime createdAt,
    DateTime? lastMessageAt,
  }) = _ChannelImpl;

  factory Channel.fromJson(Map<String, dynamic> jsonSerialization) {
    return Channel(
      id: jsonSerialization['id'] as int?,
      type: _i2.ChannelType.fromJson((jsonSerialization['type'] as String)),
      name: jsonSerialization['name'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
    );
  }

  static final t = ChannelTable();

  static const db = ChannelRepository._();

  @override
  int? id;

  _i2.ChannelType type;

  String? name;

  DateTime createdAt;

  DateTime? lastMessageAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Channel copyWith({
    int? id,
    _i2.ChannelType? type,
    String? name,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'type': type.toJson(),
      if (name != null) 'name': name,
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'type': type.toJson(),
      if (name != null) 'name': name,
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
    };
  }

  static ChannelInclude include() {
    return ChannelInclude._();
  }

  static ChannelIncludeList includeList({
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    ChannelInclude? include,
  }) {
    return ChannelIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Channel.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Channel.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelImpl extends Channel {
  _ChannelImpl({
    int? id,
    required _i2.ChannelType type,
    String? name,
    required DateTime createdAt,
    DateTime? lastMessageAt,
  }) : super._(
         id: id,
         type: type,
         name: name,
         createdAt: createdAt,
         lastMessageAt: lastMessageAt,
       );

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Channel copyWith({
    Object? id = _Undefined,
    _i2.ChannelType? type,
    Object? name = _Undefined,
    DateTime? createdAt,
    Object? lastMessageAt = _Undefined,
  }) {
    return Channel(
      id: id is int? ? id : this.id,
      type: type ?? this.type,
      name: name is String? ? name : this.name,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
    );
  }
}

class ChannelUpdateTable extends _i1.UpdateTable<ChannelTable> {
  ChannelUpdateTable(super.table);

  _i1.ColumnValue<_i2.ChannelType, _i2.ChannelType> type(
    _i2.ChannelType value,
  ) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<String, String> name(String? value) => _i1.ColumnValue(
    table.name,
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
}

class ChannelTable extends _i1.Table<int?> {
  ChannelTable({super.tableRelation}) : super(tableName: 'channel') {
    updateTable = ChannelUpdateTable(this);
    type = _i1.ColumnEnum(
      'type',
      this,
      _i1.EnumSerialization.byName,
    );
    name = _i1.ColumnString(
      'name',
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
  }

  late final ChannelUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.ChannelType> type;

  late final _i1.ColumnString name;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime lastMessageAt;

  @override
  List<_i1.Column> get columns => [
    id,
    type,
    name,
    createdAt,
    lastMessageAt,
  ];
}

class ChannelInclude extends _i1.IncludeObject {
  ChannelInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Channel.t;
}

class ChannelIncludeList extends _i1.IncludeList {
  ChannelIncludeList._({
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Channel.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Channel.t;
}

class ChannelRepository {
  const ChannelRepository._();

  /// Returns a list of [Channel]s matching the given query parameters.
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
  Future<List<Channel>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Channel>(
      where: where?.call(Channel.t),
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Channel] matching the given query parameters.
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
  Future<Channel?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Channel>(
      where: where?.call(Channel.t),
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Channel] by its [id] or null if no such row exists.
  Future<Channel?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Channel>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Channel]s in the list and returns the inserted rows.
  ///
  /// The returned [Channel]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Channel>> insert(
    _i1.Session session,
    List<Channel> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Channel>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Channel] and returns the inserted row.
  ///
  /// The returned [Channel] will have its `id` field set.
  Future<Channel> insertRow(
    _i1.Session session,
    Channel row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Channel>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Channel]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Channel>> update(
    _i1.Session session,
    List<Channel> rows, {
    _i1.ColumnSelections<ChannelTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Channel>(
      rows,
      columns: columns?.call(Channel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Channel]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Channel> updateRow(
    _i1.Session session,
    Channel row, {
    _i1.ColumnSelections<ChannelTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Channel>(
      row,
      columns: columns?.call(Channel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Channel] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Channel?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ChannelUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Channel>(
      id,
      columnValues: columnValues(Channel.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Channel]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Channel>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ChannelUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ChannelTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Channel>(
      columnValues: columnValues(Channel.t.updateTable),
      where: where(Channel.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Channel]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Channel>> delete(
    _i1.Session session,
    List<Channel> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Channel>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Channel].
  Future<Channel> deleteRow(
    _i1.Session session,
    Channel row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Channel>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Channel>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChannelTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Channel>(
      where: where(Channel.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Channel>(
      where: where?.call(Channel.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Channel] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChannelTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Channel>(
      where: where(Channel.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
