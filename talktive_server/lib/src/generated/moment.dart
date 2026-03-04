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

abstract class Moment implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Moment._({
    this.id,
    required this.authorId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.authorName,
    required this.authorAvatar,
    this.authorMood,
    required this.authorFloor,
  });

  factory Moment({
    int? id,
    required int authorId,
    required String imageUrl,
    String? caption,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    required String authorAvatar,
    String? authorMood,
    required int authorFloor,
  }) = _MomentImpl;

  factory Moment.fromJson(Map<String, dynamic> jsonSerialization) {
    return Moment(
      id: jsonSerialization['id'] as int?,
      authorId: jsonSerialization['authorId'] as int,
      imageUrl: jsonSerialization['imageUrl'] as String,
      caption: jsonSerialization['caption'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      likesCount: jsonSerialization['likesCount'] as int,
      commentsCount: jsonSerialization['commentsCount'] as int,
      authorName: jsonSerialization['authorName'] as String,
      authorAvatar: jsonSerialization['authorAvatar'] as String,
      authorMood: jsonSerialization['authorMood'] as String?,
      authorFloor: jsonSerialization['authorFloor'] as int,
    );
  }

  static final t = MomentTable();

  static const db = MomentRepository._();

  @override
  int? id;

  int authorId;

  String imageUrl;

  String? caption;

  DateTime createdAt;

  int likesCount;

  int commentsCount;

  String authorName;

  String authorAvatar;

  String? authorMood;

  int authorFloor;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Moment copyWith({
    int? id,
    int? authorId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    String? authorAvatar,
    String? authorMood,
    int? authorFloor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Moment',
      if (id != null) 'id': id,
      'authorId': authorId,
      'imageUrl': imageUrl,
      if (caption != null) 'caption': caption,
      'createdAt': createdAt.toJson(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      if (authorMood != null) 'authorMood': authorMood,
      'authorFloor': authorFloor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Moment',
      if (id != null) 'id': id,
      'authorId': authorId,
      'imageUrl': imageUrl,
      if (caption != null) 'caption': caption,
      'createdAt': createdAt.toJson(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      if (authorMood != null) 'authorMood': authorMood,
      'authorFloor': authorFloor,
    };
  }

  static MomentInclude include() {
    return MomentInclude._();
  }

  static MomentIncludeList includeList({
    _i1.WhereExpressionBuilder<MomentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentTable>? orderByList,
    MomentInclude? include,
  }) {
    return MomentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Moment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Moment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MomentImpl extends Moment {
  _MomentImpl({
    int? id,
    required int authorId,
    required String imageUrl,
    String? caption,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    required String authorAvatar,
    String? authorMood,
    required int authorFloor,
  }) : super._(
         id: id,
         authorId: authorId,
         imageUrl: imageUrl,
         caption: caption,
         createdAt: createdAt,
         likesCount: likesCount,
         commentsCount: commentsCount,
         authorName: authorName,
         authorAvatar: authorAvatar,
         authorMood: authorMood,
         authorFloor: authorFloor,
       );

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Moment copyWith({
    Object? id = _Undefined,
    int? authorId,
    String? imageUrl,
    Object? caption = _Undefined,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    String? authorAvatar,
    Object? authorMood = _Undefined,
    int? authorFloor,
  }) {
    return Moment(
      id: id is int? ? id : this.id,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption is String? ? caption : this.caption,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorMood: authorMood is String? ? authorMood : this.authorMood,
      authorFloor: authorFloor ?? this.authorFloor,
    );
  }
}

class MomentUpdateTable extends _i1.UpdateTable<MomentTable> {
  MomentUpdateTable(super.table);

  _i1.ColumnValue<int, int> authorId(int value) => _i1.ColumnValue(
    table.authorId,
    value,
  );

  _i1.ColumnValue<String, String> imageUrl(String value) => _i1.ColumnValue(
    table.imageUrl,
    value,
  );

  _i1.ColumnValue<String, String> caption(String? value) => _i1.ColumnValue(
    table.caption,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<int, int> likesCount(int value) => _i1.ColumnValue(
    table.likesCount,
    value,
  );

  _i1.ColumnValue<int, int> commentsCount(int value) => _i1.ColumnValue(
    table.commentsCount,
    value,
  );

  _i1.ColumnValue<String, String> authorName(String value) => _i1.ColumnValue(
    table.authorName,
    value,
  );

  _i1.ColumnValue<String, String> authorAvatar(String value) => _i1.ColumnValue(
    table.authorAvatar,
    value,
  );

  _i1.ColumnValue<String, String> authorMood(String? value) => _i1.ColumnValue(
    table.authorMood,
    value,
  );

  _i1.ColumnValue<int, int> authorFloor(int value) => _i1.ColumnValue(
    table.authorFloor,
    value,
  );
}

class MomentTable extends _i1.Table<int?> {
  MomentTable({super.tableRelation}) : super(tableName: 'moment') {
    updateTable = MomentUpdateTable(this);
    authorId = _i1.ColumnInt(
      'authorId',
      this,
    );
    imageUrl = _i1.ColumnString(
      'imageUrl',
      this,
    );
    caption = _i1.ColumnString(
      'caption',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    likesCount = _i1.ColumnInt(
      'likesCount',
      this,
    );
    commentsCount = _i1.ColumnInt(
      'commentsCount',
      this,
    );
    authorName = _i1.ColumnString(
      'authorName',
      this,
    );
    authorAvatar = _i1.ColumnString(
      'authorAvatar',
      this,
    );
    authorMood = _i1.ColumnString(
      'authorMood',
      this,
    );
    authorFloor = _i1.ColumnInt(
      'authorFloor',
      this,
    );
  }

  late final MomentUpdateTable updateTable;

  late final _i1.ColumnInt authorId;

  late final _i1.ColumnString imageUrl;

  late final _i1.ColumnString caption;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt likesCount;

  late final _i1.ColumnInt commentsCount;

  late final _i1.ColumnString authorName;

  late final _i1.ColumnString authorAvatar;

  late final _i1.ColumnString authorMood;

  late final _i1.ColumnInt authorFloor;

  @override
  List<_i1.Column> get columns => [
    id,
    authorId,
    imageUrl,
    caption,
    createdAt,
    likesCount,
    commentsCount,
    authorName,
    authorAvatar,
    authorMood,
    authorFloor,
  ];
}

class MomentInclude extends _i1.IncludeObject {
  MomentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Moment.t;
}

class MomentIncludeList extends _i1.IncludeList {
  MomentIncludeList._({
    _i1.WhereExpressionBuilder<MomentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Moment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Moment.t;
}

class MomentRepository {
  const MomentRepository._();

  /// Returns a list of [Moment]s matching the given query parameters.
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
  Future<List<Moment>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Moment>(
      where: where?.call(Moment.t),
      orderBy: orderBy?.call(Moment.t),
      orderByList: orderByList?.call(Moment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Moment] matching the given query parameters.
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
  Future<Moment?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentTable>? where,
    int? offset,
    _i1.OrderByBuilder<MomentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MomentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Moment>(
      where: where?.call(Moment.t),
      orderBy: orderBy?.call(Moment.t),
      orderByList: orderByList?.call(Moment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Moment] by its [id] or null if no such row exists.
  Future<Moment?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Moment>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Moment]s in the list and returns the inserted rows.
  ///
  /// The returned [Moment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Moment>> insert(
    _i1.Session session,
    List<Moment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Moment>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Moment] and returns the inserted row.
  ///
  /// The returned [Moment] will have its `id` field set.
  Future<Moment> insertRow(
    _i1.Session session,
    Moment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Moment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Moment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Moment>> update(
    _i1.Session session,
    List<Moment> rows, {
    _i1.ColumnSelections<MomentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Moment>(
      rows,
      columns: columns?.call(Moment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Moment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Moment> updateRow(
    _i1.Session session,
    Moment row, {
    _i1.ColumnSelections<MomentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Moment>(
      row,
      columns: columns?.call(Moment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Moment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Moment?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<MomentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Moment>(
      id,
      columnValues: columnValues(Moment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Moment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Moment>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<MomentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<MomentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MomentTable>? orderBy,
    _i1.OrderByListBuilder<MomentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Moment>(
      columnValues: columnValues(Moment.t.updateTable),
      where: where(Moment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Moment.t),
      orderByList: orderByList?.call(Moment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Moment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Moment>> delete(
    _i1.Session session,
    List<Moment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Moment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Moment].
  Future<Moment> deleteRow(
    _i1.Session session,
    Moment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Moment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Moment>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MomentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Moment>(
      where: where(Moment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MomentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Moment>(
      where: where?.call(Moment.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
