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
import 'resident_role.dart' as _i2;
import 'package:talktive_client/src/protocol/protocol.dart' as _i3;

abstract class Resident implements _i1.SerializableModel {
  Resident._({
    this.id,
    required this.userInfoId,
    this.createdAt,
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
    String? ageRange,
    this.interests,
    this.languages,
    _i2.ResidentRole? role,
    this.lastSeen,
    bool? isPremium,
    this.premiumTrialExpires,
    int? trialCount,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? allowDiscovery,
    bool? showCustomAvatar,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
    this.customAvatarUrl,
  }) : trustScore = trustScore ?? 100,
       suspended = suspended ?? false,
       xp = xp ?? 0,
       level = level ?? 0,
       currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       experienceMessageCount = experienceMessageCount ?? 0,
       ageRange = ageRange ?? '18-24',
       role = role ?? _i2.ResidentRole.user,
       isPremium = isPremium ?? false,
       trialCount = trialCount ?? 0,
       showOnlineStatus = showOnlineStatus ?? true,
       showReadReceipts = showReadReceipts ?? true,
       showTypingIndicator = showTypingIndicator ?? true,
       showVoiceMessages = showVoiceMessages ?? true,
       showNeighborsDiscovery = showNeighborsDiscovery ?? true,
       allowDiscovery = allowDiscovery ?? true,
       showCustomAvatar = showCustomAvatar ?? true,
       showImagesInPlaza = showImagesInPlaza ?? true,
       showImagesInLounges = showImagesInLounges ?? true,
       showImagesInPrivateChats = showImagesInPrivateChats ?? true,
       showImagesInMoments = showImagesInMoments ?? true,
       showOthersOnlineStatus = showOthersOnlineStatus ?? true,
       showOthersReadReceipts = showOthersReadReceipts ?? true,
       showOthersTypingIndicators = showOthersTypingIndicators ?? true,
       keepPrivateChats = keepPrivateChats ?? true;

  factory Resident({
    int? id,
    required _i1.UuidValue userInfoId,
    DateTime? createdAt,
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
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    _i2.ResidentRole? role,
    DateTime? lastSeen,
    bool? isPremium,
    DateTime? premiumTrialExpires,
    int? trialCount,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? allowDiscovery,
    bool? showCustomAvatar,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
    String? customAvatarUrl,
  }) = _ResidentImpl;

