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

abstract class Resident
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
    bool? keepPrivateChats,
    this.customAvatarUrl,
  }) : trustScore = trustScore ?? 100,
       suspended = suspended ?? false,
       xp = xp ?? 0,
       level = level ?? 0,
       currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       ageRange = ageRange ?? '18-24',
       role = role ?? _i2.ResidentRole.user,
       isPremium = isPremium ?? false,
       trialCount = trialCount ?? 0,
       showOthersOnlineStatus = showOthersOnlineStatus ?? true,
       showOthersReadReceipts = showOthersReadReceipts ?? true,
       showOthersTypingIndicators = showOthersTypingIndicators ?? true,
       hideAds = hideAds ?? false,
       showVoiceMessages = showVoiceMessages ?? true,
       showAdvancedDiscovery = showAdvancedDiscovery ?? true,
       showCustomAvatar = showCustomAvatar ?? true,
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
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
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
      hideAds: jsonSerialization['hideAds'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['hideAds']),
      showVoiceMessages: jsonSerialization['showVoiceMessages'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showVoiceMessages'],
            ),
      showAdvancedDiscovery: jsonSerialization['showAdvancedDiscovery'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showAdvancedDiscovery'],
            ),
      showCustomAvatar: jsonSerialization['showCustomAvatar'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showCustomAvatar'],
            ),
      keepPrivateChats: jsonSerialization['keepPrivateChats'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['keepPrivateChats'],
            ),
      customAvatarUrl: jsonSerialization['customAvatarUrl'] as String?,
    );
  }

  static final t = ResidentTable();

  static const db = ResidentRepository._();

  @override
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

  bool showOthersOnlineStatus;

  bool showOthersReadReceipts;

  bool showOthersTypingIndicators;

  bool hideAds;

  bool showVoiceMessages;

  bool showAdvancedDiscovery;

  bool showCustomAvatar;

  bool keepPrivateChats;

  String? customAvatarUrl;

  @override
  _i1.Table<int?> get table => t;

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
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
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
      'showOthersOnlineStatus': showOthersOnlineStatus,
      'showOthersReadReceipts': showOthersReadReceipts,
      'showOthersTypingIndicators': showOthersTypingIndicators,
      'hideAds': hideAds,
      'showVoiceMessages': showVoiceMessages,
      'showAdvancedDiscovery': showAdvancedDiscovery,
      'showCustomAvatar': showCustomAvatar,
      'keepPrivateChats': keepPrivateChats,
      if (customAvatarUrl != null) 'customAvatarUrl': customAvatarUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
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
      'showOthersOnlineStatus': showOthersOnlineStatus,
      'showOthersReadReceipts': showOthersReadReceipts,
      'showOthersTypingIndicators': showOthersTypingIndicators,
      'hideAds': hideAds,
      'showVoiceMessages': showVoiceMessages,
      'showAdvancedDiscovery': showAdvancedDiscovery,
      'showCustomAvatar': showCustomAvatar,
      'keepPrivateChats': keepPrivateChats,
      if (customAvatarUrl != null) 'customAvatarUrl': customAvatarUrl,
    };
  }

  static ResidentInclude include() {
    return ResidentInclude._();
  }

  static ResidentIncludeList includeList({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    ResidentInclude? include,
  }) {
    return ResidentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Resident.t),
      include: include,
    );
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
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
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
         showOthersOnlineStatus: showOthersOnlineStatus,
         showOthersReadReceipts: showOthersReadReceipts,
         showOthersTypingIndicators: showOthersTypingIndicators,
         hideAds: hideAds,
         showVoiceMessages: showVoiceMessages,
         showAdvancedDiscovery: showAdvancedDiscovery,
         showCustomAvatar: showCustomAvatar,
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
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
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
      showOthersOnlineStatus:
          showOthersOnlineStatus ?? this.showOthersOnlineStatus,
      showOthersReadReceipts:
          showOthersReadReceipts ?? this.showOthersReadReceipts,
      showOthersTypingIndicators:
          showOthersTypingIndicators ?? this.showOthersTypingIndicators,
      hideAds: hideAds ?? this.hideAds,
      showVoiceMessages: showVoiceMessages ?? this.showVoiceMessages,
      showAdvancedDiscovery:
          showAdvancedDiscovery ?? this.showAdvancedDiscovery,
      showCustomAvatar: showCustomAvatar ?? this.showCustomAvatar,
      keepPrivateChats: keepPrivateChats ?? this.keepPrivateChats,
      customAvatarUrl: customAvatarUrl is String?
          ? customAvatarUrl
          : this.customAvatarUrl,
    );
  }
}

