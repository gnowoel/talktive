import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import 'apartment_service.dart';

/// Service for managing achievements and tracking user progress.
class AchievementService {
  /// Seeds the database with predefined achievements.
  static Future<void> seedAchievements(Session session) async {
    final achievements = [
      // Social Achievements
      protocol.Achievement(
        key: 'first_message',
        name: 'First Steps',
        description: 'Send your first message',
        emoji: '👋',
        category: 'social',
        targetValue: 1,
        points: 10,
      ),
      protocol.Achievement(
        key: 'conversationalist',
        name: 'Conversationalist',
        description: 'Send 100 messages',
        emoji: '💬',
        category: 'social',
        targetValue: 100,
        points: 50,
      ),
      protocol.Achievement(
        key: 'chatterbox',
        name: 'Chatterbox',
        description: 'Send 1000 messages',
        emoji: '🗣️',
        category: 'social',
        targetValue: 1000,
        points: 200,
      ),
      protocol.Achievement(
        key: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Join 5 groups',
        emoji: '🦋',
        category: 'social',
        targetValue: 5,
        points: 30,
      ),
      protocol.Achievement(
        key: 'community_builder',
        name: 'Community Builder',
        description: 'Create your first group',
        emoji: '🏗️',
        category: 'social',
        targetValue: 1,
        points: 25,
      ),
      protocol.Achievement(
        key: 'private_chat',
        name: 'Making Friends',
        description: 'Start a private chat',
        emoji: '🤝',
        category: 'social',
        targetValue: 1,
        points: 15,
      ),

      // Moments Achievements
      protocol.Achievement(
        key: 'first_moment',
        name: 'Moment Maker',
        description: 'Post your first moment',
        emoji: '📸',
        category: 'moments',
        targetValue: 1,
        points: 15,
      ),
      protocol.Achievement(
        key: 'photographer',
        name: 'Photographer',
        description: 'Post 10 moments',
        emoji: '📷',
        category: 'moments',
        targetValue: 10,
        points: 50,
      ),
      protocol.Achievement(
        key: 'influencer',
        name: 'Influencer',
        description: 'Post 50 moments',
        emoji: '⭐',
        category: 'moments',
        targetValue: 50,
        points: 150,
      ),

      // Floor Progression Achievements
      protocol.Achievement(
        key: 'rising_star',
        name: 'Rising Star',
        description: 'Reach Floor 1',
        emoji: '🌟',
        category: 'progression',
        targetValue: 1,
        points: 20,
      ),
      protocol.Achievement(
        key: 'high_rise',
        name: 'High Rise',
        description: 'Reach Floor 2',
        emoji: '🏢',
        category: 'progression',
        targetValue: 2,
        points: 50,
      ),
      protocol.Achievement(
        key: 'penthouse',
        name: 'Penthouse',
        description: 'Reach Floor 3',
        emoji: '🏰',
        category: 'progression',
        targetValue: 3,
        points: 100,
      ),

      // Behavior Achievements
      protocol.Achievement(
        key: 'helpful',
        name: 'Helpful',
        description: 'Report 5 violations',
        emoji: '🛡️',
        category: 'behavior',
        targetValue: 5,
        points: 30,
      ),
      protocol.Achievement(
        key: 'trusted',
        name: 'Trusted',
        description: 'Maintain 100 credit score for 7 days',
        emoji: '✅',
        category: 'behavior',
        targetValue: 7,
        points: 75,
        isSecret: true,
      ),

      // Time-based Achievements
      protocol.Achievement(
        key: 'night_owl',
        name: 'Night Owl',
        description: 'Send a message at 3 AM',
        emoji: '🦉',
        category: 'special',
        targetValue: 1,
        points: 15,
        isSecret: true,
      ),
      protocol.Achievement(
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
      // Check if achievement already exists
      final existing = await protocol.Achievement.db.findFirstRow(
        session,
        where: (t) => t.key.equals(achievement.key),
      );

      if (existing == null) {
        await protocol.Achievement.db.insertRow(session, achievement);
      }
    }
  }

  /// Tracks progress for a specific achievement.
  static Future<protocol.UserAchievement?> trackProgress(
    Session session,
    UuidValue userId,
    String achievementKey, {
    int increment = 1,
  }) async {
    // Get the achievement
    final achievement = await protocol.Achievement.db.findFirstRow(
      session,
      where: (t) => t.key.equals(achievementKey),
    );

    if (achievement == null) {
      return null;
    }

    // Get or create user achievement
    var userAchievement = await protocol.UserAchievement.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.achievementId.equals(achievement.id!),
    );

    if (userAchievement == null) {
      userAchievement = protocol.UserAchievement(
        userId: userId,
        achievementId: achievement.id!,
        progress: 0,
        unlockedAt: null,
        notified: false,
      );
      userAchievement = await protocol.UserAchievement.db.insertRow(
        session,
        userAchievement,
      );
    }

    // Don't update if already unlocked
    if (userAchievement.unlockedAt != null) {
      return userAchievement;
    }

    // Update progress
    userAchievement.progress += increment;

    // Check if unlocked
    if (userAchievement.progress >= achievement.targetValue) {
      userAchievement.unlockedAt = DateTime.now();
      userAchievement.notified = false; // Will be notified on next fetch
    }

    return await protocol.UserAchievement.db.updateRow(
      session,
      userAchievement,
    );
  }

  /// Checks and awards floor-based achievements.
  static Future<void> checkFloorAchievements(
    Session session,
    protocol.Resident resident,
  ) async {
    final rep = ApartmentService.computeEffectiveFloor(resident);
    if (rep >= 1) {
      await trackProgress(session, resident.userInfoId, 'rising_star');
    }
    if (rep >= 2) {
      await trackProgress(session, resident.userInfoId, 'high_rise');
    }
    if (rep >= 3) {
      await trackProgress(session, resident.userInfoId, 'penthouse');
    }
  }

  /// Checks time-based achievements.
  static Future<void> checkTimeBasedAchievements(
    Session session,
    UuidValue userId,
  ) async {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour == 3) {
      await trackProgress(session, userId, 'night_owl');
    }
    if (hour == 6) {
      await trackProgress(session, userId, 'early_bird');
    }
  }

  /// Gets all achievements with user progress.
  static Future<List<Map<String, dynamic>>> getUserAchievements(
    Session session,
    UuidValue userId,
  ) async {
    final achievements = await protocol.Achievement.db.find(session);
    final userAchievements = await protocol.UserAchievement.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final result = <Map<String, dynamic>>[];

    for (final achievement in achievements) {
      final userAchievement = userAchievements.firstWhere(
        (ua) => ua.achievementId == achievement.id,
        orElse: () => protocol.UserAchievement(
          userId: userId,
          achievementId: achievement.id!,
          progress: 0,
          unlockedAt: null,
          notified: false,
        ),
      );

      result.add({
        'achievement': achievement,
        'progress': userAchievement.progress,
        'unlocked': userAchievement.unlockedAt != null,
        'unlockedAt': userAchievement.unlockedAt,
        'isNew':
            userAchievement.unlockedAt != null && !userAchievement.notified,
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
      final userAchievement = await protocol.UserAchievement.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(userId) & t.achievementId.equals(achievementId),
      );

      if (userAchievement != null && !userAchievement.notified) {
        userAchievement.notified = true;
        await protocol.UserAchievement.db.updateRow(session, userAchievement);
      }
    }
  }
}