  factory Resident.fromJson(Map<String, dynamic> jsonSerialization) {
    return Resident(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
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
      ageRange: jsonSerialization['ageRange'] as String?,
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
      role: jsonSerialization['role'] == null
          ? null
          : _i2.ResidentRole.fromJson((jsonSerialization['role'] as String)),
      lastSeen: jsonSerialization['lastSeen'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeen']),
      isPremium: jsonSerialization['isPremium'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isPremium']),
      premiumTrialExpires: jsonSerialization['premiumTrialExpires'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['premiumTrialExpires'],
            ),
      trialCount: jsonSerialization['trialCount'] as int?,
      showOnlineStatus: jsonSerialization['showOnlineStatus'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showOnlineStatus'],
            ),
      showReadReceipts: jsonSerialization['showReadReceipts'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showReadReceipts'],
            ),
      showTypingIndicator: jsonSerialization['showTypingIndicator'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showTypingIndicator'],
            ),
      showVoiceMessages: jsonSerialization['showVoiceMessages'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showVoiceMessages'],
            ),
      showNeighborsDiscovery:
          jsonSerialization['showNeighborsDiscovery'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showNeighborsDiscovery'],
            ),
      allowDiscovery: jsonSerialization['allowDiscovery'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['allowDiscovery']),
      showCustomAvatar: jsonSerialization['showCustomAvatar'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showCustomAvatar'],
            ),
      showImagesInPlaza: jsonSerialization['showImagesInPlaza'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showImagesInPlaza'],
            ),
      showImagesInLounges: jsonSerialization['showImagesInLounges'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showImagesInLounges'],
            ),
      showImagesInPrivateChats:
          jsonSerialization['showImagesInPrivateChats'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showImagesInPrivateChats'],
            ),
      showImagesInMoments: jsonSerialization['showImagesInMoments'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showImagesInMoments'],
            ),
      showOthersOnlineStatus:
          jsonSerialization['showOthersOnlineStatus'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showOthersOnlineStatus'],
            ),
      showOthersReadReceipts:
          jsonSerialization['showOthersReadReceipts'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showOthersReadReceipts'],
            ),
      showOthersTypingIndicators:
          jsonSerialization['showOthersTypingIndicators'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showOthersTypingIndicators'],
            ),
      keepPrivateChats: jsonSerialization['keepPrivateChats'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['keepPrivateChats'],
            ),
      customAvatarUrl: jsonSerialization['customAvatarUrl'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userInfoId;

  DateTime? createdAt;

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

  String? ageRange;

  List<String>? interests;

  List<String>? languages;

  _i2.ResidentRole role;

  DateTime? lastSeen;

  bool isPremium;

  DateTime? premiumTrialExpires;

  int trialCount;

  bool showOnlineStatus;

  bool showReadReceipts;

  bool showTypingIndicator;

  bool showVoiceMessages;

  bool showNeighborsDiscovery;

  bool allowDiscovery;

  bool showCustomAvatar;

  bool showImagesInPlaza;

  bool showImagesInLounges;

  bool showImagesInPrivateChats;

  bool showImagesInMoments;

  bool showOthersOnlineStatus;

  bool showOthersReadReceipts;

  bool showOthersTypingIndicators;

  bool keepPrivateChats;

  String? customAvatarUrl;

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Resident copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    DateTime? createdAt,
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
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    _i2.ResidentRole? role,
    DateTime? lastSeen,
    bool? isPremium,
    DateTime? premiumTrialExpires,
    int? trialCount,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? allowDiscovery,
    bool? showCustomAvatar,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
    String? customAvatarUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
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
      if (ageRange != null) 'ageRange': ageRange,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      'role': role.toJson(),
      if (lastSeen != null) 'lastSeen': lastSeen?.toJson(),
      'isPremium': isPremium,
      if (premiumTrialExpires != null)
        'premiumTrialExpires': premiumTrialExpires?.toJson(),
      'trialCount': trialCount,
      'showOnlineStatus': showOnlineStatus,
      'showReadReceipts': showReadReceipts,
      'showTypingIndicator': showTypingIndicator,
      'showVoiceMessages': showVoiceMessages,
      'showNeighborsDiscovery': showNeighborsDiscovery,
      'allowDiscovery': allowDiscovery,
      'showCustomAvatar': showCustomAvatar,
      'showImagesInPlaza': showImagesInPlaza,
      'showImagesInLounges': showImagesInLounges,
      'showImagesInPrivateChats': showImagesInPrivateChats,
      'showImagesInMoments': showImagesInMoments,
      'showOthersOnlineStatus': showOthersOnlineStatus,
      'showOthersReadReceipts': showOthersReadReceipts,
      'showOthersTypingIndicators': showOthersTypingIndicators,
      'keepPrivateChats': keepPrivateChats,
      if (customAvatarUrl != null) 'customAvatarUrl': customAvatarUrl,
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
    DateTime? createdAt,
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
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    _i2.ResidentRole? role,
    DateTime? lastSeen,
    bool? isPremium,
    DateTime? premiumTrialExpires,
    int? trialCount,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? allowDiscovery,
    bool? showCustomAvatar,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
    String? customAvatarUrl,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         createdAt: createdAt,
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
         ageRange: ageRange,
         interests: interests,
         languages: languages,
         role: role,
         lastSeen: lastSeen,
         isPremium: isPremium,
         premiumTrialExpires: premiumTrialExpires,
         trialCount: trialCount,
         showOnlineStatus: showOnlineStatus,
         showReadReceipts: showReadReceipts,
         showTypingIndicator: showTypingIndicator,
         showVoiceMessages: showVoiceMessages,
         showNeighborsDiscovery: showNeighborsDiscovery,
         allowDiscovery: allowDiscovery,
         showCustomAvatar: showCustomAvatar,
         showImagesInPlaza: showImagesInPlaza,
         showImagesInLounges: showImagesInLounges,
         showImagesInPrivateChats: showImagesInPrivateChats,
         showImagesInMoments: showImagesInMoments,
         showOthersOnlineStatus: showOthersOnlineStatus,
         showOthersReadReceipts: showOthersReadReceipts,
         showOthersTypingIndicators: showOthersTypingIndicators,
         keepPrivateChats: keepPrivateChats,
         customAvatarUrl: customAvatarUrl,
       );

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Resident copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    Object? createdAt = _Undefined,
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
    Object? ageRange = _Undefined,
    Object? interests = _Undefined,
    Object? languages = _Undefined,
    _i2.ResidentRole? role,
    Object? lastSeen = _Undefined,
    bool? isPremium,
    Object? premiumTrialExpires = _Undefined,
    int? trialCount,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? allowDiscovery,
    bool? showCustomAvatar,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
    Object? customAvatarUrl = _Undefined,
  }) {
    return Resident(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
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
      ageRange: ageRange is String? ? ageRange : this.ageRange,
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      role: role ?? this.role,
      lastSeen: lastSeen is DateTime? ? lastSeen : this.lastSeen,
      isPremium: isPremium ?? this.isPremium,
      premiumTrialExpires: premiumTrialExpires is DateTime?
          ? premiumTrialExpires
          : this.premiumTrialExpires,
      trialCount: trialCount ?? this.trialCount,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      showVoiceMessages: showVoiceMessages ?? this.showVoiceMessages,
      showNeighborsDiscovery:
          showNeighborsDiscovery ?? this.showNeighborsDiscovery,
      allowDiscovery: allowDiscovery ?? this.allowDiscovery,
      showCustomAvatar: showCustomAvatar ?? this.showCustomAvatar,
      showImagesInPlaza: showImagesInPlaza ?? this.showImagesInPlaza,
      showImagesInLounges: showImagesInLounges ?? this.showImagesInLounges,
      showImagesInPrivateChats:
          showImagesInPrivateChats ?? this.showImagesInPrivateChats,
      showImagesInMoments: showImagesInMoments ?? this.showImagesInMoments,
      showOthersOnlineStatus:
          showOthersOnlineStatus ?? this.showOthersOnlineStatus,
      showOthersReadReceipts:
          showOthersReadReceipts ?? this.showOthersReadReceipts,
      showOthersTypingIndicators:
          showOthersTypingIndicators ?? this.showOthersTypingIndicators,
      keepPrivateChats: keepPrivateChats ?? this.keepPrivateChats,
      customAvatarUrl: customAvatarUrl is String?
          ? customAvatarUrl
          : this.customAvatarUrl,
    );
  }
}
