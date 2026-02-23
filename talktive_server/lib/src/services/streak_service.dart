import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

class StreakService {
  /// Updates user streak based on activity.
  /// Call this whenever a user performs a significant action (message, moment, etc.)
  static Future<protocol.UserStreak> updateStreak(
    Session session,
    UuidValue userId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find or create user streak
    var streak = await protocol.UserStreak.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (streak == null) {
      // First time user
      streak = protocol.UserStreak(
        userId: userId,
        currentStreak: 1,
        longestStreak: 1,
        lastActiveDate: today,
        totalActiveDays: 1,
      );
      return await protocol.UserStreak.db.insertRow(session, streak);
    }

    // Check if already active today
    if (streak.lastActiveDate != null) {
      final lastActive = DateTime(
        streak.lastActiveDate!.year,
        streak.lastActiveDate!.month,
        streak.lastActiveDate!.day,
      );

      if (lastActive == today) {
        // Already active today, no update needed
        return streak;
      }

      final daysSinceLastActive = today.difference(lastActive).inDays;

      if (daysSinceLastActive == 1) {
        // Consecutive day - increment streak
        streak.currentStreak += 1;
        streak.totalActiveDays += 1;
        if (streak.currentStreak > streak.longestStreak) {
          streak.longestStreak = streak.currentStreak;
        }
      } else if (daysSinceLastActive > 1) {
        // Streak broken - reset to 1
        streak.currentStreak = 1;
        streak.totalActiveDays += 1;
      }
    } else {
      // No previous activity
      streak.currentStreak = 1;
      streak.totalActiveDays = 1;
    }

    streak.lastActiveDate = today;
    await protocol.UserStreak.db.updateRow(session, streak);

    return streak;
  }

  /// Gets user streak data.
  static Future<protocol.UserStreak?> getUserStreak(
    Session session,
    UuidValue userId,
  ) async {
    return await protocol.UserStreak.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
  }

  /// Checks if user can claim daily reward.
  static Future<bool> canClaimDailyReward(
    Session session,
    UuidValue userId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayReward = await protocol.DailyReward.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.claimedDate.equals(today),
    );

    return todayReward == null;
  }

  /// Claims daily reward based on streak.
  static Future<protocol.DailyReward> claimDailyReward(
    Session session,
    UuidValue userId,
  ) async {
    final canClaim = await canClaimDailyReward(session, userId);
    if (!canClaim) {
      throw Exception('Daily reward already claimed today');
    }

    // Update streak first
    final streak = await updateStreak(session, userId);

    // Calculate reward based on streak
    final rewardAmount = _calculateReward(streak.currentStreak);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final reward = protocol.DailyReward(
      userId: userId,
      claimedDate: today,
      rewardType: 'credits',
      rewardAmount: rewardAmount,
      streakDay: streak.currentStreak,
    );

    final savedReward = await protocol.DailyReward.db.insertRow(
      session,
      reward,
    );

    // Award trustScore to resident (daily reward)
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );

    if (resident != null) {
      resident.trustScore = (resident.trustScore + rewardAmount).clamp(
        0,
        100, // Max trustScore is 100
      );
      await protocol.Resident.db.updateRow(session, resident);
    }

    return savedReward;
  }

  /// Calculates reward amount based on streak day.
  static int _calculateReward(int streakDay) {
    // Base reward: 10 credits
    // Bonus: +2 credits per streak day (up to 7 days)
    // Max: 24 credits at 7+ day streak
    final bonus = (streakDay - 1).clamp(0, 6) * 2;
    return 10 + bonus;
  }

  /// Gets user's reward history.
  static Future<List<protocol.DailyReward>> getRewardHistory(
    Session session,
    UuidValue userId, {
    int limit = 30,
  }) async {
    return await protocol.DailyReward.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.claimedDate,
      orderDescending: true,
      limit: limit,
    );
  }
}
