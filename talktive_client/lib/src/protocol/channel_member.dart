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
import 'channel_member_status.dart' as _i3;
import 'package:talktive_client/src/protocol/protocol.dart' as _i4;

abstract class ChannelMember implements _i1.SerializableModel {
  ChannelMember._({
    this.id,
    required this.channelId,
    required this.channelId,
    this.channel,
    required this.userInfoId,
    required this.joinedAt,
    this.role,
    required this.status,
  });

  factory ChannelMember({
    int? id,
    required int channelId,
    required int channelId,
    _i2.Channel? channel,
    required int userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i3.ChannelMemberStatus status,
  }) = _ChannelMemberImpl;

  factory ChannelMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChannelMember(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      channel: jsonSerialization['channel'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Channel>(
              jsonSerialization['channel'],
            ),
      userInfoId: jsonSerialization['userInfoId'] as int,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      role: jsonSerialization['role'] as String?,
      status: _i3.ChannelMemberStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  int channelId;

  _i2.Channel? channel;

  int userInfoId;

  DateTime joinedAt;

  String? role;

  _i3.ChannelMemberStatus status;

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChannelMember copyWith({
    int? id,
    int? channelId,
    int? channelId,
    _i2.Channel? channel,
    int? userInfoId,
    DateTime? joinedAt,
    String? role,
    _i3.ChannelMemberStatus? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChannelMember',
      if (id != null) 'id': id,
      'channelId': channelId,
      'channelId': channelId,
      if (channel != null) 'channel': channel?.toJson(),
      'userInfoId': userInfoId,
      'joinedAt': joinedAt.toJson(),
      if (role != null) 'role': role,
      'status': status.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelMemberImpl extends ChannelMember {
  _ChannelMemberImpl({
    int? id,
    required int channelId,
    required int channelId,
    _i2.Channel? channel,
    required int userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i3.ChannelMemberStatus status,
  }) : super._(
         id: id,
         channelId: channelId,
         channel: channel,
         userInfoId: userInfoId,
         joinedAt: joinedAt,
         role: role,
         status: status,
       );

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChannelMember copyWith({
    Object? id = _Undefined,
    int? channelId,
    int? channelId,
    Object? channel = _Undefined,
    int? userInfoId,
    DateTime? joinedAt,
    Object? role = _Undefined,
    _i3.ChannelMemberStatus? status,
  }) {
    return ChannelMember(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      channel: channel is _i2.Channel? ? channel : this.channel?.copyWith(),
      userInfoId: userInfoId ?? this.userInfoId,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role is String? ? role : this.role,
      status: status ?? this.status,
    );
  }
}
