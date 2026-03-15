// ignore_for_file: constant_identifier_names
import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'apartment_service.dart';
import 'notification_service.dart';

/// Gamification Service
/// Handles XP, levels, streaks, achievements, and daily rewards.
class GamificationService {
  // XP Awards
  static const int XP_PER_MESSAGE = 10;
  static const int XP_PER_MOMENT = 20;
  static const int XP_PER_COMMENT = 5;
  static const int XP_PER_LIKE = 2;
  static const int XP_PER_LOGIN = 5;
  static const int XP_USER_VOUCH = 20; // Reward for the publisher when liked

  // Streak Rewards
  static const int XP_STREAK_3_DAYS = 50;
  static const int XP_STREAK_7_DAYS = 100;
  static const int XP_STREAK_30_DAYS = 500;

  /// Award XP to a resident and update their level/floor
  static Future<bool> awardXP(
    Session session,
    Resident resident,
    int xp,
    String reason, {
    bool save = true,
  }) async {
    final oldLevel = resident.level;

    // Add XP
    resident.xp += xp;

    // Calculate new Base Floor (exponential curve up to 50)
    resident.level = computeBaseFloor(resident.xp);

    // Save if required
    if (save) {
      await Resident.db.updateRow(session, resident);
    }

    // Log level up
    if (resident.level > oldLevel) {
      session.log(
        'User ${resident.userInfoId} leveled up to ${resident.level}! Reason: $reason',
      );
    }

    return true; // Returns true indicating changes were made
  }

  /// Fetch all residents starting with top XP
  static Future<List<Resident>> getLeaderboard(
    Session session, {
    int limit = 100,
  }) async {
    return await Resident.db.find(
      session,
      limit: limit,
      orderByList: (t) => [
        Order(column: t.xp, orderDescending: true),
      ],
    );
  }

  /// Calculates the raw BaseFloor from an XP amount using an exponential curve.
  /// Formula: floor(sqrt(xp / 50)) + 1
  /// Max is 50.
  static int computeBaseFloor(int xp) {
    if (xp <= 0) return 1;
    final floor = (sqrt(xp / 50.0)).floor() + 1;
    return min(floor, 50);
  }

  /// Check and award daily login bonus. Returns true if changes were made to resident.
  static Future<bool> checkDailyLogin(
    Session session,
    Resident resident, {
    bool save = true,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = resident.lastLoginDate;

    if (lastLogin == null || lastLogin.isBefore(today)) {
      // Award login bonus (don't save yet, we batch it)
      await awardXP(
        session,
        resident,
        XP_PER_LOGIN,
        'Daily login',
        save: false,
      );

      // Update login date
      resident.lastLoginDate = now;

      // Update streak (don't save yet)
      await updateLoginStreak(
        session,
        resident,
        lastLogin,
        today,
        save: false,
      );

      if (save) {
        await Resident.db.updateRow(session, resident);
      }
      return true;
    }
    return false;
  }

  /// Update login streak
  static Future<void> updateLoginStreak(
    Session session,
    Resident resident,
    DateTime? lastLogin,
    DateTime today, {
    bool save = true,
  }) async {
    if (lastLogin == null) {
      // First login
      resident.currentStreak = 1;
      resident.longestStreak = 1;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      final lastLoginDay = DateTime(
        lastLogin.year,
        lastLogin.month,
        lastLogin.day,
      );

      if (lastLoginDay == yesterday) {
        // Consecutive day
        resident.currentStreak += 1;

        // Update longest streak
        if (resident.currentStreak > resident.longestStreak) {
          resident.longestStreak = resident.currentStreak;
        }

        // Award streak bonuses
        if (resident.currentStreak == 3) {
          await awardXP(
            session,
            resident,
            XP_STREAK_3_DAYS,
            '3-day streak',
            save: false,
          );
        } else if (resident.currentStreak == 7) {
          await awardXP(
            session,
            resident,
            XP_STREAK_7_DAYS,
            '7-day streak',
            save: false,
          );
        } else if (resident.currentStreak == 30) {
          await awardXP(
            session,
            resident,
            XP_STREAK_30_DAYS,
            '30-day streak',
            save: false,
          );
        }
      } else if (lastLoginDay != today) {
        // Streak broken
        resident.currentStreak = 1;
      }
    }

    if (save) {
      await Resident.db.updateRow(session, resident);
    }
  }

  /// Update message streak
  static Future<void> updateMessageStreak(
    Session session,
    Resident resident, {
    bool save = true,
  }) async {
    final now = DateTime.now();
    resident.lastMessageDate = now;
    if (save) {
      await Resident.db.updateRow(session, resident);
    }
  }

  // --- Daily Rewards ---

  /// Checks if user can claim daily reward.
  static Future<bool> canClaimDailyReward(
    Session session,
    UuidValue userId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayReward = await DailyReward.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.claimedDate.equals(today),
    );

    return todayReward == null;
  }

