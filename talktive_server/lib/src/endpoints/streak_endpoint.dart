import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/streak_service.dart';
import '../services/input_validation_service.dart';

class StreakEndpoint extends Endpoint {
  /// Gets the current user's streak data.
  Future<protocol.UserStreak?> getUserStreak(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await StreakService.getUserStreak(session, currentUserId);
  }

  /// Checks if the user can claim today's daily reward.
  Future<bool> canClaimDailyReward(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await StreakService.canClaimDailyReward(session, currentUserId);
  }

  /// Claims the daily reward.
  Future<protocol.DailyReward> claimDailyReward(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await StreakService.claimDailyReward(session, currentUserId);
  }

  /// Gets the user's reward history.
  Future<List<protocol.DailyReward>> getRewardHistory(
    Session session, {
    int limit = 30,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await StreakService.getRewardHistory(
      session,
      currentUserId,
      limit: limit,
    );
  }
}
