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
import 'resident_role.dart' as _i2;
import 'package:talktive_server/src/generated/protocol.dart' as _i3;

/// Simplified user data for lists and search
abstract class UserSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  UserSummary._({
    required this.userId,
    this.userName,
    this.userAvatar,
    this.userMood,
    required this.floor,
    this.trustScore,
    this.sharedInterests,
    this.sharedLanguages,
    this.matchScore,
    this.ageRange,
    bool? isOnline,
    this.role,
  }) : isOnline = isOnline ?? false;

  factory UserSummary({
    required _i1.UuidValue userId,
    String? userName,
    String? userAvatar,
    String? userMood,
    required int floor,
    int? trustScore,
    List<String>? sharedInterests,
    List<String>? sharedLanguages,
    int? matchScore,
    String? ageRange,
    bool? isOnline,
    _i2.ResidentRole? role,
  }) = _UserSummaryImpl;

  factory UserSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSummary(
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      userName: jsonSerialization['userName'] as String?,
      userAvatar: jsonSerialization['userAvatar'] as String?,
      userMood: jsonSerialization['userMood'] as String?,
      floor: jsonSerialization['floor'] as int,
      trustScore: jsonSerialization['trustScore'] as int?,
      sharedInterests: jsonSerialization['sharedInterests'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['sharedInterests'],
            ),
      sharedLanguages: jsonSerialization['sharedLanguages'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['sharedLanguages'],
            ),
      matchScore: jsonSerialization['matchScore'] as int?,
      ageRange: jsonSerialization['ageRange'] as String?,
      isOnline: jsonSerialization['isOnline'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isOnline']),
      role: jsonSerialization['role'] == null
          ? null
          : _i2.ResidentRole.fromJson((jsonSerialization['role'] as String)),
    );
  }

  _i1.UuidValue userId;

  String? userName;

  String? userAvatar;

  String? userMood;

  int floor;

  int? trustScore;

  List<String>? sharedInterests;

  List<String>? sharedLanguages;

  int? matchScore;

  String? ageRange;

  bool isOnline;

  _i2.ResidentRole? role;

  /// Returns a shallow copy of this [UserSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSummary copyWith({
    _i1.UuidValue? userId,
    String? userName,
    String? userAvatar,
    String? userMood,
    int? floor,
    int? trustScore,
    List<String>? sharedInterests,
    List<String>? sharedLanguages,
    int? matchScore,
    String? ageRange,
    bool? isOnline,
    _i2.ResidentRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserSummary',
      'userId': userId.toJson(),
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'floor': floor,
      if (trustScore != null) 'trustScore': trustScore,
      if (sharedInterests != null) 'sharedInterests': sharedInterests?.toJson(),
      if (sharedLanguages != null) 'sharedLanguages': sharedLanguages?.toJson(),
      if (matchScore != null) 'matchScore': matchScore,
      if (ageRange != null) 'ageRange': ageRange,
      'isOnline': isOnline,
      if (role != null) 'role': role?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserSummary',
      'userId': userId.toJson(),
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'floor': floor,
      if (trustScore != null) 'trustScore': trustScore,
      if (sharedInterests != null) 'sharedInterests': sharedInterests?.toJson(),
      if (sharedLanguages != null) 'sharedLanguages': sharedLanguages?.toJson(),
      if (matchScore != null) 'matchScore': matchScore,
      if (ageRange != null) 'ageRange': ageRange,
      'isOnline': isOnline,
      if (role != null) 'role': role?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserSummaryImpl extends UserSummary {
  _UserSummaryImpl({
    required _i1.UuidValue userId,
    String? userName,
    String? userAvatar,
    String? userMood,
    required int floor,
    int? trustScore,
    List<String>? sharedInterests,
    List<String>? sharedLanguages,
    int? matchScore,
    String? ageRange,
    bool? isOnline,
    _i2.ResidentRole? role,
  }) : super._(
         userId: userId,
         userName: userName,
         userAvatar: userAvatar,
         userMood: userMood,
         floor: floor,
         trustScore: trustScore,
         sharedInterests: sharedInterests,
         sharedLanguages: sharedLanguages,
         matchScore: matchScore,
         ageRange: ageRange,
         isOnline: isOnline,
         role: role,
       );

  /// Returns a shallow copy of this [UserSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserSummary copyWith({
    _i1.UuidValue? userId,
    Object? userName = _Undefined,
    Object? userAvatar = _Undefined,
    Object? userMood = _Undefined,
    int? floor,
    Object? trustScore = _Undefined,
    Object? sharedInterests = _Undefined,
    Object? sharedLanguages = _Undefined,
    Object? matchScore = _Undefined,
    Object? ageRange = _Undefined,
    bool? isOnline,
    Object? role = _Undefined,
  }) {
    return UserSummary(
      userId: userId ?? this.userId,
      userName: userName is String? ? userName : this.userName,
      userAvatar: userAvatar is String? ? userAvatar : this.userAvatar,
      userMood: userMood is String? ? userMood : this.userMood,
      floor: floor ?? this.floor,
      trustScore: trustScore is int? ? trustScore : this.trustScore,
      sharedInterests: sharedInterests is List<String>?
          ? sharedInterests
          : this.sharedInterests?.map((e0) => e0).toList(),
      sharedLanguages: sharedLanguages is List<String>?
          ? sharedLanguages
          : this.sharedLanguages?.map((e0) => e0).toList(),
      matchScore: matchScore is int? ? matchScore : this.matchScore,
      ageRange: ageRange is String? ? ageRange : this.ageRange,
      isOnline: isOnline ?? this.isOnline,
      role: role is _i2.ResidentRole? ? role : this.role,
    );
  }
}