  /// Claims daily reward based on streak.
  static Future<DailyReward> claimDailyReward(
    Session session,
    Resident resident,
  ) async {
    final userId = resident.userInfoId;
    final canClaim = await canClaimDailyReward(session, userId);
    if (!canClaim) {
      throw Exception('Daily reward already claimed today');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ensure streak is up to date
    await checkDailyLogin(session, resident, save: false);

    // Calculate reward based on streak
    // Base reward: 10 credits
    // Bonus: +2 credits per streak day (up to 7 days)
    final bonus = (resident.currentStreak - 1).clamp(0, 6) * 2;
    final rewardAmount = 10 + bonus;

    final reward = DailyReward(
      userId: userId,
      claimedDate: today,
      rewardType: 'credits',
      rewardAmount: rewardAmount,
      streakDay: resident.currentStreak,
    );

    final savedReward = await DailyReward.db.insertRow(session, reward);

    // Award trustScore to resident (daily reward)
    resident.trustScore = (resident.trustScore + rewardAmount).clamp(0, 100);
    await Resident.db.updateRow(session, resident);

    return savedReward;
  }

  // --- Achievements ---

  /// Seeds the database with predefined achievements.
  static Future<void> seedAchievements(Session session) async {
    final achievements = [
      Achievement(
        key: 'first_message',
        name: 'First Steps',
        description: 'Send your first message',
        emoji: '👋',
        category: 'social',
        targetValue: 1,
        points: 10,
      ),
      Achievement(
        key: 'conversationalist',
        name: 'Conversationalist',
        description: 'Send 100 messages',
        emoji: '💬',
        category: 'social',
        targetValue: 100,
        points: 50,
      ),
      Achievement(
        key: 'chatterbox',
        name: 'Chatterbox',
        description: 'Send 1000 messages',
        emoji: '🗣️',
        category: 'social',
        targetValue: 1000,
        points: 200,
      ),
      Achievement(
        key: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Join 5 groups',
        emoji: '🦋',
        category: 'social',
        targetValue: 5,
        points: 30,
      ),
      Achievement(
        key: 'community_builder',
        name: 'Community Builder',
        description: 'Create your first group',
        emoji: '🏗️',
        category: 'social',
        targetValue: 1,
        points: 25,
      ),
      Achievement(
        key: 'private_chat',
        name: 'Making Friends',
        description: 'Start a private chat',
        emoji: '🤝',
        category: 'social',
        targetValue: 1,
        points: 15,
      ),
      Achievement(
        key: 'first_moment',
        name: 'Moment Maker',
        description: 'Post your first moment',
        emoji: '📸',
        category: 'moments',
        targetValue: 1,
        points: 15,
      ),
      Achievement(
        key: 'photographer',
        name: 'Photographer',
        description: 'Post 10 moments',
        emoji: '📷',
        category: 'moments',
        targetValue: 10,
        points: 50,
      ),
      Achievement(
        key: 'influencer',
        name: 'Influencer',
        description: 'Post 50 moments',
        emoji: '⭐',
        category: 'moments',
        targetValue: 50,
        points: 150,
      ),
      Achievement(
        key: 'rising_star',
        name: 'Rising Star',
        description: 'Reach Floor 1',
        emoji: '🌟',
        category: 'progression',
        targetValue: 1,
        points: 20,
      ),
      Achievement(
        key: 'high_rise',
        name: 'High Rise',
        description: 'Reach Floor 2',
        emoji: '🏢',
        category: 'progression',
        targetValue: 2,
        points: 50,
      ),
      Achievement(
        key: 'penthouse',
        name: 'Penthouse',
        description: 'Reach Floor 3',
        emoji: '🏰',
        category: 'progression',
        targetValue: 3,
        points: 100,
      ),
      Achievement(
        key: 'helpful',
        name: 'Helpful',
        description: 'Report 5 violations',
        emoji: '🛡️',
        category: 'behavior',
        targetValue: 5,
        points: 30,
      ),
      Achievement(
        key: 'trusted',
        name: 'Trusted',
        description: 'Maintain 100 credit score for 7 days',
        emoji: '✅',
        category: 'behavior',
        targetValue: 7,
        points: 75,
        isSecret: true,
      ),
      Achievement(
        key: 'night_owl',
        name: 'Night Owl',
        description: 'Send a message at 3 AM',
        emoji: '🦉',
        category: 'special',
        targetValue: 1,
        points: 15,
        isSecret: true,
      ),
      Achievement(
        key: 'early_bird',
        name: 'Early Bird',
        description: 'Send a message at 6 AM',
        emoji: '🐦',
        category: 'special',
        targetValue: 1,
        points: 15,
        isSecret: true,
      ),
    ];

    for (final achievement in achievements) {
      final existing = await Achievement.db.findFirstRow(
        session,
        where: (t) => t.key.equals(achievement.key),
      );

      if (existing == null) {
        await Achievement.db.insertRow(session, achievement);
      }
    }
  }

  /// Tracks progress for a specific achievement.
  static Future<UserAchievement?> trackProgress(
    Session session,
    UuidValue userId,
    String achievementKey, {
    int increment = 1,
  }) async {
    final achievement = await Achievement.db.findFirstRow(
      session,
      where: (t) => t.key.equals(achievementKey),
    );

    if (achievement == null) return null;

    var userAchievement = await UserAchievement.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.achievementId.equals(achievement.id!),
    );

    if (userAchievement == null) {
      userAchievement = UserAchievement(
        userId: userId,
        achievementId: achievement.id!,
        progress: 0,
        unlockedAt: null,
        notified: false,
      );
      userAchievement = await UserAchievement.db.insertRow(
        session,
        userAchievement,
      );
    }

    if (userAchievement.unlockedAt != null) return userAchievement;

    userAchievement.progress += increment;

    if (userAchievement.progress >= achievement.targetValue) {
      userAchievement.unlockedAt = DateTime.now();
      userAchievement.notified = false;

      try {
        await NotificationService.sendAchievementNotification(
          session,
          userId,
          achievement.name ?? achievement.key,
          achievement.emoji ?? '🏆',
          achievement.points,
        );
      } catch (e) {
        session.log('Failed to send achievement notification: $e');
      }
    }

    return await UserAchievement.db.updateRow(session, userAchievement);
  }

