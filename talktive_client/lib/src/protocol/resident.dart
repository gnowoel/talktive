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
import 'package:talktive_client/src/protocol/protocol.dart' as _i2;

abstract class Resident implements _i1.SerializableModel {
  Resident._({
    this.id,
    required this.userInfoId,
    int? trustScore,
    this.lastReputationIncrease,
    this.mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    this.lastLoginDate,
    this.lastMessageDate,
    int? experienceMessageCount,
    this.userName,
    this.gender,
    this.country,
    this.bio,
    this.mood,
    this.avatar,
    this.interests,
    this.languages,
    this.role,
    bool? isAdmin,
  }) : trustScore = trustScore ?? 100,
       suspended = suspended ?? false,
       xp = xp ?? 0,
       level = level ?? 0,
       currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       experienceMessageCount = experienceMessageCount ?? 0,
       isAdmin = isAdmin ?? false;

  factory Resident({
    int? id,
    required _i1.UuidValue userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  }) = _ResidentImpl;

  factory Resident.fromJson(Map<String, dynamic> jsonSerialization) {
    return Resident(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      trustScore: jsonSerialization['trustScore'] as int?,
      lastReputationIncrease:
          jsonSerialization['lastReputationIncrease'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastReputationIncrease'],
            ),
      mutedUntil: jsonSerialization['mutedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['mutedUntil']),
      suspended: jsonSerialization['suspended'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['suspended']),
      xp: jsonSerialization['xp'] as int?,
      level: jsonSerialization['level'] as int?,
      currentStreak: jsonSerialization['currentStreak'] as int?,
      longestStreak: jsonSerialization['longestStreak'] as int?,
      lastLoginDate: jsonSerialization['lastLoginDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginDate'],
            ),
      lastMessageDate: jsonSerialization['lastMessageDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageDate'],
            ),
      experienceMessageCount:
          jsonSerialization['experienceMessageCount'] as int?,
      userName: jsonSerialization['userName'] as String?,
      gender: jsonSerialization['gender'] as String?,
      country: jsonSerialization['country'] as String?,
      bio: jsonSerialization['bio'] as String?,
      mood: jsonSerialization['mood'] as String?,
      avatar: jsonSerialization['avatar'] as String?,
      interests: jsonSerialization['interests'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['interests'],
            ),
      languages: jsonSerialization['languages'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['languages'],
            ),
      role: jsonSerialization['role'] as String?,
      isAdmin: jsonSerialization['isAdmin'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userInfoId;

  int trustScore;

  DateTime? lastReputationIncrease;

  DateTime? mutedUntil;

  bool suspended;

  int xp;

  int level;

  int currentStreak;

  int longestStreak;

  DateTime? lastLoginDate;

  DateTime? lastMessageDate;

  int experienceMessageCount;

  String? userName;

  String? gender;

  String? country;

  String? bio;

  String? mood;

  String? avatar;

  List<String>? interests;

  List<String>? languages;

  String? role;

  bool isAdmin;

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Resident copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'trustScore': trustScore,
      if (lastReputationIncrease != null)
        'lastReputationIncrease': lastReputationIncrease?.toJson(),
      if (mutedUntil != null) 'mutedUntil': mutedUntil?.toJson(),
      'suspended': suspended,
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastLoginDate != null) 'lastLoginDate': lastLoginDate?.toJson(),
      if (lastMessageDate != null) 'lastMessageDate': lastMessageDate?.toJson(),
      'experienceMessageCount': experienceMessageCount,
      if (userName != null) 'userName': userName,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (mood != null) 'mood': mood,
      if (avatar != null) 'avatar': avatar,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (role != null) 'role': role,
      'isAdmin': isAdmin,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResidentImpl extends Resident {
  _ResidentImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         trustScore: trustScore,
         lastReputationIncrease: lastReputationIncrease,
         mutedUntil: mutedUntil,
         suspended: suspended,
         xp: xp,
         level: level,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         lastLoginDate: lastLoginDate,
         lastMessageDate: lastMessageDate,
         experienceMessageCount: experienceMessageCount,
         userName: userName,
         gender: gender,
         country: country,
         bio: bio,
         mood: mood,
         avatar: avatar,
         interests: interests,
         languages: languages,
         role: role,
         isAdmin: isAdmin,
       );

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Resident copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? trustScore,
    Object? lastReputationIncrease = _Undefined,
    Object? mutedUntil = _Undefined,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    Object? lastLoginDate = _Undefined,
    Object? lastMessageDate = _Undefined,
    int? experienceMessageCount,
    Object? userName = _Undefined,
    Object? gender = _Undefined,
    Object? country = _Undefined,
    Object? bio = _Undefined,
    Object? mood = _Undefined,
    Object? avatar = _Undefined,
    Object? interests = _Undefined,
    Object? languages = _Undefined,
    Object? role = _Undefined,
    bool? isAdmin,
  }) {
    return Resident(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      trustScore: trustScore ?? this.trustScore,
      lastReputationIncrease: lastReputationIncrease is DateTime?
          ? lastReputationIncrease
          : this.lastReputationIncrease,
      mutedUntil: mutedUntil is DateTime? ? mutedUntil : this.mutedUntil,
      suspended: suspended ?? this.suspended,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate is DateTime?
          ? lastLoginDate
          : this.lastLoginDate,
      lastMessageDate: lastMessageDate is DateTime?
          ? lastMessageDate
          : this.lastMessageDate,
      experienceMessageCount:
          experienceMessageCount ?? this.experienceMessageCount,
      userName: userName is String? ? userName : this.userName,
      gender: gender is String? ? gender : this.gender,
      country: country is String? ? country : this.country,
      bio: bio is String? ? bio : this.bio,
      mood: mood is String? ? mood : this.mood,
      avatar: avatar is String? ? avatar : this.avatar,
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      role: role is String? ? role : this.role,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
