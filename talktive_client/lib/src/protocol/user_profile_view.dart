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
import 'moment.dart' as _i2;
import 'package:talktive_client/src/protocol/protocol.dart' as _i3;

/// User profile view data
abstract class UserProfileView implements _i1.SerializableModel {
  UserProfileView._({
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.reputation,
    required this.trustScore,
    required this.likes,
    required this.totalMessages,
    required this.totalMoments,
    required this.achievementsUnlocked,
    required this.currentStreak,
    required this.longestStreak,
    required this.isBlocked,
    required this.hasBlockedMe,
    required this.mutualGroups,
    this.recentMoments,
  });

  factory UserProfileView({
    required String userId,
    String? userName,
    String? userAvatar,
    required int reputation,
    required int trustScore,
    required int likes,
    required int totalMessages,
    required int totalMoments,
    required int achievementsUnlocked,
    required int currentStreak,
    required int longestStreak,
    required bool isBlocked,
    required bool hasBlockedMe,
    required int mutualGroups,
    List<_i2.Moment>? recentMoments,
  }) = _UserProfileViewImpl;

  factory UserProfileView.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfileView(
      userId: jsonSerialization['userId'] as String,
      userName: jsonSerialization['userName'] as String?,
      userAvatar: jsonSerialization['userAvatar'] as String?,
      reputation: jsonSerialization['reputation'] as int,
      trustScore: jsonSerialization['trustScore'] as int,
      likes: jsonSerialization['likes'] as int,
      totalMessages: jsonSerialization['totalMessages'] as int,
      totalMoments: jsonSerialization['totalMoments'] as int,
      achievementsUnlocked: jsonSerialization['achievementsUnlocked'] as int,
      currentStreak: jsonSerialization['currentStreak'] as int,
      longestStreak: jsonSerialization['longestStreak'] as int,
      isBlocked: jsonSerialization['isBlocked'] as bool,
      hasBlockedMe: jsonSerialization['hasBlockedMe'] as bool,
      mutualGroups: jsonSerialization['mutualGroups'] as int,
      recentMoments: jsonSerialization['recentMoments'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.Moment>>(
              jsonSerialization['recentMoments'],
            ),
    );
  }

  String userId;

  String? userName;

  String? userAvatar;

  int reputation;

  int trustScore;

  int likes;

  int totalMessages;

  int totalMoments;

  int achievementsUnlocked;

  int currentStreak;

  int longestStreak;

  bool isBlocked;

  bool hasBlockedMe;

  int mutualGroups;

  List<_i2.Moment>? recentMoments;

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserProfileView copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    int? reputation,
    int? trustScore,
    int? likes,
    int? totalMessages,
    int? totalMoments,
    int? achievementsUnlocked,
    int? currentStreak,
    int? longestStreak,
    bool? isBlocked,
    bool? hasBlockedMe,
    int? mutualGroups,
    List<_i2.Moment>? recentMoments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserProfileView',
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      'reputation': reputation,
      'trustScore': trustScore,
      'likes': likes,
      'totalMessages': totalMessages,
      'totalMoments': totalMoments,
      'achievementsUnlocked': achievementsUnlocked,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isBlocked': isBlocked,
      'hasBlockedMe': hasBlockedMe,
      'mutualGroups': mutualGroups,
      if (recentMoments != null)
        'recentMoments': recentMoments?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserProfileViewImpl extends UserProfileView {
  _UserProfileViewImpl({
    required String userId,
    String? userName,
    String? userAvatar,
    required int reputation,
    required int trustScore,
    required int likes,
    required int totalMessages,
    required int totalMoments,
    required int achievementsUnlocked,
    required int currentStreak,
    required int longestStreak,
    required bool isBlocked,
    required bool hasBlockedMe,
    required int mutualGroups,
    List<_i2.Moment>? recentMoments,
  }) : super._(
         userId: userId,
         userName: userName,
         userAvatar: userAvatar,
         reputation: reputation,
         trustScore: trustScore,
         likes: likes,
         totalMessages: totalMessages,
         totalMoments: totalMoments,
         achievementsUnlocked: achievementsUnlocked,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         isBlocked: isBlocked,
         hasBlockedMe: hasBlockedMe,
         mutualGroups: mutualGroups,
         recentMoments: recentMoments,
       );

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserProfileView copyWith({
    String? userId,
    Object? userName = _Undefined,
    Object? userAvatar = _Undefined,
    int? reputation,
    int? trustScore,
    int? likes,
    int? totalMessages,
    int? totalMoments,
    int? achievementsUnlocked,
    int? currentStreak,
    int? longestStreak,
    bool? isBlocked,
    bool? hasBlockedMe,
    int? mutualGroups,
    Object? recentMoments = _Undefined,
  }) {
    return UserProfileView(
      userId: userId ?? this.userId,
      userName: userName is String? ? userName : this.userName,
      userAvatar: userAvatar is String? ? userAvatar : this.userAvatar,
      reputation: reputation ?? this.reputation,
      trustScore: trustScore ?? this.trustScore,
      likes: likes ?? this.likes,
      totalMessages: totalMessages ?? this.totalMessages,
      totalMoments: totalMoments ?? this.totalMoments,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isBlocked: isBlocked ?? this.isBlocked,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      mutualGroups: mutualGroups ?? this.mutualGroups,
      recentMoments: recentMoments is List<_i2.Moment>?
          ? recentMoments
          : this.recentMoments?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