  /// Tracks progress for multiple achievements in a single database round-trip.
  static Future<List<UserAchievement>> trackMultipleProgress(
    Session session,
    UuidValue userId,
    List<String> achievementKeys, {
    int increment = 1,
  }) async {
    final result = <UserAchievement>[];
    if (achievementKeys.isEmpty) return result;

    final achievements = await Achievement.db.find(
      session,
      where: (t) => t.key.inSet(achievementKeys.toSet()),
    );

    if (achievements.isEmpty) return result;

    final achievementIds = achievements.map((a) => a.id!).toList();

    final existingProgress = await UserAchievement.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.achievementId.inSet(achievementIds.toSet()),
    );

    final progressMap = {for (var p in existingProgress) p.achievementId: p};
    final now = DateTime.now();

    final toInsert = <UserAchievement>[];
    final toUpdate = <UserAchievement>[];

    for (final achievement in achievements) {
      var userAchievement = progressMap[achievement.id!];

      if (userAchievement == null) {
        userAchievement = UserAchievement(
          userId: userId,
          achievementId: achievement.id!,
          progress: increment,
          unlockedAt: increment >= achievement.targetValue ? now : null,
          notified: false,
        );

        if (userAchievement.unlockedAt != null) {
          try {
            await NotificationService.sendAchievementNotification(
              session,
              userId,
              achievement.name ?? achievement.key,
              achievement.emoji ?? '🏆',
              achievement.points,
            );
          } catch (e) {
            session.log('Failed to send batch achievement notification: $e');
          }
        }

        toInsert.add(userAchievement);
        result.add(userAchievement);
      } else {
        if (userAchievement.unlockedAt != null) {
          result.add(userAchievement);
          continue;
        }

        userAchievement.progress += increment;

        if (userAchievement.progress >= achievement.targetValue) {
          userAchievement.unlockedAt = now;
          userAchievement.notified = false;

          try {
            await NotificationService.sendAchievementNotification(
              session,
              userId,
              achievement.name ?? achievement.key,
              achievement.emoji ?? '🏆',
              achievement.points,
            );
          } catch (e) {
            session.log('Failed to send batch achievement notification: $e');
          }
        }

        toUpdate.add(userAchievement);
        result.add(userAchievement);
      }
    }

