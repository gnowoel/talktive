/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'channel.dart' as _i2;
import 'package:talktive_server/src/generated/protocol.dart' as _i3;

abstract class Message
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Message._({
    this.id,
    required this.channelId,
    required this.channelId,
    this.channel,
    required this.senderId,
    this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory Message({
    int? id,
    required int channelId,
    required int channelId,
    _i2.Channel? channel,
    required int senderId,
    String? content,
    String? imageUrl,
    required DateTime createdAt,
  }) = _MessageImpl;

  factory Message.fromJson(Map<String, dynamic> jsonSerialization) {
    return Message(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      channel: jsonSerialization['channel'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Channel>(
              jsonSerialization['channel'],
            ),
      senderId: jsonSerialization['senderId'] as int,
      content: jsonSerialization['content'] as String?,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = MessageTable();

  static const db = MessageRepository._();

  @override
  int? id;

  int channelId;

  int channelId;

  _i2.Channel? channel;

  int senderId;

  String? content;

  String? imageUrl;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Message copyWith({
    int? id,
    int? channelId,
    int? channelId,
    _i2.Channel? channel,
    int? senderId,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'channelId': channelId,
      'channelId': channelId,
      if (channel != null) 'channel': channel?.toJson(),
      'senderId': senderId,
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'channelId': channelId,
      'channelId': channelId,
      if (channel != null) 'channel': channel?.toJsonForProtocol(),
      'senderId': senderId,
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toJson(),
    };
  }

  static MessageInclude include({_i2.ChannelInclude? channel}) {
    return MessageInclude._(channel: channel);
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
    required int channelId,
    _i2.Channel? channel,
    required int senderId,
    String? content,
    String? imageUrl,
    required DateTime createdAt,
  }) : super._(
         id: id,
         channelId: channelId,
         channel: channel,
         senderId: senderId,
         content: content,
         imageUrl: imageUrl,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Message copyWith({
    Object? id = _Undefined,
    int? channelId,
    int? channelId,
    Object? channel = _Undefined,
    int? senderId,
    Object? content = _Undefined,
    Object? imageUrl = _Undefined,
    DateTime? createdAt,
  }) {
    return Message(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      channel: channel is _i2.Channel? ? channel : this.channel?.copyWith(),
      senderId: senderId ?? this.senderId,
      content: content is String? ? content : this.content,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MessageUpdateTable extends _i1.UpdateTable<MessageTable> {
  MessageUpdateTable(super.table);

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<int, int> senderId(int value) => _i1.ColumnValue(
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

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
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
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    senderId = _i1.ColumnInt(
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
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final MessageUpdateTable updateTable;

  late final _i1.ColumnInt channelId;

  late final _i1.ColumnInt channelId;

  _i2.ChannelTable? _channel;

  late final _i1.ColumnInt senderId;

  late final _i1.ColumnString content;

  late final _i1.ColumnString imageUrl;

  late final _i1.ColumnDateTime createdAt;

  _i2.ChannelTable get channel {
    if (_channel != null) return _channel!;
    _channel = _i1.createRelationTable(
      relationFieldName: 'channel',
      field: Message.t.channelId,
      foreignField: _i2.Channel.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ChannelTable(tableRelation: foreignTableRelation),
    );
    return _channel!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    channelId,
    channelId,
    senderId,
    content,
    imageUrl,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'channel') {
      return channel;
    }
    return null;
  }
}

class MessageInclude extends _i1.IncludeObject {
  MessageInclude._({_i2.ChannelInclude? channel}) {
    _channel = channel;
  }

  _i2.ChannelInclude? _channel;

  @override
  Map<String, _i1.Include?> get includes => {'channel': _channel};

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

  final attachRow = const MessageAttachRowRepository._();

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
    MessageInclude? include,
  }) async {
    return session.db.find<Message>(
      where: where?.call(Message.t),
      orderBy: orderBy?.call(Message.t),
      orderByList: orderByList?.call(Message.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
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
    MessageInclude? include,
  }) async {
    return session.db.findFirstRow<Message>(
      where: where?.call(Message.t),
      orderBy: orderBy?.call(Message.t),
      orderByList: orderByList?.call(Message.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Finds a single [Message] by its [id] or null if no such row exists.
  Future<Message?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    MessageInclude? include,
  }) async {
    return session.db.findById<Message>(
      id,
      transaction: transaction,
      include: include,
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

class MessageAttachRowRepository {
  const MessageAttachRowRepository._();

  /// Creates a relation between the given [Message] and [Channel]
  /// by setting the [Message]'s foreign key `channelId` to refer to the [Channel].
  Future<void> channel(
    _i1.Session session,
    Message message,
    _i2.Channel channel, {
    _i1.Transaction? transaction,
  }) async {
    if (message.id == null) {
      throw ArgumentError.notNull('message.id');
    }
    if (channel.id == null) {
      throw ArgumentError.notNull('channel.id');
    }

    var $message = message.copyWith(channelId: channel.id);
    await session.db.updateRow<Message>(
      $message,
      columns: [Message.t.channelId],
      transaction: transaction,
    );
  }
}
