import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/gamification_service.dart';
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class GamificationEndpoint extends Endpoint with EndpointAuthMixin {
  /// Gets all achievements with user progress.
  Future<List<Map<String, dynamic>>> getUserAchievements(Session session) async {
    final userId = await getUserId(session);
    return await GamificationService.getUserAchievements(session, userId);
  }

  /// Marks achievements as notified (user has seen them).
  Future<void> markAchievementsAsNotified(
    Session session,
    List<int> achievementIds,
  ) async {
    for (final id in achievementIds) {
      InputValidationService.validateId(id, 'Achievement ID').throwIfInvalid();
    }
    final userId = await getUserId(session);
    await GamificationService.markAsNotified(session, userId, achievementIds);
  }

  /// Gets the current user's resident data (containing streaks).
  Future<Resident> getGamificationData(Session session) async {
    return await getAuthenticatedResident(session);
  }

  /// Checks if the user can claim today's daily reward.
  Future<bool> canClaimDailyReward(Session session) async {
    final userId = await getUserId(session);
    return await GamificationService.canClaimDailyReward(session, userId);
  }

  /// Claims the daily reward.
  Future<DailyReward> claimDailyReward(Session session) async {
    final resident = await getAuthenticatedResident(session);
    return await GamificationService.claimDailyReward(session, resident);
  }

  /// Gets the user's reward history.
  Future<List<DailyReward>> getRewardHistory(
    Session session, {
    int limit = 30,
  }) async {
    InputValidationService.validatePagination(limit: limit, offset: 0).throwIfInvalid();
    final userId = await getUserId(session);
    
    return await DailyReward.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.claimedDate,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Seeds the database with predefined achievements (admin only).
  Future<void> seedAchievements(Session session) async {
    // In production, add admin check here
    await GamificationService.seedAchievements(session);
  }
}
