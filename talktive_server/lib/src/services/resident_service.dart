import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/notification_service.dart';
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../services/file_storage_service.dart';
import '../utils/task_utils.dart';

/// Service for managing Resident profiles and synchronization with AuthUser.
class ResidentService {
  static String _getCacheKey(UuidValue userId) => 'resident_$userId';

  /// Fetches a Resident by their userInfoId.
  static Future<protocol.Resident?> getResident(
    Session session,
    UuidValue userId,
  ) async {
    final residents = await getResidents(session, [userId]);
    return residents.isNotEmpty ? residents.first : null;
  }

  /// Fetches multiple Residents by their userInfoIds with batch caching.
  static Future<List<protocol.Resident>> getResidents(
    Session session,
    List<UuidValue> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    final result = <protocol.Resident>[];
    final missingIds = <UuidValue>[];
    final cacheKeyMap = {for (final id in userIds) id: 'resident_$id'};

    // 1. Try Cache Lookups (Session Local -> Global)
    for (final id in userIds) {
      final key = cacheKeyMap[id]!;
      protocol.Resident? cached = await session.caches.local
          .get<protocol.Resident>(key);

      if (cached == null) {
        try {
          cached = await session.caches.global.get<protocol.Resident>(key);
          if (cached != null) {
            await session.caches.local.put(key, cached);
          }
        } catch (_) {}
      }

      if (cached != null) {
        result.add(cached);
      } else {
        missingIds.add(id);
      }
    }

    if (missingIds.isEmpty) return result;

    // 2. Database Fallback
    final missingResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(missingIds.toSet()),
    );

    for (final resident in missingResidents) {
      result.add(resident);
      final key = _getCacheKey(resident.userInfoId);
      await session.caches.local.put(
        key,
        resident,
        lifetime: const Duration(minutes: 5),
      );

      // Optimization: Background Redis cache updates to avoid blocking DB flow
      TaskUtils.runBackground(session, (backgroundSession) async {
        try {
          await backgroundSession.caches.global.put(
            key,
            resident,
            lifetime: const Duration(minutes: 5),
          );
        } catch (_) {}
      });
    }

