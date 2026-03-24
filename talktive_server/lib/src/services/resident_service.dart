import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/notification_service.dart';
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../utils/endpoint_auth_mixin.dart';

/// Service for managing Resident profiles and synchronization with AuthUser.
class ResidentService {
  /// Fetches a Resident by their userInfoId.
  static Future<protocol.Resident?> getResident(
    Session session,
    UuidValue userId,
  ) async {
    return await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
  }

  /// Fetches multiple Residents by their userInfoIds.
  static Future<List<protocol.Resident>> getResidents(
    Session session,
    List<UuidValue> userIds,
  ) async {
    if (userIds.isEmpty) return [];
    return await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(userIds.toSet()),
    );
  }

  /// Fetches a Resident and performs passive updates (Trust Score, Daily Login, lastSeen).
  static Future<protocol.Resident?> getActiveResident(
    Session session,
    UuidValue userInfoId,
  ) async {
    final resident = await getResident(session, userInfoId);
    if (resident == null) return null;

    // Perform passive updates
    await ensureActiveState(session, resident);
    return resident;
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
      await protocol.Resident.db.updateRow(session, resident);
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
      experienceMessageCount: 0,
      userName: name,
      gender: gender,
      country: country,
      bio: bio,
      mood: mood,
      avatar: avatar,
      interests: interests ?? [],
      languages: languages ?? ['en'],
      role: protocol.ResidentRole.user,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isPremium: false,
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
    List<String>? sharedInterests,
    List<String>? sharedLanguages,
    int? matchScore,
    int? messageCount,
  }) {
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
      messageCount: messageCount,
      isOnline: isResidentOnline(resident),
      role: resident.role,
    );
  }

  /// Helper to check if a resident is online based on privacy settings and lastSeen.
  static bool isResidentOnline(protocol.Resident resident) {
    return resident.showOnlineStatus &&
        resident.lastSeen != null &&
        DateTime.now().difference(resident.lastSeen!).inMinutes < 5;
  }

  /// Builds a comprehensive UserProfileView for a resident.
  static Future<protocol.UserProfileView?> getResidentProfileView(
    Session session,
    UuidValue targetId, {
    UuidValue? viewerId,
  }) async {
    final resident = await getResident(session, targetId);
    if (resident == null) return null;

    // Parallelize all data fetching for optimal performance
    final socialStateFuture = viewerId != null
        ? Future.wait([
            ResidentService.isBlocked(session, blockerId: viewerId, blockedId: targetId),
            ResidentService.isBlocked(session, blockerId: targetId, blockedId: viewerId),
            protocol.UserLike.db.findFirstRow(session,
                where: (t) => t.senderId.equals(viewerId) & t.receiverId.equals(targetId)),
          ])
        : Future.value([false, false, null]);

    final statsFuture = Future.wait([
      protocol.Message.db.count(session, where: (t) => t.senderId.equals(targetId)),
      protocol.Moment.db.count(session, where: (t) => t.authorId.equals(targetId)),
      protocol.UserAchievement.db.count(session,
          where: (t) => t.userId.equals(targetId) & t.unlockedAt.notEquals(null)),
    ]);

    final recentMomentsFuture = protocol.Moment.db.find(
      session,
      where: (t) => t.authorId.equals(targetId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 6,
    );

    final mutualLoungesFuture = viewerId != null
        ? Future.wait([
            protocol.ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(viewerId)),
            protocol.ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(targetId)),
          ])
        : Future.value([<protocol.ChannelMember>[], <protocol.ChannelMember>[]]);

    // Await all results
    final results = await Future.wait([
      socialStateFuture,
      statsFuture,
      recentMomentsFuture,
      mutualLoungesFuture,
    ]);

    final socialState = results[0] as List<dynamic>;
    final stats = results[1] as List<int>;
    final recentMoments = results[2] as List<protocol.Moment>;
    final loungeMemberships = results[3] as List<List<protocol.ChannelMember>>;

    final isBlocked = socialState[0] as bool;
    final hasBlockedMe = socialState[1] as bool;
    final isLiked = socialState[2] != null;

    final messageCount = stats[0];
    final momentCount = stats[1];
    final achievements = stats[2];

    int mutualLoungesCount = 0;
    if (viewerId != null) {
      final viewerLoungeIds = loungeMemberships[0].map((g) => g.channelId).toSet();
      final targetLoungeIds = loungeMemberships[1].map((g) => g.channelId).toSet();
      mutualLoungesCount = viewerLoungeIds.intersection(targetLoungeIds).length;
    }

    return protocol.UserProfileView(
      userId: targetId,
      userName: resident.userName ?? 'Resident',
      userAvatar: resident.customAvatarUrl ?? resident.avatar ?? '👤',
      userMood: resident.mood,
      floor: ApartmentService.computeEffectiveFloor(resident),
      trustScore: resident.trustScore,
      level: resident.level,
      xp: resident.xp,
      totalMessages: messageCount,
      totalMoments: momentCount,
      achievementsUnlocked: achievements,
      currentStreak: resident.currentStreak,
      longestStreak: resident.longestStreak,
      isBlocked: isBlocked,
      hasBlockedMe: hasBlockedMe,
      isLiked: isLiked,
      mutualLounges: mutualLoungesCount,
      recentMoments: recentMoments,
      interests: resident.interests,
      languages: resident.languages,
      gender: resident.gender,
      country: resident.country,
      bio: resident.bio,
      lastSeen: resident.lastSeen,
      isOnline: isResidentOnline(resident),
      role: resident.role,
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

  /// Updates a user's suspension status.
  static Future<void> setSuspensionStatus(
    Session session,
    UuidValue userId, {
    required bool suspended,
  }) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.suspended = suspended;
    if (suspended) {
      resident.trustScore = 0;
    } else {
      resident.trustScore = 50; // Restore partial trust
    }
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Sets a user's mute status.
  static Future<void> setMuteStatus(
    Session session,
    UuidValue userId, {
    required DateTime? until,
  }) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.mutedUntil = until;
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Updates a user's role.
  static Future<void> setRole(
    Session session,
    UuidValue userId,
    protocol.ResidentRole role,
  ) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.role = role;
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Resets a user's reputation and clears mutes.
  static Future<void> resetReputation(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.trustScore = 100;
    resident.mutedUntil = null;
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Batch retrieve message, moment, and report counts for multiple users.
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
      throw protocol.TalktiveException(message: 'You cannot vouch for yourself.');
    }

    final target = await getResident(session, targetId);
    if (target == null) throw protocol.TalktiveException(message: 'Target resident not found');

    // One-Vouch Rule
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(senderId) & t.receiverId.equals(targetId),
    );
    if (existingLike != null) throw protocol.TalktiveException(message: 'You have already vouched for this resident.');

    // Blocking Check
    final isBlocked = await ResidentService.isBlocked(session, blockerId: senderId, blockedId: targetId);
    final hasBlockedMe = await ResidentService.isBlocked(session, blockerId: targetId, blockedId: senderId);
    if (isBlocked || hasBlockedMe) {
      throw protocol.TalktiveException(message: 'You cannot vouch for this resident due to privacy settings.');
    }

    // Report Check
    final existingReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) => t.reporterId.equals(senderId) & t.targetId.equals(targetId),
    );
    if (existingReport != null) {
      throw protocol.TalktiveException(message: 'You cannot vouch for a resident you have reported.');
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
    await protocol.Resident.db.updateRow(session, target);

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
    if (target == null) throw protocol.TalktiveException(message: 'Target resident not found');

    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(senderId) & t.receiverId.equals(targetId),
    );
    if (existingLike == null) throw protocol.TalktiveException(message: 'Vouch not found');

    await protocol.UserLike.db.deleteRow(session, existingLike);

    ApartmentService.removeVouch(target: target);
    await protocol.Resident.db.updateRow(session, target);
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
      where: (t) => t.blockerId.equals(blockerId) & t.blockedId.equals(targetId),
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

  /// Updates privacy settings for a resident.
  static Future<protocol.Resident> updatePrivacy(
    Session session, {
    required protocol.Resident resident,
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
  }) async {
    if (showOnlineStatus != null) resident.showOnlineStatus = showOnlineStatus;
    if (showReadReceipts != null) resident.showReadReceipts = showReadReceipts;
    if (showTypingIndicator != null) resident.showTypingIndicator = showTypingIndicator;
    if (showVoiceMessages != null) resident.showVoiceMessages = showVoiceMessages;
    if (showNeighborsDiscovery != null) resident.showNeighborsDiscovery = showNeighborsDiscovery;
    if (showCustomAvatar != null) resident.showCustomAvatar = showCustomAvatar;
    if (showOthersOnlineStatus != null) resident.showOthersOnlineStatus = showOthersOnlineStatus;
    if (showOthersReadReceipts != null) resident.showOthersReadReceipts = showOthersReadReceipts;
    if (showOthersTypingIndicators != null) resident.showOthersTypingIndicators = showOthersTypingIndicators;
    final bool oldKeepPrivateChats = resident.keepPrivateChats;
    if (keepPrivateChats != null) resident.keepPrivateChats = keepPrivateChats;

    final updatedResident = await protocol.Resident.db.updateRow(session, resident);

    // If transitioned from true to false, unkeep all private chats for this user.
    if (oldKeepPrivateChats && updatedResident.keepPrivateChats == false) {
      await _unkeepAllPrivateChats(session, updatedResident.userInfoId);
    }

    return updatedResident;
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

    if (!isPremium) {
      // Automatically disable all premium settings
      final bool oldKeepPrivateChats = resident.keepPrivateChats;
      resident.keepPrivateChats = false;
      resident.showCustomAvatar = false;
      resident.showVoiceMessages = false;
      resident.showNeighborsDiscovery = false;
      // We don't necessarily clear customAvatarUrl, just hide it via showCustomAvatar
      // so they keep it if they resubscribe.

      final updated = await protocol.Resident.db.updateRow(session, resident);

      // Perform cleanup for kept chats if they were previously enabled
      if (oldKeepPrivateChats) {
        await _unkeepAllPrivateChats(session, userId);
      }
      return updated;
    }

    return await protocol.Resident.db.updateRow(session, resident);
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
        where: (t) => t.id.inSet(channelIds) & 
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
      session.log('Failed to unkeep private chats for $userId: $e', level: LogLevel.error);
    }
  }
}
