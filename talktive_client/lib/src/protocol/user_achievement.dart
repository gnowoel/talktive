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

abstract class UserAchievement implements _i1.SerializableModel {
  UserAchievement._({
    this.id,
    required this.userId,
    required this.achievementId,
    int? progress,
    this.unlockedAt,
    bool? notified,
  }) : progress = progress ?? 0,
       notified = notified ?? false;

  factory UserAchievement({
    int? id,
    required _i1.UuidValue userId,
    required int achievementId,
    int? progress,
    DateTime? unlockedAt,
    bool? notified,
  }) = _UserAchievementImpl;

  factory UserAchievement.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserAchievement(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      achievementId: jsonSerialization['achievementId'] as int,
      progress: jsonSerialization['progress'] as int?,
      unlockedAt: jsonSerialization['unlockedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['unlockedAt']),
      notified: jsonSerialization['notified'] as bool?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  int achievementId;

  int progress;

  DateTime? unlockedAt;

  bool notified;

  /// Returns a shallow copy of this [UserAchievement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserAchievement copyWith({
    int? id,
    _i1.UuidValue? userId,
    int? achievementId,
    int? progress,
    DateTime? unlockedAt,
    bool? notified,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserAchievement',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'achievementId': achievementId,
      'progress': progress,
      if (unlockedAt != null) 'unlockedAt': unlockedAt?.toJson(),
      'notified': notified,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserAchievementImpl extends UserAchievement {
  _UserAchievementImpl({
    int? id,
    required _i1.UuidValue userId,
    required int achievementId,
    int? progress,
    DateTime? unlockedAt,
    bool? notified,
  }) : super._(
         id: id,
         userId: userId,
         achievementId: achievementId,
         progress: progress,
         unlockedAt: unlockedAt,
         notified: notified,
       );

  /// Returns a shallow copy of this [UserAchievement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserAchievement copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    int? achievementId,
    int? progress,
    Object? unlockedAt = _Undefined,
    bool? notified,
  }) {
    return UserAchievement(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt is DateTime? ? unlockedAt : this.unlockedAt,
      notified: notified ?? this.notified,
    );
  }
}
