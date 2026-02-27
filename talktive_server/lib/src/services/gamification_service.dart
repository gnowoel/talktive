// ignore_for_file: constant_identifier_names
import 'dart:math';
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

    // Calculate new Base Floor (exponential curve up to 50)
    resident.level = computeBaseFloor(resident.xp);

    // NOTE: effective floor is computed dynamically via
    // ApartmentService.computeEffectiveFloor() and is NOT stored.
    // Save
    await Resident.db.updateRow(session, resident);

    // Log level up
    if (resident.level > oldLevel) {
      session.log(
        'User ${resident.userInfoId} leveled up to ${resident.level}! Reason: $reason',
      );
    }
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

  /// Get XP required to reach a specific Base Floor.
  /// Formula: 50 * (floor - 1)^2
  static int xpForBaseFloor(int floor) {
    if (floor <= 1) return 0;
    return 50 * pow((floor - 1), 2).toInt();
  }

  /// Get XP needed for next floor
  static int xpForNextLevel(Resident resident) {
    if (resident.level >= 50) return 0;
    final nextFloor = resident.level + 1;
    return xpForBaseFloor(nextFloor) - resident.xp;
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
