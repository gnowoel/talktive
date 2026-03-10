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
    this.userMood,
    required this.floor,
    required this.trustScore,
    required this.totalMessages,
    required this.totalMoments,
    required this.achievementsUnlocked,
    required this.currentStreak,
    required this.longestStreak,
    required this.isBlocked,
    required this.hasBlockedMe,
    required this.mutualGroups,
    this.recentMoments,
    this.level,
    this.xp,
    this.interests,
    this.languages,
    this.gender,
    this.country,
    this.bio,
  });

  factory UserProfileView({
    required String userId,
    String? userName,
    String? userAvatar,
    String? userMood,
    required int floor,
    required int trustScore,
    required int totalMessages,
    required int totalMoments,
    required int achievementsUnlocked,
    required int currentStreak,
    required int longestStreak,
    required bool isBlocked,
    required bool hasBlockedMe,
    required int mutualGroups,
    List<_i2.Moment>? recentMoments,
    int? level,
    int? xp,
    List<String>? interests,
    List<String>? languages,
    String? gender,
    String? country,
    String? bio,
  }) = _UserProfileViewImpl;

  factory UserProfileView.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfileView(
      userId: jsonSerialization['userId'] as String,
      userName: jsonSerialization['userName'] as String?,
      userAvatar: jsonSerialization['userAvatar'] as String?,
      userMood: jsonSerialization['userMood'] as String?,
      floor: jsonSerialization['floor'] as int,
      trustScore: jsonSerialization['trustScore'] as int,
      totalMessages: jsonSerialization['totalMessages'] as int,
      totalMoments: jsonSerialization['totalMoments'] as int,
      achievementsUnlocked: jsonSerialization['achievementsUnlocked'] as int,
      currentStreak: jsonSerialization['currentStreak'] as int,
      longestStreak: jsonSerialization['longestStreak'] as int,
      isBlocked: _i1.BoolJsonExtension.fromJson(jsonSerialization['isBlocked']),
      hasBlockedMe: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasBlockedMe'],
      ),
      mutualGroups: jsonSerialization['mutualGroups'] as int,
      recentMoments: jsonSerialization['recentMoments'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.Moment>>(
              jsonSerialization['recentMoments'],
            ),
      level: jsonSerialization['level'] as int?,
      xp: jsonSerialization['xp'] as int?,
      interests: jsonSerialization['interests'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['interests'],
            ),
      languages: jsonSerialization['languages'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['languages'],
            ),
      gender: jsonSerialization['gender'] as String?,
      country: jsonSerialization['country'] as String?,
      bio: jsonSerialization['bio'] as String?,
    );
  }

  String userId;

  String? userName;

  String? userAvatar;

  String? userMood;

  int floor;

  int trustScore;

  int totalMessages;

  int totalMoments;

  int achievementsUnlocked;

  int currentStreak;

  int longestStreak;

  bool isBlocked;

  bool hasBlockedMe;

  int mutualGroups;

  List<_i2.Moment>? recentMoments;

  int? level;

  int? xp;

  List<String>? interests;

  List<String>? languages;

  String? gender;

  String? country;

  String? bio;

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserProfileView copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    String? userMood,
    int? floor,
    int? trustScore,
    int? totalMessages,
    int? totalMoments,
    int? achievementsUnlocked,
    int? currentStreak,
    int? longestStreak,
    bool? isBlocked,
    bool? hasBlockedMe,
    int? mutualGroups,
    List<_i2.Moment>? recentMoments,
    int? level,
    int? xp,
    List<String>? interests,
    List<String>? languages,
    String? gender,
    String? country,
    String? bio,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserProfileView',
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (userMood != null) 'userMood': userMood,
      'floor': floor,
      'trustScore': trustScore,
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
      if (level != null) 'level': level,
      if (xp != null) 'xp': xp,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
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
    String? userMood,
    required int floor,
    required int trustScore,
    required int totalMessages,
    required int totalMoments,
    required int achievementsUnlocked,
    required int currentStreak,
    required int longestStreak,
    required bool isBlocked,
    required bool hasBlockedMe,
    required int mutualGroups,
    List<_i2.Moment>? recentMoments,
    int? level,
    int? xp,
    List<String>? interests,
    List<String>? languages,
    String? gender,
    String? country,
    String? bio,
  }) : super._(
         userId: userId,
         userName: userName,
         userAvatar: userAvatar,
         userMood: userMood,
         floor: floor,
         trustScore: trustScore,
         totalMessages: totalMessages,
         totalMoments: totalMoments,
         achievementsUnlocked: achievementsUnlocked,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         isBlocked: isBlocked,
         hasBlockedMe: hasBlockedMe,
         mutualGroups: mutualGroups,
         recentMoments: recentMoments,
         level: level,
         xp: xp,
         interests: interests,
         languages: languages,
         gender: gender,
         country: country,
         bio: bio,
       );

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserProfileView copyWith({
    String? userId,
    Object? userName = _Undefined,
    Object? userAvatar = _Undefined,
    Object? userMood = _Undefined,
    int? floor,
    int? trustScore,
    int? totalMessages,
    int? totalMoments,
    int? achievementsUnlocked,
    int? currentStreak,
    int? longestStreak,
    bool? isBlocked,
    bool? hasBlockedMe,
    int? mutualGroups,
    Object? recentMoments = _Undefined,
    Object? level = _Undefined,
    Object? xp = _Undefined,
    Object? interests = _Undefined,
    Object? languages = _Undefined,
    Object? gender = _Undefined,
    Object? country = _Undefined,
    Object? bio = _Undefined,
  }) {
    return UserProfileView(
      userId: userId ?? this.userId,
      userName: userName is String? ? userName : this.userName,
      userAvatar: userAvatar is String? ? userAvatar : this.userAvatar,
      userMood: userMood is String? ? userMood : this.userMood,
      floor: floor ?? this.floor,
      trustScore: trustScore ?? this.trustScore,
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
      level: level is int? ? level : this.level,
      xp: xp is int? ? xp : this.xp,
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      gender: gender is String? ? gender : this.gender,
      country: country is String? ? country : this.country,
      bio: bio is String? ? bio : this.bio,
    );
  }
}
