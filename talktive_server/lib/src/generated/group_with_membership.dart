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
import 'group.dart' as _i2;
import 'channel_member_status.dart' as _i3;
import 'package:talktive_server/src/generated/protocol.dart' as _i4;

abstract class GroupWithMembership
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GroupWithMembership._({
    required this.group,
    this.membershipStatus,
    this.membershipRole,
  });

  factory GroupWithMembership({
    required _i2.Group group,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
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
    );
  }

  _i2.Group group;

  _i3.ChannelMemberStatus? membershipStatus;

  String? membershipRole;

  /// Returns a shallow copy of this [GroupWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GroupWithMembership copyWith({
    _i2.Group? group,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupWithMembership',
      'group': group.toJson(),
      if (membershipStatus != null)
        'membershipStatus': membershipStatus?.toJson(),
      if (membershipRole != null) 'membershipRole': membershipRole,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GroupWithMembership',
      'group': group.toJsonForProtocol(),
      if (membershipStatus != null)
        'membershipStatus': membershipStatus?.toJson(),
      if (membershipRole != null) 'membershipRole': membershipRole,
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
  }) : super._(
         group: group,
         membershipStatus: membershipStatus,
         membershipRole: membershipRole,
       );

  /// Returns a shallow copy of this [GroupWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GroupWithMembership copyWith({
    _i2.Group? group,
    Object? membershipStatus = _Undefined,
    Object? membershipRole = _Undefined,
  }) {
    return GroupWithMembership(
      group: group ?? this.group.copyWith(),
      membershipStatus: membershipStatus is _i3.ChannelMemberStatus?
          ? membershipStatus
          : this.membershipStatus,
      membershipRole: membershipRole is String?
          ? membershipRole
          : this.membershipRole,
    );
  }
}
