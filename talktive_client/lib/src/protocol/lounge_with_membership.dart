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
import 'lounge.dart' as _i2;
import 'channel_member_status.dart' as _i3;
import 'package:talktive_client/src/protocol/protocol.dart' as _i4;

abstract class LoungeWithMembership implements _i1.SerializableModel {
  LoungeWithMembership._({
    required this.lounge,
    this.membershipStatus,
    this.membershipRole,
    this.isMuted,
    int? unreadCount,
  }) : unreadCount = unreadCount ?? 0;

  factory LoungeWithMembership({
    required _i2.Lounge lounge,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
    int? unreadCount,
  }) = _LoungeWithMembershipImpl;

  factory LoungeWithMembership.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LoungeWithMembership(
      lounge: _i4.Protocol().deserialize<_i2.Lounge>(
        jsonSerialization['lounge'],
      ),
      membershipStatus: jsonSerialization['membershipStatus'] == null
          ? null
          : _i3.ChannelMemberStatus.fromJson(
              (jsonSerialization['membershipStatus'] as String),
            ),
      membershipRole: jsonSerialization['membershipRole'] as String?,
      isMuted: jsonSerialization['isMuted'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isMuted']),
      unreadCount: jsonSerialization['unreadCount'] as int?,
    );
  }

  _i2.Lounge lounge;

  _i3.ChannelMemberStatus? membershipStatus;

  String? membershipRole;

  bool? isMuted;

  int unreadCount;

  /// Returns a shallow copy of this [LoungeWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LoungeWithMembership copyWith({
    _i2.Lounge? lounge,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
    int? unreadCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LoungeWithMembership',
      'lounge': lounge.toJson(),
      if (membershipStatus != null)
        'membershipStatus': membershipStatus?.toJson(),
      if (membershipRole != null) 'membershipRole': membershipRole,
      if (isMuted != null) 'isMuted': isMuted,
      'unreadCount': unreadCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LoungeWithMembershipImpl extends LoungeWithMembership {
  _LoungeWithMembershipImpl({
    required _i2.Lounge lounge,
    _i3.ChannelMemberStatus? membershipStatus,
    String? membershipRole,
    bool? isMuted,
    int? unreadCount,
  }) : super._(
         lounge: lounge,
         membershipStatus: membershipStatus,
         membershipRole: membershipRole,
         isMuted: isMuted,
         unreadCount: unreadCount,
       );

  /// Returns a shallow copy of this [LoungeWithMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LoungeWithMembership copyWith({
    _i2.Lounge? lounge,
    Object? membershipStatus = _Undefined,
    Object? membershipRole = _Undefined,
    Object? isMuted = _Undefined,
    int? unreadCount,
  }) {
    return LoungeWithMembership(
      lounge: lounge ?? this.lounge.copyWith(),
      membershipStatus: membershipStatus is _i3.ChannelMemberStatus?
          ? membershipStatus
          : this.membershipStatus,
      membershipRole: membershipRole is String?
          ? membershipRole
          : this.membershipRole,
      isMuted: isMuted is bool? ? isMuted : this.isMuted,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
