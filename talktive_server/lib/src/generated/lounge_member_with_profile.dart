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
import 'resident.dart' as _i2;
import 'channel_member_status.dart' as _i3;
import 'package:talktive_server/src/generated/protocol.dart' as _i4;

abstract class LoungeMemberWithProfile
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LoungeMemberWithProfile._({
    required this.resident,
    required this.status,
    this.role,
    this.joinedAt,
  });

  factory LoungeMemberWithProfile({
    required _i2.Resident resident,
    required _i3.ChannelMemberStatus status,
    String? role,
    DateTime? joinedAt,
  }) = _LoungeMemberWithProfileImpl;

  factory LoungeMemberWithProfile.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LoungeMemberWithProfile(
      resident: _i4.Protocol().deserialize<_i2.Resident>(
        jsonSerialization['resident'],
      ),
      status: _i3.ChannelMemberStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      role: jsonSerialization['role'] as String?,
      joinedAt: jsonSerialization['joinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['joinedAt']),
    );
  }

  _i2.Resident resident;

  _i3.ChannelMemberStatus status;

  String? role;

  DateTime? joinedAt;

  /// Returns a shallow copy of this [LoungeMemberWithProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LoungeMemberWithProfile copyWith({
    _i2.Resident? resident,
    _i3.ChannelMemberStatus? status,
    String? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LoungeMemberWithProfile',
      'resident': resident.toJson(),
      'status': status.toJson(),
      if (role != null) 'role': role,
      if (joinedAt != null) 'joinedAt': joinedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LoungeMemberWithProfile',
      'resident': resident.toJsonForProtocol(),
      'status': status.toJson(),
      if (role != null) 'role': role,
      if (joinedAt != null) 'joinedAt': joinedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LoungeMemberWithProfileImpl extends LoungeMemberWithProfile {
  _LoungeMemberWithProfileImpl({
    required _i2.Resident resident,
    required _i3.ChannelMemberStatus status,
    String? role,
    DateTime? joinedAt,
  }) : super._(
         resident: resident,
         status: status,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [LoungeMemberWithProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LoungeMemberWithProfile copyWith({
    _i2.Resident? resident,
    _i3.ChannelMemberStatus? status,
    Object? role = _Undefined,
    Object? joinedAt = _Undefined,
  }) {
    return LoungeMemberWithProfile(
      resident: resident ?? this.resident.copyWith(),
      status: status ?? this.status,
      role: role is String? ? role : this.role,
      joinedAt: joinedAt is DateTime? ? joinedAt : this.joinedAt,
    );
  }
}
