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

abstract class Report implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Report._({
    this.id,
    required this.reporterId,
    required this.targetId,
    required this.reason,
    this.channelId,
    this.messageId,
    required this.createdAt,
    required this.resolved,
  });

  factory Report({
    int? id,
    required _i1.UuidValue reporterId,
    required _i1.UuidValue targetId,
    required String reason,
    int? channelId,
    int? messageId,
    required DateTime createdAt,
    required bool resolved,
  }) = _ReportImpl;

  factory Report.fromJson(Map<String, dynamic> jsonSerialization) {
    return Report(
      id: jsonSerialization['id'] as int?,
      reporterId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['reporterId'],
      ),
      targetId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['targetId'],
      ),
      reason: jsonSerialization['reason'] as String,
      channelId: jsonSerialization['channelId'] as int?,
      messageId: jsonSerialization['messageId'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      resolved: jsonSerialization['resolved'] as bool,
    );
  }

  static final t = ReportTable();

  static const db = ReportRepository._();

  @override
  int? id;

  _i1.UuidValue reporterId;

  _i1.UuidValue targetId;

  String reason;

  int? channelId;

  int? messageId;

  DateTime createdAt;

  bool resolved;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Report copyWith({
    int? id,
    _i1.UuidValue? reporterId,
    _i1.UuidValue? targetId,
    String? reason,
    int? channelId,
    int? messageId,
    DateTime? createdAt,
    bool? resolved,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Report',
      if (id != null) 'id': id,
      'reporterId': reporterId.toJson(),
      'targetId': targetId.toJson(),
      'reason': reason,
      if (channelId != null) 'channelId': channelId,
      if (messageId != null) 'messageId': messageId,
      'createdAt': createdAt.toJson(),
      'resolved': resolved,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Report',
      if (id != null) 'id': id,
      'reporterId': reporterId.toJson(),
      'targetId': targetId.toJson(),
      'reason': reason,
      if (channelId != null) 'channelId': channelId,
      if (messageId != null) 'messageId': messageId,
      'createdAt': createdAt.toJson(),
      'resolved': resolved,
    };
  }

  static ReportInclude include() {
    return ReportInclude._();
  }

  static ReportIncludeList includeList({
    _i1.WhereExpressionBuilder<ReportTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReportTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportTable>? orderByList,
    ReportInclude? include,
  }) {
    return ReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Report.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Report.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportImpl extends Report {
  _ReportImpl({
    int? id,
    required _i1.UuidValue reporterId,
    required _i1.UuidValue targetId,
    required String reason,
    int? channelId,
    int? messageId,
    required DateTime createdAt,
    required bool resolved,
  }) : super._(
         id: id,
         reporterId: reporterId,
         targetId: targetId,
         reason: reason,
         channelId: channelId,
         messageId: messageId,
         createdAt: createdAt,
         resolved: resolved,
       );

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Report copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? reporterId,
    _i1.UuidValue? targetId,
    String? reason,
    Object? channelId = _Undefined,
    Object? messageId = _Undefined,
    DateTime? createdAt,
    bool? resolved,
  }) {
    return Report(
      id: id is int? ? id : this.id,
      reporterId: reporterId ?? this.reporterId,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      channelId: channelId is int? ? channelId : this.channelId,
      messageId: messageId is int? ? messageId : this.messageId,
      createdAt: createdAt ?? this.createdAt,
      resolved: resolved ?? this.resolved,
    );
  }
}

class ReportUpdateTable extends _i1.UpdateTable<ReportTable> {
  ReportUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> reporterId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.reporterId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> targetId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.targetId,
        value,
      );

  _i1.ColumnValue<String, String> reason(String value) => _i1.ColumnValue(
    table.reason,
    value,
  );

  _i1.ColumnValue<int, int> channelId(int? value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<int, int> messageId(int? value) => _i1.ColumnValue(
    table.messageId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<bool, bool> resolved(bool value) => _i1.ColumnValue(
    table.resolved,
    value,
  );
}

class ReportTable extends _i1.Table<int?> {
  ReportTable({super.tableRelation}) : super(tableName: 'report') {
    updateTable = ReportUpdateTable(this);
    reporterId = _i1.ColumnUuid(
      'reporterId',
      this,
    );
    targetId = _i1.ColumnUuid(
      'targetId',
      this,
    );
    reason = _i1.ColumnString(
      'reason',
      this,
    );
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    messageId = _i1.ColumnInt(
      'messageId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    resolved = _i1.ColumnBool(
      'resolved',
      this,
    );
  }

  late final ReportUpdateTable updateTable;

  late final _i1.ColumnUuid reporterId;

  late final _i1.ColumnUuid targetId;

  late final _i1.ColumnString reason;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnInt messageId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnBool resolved;

  @override
  List<_i1.Column> get columns => [
    id,
    reporterId,
    targetId,
    reason,
    channelId,
    messageId,
    createdAt,
    resolved,
  ];
}

class ReportInclude extends _i1.IncludeObject {
  ReportInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Report.t;
}

class ReportIncludeList extends _i1.IncludeList {
  ReportIncludeList._({
    _i1.WhereExpressionBuilder<ReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Report.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Report.t;
}

class ReportRepository {
  const ReportRepository._();

  /// Returns a list of [Report]s matching the given query parameters.
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
  Future<List<Report>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReportTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Report>(
      where: where?.call(Report.t),
      orderBy: orderBy?.call(Report.t),
      orderByList: orderByList?.call(Report.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Report] matching the given query parameters.
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
  Future<Report?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportTable>? where,
    int? offset,
    _i1.OrderByBuilder<ReportTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Report>(
      where: where?.call(Report.t),
      orderBy: orderBy?.call(Report.t),
      orderByList: orderByList?.call(Report.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Report] by its [id] or null if no such row exists.
  Future<Report?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Report>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Report]s in the list and returns the inserted rows.
  ///
  /// The returned [Report]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Report>> insert(
    _i1.Session session,
    List<Report> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Report>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Report] and returns the inserted row.
  ///
  /// The returned [Report] will have its `id` field set.
  Future<Report> insertRow(
    _i1.Session session,
    Report row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Report>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Report]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Report>> update(
    _i1.Session session,
    List<Report> rows, {
    _i1.ColumnSelections<ReportTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Report>(
      rows,
      columns: columns?.call(Report.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Report]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Report> updateRow(
    _i1.Session session,
    Report row, {
    _i1.ColumnSelections<ReportTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Report>(
      row,
      columns: columns?.call(Report.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Report] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Report?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ReportUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Report>(
      id,
      columnValues: columnValues(Report.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Report]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Report>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ReportUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ReportTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReportTable>? orderBy,
    _i1.OrderByListBuilder<ReportTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Report>(
      columnValues: columnValues(Report.t.updateTable),
      where: where(Report.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Report.t),
      orderByList: orderByList?.call(Report.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Report]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Report>> delete(
    _i1.Session session,
    List<Report> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Report>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Report].
  Future<Report> deleteRow(
    _i1.Session session,
    Report row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Report>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Report>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ReportTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Report>(
      where: where(Report.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Report>(
      where: where?.call(Report.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
