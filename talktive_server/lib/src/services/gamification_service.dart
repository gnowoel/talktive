import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Gamification Service
/// Handles XP, levels, streaks, and daily rewards
class GamificationService {
  // XP Awards
  static const int XP_PER_MESSAGE = 10;
  static const int XP_PER_MOMENT = 20;
  static const int XP_PER_COMMENT = 5;
  static const int XP_PER_LIKE = 2;
  static const int XP_PER_LOGIN = 5;
  static const int XP_PER_LEVEL = 100;

  // Streak Rewards
  static const int XP_STREAK_3_DAYS = 50;
  static const int XP_STREAK_7_DAYS = 100;
  static const int XP_STREAK_30_DAYS = 500;

  /// Award XP to a resident and update their level/floor
  static Future<void> awardXP(
    Session session,
    Resident resident,
    int xp,
    String reason,
  ) async {
    final oldLevel = resident.level;

    // Add XP
    resident.xp += xp;

    // Calculate new level (floor(xp / 100))
    resident.level = (resident.xp / XP_PER_LEVEL).floor();

    // NOTE: effective floor is computed dynamically via
    // ApartmentService.computeReputation() and is NOT stored.
    // Save
    await Resident.db.updateRow(session, resident);

    // Log level up
    if (resident.level > oldLevel) {
      session.log(
        'User ${resident.userInfoId} leveled up to ${resident.level}! Reason: $reason',
      );
    }
  }

  /// Check and award daily login bonus
  static Future<void> checkDailyLogin(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = resident.lastLoginDate;

    if (lastLogin == null || lastLogin.isBefore(today)) {
      // Award login bonus
      await awardXP(session, resident, XP_PER_LOGIN, 'Daily login');

      // Update login date
      resident.lastLoginDate = now;

      // Update streak
      await _updateLoginStreak(session, resident, lastLogin, today);

      await Resident.db.updateRow(session, resident);
    }
  }

  /// Update login streak
  static Future<void> _updateLoginStreak(
    Session session,
    Resident resident,
    DateTime? lastLogin,
    DateTime today,
  ) async {
    if (lastLogin == null) {
      // First login
      resident.currentStreak = 1;
      resident.longestStreak = 1;
      return;
    }

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
        await awardXP(session, resident, XP_STREAK_3_DAYS, '3-day streak');
      } else if (resident.currentStreak == 7) {
        await awardXP(session, resident, XP_STREAK_7_DAYS, '7-day streak');
      } else if (resident.currentStreak == 30) {
        await awardXP(session, resident, XP_STREAK_30_DAYS, '30-day streak');
      }
    } else if (lastLoginDay != today) {
      // Streak broken
      resident.currentStreak = 1;
    }
  }

  /// Update message streak
  static Future<void> updateMessageStreak(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    resident.lastMessageDate = now;
    await Resident.db.updateRow(session, resident);
    // Could add message-specific streak logic here if desired
  }

  /// Check if user has reached a level milestone
  static bool isLevelMilestone(int level) {
    return level % 5 == 0; // Every 5 levels
  }

  /// Get XP needed for next level
  static int xpForNextLevel(Resident resident) {
    final nextLevel = resident.level + 1;
    return (nextLevel * XP_PER_LEVEL) - resident.xp;
  }

  /// Get progress to next level (0.0 to 1.0)
  static double levelProgress(Resident resident) {
    final currentLevelXP = resident.level * XP_PER_LEVEL;
    final xpInCurrentLevel = resident.xp - currentLevelXP;
    return xpInCurrentLevel / XP_PER_LEVEL;
  }
}
