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

abstract class MomentLike implements _i1.SerializableModel {
  MomentLike._({
    this.id,
    required this.momentId,
    required this.userId,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
    this.userMood,
    required this.userFloor,
    required this.userTrustScore,
  });

  factory MomentLike({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required DateTime createdAt,
    required String userName,
    String? userAvatar,
    String? userMood,
    required int userFloor,
    required int userTrustScore,
  }) = _MomentLikeImpl;

  factory MomentLike.fromJson(Map<String, dynamic> jsonSerialization) {
    return MomentLike(
      id: jsonSerialization['id'] as int?,
      momentId: jsonSerialization['momentId'] as int,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      userName: jsonSerialization['userName'] as String,
      userAvatar: jsonSerialization['userAvatar'] as String?,
      userMood: jsonSerialization['userMood'] as String?,
      userFloor: jsonSerialization['userFloor'] as int,
      userTrustScore: jsonSerialization['userTrustScore'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int momentId;

  _i1.UuidValue userId;

  DateTime createdAt;

  String userName;

  String? userAvatar;

  String? userMood;

  int userFloor;

  int userTrustScore;

  /// Returns a shallow copy of this [MomentLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MomentLike copyWith({
    int? id,
    int? momentId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
    String? userName,
    String? userAvatar,
    String? userMood,
    int? userFloor,
    int? userTrustScore,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MomentLike',
      if (id != null) 'id': id,
      'momentId': momentId,
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
      'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'userFloor': userFloor,
      'userTrustScore': userTrustScore,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MomentLikeImpl extends MomentLike {
  _MomentLikeImpl({
    int? id,
    required int momentId,
    required _i1.UuidValue userId,
    required DateTime createdAt,
    required String userName,
    String? userAvatar,
    String? userMood,
    required int userFloor,
    required int userTrustScore,
  }) : super._(
         id: id,
         momentId: momentId,
         userId: userId,
         createdAt: createdAt,
         userName: userName,
         userAvatar: userAvatar,
         userMood: userMood,
         userFloor: userFloor,
         userTrustScore: userTrustScore,
       );

  /// Returns a shallow copy of this [MomentLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MomentLike copyWith({
    Object? id = _Undefined,
    int? momentId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
    String? userName,
    Object? userAvatar = _Undefined,
    Object? userMood = _Undefined,
    int? userFloor,
    int? userTrustScore,
  }) {
    return MomentLike(
      id: id is int? ? id : this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar is String? ? userAvatar : this.userAvatar,
      userMood: userMood is String? ? userMood : this.userMood,
      userFloor: userFloor ?? this.userFloor,
      userTrustScore: userTrustScore ?? this.userTrustScore,
    );
  }
}
