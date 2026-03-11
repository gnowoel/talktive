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
import 'group.dart' as _i2;
import 'channel_member_status.dart' as _i3;
import 'package:talktive_client/src/protocol/protocol.dart' as _i4;

abstract class GroupWithMembership implements _i1.SerializableModel {
  GroupWithMembership._({
    required this.group,
    this.membershipStatus,
    this.membershipRole,
    this.isMuted,
  });

  factory GroupWithMembership({
    required _i2.Group group,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
  }) = _GroupWithMembershipImpl;

  factory GroupWithMembership.fromJson(Map<String, dynamic> jsonSerialization) {
    return GroupWithMembership(
      group: _i4.Protocol().deserialize<_i2.Group>(jsonSerialization['group']),
      membershipStatus: jsonSerialization['membershipStatus'] == null
          ? null
          : _i3.ChannelMemberStatus.fromJson(
              (jsonSerialization['membershipStatus'] as String),
            ),
      membershipRole: jsonSerialization['membershipRole'] as String?,
      isMuted: jsonSerialization['isMuted'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isMuted']),
    );
  }

  _i2.Group group;

  _i3.ChannelMemberStatus? membershipStatus;

  String? membershipRole;

  bool? isMuted;

  /// Returns a shallow copy of this [GroupWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GroupWithMembership copyWith({
    _i2.Group? group,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupWithMembership',
      'group': group.toJson(),
      if (membershipStatus != null)
        'membershipStatus': membershipStatus?.toJson(),
      if (membershipRole != null) 'membershipRole': membershipRole,
      if (isMuted != null) 'isMuted': isMuted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupWithMembershipImpl extends GroupWithMembership {
  _GroupWithMembershipImpl({
    required _i2.Group group,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
  }) : super._(
         group: group,
         membershipStatus: membershipStatus,
         membershipRole: membershipRole,
         isMuted: isMuted,
       );

  /// Returns a shallow copy of this [GroupWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GroupWithMembership copyWith({
    _i2.Group? group,
    Object? membershipStatus = _Undefined,
    Object? membershipRole = _Undefined,
    Object? isMuted = _Undefined,
  }) {
    return GroupWithMembership(
      group: group ?? this.group.copyWith(),
      membershipStatus: membershipStatus is _i3.ChannelMemberStatus?
          ? membershipStatus
          : this.membershipStatus,
      membershipRole: membershipRole is String?
          ? membershipRole
          : this.membershipRole,
      isMuted: isMuted is bool? ? isMuted : this.isMuted,
    );
  }
}
