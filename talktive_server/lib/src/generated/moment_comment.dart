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

abstract class MomentComment
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  MomentComment._({
    this.id,
    required this.momentId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
    this.userMood,
    required this.userFloor,
    required this.userTrustScore,
  });

  factory MomentComment({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required String text,
    required DateTime createdAt,
    required String userName,
    String? userAvatar,
    String? userMood,
    required int userFloor,
    required int userTrustScore,
  }) = _MomentCommentImpl;

  factory MomentComment.fromJson(Map<String, dynamic> jsonSerialization) {
    return MomentComment(
      id: jsonSerialization['id'] as int?,
      momentId: jsonSerialization['momentId'] as int,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      text: jsonSerialization['text'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      userName: jsonSerialization['userName'] as String,
      userAvatar: jsonSerialization['userAvatar'] as String?,
      userMood: jsonSerialization['userMood'] as String?,
      userFloor: jsonSerialization['userFloor'] as int,
      userTrustScore: jsonSerialization['userTrustScore'] as int,
    );
  }

  static final t = MomentCommentTable();

  static const db = MomentCommentRepository._();

  @override
  int? id;

  int momentId;

  _i1.UuidValue userId;

  String text;

  DateTime createdAt;

  String userName;

  String? userAvatar;

  String? userMood;

  int userFloor;

  int userTrustScore;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [MomentComment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MomentComment copyWith({
    int? id,
    int? momentId,
    _i1.UuidValue? userId,
    String? text,
    DateTime? createdAt,
    String? userName,
    String? userAvatar,
    String? userMood,
    int? userFloor,
    int? userTrustScore,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MomentComment',
      if (id != null) 'id': id,
      'momentId': momentId,
      'userId': userId.toJson(),
      'text': text,
      'createdAt': createdAt.toJson(),
      'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'userFloor': userFloor,
      'userTrustScore': userTrustScore,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MomentComment',
      if (id != null) 'id': id,
      'momentId': momentId,
      'userId': userId.toJson(),
      'text': text,
      'createdAt': createdAt.toJson(),
      'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'userFloor': userFloor,
      'userTrustScore': userTrustScore,
    };
  }

  static MomentCommentInclude include() {
    return MomentCommentInclude._();
  }

  static MomentCommentIncludeList includeList({
    _i1.WhereExpressionBuilder<MomentCommentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentCommentTable>? orderByList,
    MomentCommentInclude? include,
  }) {
    return MomentCommentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MomentComment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MomentComment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MomentCommentImpl extends MomentComment {
  _MomentCommentImpl({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required String text,
    required DateTime createdAt,
    required String userName,
    String? userAvatar,
    String? userMood,
    required int userFloor,
    required int userTrustScore,
  }) : super._(
         id: id,
         momentId: momentId,
         userId: userId,
         text: text,
         createdAt: createdAt,
         userName: userName,
         userAvatar: userAvatar,
         userMood: userMood,
         userFloor: userFloor,
         userTrustScore: userTrustScore,
       );

  /// Returns a shallow copy of this [MomentComment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MomentComment copyWith({
    Object? id = _Undefined,
    int? momentId,
    _i1.UuidValue? userId,
    String? text,
    DateTime? createdAt,
    String? userName,
    Object? userAvatar = _Undefined,
    Object? userMood = _Undefined,
    int? userFloor,
    int? userTrustScore,
  }) {
    return MomentComment(
      id: id is int? ? id : this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar is String? ? userAvatar : this.userAvatar,
      userMood: userMood is String? ? userMood : this.userMood,
      userFloor: userFloor ?? this.userFloor,
      userTrustScore: userTrustScore ?? this.userTrustScore,
    );
  }
}

class MomentCommentUpdateTable extends _i1.UpdateTable<MomentCommentTable> {
  MomentCommentUpdateTable(super.table);

  _i1.ColumnValue<int, int> momentId(int value) => _i1.ColumnValue(
    table.momentId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<String, String> text(String value) => _i1.ColumnValue(
    table.text,
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

  _i1.ColumnValue<String, String> userAvatar(String? value) => _i1.ColumnValue(
    table.userAvatar,
    value,
  );

  _i1.ColumnValue<String, String> userMood(String? value) => _i1.ColumnValue(
    table.userMood,
    value,
  );

  _i1.ColumnValue<int, int> userFloor(int value) => _i1.ColumnValue(
    table.userFloor,
    value,
  );

  _i1.ColumnValue<int, int> userTrustScore(int value) => _i1.ColumnValue(
    table.userTrustScore,
    value,
  );
}

class MomentCommentTable extends _i1.Table<int?> {
  MomentCommentTable({super.tableRelation})
    : super(tableName: 'moment_comments') {
    updateTable = MomentCommentUpdateTable(this);
    momentId = _i1.ColumnInt(
      'momentId',
      this,
    );
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    text = _i1.ColumnString(
      'text',
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
    userMood = _i1.ColumnString(
      'userMood',
      this,
    );
    userFloor = _i1.ColumnInt(
      'userFloor',
      this,
    );
    userTrustScore = _i1.ColumnInt(
      'userTrustScore',
      this,
    );
  }

  late final MomentCommentUpdateTable updateTable;

  late final _i1.ColumnInt momentId;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnString text;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString userName;

  late final _i1.ColumnString userAvatar;

  late final _i1.ColumnString userMood;

  late final _i1.ColumnInt userFloor;

  late final _i1.ColumnInt userTrustScore;

  @override
  List<_i1.Column> get columns => [
    id,
    momentId,
    userId,
    text,
    createdAt,
    userName,
    userAvatar,
    userMood,
    userFloor,
    userTrustScore,
  ];
}

class MomentCommentInclude extends _i1.IncludeObject {
  MomentCommentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => MomentComment.t;
}

class MomentCommentIncludeList extends _i1.IncludeList {
  MomentCommentIncludeList._({
    _i1.WhereExpressionBuilder<MomentCommentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MomentComment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => MomentComment.t;
}

class MomentCommentRepository {
  const MomentCommentRepository._();

  /// Returns a list of [MomentComment]s matching the given query parameters.
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
  Future<List<MomentComment>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentCommentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentCommentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<MomentComment>(
      where: where?.call(MomentComment.t),
      orderBy: orderBy?.call(MomentComment.t),
      orderByList: orderByList?.call(MomentComment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [MomentComment] matching the given query parameters.
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
  Future<MomentComment?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentCommentTable>? where,
    int? offset,
    _i1.OrderByBuilder<MomentCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentCommentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<MomentComment>(
      where: where?.call(MomentComment.t),
      orderBy: orderBy?.call(MomentComment.t),
      orderByList: orderByList?.call(MomentComment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [MomentComment] by its [id] or null if no such row exists.
  Future<MomentComment?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<MomentComment>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [MomentComment]s in the list and returns the inserted rows.
  ///
  /// The returned [MomentComment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<MomentComment>> insert(
    _i1.Session session,
    List<MomentComment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<MomentComment>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [MomentComment] and returns the inserted row.
  ///
  /// The returned [MomentComment] will have its `id` field set.
  Future<MomentComment> insertRow(
    _i1.Session session,
    MomentComment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MomentComment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MomentComment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MomentComment>> update(
    _i1.Session session,
    List<MomentComment> rows, {
    _i1.ColumnSelections<MomentCommentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MomentComment>(
      rows,
      columns: columns?.call(MomentComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MomentComment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MomentComment> updateRow(
    _i1.Session session,
    MomentComment row, {
    _i1.ColumnSelections<MomentCommentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MomentComment>(
      row,
      columns: columns?.call(MomentComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MomentComment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MomentComment?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<MomentCommentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<MomentComment>(
      id,
      columnValues: columnValues(MomentComment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MomentComment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<MomentComment>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<MomentCommentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<MomentCommentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentCommentTable>? orderBy,
    _i1.OrderByListBuilder<MomentCommentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<MomentComment>(
      columnValues: columnValues(MomentComment.t.updateTable),
      where: where(MomentComment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MomentComment.t),
      orderByList: orderByList?.call(MomentComment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [MomentComment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MomentComment>> delete(
    _i1.Session session,
    List<MomentComment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MomentComment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MomentComment].
  Future<MomentComment> deleteRow(
    _i1.Session session,
    MomentComment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MomentComment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MomentComment>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MomentCommentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MomentComment>(
      where: where(MomentComment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentCommentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MomentComment>(
      where: where?.call(MomentComment.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
