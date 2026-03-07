import 'package:serverpod/serverpod.dart';
import '../services/achievement_service.dart';
import '../services/input_validation_service.dart';

class AchievementEndpoint extends Endpoint {
  /// Gets all achievements with user progress.
  Future<List<Map<String, dynamic>>> getUserAchievements(
    Session session,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await AchievementService.getUserAchievements(
      session,
      currentUserId,
    );
  }

  /// Marks achievements as notified (user has seen them).
  Future<void> markAchievementsAsNotified(
    Session session,
    List<int> achievementIds,
  ) async {
    for (final id in achievementIds) {
      InputValidationService.validateId(id, 'Achievement ID').throwIfInvalid();
    }

    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    await AchievementService.markAsNotified(
      session,
      currentUserId,
      achievementIds,
    );
  }

  /// Seeds the database with predefined achievements (admin only).
  Future<void> seedAchievements(Session session) async {
    // In production, add admin check here
    await AchievementService.seedAchievements(session);
  }
}

