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

abstract class MomentLike
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  MomentLike._({
    this.id,
    required this.momentId,
    required this.userId,
    required this.createdAt,
    required this.userName,
    required this.userAvatar,
    required this.userFloor,
  });

  factory MomentLike({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required DateTime createdAt,
    required String userName,
    required String userAvatar,
    required int userFloor,
  }) = _MomentLikeImpl;

  factory MomentLike.fromJson(Map<String, dynamic> jsonSerialization) {
    return MomentLike(
      id: jsonSerialization['id'] as int?,
      momentId: jsonSerialization['momentId'] as int,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      userName: jsonSerialization['userName'] as String,
      userAvatar: jsonSerialization['userAvatar'] as String,
      userFloor: jsonSerialization['userFloor'] as int,
    );
  }

  static final t = MomentLikeTable();

  static const db = MomentLikeRepository._();

  @override
  int? id;

  int momentId;

  _i1.UuidValue userId;

  DateTime createdAt;

  String userName;

  String userAvatar;

  int userFloor;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [MomentLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MomentLike copyWith({
    int? id,
    int? momentId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
    String? userName,
    String? userAvatar,
    int? userFloor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MomentLike',
      if (id != null) 'id': id,
      'momentId': momentId,
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
      'userName': userName,
      'userAvatar': userAvatar,
      'userFloor': userFloor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MomentLike',
      if (id != null) 'id': id,
      'momentId': momentId,
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
      'userName': userName,
      'userAvatar': userAvatar,
      'userFloor': userFloor,
    };
  }

  static MomentLikeInclude include() {
    return MomentLikeInclude._();
  }

  static MomentLikeIncludeList includeList({
    _i1.WhereExpressionBuilder<MomentLikeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentLikeTable>? orderByList,
    MomentLikeInclude? include,
  }) {
    return MomentLikeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MomentLike.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MomentLike.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MomentLikeImpl extends MomentLike {
  _MomentLikeImpl({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required DateTime createdAt,
    required String userName,
    required String userAvatar,
    required int userFloor,
  }) : super._(
         id: id,
         momentId: momentId,
         userId: userId,
         createdAt: createdAt,
         userName: userName,
         userAvatar: userAvatar,
         userFloor: userFloor,
       );

  /// Returns a shallow copy of this [MomentLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MomentLike copyWith({
    Object? id = _Undefined,
    int? momentId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
    String? userName,
    String? userAvatar,
    int? userFloor,
  }) {
    return MomentLike(
      id: id is int? ? id : this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userFloor: userFloor ?? this.userFloor,
    );
  }
}

class MomentLikeUpdateTable extends _i1.UpdateTable<MomentLikeTable> {
  MomentLikeUpdateTable(super.table);

  _i1.ColumnValue<int, int> momentId(int value) => _i1.ColumnValue(
    table.momentId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<String, String> userName(String value) => _i1.ColumnValue(
    table.userName,
    value,
  );

  _i1.ColumnValue<String, String> userAvatar(String value) => _i1.ColumnValue(
    table.userAvatar,
    value,
  );

  _i1.ColumnValue<int, int> userFloor(int value) => _i1.ColumnValue(
    table.userFloor,
    value,
  );
}

class MomentLikeTable extends _i1.Table<int?> {
  MomentLikeTable({super.tableRelation}) : super(tableName: 'moment_likes') {
    updateTable = MomentLikeUpdateTable(this);
    momentId = _i1.ColumnInt(
      'momentId',
      this,
    );
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    userName = _i1.ColumnString(
      'userName',
      this,
    );
    userAvatar = _i1.ColumnString(
      'userAvatar',
      this,
    );
    userFloor = _i1.ColumnInt(
      'userFloor',
      this,
    );
  }

  late final MomentLikeUpdateTable updateTable;

  late final _i1.ColumnInt momentId;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString userName;

  late final _i1.ColumnString userAvatar;

  late final _i1.ColumnInt userFloor;

  @override
  List<_i1.Column> get columns => [
    id,
    momentId,
    userId,
    createdAt,
    userName,
    userAvatar,
    userFloor,
  ];
}

class MomentLikeInclude extends _i1.IncludeObject {
  MomentLikeInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => MomentLike.t;
}

class MomentLikeIncludeList extends _i1.IncludeList {
  MomentLikeIncludeList._({
    _i1.WhereExpressionBuilder<MomentLikeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MomentLike.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => MomentLike.t;
}

class MomentLikeRepository {
  const MomentLikeRepository._();

  /// Returns a list of [MomentLike]s matching the given query parameters.
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
  Future<List<MomentLike>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentLikeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentLikeTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<MomentLike>(
      where: where?.call(MomentLike.t),
      orderBy: orderBy?.call(MomentLike.t),
      orderByList: orderByList?.call(MomentLike.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [MomentLike] matching the given query parameters.
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
  Future<MomentLike?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentLikeTable>? where,
    int? offset,
    _i1.OrderByBuilder<MomentLikeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentLikeTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<MomentLike>(
      where: where?.call(MomentLike.t),
      orderBy: orderBy?.call(MomentLike.t),
      orderByList: orderByList?.call(MomentLike.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [MomentLike] by its [id] or null if no such row exists.
  Future<MomentLike?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<MomentLike>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [MomentLike]s in the list and returns the inserted rows.
  ///
  /// The returned [MomentLike]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<MomentLike>> insert(
    _i1.Session session,
    List<MomentLike> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<MomentLike>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [MomentLike] and returns the inserted row.
  ///
  /// The returned [MomentLike] will have its `id` field set.
  Future<MomentLike> insertRow(
    _i1.Session session,
    MomentLike row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MomentLike>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MomentLike]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MomentLike>> update(
    _i1.Session session,
    List<MomentLike> rows, {
    _i1.ColumnSelections<MomentLikeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MomentLike>(
      rows,
      columns: columns?.call(MomentLike.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MomentLike]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MomentLike> updateRow(
    _i1.Session session,
    MomentLike row, {
    _i1.ColumnSelections<MomentLikeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MomentLike>(
      row,
      columns: columns?.call(MomentLike.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MomentLike] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MomentLike?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<MomentLikeUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<MomentLike>(
      id,
      columnValues: columnValues(MomentLike.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MomentLike]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<MomentLike>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<MomentLikeUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<MomentLikeTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentLikeTable>? orderBy,
    _i1.OrderByListBuilder<MomentLikeTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<MomentLike>(
      columnValues: columnValues(MomentLike.t.updateTable),
      where: where(MomentLike.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MomentLike.t),
      orderByList: orderByList?.call(MomentLike.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [MomentLike]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MomentLike>> delete(
    _i1.Session session,
    List<MomentLike> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MomentLike>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MomentLike].
  Future<MomentLike> deleteRow(
    _i1.Session session,
    MomentLike row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MomentLike>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MomentLike>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MomentLikeTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MomentLike>(
      where: where(MomentLike.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentLikeTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MomentLike>(
      where: where?.call(MomentLike.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
