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
import 'channel_member_status.dart' as _i2;

abstract class ChannelMember implements _i1.SerializableModel {
  ChannelMember._({
    this.id,
    required this.channelId,
    required this.userInfoId,
    required this.joinedAt,
    this.role,
    required this.status,
    this.invitedBy,
  });

  factory ChannelMember({
    int? id,
    required int channelId,
    required _i1.UuidValue userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i2.ChannelMemberStatus status,
    _i1.UuidValue? invitedBy,
  }) = _ChannelMemberImpl;

  factory ChannelMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChannelMember(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      role: jsonSerialization['role'] as String?,
      status: _i2.ChannelMemberStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      invitedBy: jsonSerialization['invitedBy'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['invitedBy']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  _i1.UuidValue userInfoId;

  DateTime joinedAt;

  String? role;

  _i2.ChannelMemberStatus status;

  _i1.UuidValue? invitedBy;

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChannelMember copyWith({
    int? id,
    int? channelId,
    _i1.UuidValue? userInfoId,
    DateTime? joinedAt,
    String? role,
    _i2.ChannelMemberStatus? status,
    _i1.UuidValue? invitedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChannelMember',
      if (id != null) 'id': id,
      'channelId': channelId,
      'userInfoId': userInfoId.toJson(),
      'joinedAt': joinedAt.toJson(),
      if (role != null) 'role': role,
      'status': status.toJson(),
      if (invitedBy != null) 'invitedBy': invitedBy?.toJson(),
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
    required _i1.UuidValue userInfoId,
    required DateTime joinedAt,
    String? role,
    required _i2.ChannelMemberStatus status,
    _i1.UuidValue? invitedBy,
  }) : super._(
         id: id,
         channelId: channelId,
         userInfoId: userInfoId,
         joinedAt: joinedAt,
         role: role,
         status: status,
         invitedBy: invitedBy,
       );

  /// Returns a shallow copy of this [ChannelMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChannelMember copyWith({
    Object? id = _Undefined,
    int? channelId,
    _i1.UuidValue? userInfoId,
    DateTime? joinedAt,
    Object? role = _Undefined,
    _i2.ChannelMemberStatus? status,
    Object? invitedBy = _Undefined,
  }) {
    return ChannelMember(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      userInfoId: userInfoId ?? this.userInfoId,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role is String? ? role : this.role,
      status: status ?? this.status,
      invitedBy: invitedBy is _i1.UuidValue? ? invitedBy : this.invitedBy,
    );
  }
}
