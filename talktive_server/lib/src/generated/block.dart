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

abstract class Block implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Block._({
    this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory Block({
    int? id,
    required _i1.UuidValue blockerId,
    required _i1.UuidValue blockedId,
    required DateTime createdAt,
  }) = _BlockImpl;

  factory Block.fromJson(Map<String, dynamic> jsonSerialization) {
    return Block(
      id: jsonSerialization['id'] as int?,
      blockerId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['blockerId'],
      ),
      blockedId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['blockedId'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = BlockTable();

  static const db = BlockRepository._();

  @override
  int? id;

  _i1.UuidValue blockerId;

  _i1.UuidValue blockedId;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Block]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Block copyWith({
    int? id,
    _i1.UuidValue? blockerId,
    _i1.UuidValue? blockedId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Block',
      if (id != null) 'id': id,
      'blockerId': blockerId.toJson(),
      'blockedId': blockedId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Block',
      if (id != null) 'id': id,
      'blockerId': blockerId.toJson(),
      'blockedId': blockedId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static BlockInclude include() {
    return BlockInclude._();
  }

  static BlockIncludeList includeList({
    _i1.WhereExpressionBuilder<BlockTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BlockTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BlockTable>? orderByList,
    BlockInclude? include,
  }) {
    return BlockIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Block.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Block.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BlockImpl extends Block {
  _BlockImpl({
    int? id,
    required _i1.UuidValue blockerId,
    required _i1.UuidValue blockedId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         blockerId: blockerId,
         blockedId: blockedId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Block]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Block copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? blockerId,
    _i1.UuidValue? blockedId,
    DateTime? createdAt,
  }) {
    return Block(
      id: id is int? ? id : this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BlockUpdateTable extends _i1.UpdateTable<BlockTable> {
  BlockUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> blockerId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.blockerId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> blockedId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.blockedId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class BlockTable extends _i1.Table<int?> {
  BlockTable({super.tableRelation}) : super(tableName: 'user_block') {
    updateTable = BlockUpdateTable(this);
    blockerId = _i1.ColumnUuid(
      'blockerId',
      this,
    );
    blockedId = _i1.ColumnUuid(
      'blockedId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BlockUpdateTable updateTable;

  late final _i1.ColumnUuid blockerId;

  late final _i1.ColumnUuid blockedId;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    blockerId,
    blockedId,
    createdAt,
  ];
}

class BlockInclude extends _i1.IncludeObject {
  BlockInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Block.t;
}

class BlockIncludeList extends _i1.IncludeList {
  BlockIncludeList._({
    _i1.WhereExpressionBuilder<BlockTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Block.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Block.t;
}

class BlockRepository {
  const BlockRepository._();

  /// Returns a list of [Block]s matching the given query parameters.
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
  Future<List<Block>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BlockTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BlockTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BlockTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Block>(
      where: where?.call(Block.t),
      orderBy: orderBy?.call(Block.t),
      orderByList: orderByList?.call(Block.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Block] matching the given query parameters.
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
  Future<Block?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BlockTable>? where,
    int? offset,
    _i1.OrderByBuilder<BlockTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BlockTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Block>(
      where: where?.call(Block.t),
      orderBy: orderBy?.call(Block.t),
      orderByList: orderByList?.call(Block.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Block] by its [id] or null if no such row exists.
  Future<Block?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Block>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Block]s in the list and returns the inserted rows.
  ///
  /// The returned [Block]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Block>> insert(
    _i1.DatabaseSession session,
    List<Block> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Block>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Block] and returns the inserted row.
  ///
  /// The returned [Block] will have its `id` field set.
  Future<Block> insertRow(
    _i1.DatabaseSession session,
    Block row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Block>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Block]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Block>> update(
    _i1.DatabaseSession session,
    List<Block> rows, {
    _i1.ColumnSelections<BlockTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Block>(
      rows,
      columns: columns?.call(Block.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Block]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Block> updateRow(
    _i1.DatabaseSession session,
    Block row, {
    _i1.ColumnSelections<BlockTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Block>(
      row,
      columns: columns?.call(Block.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Block] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Block?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<BlockUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Block>(
      id,
      columnValues: columnValues(Block.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Block]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Block>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<BlockUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<BlockTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BlockTable>? orderBy,
    _i1.OrderByListBuilder<BlockTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Block>(
      columnValues: columnValues(Block.t.updateTable),
      where: where(Block.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Block.t),
      orderByList: orderByList?.call(Block.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Block]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Block>> delete(
    _i1.DatabaseSession session,
    List<Block> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Block>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Block].
  Future<Block> deleteRow(
    _i1.DatabaseSession session,
    Block row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Block>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Block>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BlockTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Block>(
      where: where(Block.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BlockTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Block>(
      where: where?.call(Block.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Block] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BlockTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Block>(
      where: where(Block.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
