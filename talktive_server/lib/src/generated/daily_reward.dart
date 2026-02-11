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

abstract class DailyReward
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DailyReward._({
    this.id,
    required this.userId,
    required this.claimedDate,
    required this.rewardType,
    required this.rewardAmount,
    required this.streakDay,
  });

  factory DailyReward({
    int? id,
    required _i1.UuidValue userId,
    required DateTime claimedDate,
    required String rewardType,
    required int rewardAmount,
    required int streakDay,
  }) = _DailyRewardImpl;

  factory DailyReward.fromJson(Map<String, dynamic> jsonSerialization) {
    return DailyReward(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      claimedDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['claimedDate'],
      ),
      rewardType: jsonSerialization['rewardType'] as String,
      rewardAmount: jsonSerialization['rewardAmount'] as int,
      streakDay: jsonSerialization['streakDay'] as int,
    );
  }

  static final t = DailyRewardTable();

  static const db = DailyRewardRepository._();

  @override
  int? id;

  _i1.UuidValue userId;

  DateTime claimedDate;

  String rewardType;

  int rewardAmount;

  int streakDay;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DailyReward]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DailyReward copyWith({
    int? id,
    _i1.UuidValue? userId,
    DateTime? claimedDate,
    String? rewardType,
    int? rewardAmount,
    int? streakDay,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DailyReward',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'claimedDate': claimedDate.toJson(),
      'rewardType': rewardType,
      'rewardAmount': rewardAmount,
      'streakDay': streakDay,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DailyReward',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'claimedDate': claimedDate.toJson(),
      'rewardType': rewardType,
      'rewardAmount': rewardAmount,
      'streakDay': streakDay,
    };
  }

  static DailyRewardInclude include() {
    return DailyRewardInclude._();
  }

  static DailyRewardIncludeList includeList({
    _i1.WhereExpressionBuilder<DailyRewardTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DailyRewardTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DailyRewardTable>? orderByList,
    DailyRewardInclude? include,
  }) {
    return DailyRewardIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DailyReward.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DailyReward.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DailyRewardImpl extends DailyReward {
  _DailyRewardImpl({
    int? id,
    required _i1.UuidValue userId,
    required DateTime claimedDate,
    required String rewardType,
    required int rewardAmount,
    required int streakDay,
  }) : super._(
         id: id,
         userId: userId,
         claimedDate: claimedDate,
         rewardType: rewardType,
         rewardAmount: rewardAmount,
         streakDay: streakDay,
       );

  /// Returns a shallow copy of this [DailyReward]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DailyReward copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    DateTime? claimedDate,
    String? rewardType,
    int? rewardAmount,
    int? streakDay,
  }) {
    return DailyReward(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      claimedDate: claimedDate ?? this.claimedDate,
      rewardType: rewardType ?? this.rewardType,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      streakDay: streakDay ?? this.streakDay,
    );
  }
}

class DailyRewardUpdateTable extends _i1.UpdateTable<DailyRewardTable> {
  DailyRewardUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> claimedDate(DateTime value) =>
      _i1.ColumnValue(
        table.claimedDate,
        value,
      );

  _i1.ColumnValue<String, String> rewardType(String value) => _i1.ColumnValue(
    table.rewardType,
    value,
  );

  _i1.ColumnValue<int, int> rewardAmount(int value) => _i1.ColumnValue(
    table.rewardAmount,
    value,
  );

  _i1.ColumnValue<int, int> streakDay(int value) => _i1.ColumnValue(
    table.streakDay,
    value,
  );
}

class DailyRewardTable extends _i1.Table<int?> {
  DailyRewardTable({super.tableRelation}) : super(tableName: 'daily_rewards') {
    updateTable = DailyRewardUpdateTable(this);
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    claimedDate = _i1.ColumnDateTime(
      'claimedDate',
      this,
    );
    rewardType = _i1.ColumnString(
      'rewardType',
      this,
    );
    rewardAmount = _i1.ColumnInt(
      'rewardAmount',
      this,
    );
    streakDay = _i1.ColumnInt(
      'streakDay',
      this,
    );
  }

  late final DailyRewardUpdateTable updateTable;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnDateTime claimedDate;

  late final _i1.ColumnString rewardType;

  late final _i1.ColumnInt rewardAmount;

  late final _i1.ColumnInt streakDay;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    claimedDate,
    rewardType,
    rewardAmount,
    streakDay,
  ];
}

class DailyRewardInclude extends _i1.IncludeObject {
  DailyRewardInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DailyReward.t;
}

class DailyRewardIncludeList extends _i1.IncludeList {
  DailyRewardIncludeList._({
    _i1.WhereExpressionBuilder<DailyRewardTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DailyReward.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DailyReward.t;
}

class DailyRewardRepository {
  const DailyRewardRepository._();

  /// Returns a list of [DailyReward]s matching the given query parameters.
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
  Future<List<DailyReward>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DailyRewardTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DailyRewardTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DailyRewardTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<DailyReward>(
      where: where?.call(DailyReward.t),
      orderBy: orderBy?.call(DailyReward.t),
      orderByList: orderByList?.call(DailyReward.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [DailyReward] matching the given query parameters.
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
  Future<DailyReward?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DailyRewardTable>? where,
    int? offset,
    _i1.OrderByBuilder<DailyRewardTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DailyRewardTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<DailyReward>(
      where: where?.call(DailyReward.t),
      orderBy: orderBy?.call(DailyReward.t),
      orderByList: orderByList?.call(DailyReward.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [DailyReward] by its [id] or null if no such row exists.
  Future<DailyReward?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<DailyReward>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [DailyReward]s in the list and returns the inserted rows.
  ///
  /// The returned [DailyReward]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<DailyReward>> insert(
    _i1.Session session,
    List<DailyReward> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<DailyReward>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [DailyReward] and returns the inserted row.
  ///
  /// The returned [DailyReward] will have its `id` field set.
  Future<DailyReward> insertRow(
    _i1.Session session,
    DailyReward row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DailyReward>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DailyReward]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DailyReward>> update(
    _i1.Session session,
    List<DailyReward> rows, {
    _i1.ColumnSelections<DailyRewardTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DailyReward>(
      rows,
      columns: columns?.call(DailyReward.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DailyReward]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DailyReward> updateRow(
    _i1.Session session,
    DailyReward row, {
    _i1.ColumnSelections<DailyRewardTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DailyReward>(
      row,
      columns: columns?.call(DailyReward.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DailyReward] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DailyReward?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<DailyRewardUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DailyReward>(
      id,
      columnValues: columnValues(DailyReward.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DailyReward]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DailyReward>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<DailyRewardUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<DailyRewardTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DailyRewardTable>? orderBy,
    _i1.OrderByListBuilder<DailyRewardTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DailyReward>(
      columnValues: columnValues(DailyReward.t.updateTable),
      where: where(DailyReward.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DailyReward.t),
      orderByList: orderByList?.call(DailyReward.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DailyReward]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DailyReward>> delete(
    _i1.Session session,
    List<DailyReward> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DailyReward>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DailyReward].
  Future<DailyReward> deleteRow(
    _i1.Session session,
    DailyReward row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DailyReward>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DailyReward>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<DailyRewardTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DailyReward>(
      where: where(DailyReward.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DailyRewardTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DailyReward>(
      where: where?.call(DailyReward.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
