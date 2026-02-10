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

abstract class RateLimit implements _i1.SerializableModel {
  RateLimit._({
    this.id,
    required this.userInfoId,
    required this.channelId,
    required this.messageCount,
    required this.windowStart,
    required this.lastMessageAt,
  });

  factory RateLimit({
    int? id,
    required _i1.UuidValue userInfoId,
    required int channelId,
    required int messageCount,
    required DateTime windowStart,
    required DateTime lastMessageAt,
  }) = _RateLimitImpl;

  factory RateLimit.fromJson(Map<String, dynamic> jsonSerialization) {
    return RateLimit(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      channelId: jsonSerialization['channelId'] as int,
      messageCount: jsonSerialization['messageCount'] as int,
      windowStart: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['windowStart'],
      ),
      lastMessageAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastMessageAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userInfoId;

  int channelId;

  int messageCount;

  DateTime windowStart;

  DateTime lastMessageAt;

  /// Returns a shallow copy of this [RateLimit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RateLimit copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? channelId,
    int? messageCount,
    DateTime? windowStart,
    DateTime? lastMessageAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RateLimit',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'channelId': channelId,
      'messageCount': messageCount,
      'windowStart': windowStart.toJson(),
      'lastMessageAt': lastMessageAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RateLimitImpl extends RateLimit {
  _RateLimitImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    required int channelId,
    required int messageCount,
    required DateTime windowStart,
    required DateTime lastMessageAt,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         channelId: channelId,
         messageCount: messageCount,
         windowStart: windowStart,
         lastMessageAt: lastMessageAt,
       );

  /// Returns a shallow copy of this [RateLimit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RateLimit copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? channelId,
    int? messageCount,
    DateTime? windowStart,
    DateTime? lastMessageAt,
  }) {
    return RateLimit(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      channelId: channelId ?? this.channelId,
      messageCount: messageCount ?? this.messageCount,
      windowStart: windowStart ?? this.windowStart,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
