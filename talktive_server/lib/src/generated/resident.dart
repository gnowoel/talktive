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

abstract class Resident
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Resident._({
    this.id,
    required this.userInfoId,
    required this.floor,
    required this.creditScore,
    required this.experienceMessageCount,
    this.lastCreditIncrease,
  });

  factory Resident({
    int? id,
    required _i1.UuidValue userInfoId,
    required int floor,
    required int creditScore,
    required int experienceMessageCount,
    DateTime? lastCreditIncrease,
  }) = _ResidentImpl;

  factory Resident.fromJson(Map<String, dynamic> jsonSerialization) {
    return Resident(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      floor: jsonSerialization['floor'] as int,
      creditScore: jsonSerialization['creditScore'] as int,
      experienceMessageCount:
          jsonSerialization['experienceMessageCount'] as int,
      lastCreditIncrease: jsonSerialization['lastCreditIncrease'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastCreditIncrease'],
            ),
    );
  }

  static final t = ResidentTable();

  static const db = ResidentRepository._();

  @override
  int? id;

  _i1.UuidValue userInfoId;

  int floor;

  int creditScore;

  int experienceMessageCount;

  DateTime? lastCreditIncrease;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Resident copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? floor,
    int? creditScore,
    int? experienceMessageCount,
    DateTime? lastCreditIncrease,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'floor': floor,
      'creditScore': creditScore,
      'experienceMessageCount': experienceMessageCount,
      if (lastCreditIncrease != null)
        'lastCreditIncrease': lastCreditIncrease?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'floor': floor,
      'creditScore': creditScore,
      'experienceMessageCount': experienceMessageCount,
      if (lastCreditIncrease != null)
        'lastCreditIncrease': lastCreditIncrease?.toJson(),
    };
  }

  static ResidentInclude include() {
    return ResidentInclude._();
  }

  static ResidentIncludeList includeList({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    ResidentInclude? include,
  }) {
    return ResidentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Resident.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResidentImpl extends Resident {
  _ResidentImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    required int floor,
    required int creditScore,
    required int experienceMessageCount,
    DateTime? lastCreditIncrease,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         floor: floor,
         creditScore: creditScore,
         experienceMessageCount: experienceMessageCount,
         lastCreditIncrease: lastCreditIncrease,
       );

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Resident copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? floor,
    int? creditScore,
    int? experienceMessageCount,
    Object? lastCreditIncrease = _Undefined,
  }) {
    return Resident(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      floor: floor ?? this.floor,
      creditScore: creditScore ?? this.creditScore,
      experienceMessageCount:
          experienceMessageCount ?? this.experienceMessageCount,
      lastCreditIncrease: lastCreditIncrease is DateTime?
          ? lastCreditIncrease
          : this.lastCreditIncrease,
    );
  }
}

class ResidentUpdateTable extends _i1.UpdateTable<ResidentTable> {
  ResidentUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userInfoId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<int, int> floor(int value) => _i1.ColumnValue(
    table.floor,
    value,
  );

  _i1.ColumnValue<int, int> creditScore(int value) => _i1.ColumnValue(
    table.creditScore,
    value,
  );

  _i1.ColumnValue<int, int> experienceMessageCount(int value) =>
      _i1.ColumnValue(
        table.experienceMessageCount,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastCreditIncrease(DateTime? value) =>
      _i1.ColumnValue(
        table.lastCreditIncrease,
        value,
      );
}

class ResidentTable extends _i1.Table<int?> {
  ResidentTable({super.tableRelation}) : super(tableName: 'resident') {
    updateTable = ResidentUpdateTable(this);
    userInfoId = _i1.ColumnUuid(
      'userInfoId',
      this,
    );
    floor = _i1.ColumnInt(
      'floor',
      this,
    );
    creditScore = _i1.ColumnInt(
      'creditScore',
      this,
    );
    experienceMessageCount = _i1.ColumnInt(
      'experienceMessageCount',
      this,
    );
    lastCreditIncrease = _i1.ColumnDateTime(
      'lastCreditIncrease',
      this,
    );
  }

  late final ResidentUpdateTable updateTable;

  late final _i1.ColumnUuid userInfoId;

  late final _i1.ColumnInt floor;

  late final _i1.ColumnInt creditScore;

  late final _i1.ColumnInt experienceMessageCount;

  late final _i1.ColumnDateTime lastCreditIncrease;

  @override
  List<_i1.Column> get columns => [
    id,
    userInfoId,
    floor,
    creditScore,
    experienceMessageCount,
    lastCreditIncrease,
  ];
}

class ResidentInclude extends _i1.IncludeObject {
  ResidentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentIncludeList extends _i1.IncludeList {
  ResidentIncludeList._({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Resident.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentRepository {
  const ResidentRepository._();

  /// Returns a list of [Resident]s matching the given query parameters.
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
  Future<List<Resident>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Resident] matching the given query parameters.
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
  Future<Resident?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Resident] by its [id] or null if no such row exists.
  Future<Resident?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Resident>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Resident]s in the list and returns the inserted rows.
  ///
  /// The returned [Resident]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Resident>> insert(
    _i1.Session session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Resident>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Resident] and returns the inserted row.
  ///
  /// The returned [Resident] will have its `id` field set.
  Future<Resident> insertRow(
    _i1.Session session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Resident>> update(
    _i1.Session session,
    List<Resident> rows, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Resident>(
      rows,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Resident> updateRow(
    _i1.Session session,
    Resident row, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Resident>(
      row,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Resident?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Resident>(
      id,
      columnValues: columnValues(Resident.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Resident>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Resident>(
      columnValues: columnValues(Resident.t.updateTable),
      where: where(Resident.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Resident]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Resident>> delete(
    _i1.Session session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Resident>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Resident].
  Future<Resident> deleteRow(
    _i1.Session session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Resident>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Resident>(
      where: where(Resident.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Resident>(
      where: where?.call(Resident.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