    if (toInsert.isNotEmpty) await UserAchievement.db.insert(session, toInsert);
    if (toUpdate.isNotEmpty) await UserAchievement.db.update(session, toUpdate);

    return result;
  }

  /// Checks and awards floor-based achievements.
  static Future<void> checkFloorAchievements(
    Session session,
    Resident resident,
  ) async {
    final rep = ApartmentService.computeEffectiveFloor(resident);
    if (rep >= 1) await trackProgress(session, resident.userInfoId, 'rising_star');
    if (rep >= 2) await trackProgress(session, resident.userInfoId, 'high_rise');
    if (rep >= 3) await trackProgress(session, resident.userInfoId, 'penthouse');
  }

  /// Checks time-based achievements.
  static Future<void> checkTimeBasedAchievements(
    Session session,
    UuidValue userId,
  ) async {
    final hour = DateTime.now().hour;
    if (hour == 3) await trackProgress(session, userId, 'night_owl');
    if (hour == 6) await trackProgress(session, userId, 'early_bird');
  }

  /// Gets all achievements with user progress.
  static Future<List<Map<String, dynamic>>> getUserAchievements(
    Session session,
    UuidValue userId,
  ) async {
    final achievements = await Achievement.db.find(session);
    final userAchievements = await UserAchievement.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final result = <Map<String, dynamic>>[];

    for (final achievement in achievements) {
      final userAchievement = userAchievements.firstWhere(
        (ua) => ua.achievementId == achievement.id,
        orElse: () => UserAchievement(
          userId: userId,
          achievementId: achievement.id!,
          progress: 0,
          notified: false,
        ),
      );

      result.add({
        'achievement': achievement,
        'progress': userAchievement.progress,
        'unlocked': userAchievement.unlockedAt != null,
        'unlockedAt': userAchievement.unlockedAt,
        'isNew': userAchievement.unlockedAt != null && !userAchievement.notified,
      });
    }

    return result;
  }

  /// Marks achievements as notified.
  static Future<void> markAsNotified(
    Session session,
    UuidValue userId,
    List<int> achievementIds,
  ) async {
    for (final achievementId in achievementIds) {
      final userAchievement = await UserAchievement.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(userId) & t.achievementId.equals(achievementId),
      );

      if (userAchievement != null && !userAchievement.notified) {
        userAchievement.notified = true;
        await UserAchievement.db.updateRow(session, userAchievement);
      }
    }
  }

  /// Get XP required to reach a specific Base Floor.
  /// Formula: 50 * (floor - 1)^2
  static int xpForBaseFloor(int floor) {
    if (floor <= 1) return 0;
    return 50 * pow((floor - 1), 2).toInt();
  }

  /// Get progress to next floor (0.0 to 1.0)
  static double levelProgress(Resident resident) {
    if (resident.level >= 50) return 1.0;
    final currentFloorXP = xpForBaseFloor(resident.level);
    final nextFloorXP = xpForBaseFloor(resident.level + 1);
    final xpInCurrentFloor = resident.xp - currentFloorXP;
    final totalFloorXP = nextFloorXP - currentFloorXP;
    if (totalFloorXP <= 0) return 0.0;
    return xpInCurrentFloor / totalFloorXP;
  }
}
