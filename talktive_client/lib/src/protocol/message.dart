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

abstract class Message implements _i1.SerializableModel {
  Message._({
    this.id,
    required this.channelId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.mediaUrl,
    this.mediaType,
    required this.isSystem,
    required this.createdAt,
    required this.senderName,
    this.senderAvatar,
    this.senderMood,
    required this.senderFloor,
    required this.senderTrustScore,
  });

  factory Message({
    int? id,
    required int channelId,
    required _i1.UuidValue senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    required bool isSystem,
    required DateTime createdAt,
    required String senderName,
    String? senderAvatar,
    String? senderMood,
    required int senderFloor,
    required int senderTrustScore,
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
      isSystem: _i1.BoolJsonExtension.fromJson(jsonSerialization['isSystem']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      senderName: jsonSerialization['senderName'] as String,
      senderAvatar: jsonSerialization['senderAvatar'] as String?,
      senderMood: jsonSerialization['senderMood'] as String?,
      senderFloor: jsonSerialization['senderFloor'] as int,
      senderTrustScore: jsonSerialization['senderTrustScore'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  _i1.UuidValue senderId;

  String? content;

  String? imageUrl;

  String? mediaUrl;

  String? mediaType;

  bool isSystem;

  DateTime createdAt;

  String senderName;

  String? senderAvatar;

  String? senderMood;

  int senderFloor;

  int senderTrustScore;

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
    bool? isSystem,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
    String? senderMood,
    int? senderFloor,
    int? senderTrustScore,
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
      'isSystem': isSystem,
      'createdAt': createdAt.toJson(),
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (senderMood != null) 'senderMood': senderMood,
      'senderFloor': senderFloor,
      'senderTrustScore': senderTrustScore,
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
    required _i1.UuidValue senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    required bool isSystem,
    required DateTime createdAt,
    required String senderName,
    String? senderAvatar,
    String? senderMood,
    required int senderFloor,
    required int senderTrustScore,
  }) : super._(
         id: id,
         channelId: channelId,
         senderId: senderId,
         content: content,
         imageUrl: imageUrl,
         mediaUrl: mediaUrl,
         mediaType: mediaType,
         isSystem: isSystem,
         createdAt: createdAt,
         senderName: senderName,
         senderAvatar: senderAvatar,
         senderMood: senderMood,
         senderFloor: senderFloor,
         senderTrustScore: senderTrustScore,
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
    bool? isSystem,
    DateTime? createdAt,
    String? senderName,
    Object? senderAvatar = _Undefined,
    Object? senderMood = _Undefined,
    int? senderFloor,
    int? senderTrustScore,
  }) {
    return Message(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      content: content is String? ? content : this.content,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      mediaUrl: mediaUrl is String? ? mediaUrl : this.mediaUrl,
      mediaType: mediaType is String? ? mediaType : this.mediaType,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar is String? ? senderAvatar : this.senderAvatar,
      senderMood: senderMood is String? ? senderMood : this.senderMood,
      senderFloor: senderFloor ?? this.senderFloor,
      senderTrustScore: senderTrustScore ?? this.senderTrustScore,
    );
  }
}
