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
import 'achievement.dart' as _i2;
import 'package:talktive_client/src/protocol/protocol.dart' as _i3;

abstract class UserAchievementView implements _i1.SerializableModel {
  UserAchievementView._({
    required this.achievement,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
    required this.isNew,
  });

  factory UserAchievementView({
    required _i2.Achievement achievement,
    required int progress,
    required bool unlocked,
    DateTime? unlockedAt,
    required bool isNew,
  }) = _UserAchievementViewImpl;

  factory UserAchievementView.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserAchievementView(
      achievement: _i3.Protocol().deserialize<_i2.Achievement>(
        jsonSerialization['achievement'],
      ),
      progress: jsonSerialization['progress'] as int,
      unlocked: _i1.BoolJsonExtension.fromJson(jsonSerialization['unlocked']),
      unlockedAt: jsonSerialization['unlockedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['unlockedAt']),
      isNew: _i1.BoolJsonExtension.fromJson(jsonSerialization['isNew']),
    );
  }

  _i2.Achievement achievement;

  int progress;

  bool unlocked;

  DateTime? unlockedAt;

  bool isNew;

  /// Returns a shallow copy of this [UserAchievementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserAchievementView copyWith({
    _i2.Achievement? achievement,
    int? progress,
    bool? unlocked,
    DateTime? unlockedAt,
    bool? isNew,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserAchievementView',
      'achievement': achievement.toJson(),
      'progress': progress,
      'unlocked': unlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt?.toJson(),
      'isNew': isNew,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserAchievementViewImpl extends UserAchievementView {
  _UserAchievementViewImpl({
    required _i2.Achievement achievement,
    required int progress,
    required bool unlocked,
    DateTime? unlockedAt,
    required bool isNew,
  }) : super._(
         achievement: achievement,
         progress: progress,
         unlocked: unlocked,
         unlockedAt: unlockedAt,
         isNew: isNew,
       );

  /// Returns a shallow copy of this [UserAchievementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserAchievementView copyWith({
    _i2.Achievement? achievement,
    int? progress,
    bool? unlocked,
    Object? unlockedAt = _Undefined,
    bool? isNew,
  }) {
    return UserAchievementView(
      achievement: achievement ?? this.achievement.copyWith(),
      progress: progress ?? this.progress,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt is DateTime? ? unlockedAt : this.unlockedAt,
      isNew: isNew ?? this.isNew,
    );
  }
}