    return result;
  }

  /// Fetches a Resident and performs passive updates (Trust Score, Daily Login, lastSeen).
  static Future<protocol.Resident?> getActiveResident(
    Session session,
    UuidValue userInfoId,
  ) async {
    final resident = await getResident(session, userInfoId);
    if (resident == null) return null;

    // Perform passive updates in background if possible to avoid blocking response
    // But we need to return the 'synced' resident if we want strict consistency.
    // However, for performance, we'll run it in background if they were seen recently.
    final now = DateTime.now();
    if (resident.lastSeen != null &&
        now.difference(resident.lastSeen!).inSeconds < 30) {
      // Very recently seen, skip blocking update
      TaskUtils.runBackground(session, (s) => ensureActiveState(s, resident));
      return resident;
    }

    return await ensureActiveState(session, resident);
  }

  /// Invalidates the cache for a specific resident across all tiers (Local & Global).
  static Future<void> invalidateResidentCache(
    Session session,
    UuidValue userId,
  ) async {
    final residentKey = _getCacheKey(userId);
    final viewKey = 'profile_view_$userId';

    await session.caches.local.invalidateKey(residentKey);
    await session.caches.local.invalidateKey(viewKey);
    try {
      await session.caches.global.invalidateKey(residentKey);
      await session.caches.global.invalidateKey(viewKey);
    } catch (e) {
      session.log(
        'Cache error (invalidate resident): $e',
        level: LogLevel.debug,
      );
    }
  }

  /// Updates a resident in the database and synchronizes the global cache.
  static Future<protocol.Resident> updateResident(
    Session session,
    protocol.Resident resident,
  ) async {
    // 1. Fetch old resident to check for custom avatar changes
    final oldResident = await protocol.Resident.db.findById(
      session,
      resident.id!,
    );

    // Background tasks can outlive the row they were derived from during tests
    // and ephemeral cleanup flows. If the resident no longer exists, there is
    // nothing left to synchronize.
    if (oldResident == null) {
      session.log(
        'Skipping resident update for missing row: ${resident.userInfoId}',
        level: LogLevel.debug,
      );
      return resident;
    }

    // 2. Perform update
    final updated = await protocol.Resident.db.updateRow(session, resident);

    // 3. Clean up physical media if custom avatar changed or was removed
    if (oldResident.customAvatarUrl != null &&
        oldResident.customAvatarUrl != updated.customAvatarUrl) {
      await FileStorageService.deleteMedia(
        session,
        oldResident.customAvatarUrl,
      );
    }

    // 4. Invalidate caches including Derived Profile View
    await invalidateResidentCache(session, resident.userInfoId);

    // 5. Sync primary resident object back to caches
    final cacheKey = _getCacheKey(resident.userInfoId);
    await session.caches.local.put(cacheKey, updated);
    try {
      await session.caches.global.put(
        cacheKey,
        updated,
        lifetime: const Duration(minutes: 5),
      );
    } catch (e) {
      session.log('Cache error (sync resident): $e', level: LogLevel.debug);
    }

    return updated;
  }

  /// Ensures the resident's temporal state is up to date (trust score, daily login, last seen).
  /// Saves changes to the database if any occur.
  static Future<protocol.Resident> ensureActiveState(
    Session session,
    protocol.Resident resident,
  ) async {
    bool changed = false;

    // 1. Restore Trust Score (Passive)
    final trustChanged = await ApartmentService.restoreTrustScore(
      session,
      resident,
      save: false, // We'll save all at once
    );
    if (trustChanged) changed = true;

    // 2. Daily Login & Streak
    final loginChanged = await GamificationService.checkDailyLogin(
      session,
      resident,
      save: false,
    );
    if (loginChanged) changed = true;

    // 3. Update Last Seen
    final now = DateTime.now();
    if (resident.lastSeen == null ||
        now.difference(resident.lastSeen!).inMinutes >= 5) {
      resident.lastSeen = now;
      changed = true;
    }

    if (changed) {
      return await updateResident(session, resident);
    }

    return resident;
  }

  /// Synchronizes the AuthUser profile name with the Resident persona name.
  static Future<void> syncAuthProfile(
    Session session,
    UuidValue userId,
    String name,
  ) async {
    try {
      final userProfile = await AuthServices.instance.userProfiles
          .findUserProfileByUserId(session, userId);

      if (userProfile.userName != name) {
        await AuthServices.instance.userProfiles.changeUserName(
          session,
          userId,
          name,
        );
      }
      if (userProfile.fullName != name) {
        await AuthServices.instance.userProfiles.changeFullName(
          session,
          userId,
          name,
        );
      }
    } catch (_) {
      // User profile might not exist yet during initialization
    }
  }

  /// Creates a new Resident profile and synchronizes it with the AuthUser.
  static Future<protocol.Resident> createResident(
    Session session, {
    required UuidValue userId,
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
    int xp = 0,
    int level = 1,
    protocol.ResidentRole role = protocol.ResidentRole.user,
  }) async {
    // 1. Fetch/Update User Profile (Force Anonymous Identity)
    try {
      await syncAuthProfile(session, userId, name);
    } catch (e) {
      await AuthServices.instance.userProfiles.createUserProfile(
        session,
        userId,
        UserProfileData(
          userName: name,
          fullName: name,
          email: 'anon-$userId@anonymous.talktive.com',
        ),
      );
    }

    // 2. Create Resident
    final resident = protocol.Resident(
      userInfoId: userId,
      xp: xp,
      level: level,
      currentStreak: 0,
      longestStreak: 0,
      trustScore: ApartmentService.trustScoreStart,
      suspended: false,
      userName: name,
      gender: gender,
      country: country,
      bio: bio,
      ageRange: ageRange ?? 'Not Specified',
      mood: mood,
      avatar: avatar,
      interests: interests ?? [],
      languages: languages ?? ['en'],
      role: role,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isPremium: false,
      showOthersOnlineStatus: true,
      showOthersReadReceipts: true,
      showOthersTypingIndicators: true,
      customAvatarUrl: customAvatarUrl,
    );

    await protocol.Resident.db.insertRow(session, resident);
    return resident;
  }

  static Future<protocol.LegacyMigrationResult> applyLegacyMigration(
    Session session, {
    required protocol.Resident resident,
    required protocol.LegacyMigrationData migration,
  }) async {
    final updatedResident = _mergeLegacyMigration(resident, migration);
    final changedFields = _legacyMigrationChangedFields(
      resident,
      updatedResident,
    );

    if (changedFields.isEmpty) {
      return protocol.LegacyMigrationResult(
        resident: resident,
        changedFields: changedFields,
      );
    }

    final savedResident = await updateResident(session, updatedResident);
    if (savedResident.userName != resident.userName &&
        savedResident.userName != null) {
      await syncAuthProfile(
        session,
        savedResident.userInfoId,
        savedResident.userName!,
      );
    }

    return protocol.LegacyMigrationResult(
      resident: savedResident,
      changedFields: changedFields,
    );
  }

  static protocol.Resident _mergeLegacyMigration(
    protocol.Resident resident,
    protocol.LegacyMigrationData migration,
  ) {
    final legacyAvatar = migration.avatar;
    final hasLegacyPhoto = legacyAvatar?.contains('://') ?? false;

    return resident.copyWith(
      xp: _maxInt(resident.xp, migration.xp),
      level: _maxInt(resident.level, migration.level),
      role: _mergeRole(resident.role, migration.role),
      userName: _mergeText(resident.userName, migration.name),
      bio: _mergeText(resident.bio, migration.bio),
      gender: _mergeGender(resident.gender, migration.gender),
      languages: _mergeLanguages(resident.languages, migration.languages),
      avatar: hasLegacyPhoto
          ? resident.avatar
          : _mergeAvatar(resident.avatar, legacyAvatar),
      customAvatarUrl: hasLegacyPhoto
          ? _mergeText(resident.customAvatarUrl, legacyAvatar)
          : resident.customAvatarUrl,
    );
  }

  static List<String> _legacyMigrationChangedFields(
    protocol.Resident current,
    protocol.Resident updated,
  ) {
    final changedFields = <String>[];
    if (current.xp != updated.xp) changedFields.add('xp');
    if (current.level != updated.level) changedFields.add('level');
    if (current.role != updated.role) changedFields.add('role');
    if (current.userName != updated.userName) changedFields.add('userName');
    if (current.bio != updated.bio) changedFields.add('bio');
    if (current.gender != updated.gender) changedFields.add('gender');
    if (!_sameStringList(current.languages, updated.languages)) {
      changedFields.add('languages');
    }
    if (current.avatar != updated.avatar) changedFields.add('avatar');
    if (current.customAvatarUrl != updated.customAvatarUrl) {
      changedFields.add('customAvatarUrl');
    }
    return changedFields;
  }

  static int _maxInt(int current, int? incoming) {
    if (incoming == null) return current;
    return incoming > current ? incoming : current;
  }

  static protocol.ResidentRole _mergeRole(
    protocol.ResidentRole current,
    protocol.ResidentRole? incoming,
  ) {
    if (incoming == protocol.ResidentRole.admin) {
      return protocol.ResidentRole.admin;
    }
    if (incoming == protocol.ResidentRole.moderator &&
        current != protocol.ResidentRole.admin) {
      return protocol.ResidentRole.moderator;
    }
    return current;
  }

  static String? _mergeText(String? current, String? incoming) {
    if (!_isBlank(current)) return current;
    return _isBlank(incoming) ? current : incoming;
  }

  static String? _mergeGender(String? current, String? incoming) {
    if (!_isBlank(current) && current != 'prefer-not-to-say') {
      return current;
    }
    return _isBlank(incoming) ? current : incoming;
  }

  static List<String>? _mergeLanguages(
    List<String>? current,
    List<String>? incoming,
  ) {
    if (incoming == null || incoming.isEmpty) return current;
    if (current == null || current.isEmpty) return incoming;
    if (_isDefaultLanguageOnly(current) && incoming.length > current.length) {
      return incoming;
    }
    return current;
  }

  static String? _mergeAvatar(String? current, String? incoming) {
    if (!_isBlank(current) && current != '😊') return current;
    return _isBlank(incoming) ? current : incoming;
  }

  static bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static bool _isDefaultLanguageOnly(List<String> languages) {
    return languages.length == 1 && languages.first == 'en';
  }

  static bool _sameStringList(List<String>? left, List<String>? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return left == right;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  /// Checks if a user is blocked by another user.
  static Future<bool> isBlocked(
    Session session, {
    required UuidValue blockerId,
    required UuidValue blockedId,
  }) async {
    final block = await protocol.Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(blockerId) & t.blockedId.equals(blockedId),
    );
    return block != null;
  }

  /// Returns a set of user IDs blocked by the given user.
  static Future<Set<UuidValue>> getBlocksByUser(
    Session session,
    UuidValue blockerId,
  ) async {
    final blocks = await protocol.Block.db.find(
      session,
      where: (t) => t.blockerId.equals(blockerId),
    );
    return blocks.map((b) => b.blockedId).toSet();
  }

  /// Returns a set of user IDs who have blocked the given user.
  static Future<Set<UuidValue>> getBlocksAgainstUser(
    Session session,
    UuidValue blockedId,
  ) async {
    final blocks = await protocol.Block.db.find(
      session,
      where: (t) => t.blockedId.equals(blockedId),
    );
    return blocks.map((b) => b.blockerId).toSet();
  }

  /// Converts a Resident to a UserSummary.
  static protocol.UserSummary toUserSummary(
    protocol.Resident resident, {
    protocol.Resident? viewer,
    List<String>? sharedInterests,
    List<String>? sharedLanguages,
    int? matchScore,
  }) {
    // Apply gating rules (e.g. hide custom avatar if target is not Plus)
    final gated = gateResident(resident, viewer: viewer);
    final canSeeOnline = viewer != null && canSeeOthersOnlineStatus(viewer);

    return protocol.UserSummary(
      userId: gated.userInfoId,
      userName: gated.userName,
      userAvatar: gated.customAvatarUrl ?? gated.avatar,
      userMood: gated.mood,
      userBio: gated.bio,
      floor: ApartmentService.computeEffectiveFloor(gated),
      trustScore: gated.trustScore,
      sharedInterests: sharedInterests,
      sharedLanguages: sharedLanguages,
      matchScore: matchScore,
      ageRange: gated.ageRange,
      gender: gated.gender,
      languages: gated.languages,
      isOnline: canSeeOnline ? isResidentOnline(gated) : false,
      role: gated.role,
    );
  }

  /// Returns a gated copy of the resident based on the viewer's permissions.
  /// Nulls out sensitive fields like lastSeen if the viewer cannot see them.
  static protocol.Resident gateResident(
    protocol.Resident target, {
    protocol.Resident? viewer,
  }) {
    var gated = target;

    // 1. Gate Online Status (Viewer must be Plus and have setting enabled)
    if (viewer == null || !canSeeOthersOnlineStatus(viewer)) {
      gated = gated.copyWith(lastSeen: null);
    }

    // 2. Gate Custom Avatar (Target must be Plus)
    if (!isPlusMember(target)) {
      gated = gated.copyWith(customAvatarUrl: null);
    } else if (viewer != null && !canSeeCustomAvatars(viewer)) {
      // Viewer has explicitly opted out of seeing custom avatars
      gated = gated.copyWith(customAvatarUrl: null);
    }

    return gated;
  }

  /// Helper to check if a resident is online based on lastSeen.
  static bool isResidentOnline(protocol.Resident resident) {
    return resident.lastSeen != null &&
        DateTime.now().difference(resident.lastSeen!).inMinutes < 5;
  }

  /// Builds a comprehensive UserProfileView for a resident.
  static Future<protocol.UserProfileView?> getResidentProfileView(
    Session session,
    UuidValue targetId, {
    UuidValue? viewerId,
  }) async {
    // 1. Try Global Cache for the view (excluding mutual lounges/likes which are viewer-specific)
    final baseCacheKey = 'profile_view_$targetId';
    protocol.UserProfileView? profile;

    try {
      profile = await session.caches.global.get<protocol.UserProfileView>(
        baseCacheKey,
      );
    } catch (e) {
      session.log('Cache error (get profile view): $e', level: LogLevel.debug);
    }

    if (profile == null) {
      final resident = await getResident(session, targetId);
      if (resident == null) return null;

      // Parallelize base data fetching
      final statsFuture = Future.wait([
        protocol.Message.db.count(
          session,
          where: (t) => t.senderId.equals(targetId),
        ),
        protocol.Moment.db.count(
          session,
          where: (t) => t.authorId.equals(targetId),
        ),
        protocol.UserAchievement.db.count(
          session,
          where: (t) =>
              t.userId.equals(targetId) & t.unlockedAt.notEquals(null),
        ),
        GamificationService.getUserAchievementViews(session, targetId),
      ]);

      final recentMomentsFuture = protocol.Moment.db.find(
        session,
        where: (t) => t.authorId.equals(targetId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 6,
      );

      final results = await Future.wait([
        statsFuture,
        recentMomentsFuture,
      ]);

      final stats = results[0] as List<dynamic>;
      final recentMoments = results[1] as List<protocol.Moment>;
      final allAchievements = stats[3] as List<protocol.UserAchievementView>;

      // Get top 3 unlocked achievements (newest first) for quick view
      final unlockedAchievements = allAchievements
          .where((a) => a.unlocked)
          .toList();

      // Sort by unlockedAt descending
      unlockedAchievements.sort((a, b) {
        if (a.unlockedAt == null && b.unlockedAt == null) return 0;
        if (a.unlockedAt == null) return 1;
        if (b.unlockedAt == null) return -1;
        return b.unlockedAt!.compareTo(a.unlockedAt!);
      });

      final topAchievements = unlockedAchievements.take(3).toList();

      profile = protocol.UserProfileView(
        userId: targetId,
        userName: resident.userName ?? 'Resident',
        userAvatar: resident.customAvatarUrl ?? resident.avatar ?? '👤',
        userMood: resident.mood,
        floor: ApartmentService.computeEffectiveFloor(resident),
        trustScore: resident.trustScore,
        level: resident.level,
        xp: resident.xp,
        totalMessages: stats[0] as int,
        totalMoments: stats[1] as int,
        achievementsUnlocked: stats[2] as int,
        currentStreak: resident.currentStreak,
        longestStreak: resident.longestStreak,
        isBlocked: false, // Default for cache
        hasBlockedMe: false, // Default for cache
        isLiked: false, // Default for cache
        mutualLounges: 0, // Default for cache
        recentMoments: recentMoments,
        interests: resident.interests,
        languages: resident.languages,
        gender: resident.gender,
        country: resident.country,
        bio: resident.bio,
        ageRange: resident.ageRange,
        lastSeen: resident.lastSeen,
        isOnline:
            false, // Default to false, handled by supplement if viewer exists
        isPremium: resident.isPremium,
        role: resident.role,
        topAchievements: topAchievements,
      );

      // Cache for 2 minutes
      try {
        await session.caches.global.put(
          baseCacheKey,
          profile,
          lifetime: const Duration(minutes: 2),
        );
      } catch (_) {}
    }

    // 2. Supplement with viewer-specific state (NOT CACHED globally)
    if (viewerId != null) {
      return await _supplementProfileWithSocialState(
        session,
        profile,
        viewerId,
        targetId,
      );
    }

    return profile;
  }

  /// Supplements a profile view with data specific to the viewer (blocking, mutual lounges, etc).
  static Future<protocol.UserProfileView> _supplementProfileWithSocialState(
    Session session,
    protocol.UserProfileView profile,
    UuidValue viewerId,
    UuidValue targetId,
  ) async {
    // 1. Concurrent Fetching of basic social state
    final results = await Future.wait([
      ResidentService.isBlocked(
        session,
        blockerId: viewerId,
        blockedId: targetId,
      ),
      ResidentService.isBlocked(
        session,
        blockerId: targetId,
        blockedId: viewerId,
      ),
      protocol.UserLike.db.findFirstRow(
        session,
        where: (t) =>
            t.senderId.equals(viewerId) & t.receiverId.equals(targetId),
      ),
      // Fetch viewer's joined channel IDs to find mutuals
      protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.userInfoId.equals(viewerId) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      ),
    ]);

    final isBlocked = results[0] as bool;
    final hasBlockedMe = results[1] as bool;
    final isLiked = results[2] != null;
    final viewerMemberships = results[3] as List<protocol.ChannelMember>;
    final viewerChannelIds = viewerMemberships.map((m) => m.channelId).toSet();

    // 2. Optimized Mutual Lounges Count (Single targeted query)
    int mutualLoungesCount = 0;
    if (viewerChannelIds.isNotEmpty) {
      mutualLoungesCount = await protocol.ChannelMember.db.count(
        session,
        where: (t) =>
            t.userInfoId.equals(targetId) &
            t.channelId.inSet(viewerChannelIds) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      );
    }

    // 3. Online Status (Gated)
    final viewerResident = await getResident(session, viewerId);
    final canSeeOnline =
        viewerResident != null && canSeeOthersOnlineStatus(viewerResident);
    final targetResident = await getResident(session, targetId);
    final isOnline =
        canSeeOnline &&
        targetResident != null &&
        isResidentOnline(targetResident);

    return profile.copyWith(
      isBlocked: isBlocked,
      hasBlockedMe: hasBlockedMe,
      isLiked: isLiked,
      mutualLounges: mutualLoungesCount,
      isOnline: isOnline,
      lastSeen: canSeeOnline ? profile.lastSeen : null,
    );
  }

  /// Converts a Resident to an AdminUserSummary (for staff views).
  static protocol.AdminUserSummary toAdminUserSummary(
    protocol.Resident resident, {
    int? messageCount,
    int? momentCount,
    int? reportCount,
  }) {
    return protocol.AdminUserSummary(
      userId: resident.userInfoId,
      userName: resident.userName,
      floor: ApartmentService.computeEffectiveFloor(resident),
      trustScore: resident.trustScore,
      level: resident.level,
      xp: resident.xp,
      role: resident.role,
      suspended: resident.suspended,
      messageCount: messageCount ?? 0,
      momentCount: momentCount ?? 0,
      reportCount: reportCount ?? 0,
      createdAt: resident.createdAt,
      lastSeen: resident.lastSeen,
    );
  }

  /// Unregisters a device token.
  static Future<void> unregisterDeviceToken(
    Session session,
    String token,
  ) async {
    final existing = await protocol.DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.token.equals(token),
    );

    if (existing != null) {
      await protocol.DeviceToken.db.deleteRow(session, existing);
    }
  }

  /// Vouches for a resident, increasing their trust score and awarding XP.
  static Future<Map<String, Map<String, int>>> getBatchUserCounts(
    Session session,
    List<UuidValue> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final result = <String, Map<String, int>>{};
    for (final id in userIds) {
      result[id.toString()] = {
        'messages': 0,
        'moments': 0,
        'reports': 0,
      };
    }

    try {
      final userUuids = userIds.map((u) => u.uuid).toList();

      // 1. Message counts
      final messageCounts = await session.db.unsafeQuery(
        'SELECT "senderId", count(*) as count FROM message WHERE "senderId" = ANY(@userIds) GROUP BY "senderId"',
        parameters: QueryParameters.named({
          'userIds': userUuids,
        }),
      );
      for (final row in messageCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['messages'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 2. Moment counts
      final momentCounts = await session.db.unsafeQuery(
        'SELECT "authorId", count(*) as count FROM moment WHERE "authorId" = ANY(@userIds) GROUP BY "authorId"',
        parameters: QueryParameters.named({
          'userIds': userUuids,
        }),
      );
      for (final row in momentCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['moments'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 3. Report counts (against the user)
      final reportCounts = await session.db.unsafeQuery(
        'SELECT "targetId", count(*) as count FROM report WHERE "targetId" = ANY(@userIds) GROUP BY "targetId"',
        parameters: QueryParameters.named({
          'userIds': userUuids,
        }),
      );
      for (final row in reportCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['reports'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }
    } catch (e) {
      session.log('Error in getBatchUserCounts: $e', level: LogLevel.error);
    }

    return result;
  }

  /// Vouch for another resident (Like).
  /// This increases their trust score and awards XP.
  static Future<void> vouchForResident(
    Session session, {
    required UuidValue targetId,
    required protocol.Resident sender,
  }) async {
    final senderId = sender.userInfoId;
    if (targetId == senderId) {
      throw protocol.TalktiveException(
        message: 'You cannot vouch for yourself.',
      );
    }

    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.receiverId.equals(targetId) & t.senderId.equals(senderId),
    );

    if (existingLike != null) {
      throw protocol.TalktiveException(
        message: 'You already vouched for this resident.',
      );
    }

    final target = await getResident(session, targetId);
    if (target == null) {
      throw protocol.TalktiveException(message: 'Resident not found.');
    }

    // 1. Core State Update (Atomic)
    await protocol.UserLike.db.insertRow(
      session,
      protocol.UserLike(
        receiverId: targetId,
        senderId: senderId,
        createdAt: DateTime.now(),
      ),
    );

    // Trust Score Increase & XP Reward
    ApartmentService.awardVouch(target: target);
    await GamificationService.awardXP(
      session,
      target,
      GamificationService.xpUserVouch,
      'Vouched by another resident',
      save: false,
    );

    // Update persistent state
    await updateResident(session, target);

    // 2. Side Effects (Background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      try {
        await NotificationService.sendVouchNotification(
          backgroundSession,
          targetId,
          sender.userName ?? 'A resident',
        );
      } catch (e) {
        backgroundSession.log('Failed to send vouch notification: $e');
      }
    });
  }

  /// Remove a vouch for another resident (Unlike).
  static Future<void> removeResidentVouch(
    Session session, {
    required UuidValue targetId,
    required UuidValue senderId,
  }) async {
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.receiverId.equals(targetId) & t.senderId.equals(senderId),
    );

    if (existingLike == null) return;

    final target = await getResident(session, targetId);
    if (target == null) return;

    // 1. Core State Update
    await protocol.UserLike.db.deleteRow(session, existingLike);

    ApartmentService.removeVouch(target: target);
    await updateResident(session, target);
  }

  /// Blocks or unblocks a resident.
  static Future<void> setBlockStatus(
    Session session, {
    required UuidValue blockerId,
    required UuidValue targetId,
    required bool block,
  }) async {
    final existing = await protocol.Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(blockerId) & t.blockedId.equals(targetId),
    );

    if (block) {
      if (existing != null) return;
      await protocol.Block.db.insertRow(
        session,
        protocol.Block(
          blockerId: blockerId,
          blockedId: targetId,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      if (existing == null) return;
      await protocol.Block.db.deleteRow(session, existing);
    }
  }

  /// Checks if a resident is a paid member.
  static bool isPaidMember(protocol.Resident resident) => resident.isPremium;

  /// Checks if a resident is within the 14-day data retention grace period.
  static bool isWithinGracePeriod(protocol.Resident resident) {
    if (isPlusMember(resident)) return true;

    // Check if within 14 days after trial expired
    if (resident.premiumTrialExpires != null) {
      final now = DateTime.now();
      final graceExpiry = resident.premiumTrialExpires!.add(
        const Duration(days: 14),
      );
      return now.isBefore(graceExpiry);
    }

    return false;
  }

  /// Applies default settings based on the user's tier.
  static void applyTierDefaults(protocol.Resident resident) {
    if (isPaidMember(resident)) {
      _enableAllPlusSettings(resident);
      resident.hideAds = true;
    } else if (isPlusMember(resident)) {
      // Trial members
      _enableAllPlusSettings(resident);
      resident.hideAds = false; // Ads still shown on trial
    } else {
      // Regular members
      _disableExpiredPlusSettings(resident);
    }
  }

  /// Helper to check if a resident is a Plus member (either paid or trial).
  static bool isPlusMember(protocol.Resident resident) {
    if (isPaidMember(resident)) return true;
    if (resident.premiumTrialExpires != null &&
        resident.premiumTrialExpires!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  static bool canUploadCustomAvatar(protocol.Resident resident) =>
      isPlusMember(resident);

  static bool canSeeCustomAvatars(protocol.Resident viewer) =>
      !isPlusMember(viewer) || viewer.showCustomAvatar;

  static bool canUseVoiceMessages(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showVoiceMessages);

  static bool canUseAdvancedDiscovery(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showAdvancedDiscovery);

  static bool canSeeOthersOnlineStatus(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showOthersOnlineStatus);

  static bool canSeeOthersReadReceipts(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showOthersReadReceipts);

  static bool canSeeOthersTypingIndicators(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showOthersTypingIndicators);

  static bool canKeepPrivateChats(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.keepPrivateChats);

  static bool _hasEnabledPlusSetting(
    protocol.Resident resident,
    bool enabled,
  ) => isPlusMember(resident) && enabled;

  static void _enableAllPlusSettings(protocol.Resident resident) {
    resident.showAdvancedDiscovery = true;
    resident.showCustomAvatar = true;
    resident.showVoiceMessages = true;
    resident.showOthersOnlineStatus = true;
    resident.showOthersReadReceipts = true;
    resident.showOthersTypingIndicators = true;
    resident.keepPrivateChats = true;
  }

  static void _disableExpiredPlusSettings(protocol.Resident resident) {
    resident.hideAds = false;
    resident.keepPrivateChats = false;
    resident.showCustomAvatar = false;
    resident.showVoiceMessages = false;
    resident.showAdvancedDiscovery = false;
  }

  /// Updates privacy settings for a resident.
  /// Updates specific fields of a resident profile.
  /// Handles name sync with Auth and avatar cleanup.
  static Future<protocol.Resident> updateResidentFields(
    Session session, {
    required protocol.Resident resident,
    String? name,
    String? avatar,
    String? gender,
    String? country,
    String? bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
  }) async {
    if (name != null && name != resident.userName) {
      await syncAuthProfile(session, resident.userInfoId, name);
      resident.userName = name;
    }

    if (avatar != null) resident.avatar = avatar;
    if (gender != null) resident.gender = gender;
    if (country != null) resident.country = country;
    if (bio != null) resident.bio = bio;
    if (ageRange != null) resident.ageRange = ageRange;
    if (mood != null) resident.mood = mood;
    if (interests != null) resident.interests = interests;
    if (languages != null) resident.languages = languages;

    if (customAvatarUrl != null ||
        (customAvatarUrl == null && resident.customAvatarUrl != null)) {
      // If setting to null or a different URL, service handles cleanup internally.
      resident.customAvatarUrl = customAvatarUrl;
    }

    return await updateResident(session, resident);
  }

  /// Updates a resident's privacy settings based on their Plus status.
  static Future<protocol.Resident> updatePrivacy(
    Session session, {
    required protocol.Resident resident,
    bool? hideAds,
    bool? allowPushNotifications,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
  }) async {
    final bool isPaid = isPaidMember(resident);

    final bool oldKeepPrivateChats = resident.keepPrivateChats;

    // hideAds is specifically Paid-only (Trial does not count)
    if (hideAds != null && isPaid) {
      resident.hideAds = hideAds;
    }

    if (allowPushNotifications != null) {
      resident.allowPushNotifications = allowPushNotifications;
    }

    _setPlusToggles(resident, {
      'showVoiceMessages': showVoiceMessages,
      'showAdvancedDiscovery': showAdvancedDiscovery,
      'showCustomAvatar': showCustomAvatar,
      'showOthersOnlineStatus': showOthersOnlineStatus,
      'showOthersReadReceipts': showOthersReadReceipts,
      'showOthersTypingIndicators': showOthersTypingIndicators,
      'keepPrivateChats': keepPrivateChats,
    });

    final updatedResident = await updateResident(session, resident);

    // If transitioned from true to false, unkeep all private chats for this user.
    if (oldKeepPrivateChats && updatedResident.keepPrivateChats == false) {
      await _unkeepAllPrivateChats(session, updatedResident.userInfoId);
    }

    return updatedResident;
  }

  /// Batch updates Plus-only settings if the resident has Plus status.
  static void _setPlusToggles(
    protocol.Resident resident,
    Map<String, bool?> toggles,
  ) {
    if (!isPlusMember(resident)) return;

    toggles.forEach((key, value) {
      if (value == null) return;

      switch (key) {
        case 'showVoiceMessages':
          resident.showVoiceMessages = value;
        case 'showAdvancedDiscovery':
          resident.showAdvancedDiscovery = value;
        case 'showCustomAvatar':
          resident.showCustomAvatar = value;
        case 'showOthersOnlineStatus':
          resident.showOthersOnlineStatus = value;
        case 'showOthersReadReceipts':
          resident.showOthersReadReceipts = value;
        case 'showOthersTypingIndicators':
          resident.showOthersTypingIndicators = value;
        case 'keepPrivateChats':
          resident.keepPrivateChats = value;
      }
    });
  }

  /// Activates a premium trial for a user.
  static Future<protocol.Resident> activatePremiumTrial(
    Session session,
    UuidValue userId,
    Duration duration,
  ) async {
    final resident = await getResident(session, userId);
    if (resident == null) {
      throw protocol.TalktiveException(message: 'Resident not found');
    }

    // Set trial expiration and increment count
    resident.premiumTrialExpires = DateTime.now().add(duration);
    resident.trialCount += 1;
    _enableAllPlusSettings(resident);

    return await updateResident(session, resident);
  }

  /// Updates a user's premium status and cleans up premium settings if disabled.
  static Future<protocol.Resident> setPremiumStatus(
    Session session,
    UuidValue userId,
    bool isPremium,
  ) async {
    final resident = await getResident(session, userId);
    if (resident == null) {
      throw protocol.TalktiveException(message: 'Resident not found');
    }

    resident.isPremium = isPremium;

    if (isPremium) {
      // Clear trial once they pay
      resident.premiumTrialExpires = null;
      _enableAllPlusSettings(resident);
    } else {
      // When subscription ends, we don't disable settings immediately.
      // We rely on isPlusMember and isWithinGracePeriod in the respective feature checks.
      // The background cleanup task in ContentEphemeralityService will handle the actual deletion after 14 days.

      // We still update the resident record
    }

    return await updateResident(session, resident);
  }

  /// Removes persistence for all private channels where the user is a member.
  static Future<void> _unkeepAllPrivateChats(
    Session session,
    UuidValue userId,
  ) async {
    try {
      // 1. Find all channel IDs where the user is a member
      final memberOf = await protocol.ChannelMember.db.find(
        session,
        where: (t) => t.userInfoId.equals(userId),
      );

      final channelIds = memberOf.map((m) => m.channelId).toSet();
      if (channelIds.isEmpty) return;

      // 2. Find private channels that are currently persistent
      final privateChannels = await protocol.Channel.db.find(
        session,
        where: (t) =>
            t.id.inSet(channelIds) &
            t.type.equals(protocol.ChannelType.private) &
            t.isPersistent.equals(true),
      );

      if (privateChannels.isEmpty) return;

      // 3. Clear isPersistent flag for those channels
      for (final channel in privateChannels) {
        channel.isPersistent = false;
        await protocol.Channel.db.updateRow(session, channel);
      }
    } catch (e) {
      session.log(
        'Failed to unkeep private chats for $userId: $e',
        level: LogLevel.error,
      );
    }
  }
}
