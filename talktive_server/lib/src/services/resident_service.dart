import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';
import 'apartment_service.dart';
import 'gamification_service.dart';

/// Service for managing Resident profiles and synchronization with AuthUser.
class ResidentService {
  /// Fetches a Resident by their userInfoId.
  static Future<Resident?> getResident(
    Session session,
    UuidValue userId,
  ) async {
    return await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
  }

  /// Fetches a Resident and performs passive updates (Trust Score, Daily Login).
  static Future<Resident?> getActiveResident(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await getResident(session, userId);
    if (resident == null) return null;

    bool needsSave = false;

    // Passively restore trustScore
    if (await ApartmentService.restoreTrustScore(
      session,
      resident,
      save: false,
    )) {
      needsSave = true;
    }

    // Check daily login
    if (await GamificationService.checkDailyLogin(
      session,
      resident,
      save: false,
    )) {
      needsSave = true;
    }

    // Update lastSeen (Always update when active)
    resident.lastSeen = DateTime.now();
    needsSave = true;

    if (needsSave) {
      await Resident.db.updateRow(session, resident);
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

  /// Checks if a user is blocked by another user.
  static Future<bool> isBlocked(
    Session session, {
    required UuidValue blockerId,
    required UuidValue blockedId,
  }) async {
    final block = await Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(blockerId) & t.blockedId.equals(blockedId),
    );
    return block != null;
  }

  /// Builds a comprehensive UserProfileView for a resident.
  static Future<UserProfileView?> getResidentProfileView(
    Session session,
    UuidValue targetId, {
    UuidValue? viewerId,
  }) async {
    final resident = await getResident(session, targetId);
    if (resident == null) return null;

    final isBlocked = viewerId != null
        ? await ResidentService.isBlocked(session,
            blockerId: viewerId, blockedId: targetId)
        : false;
    final hasBlockedMe = viewerId != null
        ? await ResidentService.isBlocked(session,
            blockerId: targetId, blockedId: viewerId)
        : false;

    final isLiked = viewerId != null
        ? await UserLike.db.findFirstRow(session,
                where: (t) => t.senderId.equals(viewerId) & t.receiverId.equals(targetId)) !=
            null
        : false;

    // Optimized Stats
    // We can run these in parallel if needed, but for now simple queries are fine
    final messageCount = await Message.db.count(
      session,
      where: (t) => t.senderId.equals(targetId),
    );
    final momentCount = await Moment.db.count(
      session,
      where: (t) => t.authorId.equals(targetId),
    );
    final achievements = await UserAchievement.db.count(
      session,
      where: (t) =>
          t.userId.equals(targetId) & t.unlockedAt.notEquals(null),
    );

    // Recent moments
    final recentMoments = await Moment.db.find(
      session,
      where: (t) => t.authorId.equals(targetId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 6,
    );

    // Mutual groups (only if viewer is provided)
    int mutualGroupsCount = 0;
    if (viewerId != null) {
      final viewerGroups = await ChannelMember.db.find(
        session,
        where: (t) => t.userInfoId.equals(viewerId),
      );
      final targetGroups = await ChannelMember.db.find(
        session,
        where: (t) => t.userInfoId.equals(targetId),
      );
      final viewerGroupIds = viewerGroups.map((g) => g.channelId).toSet();
      final targetGroupIds = targetGroups.map((g) => g.channelId).toSet();
      mutualGroupsCount = viewerGroupIds.intersection(targetGroupIds).length;
    }

    return UserProfileView(
      userId: targetId.toString(),
      userName: resident.userName ?? 'Resident',
      userAvatar: resident.avatar ?? '👤',
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
      mutualGroups: mutualGroupsCount,
      recentMoments: recentMoments,
      interests: resident.interests,
      languages: resident.languages,
      gender: resident.gender,
      country: resident.country,
      bio: resident.bio,
      lastSeen: resident.lastSeen,
      isOnline: resident.showOnlineStatus &&
          resident.lastSeen != null &&
          DateTime.now().difference(resident.lastSeen!).inMinutes < 5,
      isAdmin: resident.isAdmin,
      isModerator: resident.isModerator,
    );
  }
}
