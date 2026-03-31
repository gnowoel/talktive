import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/notification_service.dart';
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../utils/task_utils.dart';

/// Service for managing Resident profiles and synchronization with AuthUser.
class ResidentService {
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
      protocol.Resident? cached = await session.caches.local.get<protocol.Resident>(key);
      
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
    final residentsFromDb = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(missingIds.toSet()),
    );

    for (final resident in residentsFromDb) {
      result.add(resident);
      final key = cacheKeyMap[resident.userInfoId]!;
      await session.caches.local.put(key, resident, lifetime: const Duration(minutes: 5));
      try {
        await session.caches.global.put(key, resident, lifetime: const Duration(minutes: 5));
      } catch (_) {}
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

    await ensureActiveState(session, resident);
    return resident;
  }

  /// Invalidates the cache for a specific resident across all tiers (Local & Global).
  static Future<void> invalidateResidentCache(
    Session session,
    UuidValue userId,
  ) async {
    final residentKey = 'resident_$userId';
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
    final updated = await protocol.Resident.db.updateRow(session, resident);

    // Invalidate caches including Derived Profile View
    await invalidateResidentCache(session, resident.userInfoId);

    // Sync primary resident object back to caches
    final cacheKey = 'resident_${resident.userInfoId}';
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
      xp: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      trustScore: ApartmentService.TRUST_SCORE_START,
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
      role: protocol.ResidentRole.user,
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
    final canSeeOnline = viewer != null && canSeeOthersOnlineStatus(viewer);

    return protocol.UserSummary(
      userId: resident.userInfoId,
      userName: resident.userName,
      userAvatar: resident.customAvatarUrl ?? resident.avatar,
      userMood: resident.mood,
      floor: ApartmentService.computeEffectiveFloor(resident),
      trustScore: resident.trustScore,
      sharedInterests: sharedInterests,
      sharedLanguages: sharedLanguages,
      matchScore: matchScore,
      ageRange: resident.ageRange,
      isOnline: canSeeOnline ? isResidentOnline(resident) : false,
      role: resident.role,
    );
  }

  /// Returns a gated copy of the resident based on the viewer's permissions.
  /// Nulls out sensitive fields like lastSeen if the viewer cannot see them.
  static protocol.Resident gateResident(
    protocol.Resident target, {
    protocol.Resident? viewer,
  }) {
    if (viewer == null || !canSeeOthersOnlineStatus(viewer)) {
      // In Serverpod, we use copyWith to avoid mutating the original object if it's cached
      return target.copyWith(lastSeen: null);
    }
    return target;
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
        isOnline: false, // Default to false, handled by supplement if viewer exists
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
      return await _supplementProfileWithSocialState(session, profile, viewerId, targetId);
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
    final results = await Future.wait([
      ResidentService.isBlocked(session, blockerId: viewerId, blockedId: targetId),
      ResidentService.isBlocked(session, blockerId: targetId, blockedId: viewerId),
      protocol.UserLike.db.findFirstRow(
        session,
        where: (t) => t.senderId.equals(viewerId) & t.receiverId.equals(targetId),
      ),
      protocol.ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(viewerId)),
      protocol.ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(targetId)),
    ]);

    final isBlocked = results[0] as bool;
    final hasBlockedMe = results[1] as bool;
    final isLiked = results[2] != null;

    final viewerLoungeIds = (results[3] as List<protocol.ChannelMember>).map((m) => m.channelId).toSet();
    final targetLoungeIds = (results[4] as List<protocol.ChannelMember>).map((m) => m.channelId).toSet();
    final mutualLoungesCount = viewerLoungeIds.intersection(targetLoungeIds).length;

    final viewerResident = await getResident(session, viewerId);
    final canSeeOnline = viewerResident != null && canSeeOthersOnlineStatus(viewerResident);
    final targetResident = await getResident(session, targetId);
    final isOnline = canSeeOnline && targetResident != null && isResidentOnline(targetResident);

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
      final idList = userIds.map((u) => "'$u'").join(',');

      // 1. Message counts
      final messageCounts = await session.db.unsafeQuery(
        'SELECT "senderId", count(*) as count FROM message WHERE "senderId" IN ($idList) GROUP BY "senderId"',
      );
      for (final row in messageCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['messages'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 2. Moment counts
      final momentCounts = await session.db.unsafeQuery(
        'SELECT "authorId", count(*) as count FROM moment WHERE "authorId" IN ($idList) GROUP BY "authorId"',
      );
      for (final row in momentCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['moments'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 3. Report counts (against the user)
      final reportCounts = await session.db.unsafeQuery(
        'SELECT "targetId", count(*) as count FROM report WHERE "targetId" IN ($idList) GROUP BY "targetId"',
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

  /// Vouches for a resident, increasing their trust score and awarding XP.
  static Future<void> vouchForUser(
    Session session, {
    required protocol.Resident sender,
    required UuidValue targetId,
  }) async {
    final senderId = sender.userInfoId;

    if (senderId == targetId) {
      throw protocol.TalktiveException(
        message: 'You cannot vouch for yourself.',
      );
    }

    final target = await getResident(session, targetId);
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target resident not found');
    }

    // One-Vouch Rule
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(senderId) & t.receiverId.equals(targetId),
    );
    if (existingLike != null) {
      throw protocol.TalktiveException(
        message: 'You have already vouched for this resident.',
      );
    }

    // Blocking Check
    final isBlocked = await ResidentService.isBlocked(
      session,
      blockerId: senderId,
      blockedId: targetId,
    );
    final hasBlockedMe = await ResidentService.isBlocked(
      session,
      blockerId: targetId,
      blockedId: senderId,
    );
    if (isBlocked || hasBlockedMe) {
      throw protocol.TalktiveException(
        message: 'You cannot vouch for this resident due to privacy settings.',
      );
    }

    // Report Check
    final existingReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) => t.reporterId.equals(senderId) & t.targetId.equals(targetId),
    );
    if (existingReport != null) {
      throw protocol.TalktiveException(
        message: 'You cannot vouch for a resident you have reported.',
      );
    }

    await protocol.UserLike.db.insertRow(
      session,
      protocol.UserLike(
        senderId: senderId,
        receiverId: targetId,
        createdAt: DateTime.now(),
      ),
    );

    // Trust Score Increase & XP Reward
    ApartmentService.awardVouch(target: target);
    await GamificationService.awardXP(
      session,
      target,
      GamificationService.XP_USER_VOUCH,
      'Vouched by another resident',
      save: false,
    );
    await updateResident(session, target);

    // Send notification
    try {
      await NotificationService.sendVouchNotification(
        session,
        targetId,
        sender.userName ?? 'A resident',
      );
    } catch (e) {
      session.log('Failed to send vouch notification: $e');
    }
  }

  /// Removes a vouch for a resident.
  static Future<void> removeVouch(
    Session session, {
    required UuidValue senderId,
    required UuidValue targetId,
  }) async {
    final target = await getResident(session, targetId);
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target resident not found');
    }

    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(senderId) & t.receiverId.equals(targetId),
    );
    if (existingLike == null) {
      throw protocol.TalktiveException(message: 'Vouch not found');
    }

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

  /// Helper to check if a resident is a Plus member (either paid or trial).
  static bool isPlusMember(protocol.Resident resident) {
    if (resident.isPremium) return true;
    if (resident.premiumTrialExpires != null &&
        resident.premiumTrialExpires!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  static bool canUseCustomAvatar(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showCustomAvatar);

  static bool canUseVoiceMessages(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showVoiceMessages);

  static bool canUseNeighborDiscovery(protocol.Resident resident) =>
      _hasEnabledPlusSetting(resident, resident.showNeighborsDiscovery);

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

  static void _setPlusSetting(
    bool? value,
    bool isPlus,
    void Function(bool value) apply,
  ) {
    if (value != null && isPlus) {
      apply(value);
    }
  }

  static void _enableAllPlusSettings(protocol.Resident resident) {
    resident.showNeighborsDiscovery = true;
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
    resident.showNeighborsDiscovery = false;
  }

  /// Updates privacy settings for a resident.
  static Future<protocol.Resident> updatePrivacy(
    Session session, {
    required protocol.Resident resident,
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
  }) async {
    final bool isPlus = isPlusMember(resident);

    final bool oldKeepPrivateChats = resident.keepPrivateChats;

    _setPlusSetting(
      hideAds,
      isPlus,
      (value) => resident.hideAds = value,
    );
    _setPlusSetting(
      showVoiceMessages,
      isPlus,
      (value) => resident.showVoiceMessages = value,
    );
    _setPlusSetting(
      showNeighborsDiscovery,
      isPlus,
      (value) => resident.showNeighborsDiscovery = value,
    );
    _setPlusSetting(
      showCustomAvatar,
      isPlus,
      (value) => resident.showCustomAvatar = value,
    );
    _setPlusSetting(
      showOthersOnlineStatus,
      isPlus,
      (value) => resident.showOthersOnlineStatus = value,
    );
    _setPlusSetting(
      showOthersReadReceipts,
      isPlus,
      (value) => resident.showOthersReadReceipts = value,
    );
    _setPlusSetting(
      showOthersTypingIndicators,
      isPlus,
      (value) => resident.showOthersTypingIndicators = value,
    );
    _setPlusSetting(
      keepPrivateChats,
      isPlus,
      (value) => resident.keepPrivateChats = value,
    );

    final updatedResident = await updateResident(session, resident);

    // If transitioned from true to false, unkeep all private chats for this user.
    if (oldKeepPrivateChats && updatedResident.keepPrivateChats == false) {
      await _unkeepAllPrivateChats(session, updatedResident.userInfoId);
    }

    return updatedResident;
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
      // Automatically disable all premium settings if subscription expires/cancels
      // ONLY if they don't have an active trial either
      if (!isPlusMember(resident)) {
        final bool oldKeepPrivateChats = resident.keepPrivateChats;
        _disableExpiredPlusSettings(resident);

        final updated = await updateResident(session, resident);

        // Perform cleanup for kept chats if they were previously enabled
        if (oldKeepPrivateChats) {
          await _unkeepAllPrivateChats(session, userId);
        }
        return updated;
      }
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
