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

abstract class PrivateChat implements _i1.SerializableModel {
  PrivateChat._({
    this.id,
    required this.channelId,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory PrivateChat({
    int? id,
    required int channelId,
    required _i1.UuidValue participant1Id,
    required _i1.UuidValue participant2Id,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) = _PrivateChatImpl;

  factory PrivateChat.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrivateChat(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      participant1Id: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['participant1Id'],
      ),
      participant2Id: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['participant2Id'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastMessage: jsonSerialization['lastMessage'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  _i1.UuidValue participant1Id;

  _i1.UuidValue participant2Id;

  DateTime createdAt;

  DateTime? lastMessageAt;

  String? lastMessage;

  /// Returns a shallow copy of this [PrivateChat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrivateChat copyWith({
    int? id,
    int? channelId,
    _i1.UuidValue? participant1Id,
    _i1.UuidValue? participant2Id,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrivateChat',
      if (id != null) 'id': id,
      'channelId': channelId,
      'participant1Id': participant1Id.toJson(),
      'participant2Id': participant2Id.toJson(),
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrivateChatImpl extends PrivateChat {
  _PrivateChatImpl({
    int? id,
    required int channelId,
    required _i1.UuidValue participant1Id,
    required _i1.UuidValue participant2Id,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) : super._(
         id: id,
         channelId: channelId,
         participant1Id: participant1Id,
         participant2Id: participant2Id,
         createdAt: createdAt,
         lastMessageAt: lastMessageAt,
         lastMessage: lastMessage,
       );

  /// Returns a shallow copy of this [PrivateChat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrivateChat copyWith({
    Object? id = _Undefined,
    int? channelId,
    _i1.UuidValue? participant1Id,
    _i1.UuidValue? participant2Id,
    DateTime? createdAt,
    Object? lastMessageAt = _Undefined,
    Object? lastMessage = _Undefined,
  }) {
    return PrivateChat(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      lastMessage: lastMessage is String? ? lastMessage : this.lastMessage,
    );
  }
}
