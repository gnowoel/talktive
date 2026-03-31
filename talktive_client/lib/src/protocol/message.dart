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
import 'package:talktive_client/src/protocol/protocol.dart' as _i2;

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
    bool? isPinned,
    this.pinnedAt,
    required this.createdAt,
    this.duration,
    this.amplitudes,
    this.fileSize,
    bool? isRecalled,
    this.recalledAt,
    required this.senderName,
    this.senderAvatar,
    this.senderMood,
    required this.senderFloor,
    required this.senderTrustScore,
  }) : isPinned = isPinned ?? false,
       isRecalled = isRecalled ?? false;

  factory Message({
    int? id,
    required int channelId,
    required _i1.UuidValue senderId,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    required bool isSystem,
    bool? isPinned,
    DateTime? pinnedAt,
    required DateTime createdAt,
    int? duration,
    List<int>? amplitudes,
    int? fileSize,
    bool? isRecalled,
    DateTime? recalledAt,
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
      isPinned: jsonSerialization['isPinned'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      pinnedAt: jsonSerialization['pinnedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['pinnedAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      duration: jsonSerialization['duration'] as int?,
      amplitudes: jsonSerialization['amplitudes'] == null
          ? null
          : _i2.Protocol().deserialize<List<int>>(
              jsonSerialization['amplitudes'],
            ),
      fileSize: jsonSerialization['fileSize'] as int?,
      isRecalled: jsonSerialization['isRecalled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isRecalled']),
      recalledAt: jsonSerialization['recalledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['recalledAt']),
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

  bool isPinned;

  DateTime? pinnedAt;

  DateTime createdAt;

  int? duration;

  List<int>? amplitudes;

  int? fileSize;

  bool isRecalled;

  DateTime? recalledAt;

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
    bool? isPinned,
    DateTime? pinnedAt,
    DateTime? createdAt,
    int? duration,
    List<int>? amplitudes,
    int? fileSize,
    bool? isRecalled,
    DateTime? recalledAt,
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
      'isPinned': isPinned,
      if (pinnedAt != null) 'pinnedAt': pinnedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      if (duration != null) 'duration': duration,
      if (amplitudes != null) 'amplitudes': amplitudes?.toJson(),
      if (fileSize != null) 'fileSize': fileSize,
      'isRecalled': isRecalled,
      if (recalledAt != null) 'recalledAt': recalledAt?.toJson(),
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
    bool? isPinned,
    DateTime? pinnedAt,
    required DateTime createdAt,
    int? duration,
    List<int>? amplitudes,
    int? fileSize,
    bool? isRecalled,
    DateTime? recalledAt,
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
         isPinned: isPinned,
         pinnedAt: pinnedAt,
         createdAt: createdAt,
         duration: duration,
         amplitudes: amplitudes,
         fileSize: fileSize,
         isRecalled: isRecalled,
         recalledAt: recalledAt,
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
    bool? isPinned,
    Object? pinnedAt = _Undefined,
    DateTime? createdAt,
    Object? duration = _Undefined,
    Object? amplitudes = _Undefined,
    Object? fileSize = _Undefined,
    bool? isRecalled,
    Object? recalledAt = _Undefined,
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
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt is DateTime? ? pinnedAt : this.pinnedAt,
      createdAt: createdAt ?? this.createdAt,
      duration: duration is int? ? duration : this.duration,
      amplitudes: amplitudes is List<int>?
          ? amplitudes
          : this.amplitudes?.map((e0) => e0).toList(),
      fileSize: fileSize is int? ? fileSize : this.fileSize,
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt is DateTime? ? recalledAt : this.recalledAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar is String? ? senderAvatar : this.senderAvatar,
      senderMood: senderMood is String? ? senderMood : this.senderMood,
      senderFloor: senderFloor ?? this.senderFloor,
      senderTrustScore: senderTrustScore ?? this.senderTrustScore,
    );
  }
}
