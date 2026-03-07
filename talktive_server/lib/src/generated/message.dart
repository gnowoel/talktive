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

abstract class Message
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Message._({
    this.id,
    required this.channelId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.senderName,
    this.senderAvatar,
    this.senderMood,
    required this.senderFloor,
  });

  factory Message({
    int? id,
    required int channelId,
    required _i1.UuidValue senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    required DateTime createdAt,
    required String senderName,
    String? senderAvatar,
    String? senderMood,
    required int senderFloor,
  }) = _MessageImpl;

  factory Message.fromJson(Map<String, dynamic> jsonSerialization) {
    return Message(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      senderId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['senderId'],
      ),
      content: jsonSerialization['content'] as String?,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      mediaUrl: jsonSerialization['mediaUrl'] as String?,
      mediaType: jsonSerialization['mediaType'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      senderName: jsonSerialization['senderName'] as String,
      senderAvatar: jsonSerialization['senderAvatar'] as String?,
      senderMood: jsonSerialization['senderMood'] as String?,
      senderFloor: jsonSerialization['senderFloor'] as int,
    );
  }

  static final t = MessageTable();

  static const db = MessageRepository._();

  @override
  int? id;

  int channelId;

  _i1.UuidValue senderId;

  String? content;

  String? imageUrl;

  String? mediaUrl;

  String? mediaType;

  DateTime createdAt;

  String senderName;

  String? senderAvatar;

  String? senderMood;

  int senderFloor;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Message copyWith({
    int? id,
    int? channelId,
    _i1.UuidValue? senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
    String? senderMood,
    int? senderFloor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'channelId': channelId,
      'senderId': senderId.toJson(),
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      'createdAt': createdAt.toJson(),
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (senderMood != null) 'senderMood': senderMood,
      'senderFloor': senderFloor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'channelId': channelId,
      'senderId': senderId.toJson(),
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      'createdAt': createdAt.toJson(),
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (senderMood != null) 'senderMood': senderMood,
      'senderFloor': senderFloor,
    };
  }

  static MessageInclude include() {
    return MessageInclude._();
  }

  static MessageIncludeList includeList({
    _i1.WhereExpressionBuilder<MessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MessageTable>? orderByList,
    MessageInclude? include,
  }) {
    return MessageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Message.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Message.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageImpl extends Message {
  _MessageImpl({
    int? id,
    required int channelId,
    required _i1.UuidValue senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    required DateTime createdAt,
    required String senderName,
    String? senderAvatar,
    String? senderMood,
    required int senderFloor,
  }) : super._(
         id: id,
         channelId: channelId,
         senderId: senderId,
         content: content,
         imageUrl: imageUrl,
         mediaUrl: mediaUrl,
         mediaType: mediaType,
         createdAt: createdAt,
         senderName: senderName,
         senderAvatar: senderAvatar,
         senderMood: senderMood,
         senderFloor: senderFloor,
       );

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Message copyWith({
    Object? id = _Undefined,
    int? channelId,
    _i1.UuidValue? senderId,
    Object? content = _Undefined,
    Object? imageUrl = _Undefined,
    Object? mediaUrl = _Undefined,
    Object? mediaType = _Undefined,
    DateTime? createdAt,
    String? senderName,
    Object? senderAvatar = _Undefined,
    Object? senderMood = _Undefined,
    int? senderFloor,
  }) {
    return Message(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      content: content is String? ? content : this.content,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      mediaUrl: mediaUrl is String? ? mediaUrl : this.mediaUrl,
      mediaType: mediaType is String? ? mediaType : this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar is String? ? senderAvatar : this.senderAvatar,
      senderMood: senderMood is String? ? senderMood : this.senderMood,
      senderFloor: senderFloor ?? this.senderFloor,
    );
  }
}

class MessageUpdateTable extends _i1.UpdateTable<MessageTable> {
  MessageUpdateTable(super.table);

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> senderId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.senderId,
        value,
      );

  _i1.ColumnValue<String, String> content(String? value) => _i1.ColumnValue(
    table.content,
    value,
  );

  _i1.ColumnValue<String, String> imageUrl(String? value) => _i1.ColumnValue(
    table.imageUrl,
    value,
  );

  _i1.ColumnValue<String, String> mediaUrl(String? value) => _i1.ColumnValue(
    table.mediaUrl,
    value,
  );

  _i1.ColumnValue<String, String> mediaType(String? value) => _i1.ColumnValue(
    table.mediaType,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<String, String> senderName(String value) => _i1.ColumnValue(
    table.senderName,
    value,
  );

  _i1.ColumnValue<String, String> senderAvatar(String? value) =>
      _i1.ColumnValue(
        table.senderAvatar,
        value,
      );

  _i1.ColumnValue<String, String> senderMood(String? value) => _i1.ColumnValue(
    table.senderMood,
    value,
  );

  _i1.ColumnValue<int, int> senderFloor(int value) => _i1.ColumnValue(
    table.senderFloor,
    value,
  );
}

class MessageTable extends _i1.Table<int?> {
  MessageTable({super.tableRelation}) : super(tableName: 'message') {
    updateTable = MessageUpdateTable(this);
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    senderId = _i1.ColumnUuid(
      'senderId',
      this,
    );
    content = _i1.ColumnString(
      'content',
      this,
    );
    imageUrl = _i1.ColumnString(
      'imageUrl',
      this,
    );
    mediaUrl = _i1.ColumnString(
      'mediaUrl',
      this,
    );
    mediaType = _i1.ColumnString(
      'mediaType',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    senderName = _i1.ColumnString(
      'senderName',
      this,
    );
    senderAvatar = _i1.ColumnString(
      'senderAvatar',
      this,
    );
    senderMood = _i1.ColumnString(
      'senderMood',
      this,
    );
    senderFloor = _i1.ColumnInt(
      'senderFloor',
      this,
    );
  }

  late final MessageUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnUuid senderId;

  late final _i1.ColumnString content;

  late final _i1.ColumnString imageUrl;

  late final _i1.ColumnString mediaUrl;

  late final _i1.ColumnString mediaType;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString senderName;

  late final _i1.ColumnString senderAvatar;

  late final _i1.ColumnString senderMood;

  late final _i1.ColumnInt senderFloor;

  @override
  List<_i1.Column> get columns => [
    id,
    channelId,
    senderId,
    content,
    imageUrl,
    mediaUrl,
    mediaType,
    createdAt,
    senderName,
    senderAvatar,
    senderMood,
    senderFloor,
  ];
}

class MessageInclude extends _i1.IncludeObject {
  MessageInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Message.t;
}

class MessageIncludeList extends _i1.IncludeList {
  MessageIncludeList._({
    _i1.WhereExpressionBuilder<MessageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Message.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Message.t;
}

class MessageRepository {
  const MessageRepository._();

  /// Returns a list of [Message]s matching the given query parameters.
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
  Future<List<Message>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MessageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Message>(
      where: where?.call(Message.t),
      orderBy: orderBy?.call(Message.t),
      orderByList: orderByList?.call(Message.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Message] matching the given query parameters.
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
  Future<Message?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MessageTable>? where,
    int? offset,
    _i1.OrderByBuilder<MessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MessageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Message>(
      where: where?.call(Message.t),
      orderBy: orderBy?.call(Message.t),
      orderByList: orderByList?.call(Message.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Message] by its [id] or null if no such row exists.
  Future<Message?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Message>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Message]s in the list and returns the inserted rows.
  ///
  /// The returned [Message]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Message>> insert(
    _i1.Session session,
    List<Message> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Message>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Message] and returns the inserted row.
  ///
  /// The returned [Message] will have its `id` field set.
  Future<Message> insertRow(
    _i1.Session session,
    Message row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Message>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Message]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Message>> update(
    _i1.Session session,
    List<Message> rows, {
    _i1.ColumnSelections<MessageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Message>(
      rows,
      columns: columns?.call(Message.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Message]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Message> updateRow(
    _i1.Session session,
    Message row, {
    _i1.ColumnSelections<MessageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Message>(
      row,
      columns: columns?.call(Message.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Message] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Message?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<MessageUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Message>(
      id,
      columnValues: columnValues(Message.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Message]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Message>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<MessageUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<MessageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MessageTable>? orderBy,
    _i1.OrderByListBuilder<MessageTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Message>(
      columnValues: columnValues(Message.t.updateTable),
      where: where(Message.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Message.t),
      orderByList: orderByList?.call(Message.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Message]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Message>> delete(
    _i1.Session session,
    List<Message> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Message>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Message].
  Future<Message> deleteRow(
    _i1.Session session,
    Message row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Message>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Message>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MessageTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Message>(
      where: where(Message.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MessageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Message>(
      where: where?.call(Message.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
