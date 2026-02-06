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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'channel.dart' as _i2;
import 'package:talktive_client/src/protocol/protocol.dart' as _i3;

abstract class Message implements _i1.SerializableModel {
  Message._({
    this.id,
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  _i2.Channel? channel;

  int senderId;

  String? content;

  String? imageUrl;

  DateTime createdAt;

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Message copyWith({
    int? id,
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
      if (channel != null) 'channel': channel?.toJson(),
      'senderId': senderId,
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toJson(),
    };
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
