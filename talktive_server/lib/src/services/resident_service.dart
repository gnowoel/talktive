import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:talktive_server/src/generated/protocol.dart';
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

  /// Creates a new Resident profile and synchronizes it with the AuthUser.
  static Future<Resident> createResident(
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
    final resident = Resident(
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
      role: ResidentRole.user,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isPremium: false,
      customAvatarUrl: customAvatarUrl,
    );

    await Resident.db.insertRow(session, resident);
    return resident;
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

    // Parallelize all data fetching for optimal performance
    final socialStateFuture = viewerId != null
        ? Future.wait([
            ResidentService.isBlocked(session, blockerId: viewerId, blockedId: targetId),
            ResidentService.isBlocked(session, blockerId: targetId, blockedId: viewerId),
            UserLike.db.findFirstRow(session,
                where: (t) => t.senderId.equals(viewerId) & t.receiverId.equals(targetId)),
          ])
        : Future.value([false, false, null]);

    final statsFuture = Future.wait([
      Message.db.count(session, where: (t) => t.senderId.equals(targetId)),
      Moment.db.count(session, where: (t) => t.authorId.equals(targetId)),
      UserAchievement.db.count(session,
          where: (t) => t.userId.equals(targetId) & t.unlockedAt.notEquals(null)),
    ]);

    final recentMomentsFuture = Moment.db.find(
      session,
      where: (t) => t.authorId.equals(targetId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 6,
    );

    final mutualLoungesFuture = viewerId != null
        ? Future.wait([
            ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(viewerId)),
            ChannelMember.db.find(session, where: (t) => t.userInfoId.equals(targetId)),
          ])
        : Future.value([<ChannelMember>[], <ChannelMember>[]]);

    // Await all results
    final results = await Future.wait([
      socialStateFuture,
      statsFuture,
      recentMomentsFuture,
      mutualLoungesFuture,
    ]);

    final socialState = results[0] as List<dynamic>;
    final stats = results[1] as List<int>;
    final recentMoments = results[2] as List<Moment>;
    final loungeMemberships = results[3] as List<List<ChannelMember>>;

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

    return UserProfileView(
      userId: targetId.toString(),
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
      isOnline: resident.showOnlineStatus &&
          resident.lastSeen != null &&
          DateTime.now().difference(resident.lastSeen!).inMinutes < 5,
      role: resident.role,
    );
  }
}
