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
import 'private_chat.dart' as _i2;
import 'resident.dart' as _i3;
import 'channel_member_status.dart' as _i4;
import 'package:talktive_client/src/protocol/protocol.dart' as _i5;

abstract class PrivateChatWithProfile implements _i1.SerializableModel {
  PrivateChatWithProfile._({
    required this.chat,
    required this.otherResident,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserMood,
    this.currentMemberStatus,
    this.otherMemberStatus,
  });

  factory PrivateChatWithProfile({
    required _i2.PrivateChat chat,
    required _i3.Resident otherResident,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserMood,
    _i4.ChannelMemberStatus? currentMemberStatus,
    _i4.ChannelMemberStatus? otherMemberStatus,
  }) = _PrivateChatWithProfileImpl;

  factory PrivateChatWithProfile.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PrivateChatWithProfile(
      chat: _i5.Protocol().deserialize<_i2.PrivateChat>(
        jsonSerialization['chat'],
      ),
      otherResident: _i5.Protocol().deserialize<_i3.Resident>(
        jsonSerialization['otherResident'],
      ),
      otherUserName: jsonSerialization['otherUserName'] as String?,
      otherUserAvatar: jsonSerialization['otherUserAvatar'] as String?,
      otherUserMood: jsonSerialization['otherUserMood'] as String?,
      currentMemberStatus: jsonSerialization['currentMemberStatus'] == null
          ? null
          : _i4.ChannelMemberStatus.fromJson(
              (jsonSerialization['currentMemberStatus'] as String),
            ),
      otherMemberStatus: jsonSerialization['otherMemberStatus'] == null
          ? null
          : _i4.ChannelMemberStatus.fromJson(
              (jsonSerialization['otherMemberStatus'] as String),
            ),
    );
  }

  _i2.PrivateChat chat;

  _i3.Resident otherResident;

  String? otherUserName;

  String? otherUserAvatar;

  String? otherUserMood;

  _i4.ChannelMemberStatus? currentMemberStatus;

  _i4.ChannelMemberStatus? otherMemberStatus;

  /// Returns a shallow copy of this [PrivateChatWithProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrivateChatWithProfile copyWith({
    _i2.PrivateChat? chat,
    _i3.Resident? otherResident,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserMood,
    _i4.ChannelMemberStatus? currentMemberStatus,
    _i4.ChannelMemberStatus? otherMemberStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrivateChatWithProfile',
      'chat': chat.toJson(),
      'otherResident': otherResident.toJson(),
      if (otherUserName != null) 'otherUserName': otherUserName,
      if (otherUserAvatar != null) 'otherUserAvatar': otherUserAvatar,
      if (otherUserMood != null) 'otherUserMood': otherUserMood,
      if (currentMemberStatus != null)
        'currentMemberStatus': currentMemberStatus?.toJson(),
      if (otherMemberStatus != null)
        'otherMemberStatus': otherMemberStatus?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrivateChatWithProfileImpl extends PrivateChatWithProfile {
  _PrivateChatWithProfileImpl({
    required _i2.PrivateChat chat,
    required _i3.Resident otherResident,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserMood,
    _i4.ChannelMemberStatus? currentMemberStatus,
    _i4.ChannelMemberStatus? otherMemberStatus,
  }) : super._(
         chat: chat,
         otherResident: otherResident,
         otherUserName: otherUserName,
         otherUserAvatar: otherUserAvatar,
         otherUserMood: otherUserMood,
         currentMemberStatus: currentMemberStatus,
         otherMemberStatus: otherMemberStatus,
       );

  /// Returns a shallow copy of this [PrivateChatWithProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrivateChatWithProfile copyWith({
    _i2.PrivateChat? chat,
    _i3.Resident? otherResident,
    Object? otherUserName = _Undefined,
    Object? otherUserAvatar = _Undefined,
    Object? otherUserMood = _Undefined,
    Object? currentMemberStatus = _Undefined,
    Object? otherMemberStatus = _Undefined,
  }) {
    return PrivateChatWithProfile(
      chat: chat ?? this.chat.copyWith(),
      otherResident: otherResident ?? this.otherResident.copyWith(),
      otherUserName: otherUserName is String?
          ? otherUserName
          : this.otherUserName,
      otherUserAvatar: otherUserAvatar is String?
          ? otherUserAvatar
          : this.otherUserAvatar,
      otherUserMood: otherUserMood is String?
          ? otherUserMood
          : this.otherUserMood,
      currentMemberStatus: currentMemberStatus is _i4.ChannelMemberStatus?
          ? currentMemberStatus
          : this.currentMemberStatus,
      otherMemberStatus: otherMemberStatus is _i4.ChannelMemberStatus?
          ? otherMemberStatus
          : this.otherMemberStatus,
    );
  }
}