class ResidentUpdateTable extends _i1.UpdateTable<ResidentTable> {
  ResidentUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userInfoId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime? value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<int, int> trustScore(int value) => _i1.ColumnValue(
    table.trustScore,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastReputationIncrease(DateTime? value) =>
      _i1.ColumnValue(
        table.lastReputationIncrease,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> mutedUntil(DateTime? value) =>
      _i1.ColumnValue(
        table.mutedUntil,
        value,
      );

  _i1.ColumnValue<bool, bool> suspended(bool value) => _i1.ColumnValue(
    table.suspended,
    value,
  );

  _i1.ColumnValue<int, int> xp(int value) => _i1.ColumnValue(
    table.xp,
    value,
  );

  _i1.ColumnValue<int, int> level(int value) => _i1.ColumnValue(
    table.level,
    value,
  );

  _i1.ColumnValue<int, int> currentStreak(int value) => _i1.ColumnValue(
    table.currentStreak,
    value,
  );

  _i1.ColumnValue<int, int> longestStreak(int value) => _i1.ColumnValue(
    table.longestStreak,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastLoginDate(DateTime? value) =>
      _i1.ColumnValue(
        table.lastLoginDate,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastMessageDate(DateTime? value) =>
      _i1.ColumnValue(
        table.lastMessageDate,
        value,
      );

  _i1.ColumnValue<String, String> userName(String? value) => _i1.ColumnValue(
    table.userName,
    value,
  );

  _i1.ColumnValue<String, String> gender(String? value) => _i1.ColumnValue(
    table.gender,
    value,
  );

  _i1.ColumnValue<String, String> country(String? value) => _i1.ColumnValue(
    table.country,
    value,
  );

  _i1.ColumnValue<String, String> bio(String? value) => _i1.ColumnValue(
    table.bio,
    value,
  );

  _i1.ColumnValue<String, String> mood(String? value) => _i1.ColumnValue(
    table.mood,
    value,
  );

  _i1.ColumnValue<String, String> avatar(String? value) => _i1.ColumnValue(
    table.avatar,
    value,
  );

  _i1.ColumnValue<String, String> ageRange(String? value) => _i1.ColumnValue(
    table.ageRange,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> interests(List<String>? value) =>
      _i1.ColumnValue(
        table.interests,
        value,
      );

  _i1.ColumnValue<List<String>, List<String>> languages(List<String>? value) =>
      _i1.ColumnValue(
        table.languages,
        value,
      );

  _i1.ColumnValue<_i2.ResidentRole, _i2.ResidentRole> role(
    _i2.ResidentRole value,
  ) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastSeen(DateTime? value) =>
      _i1.ColumnValue(
        table.lastSeen,
        value,
      );

  _i1.ColumnValue<bool, bool> isPremium(bool value) => _i1.ColumnValue(
    table.isPremium,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> premiumTrialExpires(DateTime? value) =>
      _i1.ColumnValue(
        table.premiumTrialExpires,
        value,
      );

  _i1.ColumnValue<int, int> trialCount(int value) => _i1.ColumnValue(
    table.trialCount,
    value,
  );

  _i1.ColumnValue<bool, bool> showOthersOnlineStatus(bool value) =>
      _i1.ColumnValue(
        table.showOthersOnlineStatus,
        value,
      );

  _i1.ColumnValue<bool, bool> showOthersReadReceipts(bool value) =>
      _i1.ColumnValue(
        table.showOthersReadReceipts,
        value,
      );

  _i1.ColumnValue<bool, bool> showOthersTypingIndicators(bool value) =>
      _i1.ColumnValue(
        table.showOthersTypingIndicators,
        value,
      );

  _i1.ColumnValue<bool, bool> hideAds(bool value) => _i1.ColumnValue(
    table.hideAds,
    value,
  );

  _i1.ColumnValue<bool, bool> showVoiceMessages(bool value) => _i1.ColumnValue(
    table.showVoiceMessages,
    value,
  );

  _i1.ColumnValue<bool, bool> showAdvancedDiscovery(bool value) =>
      _i1.ColumnValue(
        table.showAdvancedDiscovery,
        value,
      );

  _i1.ColumnValue<bool, bool> showCustomAvatar(bool value) => _i1.ColumnValue(
    table.showCustomAvatar,
    value,
  );

  _i1.ColumnValue<bool, bool> keepPrivateChats(bool value) => _i1.ColumnValue(
    table.keepPrivateChats,
    value,
  );

  _i1.ColumnValue<String, String> customAvatarUrl(String? value) =>
      _i1.ColumnValue(
        table.customAvatarUrl,
        value,
      );
}

class ResidentTable extends _i1.Table<int?> {
  ResidentTable({super.tableRelation}) : super(tableName: 'resident') {
    updateTable = ResidentUpdateTable(this);
    userInfoId = _i1.ColumnUuid(
      'userInfoId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    trustScore = _i1.ColumnInt(
      'trustScore',
      this,
      hasDefault: true,
    );
    lastReputationIncrease = _i1.ColumnDateTime(
      'lastReputationIncrease',
      this,
    );
    mutedUntil = _i1.ColumnDateTime(
      'mutedUntil',
      this,
    );
    suspended = _i1.ColumnBool(
      'suspended',
      this,
      hasDefault: true,
    );
    xp = _i1.ColumnInt(
      'xp',
      this,
      hasDefault: true,
    );
    level = _i1.ColumnInt(
      'level',
      this,
      hasDefault: true,
    );
    currentStreak = _i1.ColumnInt(
      'currentStreak',
      this,
      hasDefault: true,
    );
    longestStreak = _i1.ColumnInt(
      'longestStreak',
      this,
      hasDefault: true,
    );
    lastLoginDate = _i1.ColumnDateTime(
      'lastLoginDate',
      this,
    );
    lastMessageDate = _i1.ColumnDateTime(
      'lastMessageDate',
      this,
    );
    userName = _i1.ColumnString(
      'userName',
      this,
    );
    gender = _i1.ColumnString(
      'gender',
      this,
    );
    country = _i1.ColumnString(
      'country',
      this,
    );
    bio = _i1.ColumnString(
      'bio',
      this,
    );
    mood = _i1.ColumnString(
      'mood',
      this,
    );
    avatar = _i1.ColumnString(
      'avatar',
      this,
    );
    ageRange = _i1.ColumnString(
      'ageRange',
      this,
      hasDefault: true,
    );
    interests = _i1.ColumnSerializable<List<String>>(
      'interests',
      this,
    );
    languages = _i1.ColumnSerializable<List<String>>(
      'languages',
      this,
    );
    role = _i1.ColumnEnum(
      'role',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    lastSeen = _i1.ColumnDateTime(
      'lastSeen',
      this,
    );
    isPremium = _i1.ColumnBool(
      'isPremium',
      this,
      hasDefault: true,
    );
    premiumTrialExpires = _i1.ColumnDateTime(
      'premiumTrialExpires',
      this,
    );
    trialCount = _i1.ColumnInt(
      'trialCount',
      this,
      hasDefault: true,
    );
    showOthersOnlineStatus = _i1.ColumnBool(
      'showOthersOnlineStatus',
      this,
      hasDefault: true,
    );
    showOthersReadReceipts = _i1.ColumnBool(
      'showOthersReadReceipts',
      this,
      hasDefault: true,
    );
    showOthersTypingIndicators = _i1.ColumnBool(
      'showOthersTypingIndicators',
      this,
      hasDefault: true,
    );
    hideAds = _i1.ColumnBool(
      'hideAds',
      this,
      hasDefault: true,
    );
    showVoiceMessages = _i1.ColumnBool(
      'showVoiceMessages',
      this,
      hasDefault: true,
    );
    showAdvancedDiscovery = _i1.ColumnBool(
      'showAdvancedDiscovery',
      this,
      hasDefault: true,
    );
    showCustomAvatar = _i1.ColumnBool(
      'showCustomAvatar',
      this,
      hasDefault: true,
    );
    keepPrivateChats = _i1.ColumnBool(
      'keepPrivateChats',
      this,
      hasDefault: true,
    );
    customAvatarUrl = _i1.ColumnString(
      'customAvatarUrl',
      this,
    );
  }

  late final ResidentUpdateTable updateTable;

  late final _i1.ColumnUuid userInfoId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt trustScore;

  late final _i1.ColumnDateTime lastReputationIncrease;

  late final _i1.ColumnDateTime mutedUntil;

  late final _i1.ColumnBool suspended;

  late final _i1.ColumnInt xp;

  late final _i1.ColumnInt level;

  late final _i1.ColumnInt currentStreak;

  late final _i1.ColumnInt longestStreak;

  late final _i1.ColumnDateTime lastLoginDate;

  late final _i1.ColumnDateTime lastMessageDate;

  late final _i1.ColumnString userName;

  late final _i1.ColumnString gender;

  late final _i1.ColumnString country;

  late final _i1.ColumnString bio;

  late final _i1.ColumnString mood;

  late final _i1.ColumnString avatar;

  late final _i1.ColumnString ageRange;

  late final _i1.ColumnSerializable<List<String>> interests;

  late final _i1.ColumnSerializable<List<String>> languages;

  late final _i1.ColumnEnum<_i2.ResidentRole> role;

  late final _i1.ColumnDateTime lastSeen;

  late final _i1.ColumnBool isPremium;

  late final _i1.ColumnDateTime premiumTrialExpires;

  late final _i1.ColumnInt trialCount;

  late final _i1.ColumnBool showOthersOnlineStatus;

  late final _i1.ColumnBool showOthersReadReceipts;

  late final _i1.ColumnBool showOthersTypingIndicators;

  late final _i1.ColumnBool hideAds;

  late final _i1.ColumnBool showVoiceMessages;

  late final _i1.ColumnBool showAdvancedDiscovery;

  late final _i1.ColumnBool showCustomAvatar;

  late final _i1.ColumnBool keepPrivateChats;

  late final _i1.ColumnString customAvatarUrl;

  @override
  List<_i1.Column> get columns => [
    id,
    userInfoId,
    createdAt,
    trustScore,
    lastReputationIncrease,
    mutedUntil,
    suspended,
    xp,
    level,
    currentStreak,
    longestStreak,
    lastLoginDate,
    lastMessageDate,
    userName,
    gender,
    country,
    bio,
    mood,
    avatar,
    ageRange,
    interests,
    languages,
    role,
    lastSeen,
    isPremium,
    premiumTrialExpires,
    trialCount,
    showOthersOnlineStatus,
    showOthersReadReceipts,
    showOthersTypingIndicators,
    hideAds,
    showVoiceMessages,
    showAdvancedDiscovery,
    showCustomAvatar,
    keepPrivateChats,
    customAvatarUrl,
  ];
}

class ResidentInclude extends _i1.IncludeObject {
  ResidentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentIncludeList extends _i1.IncludeList {
  ResidentIncludeList._({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Resident.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentRepository {
  const ResidentRepository._();

  /// Returns a list of [Resident]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Resident>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Resident] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Resident?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Resident] by its [id] or null if no such row exists.
  Future<Resident?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Resident>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Resident]s in the list and returns the inserted rows.
  ///
  /// The returned [Resident]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Resident>> insert(
    _i1.DatabaseSession session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Resident>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Resident] and returns the inserted row.
  ///
  /// The returned [Resident] will have its `id` field set.
  Future<Resident> insertRow(
    _i1.DatabaseSession session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Resident>> update(
    _i1.DatabaseSession session,
    List<Resident> rows, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Resident>(
      rows,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Resident> updateRow(
    _i1.DatabaseSession session,
    Resident row, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Resident>(
      row,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Resident?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Resident>(
      id,
      columnValues: columnValues(Resident.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Resident>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Resident>(
      columnValues: columnValues(Resident.t.updateTable),
      where: where(Resident.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Resident]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Resident>> delete(
    _i1.DatabaseSession session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Resident>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Resident].
  Future<Resident> deleteRow(
    _i1.DatabaseSession session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Resident>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Resident>(
      where: where(Resident.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Resident>(
      where: where?.call(Resident.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Resident] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Resident>(
      where: where(Resident.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
