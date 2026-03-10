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

abstract class UserStreak
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserStreak._({
    this.id,
    required this.userId,
    int? currentStreak,
    int? longestStreak,
    this.lastActiveDate,
    int? totalActiveDays,
  }) : currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       totalActiveDays = totalActiveDays ?? 0;

  factory UserStreak({
    int? id,
    required _i1.UuidValue userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  }) = _UserStreakImpl;

  factory UserStreak.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserStreak(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      currentStreak: jsonSerialization['currentStreak'] as int?,
      longestStreak: jsonSerialization['longestStreak'] as int?,
      lastActiveDate: jsonSerialization['lastActiveDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActiveDate'],
            ),
      totalActiveDays: jsonSerialization['totalActiveDays'] as int?,
    );
  }

  static final t = UserStreakTable();

  static const db = UserStreakRepository._();

  @override
  int? id;

  _i1.UuidValue userId;

  int currentStreak;

  int longestStreak;

  DateTime? lastActiveDate;

  int totalActiveDays;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserStreak]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserStreak copyWith({
    int? id,
    _i1.UuidValue? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserStreak',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate?.toJson(),
      'totalActiveDays': totalActiveDays,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserStreak',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate?.toJson(),
      'totalActiveDays': totalActiveDays,
    };
  }

  static UserStreakInclude include() {
    return UserStreakInclude._();
  }

  static UserStreakIncludeList includeList({
    _i1.WhereExpressionBuilder<UserStreakTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStreakTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStreakTable>? orderByList,
    UserStreakInclude? include,
  }) {
    return UserStreakIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserStreak.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserStreak.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserStreakImpl extends UserStreak {
  _UserStreakImpl({
    int? id,
    required _i1.UuidValue userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  }) : super._(
         id: id,
         userId: userId,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         lastActiveDate: lastActiveDate,
         totalActiveDays: totalActiveDays,
       );

  /// Returns a shallow copy of this [UserStreak]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserStreak copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    int? currentStreak,
    int? longestStreak,
    Object? lastActiveDate = _Undefined,
    int? totalActiveDays,
  }) {
    return UserStreak(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate is DateTime?
          ? lastActiveDate
          : this.lastActiveDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
    );
  }
}

class UserStreakUpdateTable extends _i1.UpdateTable<UserStreakTable> {
  UserStreakUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<int, int> currentStreak(int value) => _i1.ColumnValue(
    table.currentStreak,
    value,
  );

  _i1.ColumnValue<int, int> longestStreak(int value) => _i1.ColumnValue(
    table.longestStreak,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastActiveDate(DateTime? value) =>
      _i1.ColumnValue(
        table.lastActiveDate,
        value,
      );

  _i1.ColumnValue<int, int> totalActiveDays(int value) => _i1.ColumnValue(
    table.totalActiveDays,
    value,
  );
}

class UserStreakTable extends _i1.Table<int?> {
  UserStreakTable({super.tableRelation}) : super(tableName: 'user_streaks') {
    updateTable = UserStreakUpdateTable(this);
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    currentStreak = _i1.ColumnInt(
      'currentStreak',
      this,
      hasDefault: true,
    );
    longestStreak = _i1.ColumnInt(
      'longestStreak',
      this,
      hasDefault: true,
    );
    lastActiveDate = _i1.ColumnDateTime(
      'lastActiveDate',
      this,
    );
    totalActiveDays = _i1.ColumnInt(
      'totalActiveDays',
      this,
      hasDefault: true,
    );
  }

  late final UserStreakUpdateTable updateTable;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnInt currentStreak;

  late final _i1.ColumnInt longestStreak;

  late final _i1.ColumnDateTime lastActiveDate;

  late final _i1.ColumnInt totalActiveDays;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    currentStreak,
    longestStreak,
    lastActiveDate,
    totalActiveDays,
  ];
}

class UserStreakInclude extends _i1.IncludeObject {
  UserStreakInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserStreak.t;
}

class UserStreakIncludeList extends _i1.IncludeList {
  UserStreakIncludeList._({
    _i1.WhereExpressionBuilder<UserStreakTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserStreak.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserStreak.t;
}

class UserStreakRepository {
  const UserStreakRepository._();

  /// Returns a list of [UserStreak]s matching the given query parameters.
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
  Future<List<UserStreak>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStreakTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStreakTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStreakTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserStreak>(
      where: where?.call(UserStreak.t),
      orderBy: orderBy?.call(UserStreak.t),
      orderByList: orderByList?.call(UserStreak.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserStreak] matching the given query parameters.
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
  Future<UserStreak?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStreakTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserStreakTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStreakTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserStreak>(
      where: where?.call(UserStreak.t),
      orderBy: orderBy?.call(UserStreak.t),
      orderByList: orderByList?.call(UserStreak.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserStreak] by its [id] or null if no such row exists.
  Future<UserStreak?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserStreak>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserStreak]s in the list and returns the inserted rows.
  ///
  /// The returned [UserStreak]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<UserStreak>> insert(
    _i1.Session session,
    List<UserStreak> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<UserStreak>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [UserStreak] and returns the inserted row.
  ///
  /// The returned [UserStreak] will have its `id` field set.
  Future<UserStreak> insertRow(
    _i1.Session session,
    UserStreak row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserStreak>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserStreak]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserStreak>> update(
    _i1.Session session,
    List<UserStreak> rows, {
    _i1.ColumnSelections<UserStreakTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserStreak>(
      rows,
      columns: columns?.call(UserStreak.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserStreak]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserStreak> updateRow(
    _i1.Session session,
    UserStreak row, {
    _i1.ColumnSelections<UserStreakTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserStreak>(
      row,
      columns: columns?.call(UserStreak.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserStreak] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserStreak?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserStreakUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserStreak>(
      id,
      columnValues: columnValues(UserStreak.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserStreak]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserStreak>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserStreakUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserStreakTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStreakTable>? orderBy,
    _i1.OrderByListBuilder<UserStreakTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserStreak>(
      columnValues: columnValues(UserStreak.t.updateTable),
      where: where(UserStreak.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserStreak.t),
      orderByList: orderByList?.call(UserStreak.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserStreak]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserStreak>> delete(
    _i1.Session session,
    List<UserStreak> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserStreak>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserStreak].
  Future<UserStreak> deleteRow(
    _i1.Session session,
    UserStreak row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserStreak>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserStreak>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserStreakTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserStreak>(
      where: where(UserStreak.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStreakTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserStreak>(
      where: where?.call(UserStreak.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserStreak] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserStreakTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserStreak>(
      where: where(UserStreak.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
