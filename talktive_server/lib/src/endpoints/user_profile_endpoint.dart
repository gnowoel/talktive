import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class UserProfileEndpoint extends Endpoint {
  /// Get a user's profile by their user ID
  Future<Map<String, dynamic>?> getUserProfile(
    Session session,
    String userId,
  ) async {
    try {
      // Get the viewing user's ID
      final viewerId = await session.auth.authenticatedUserId;
      if (viewerId == null) {
        throw Exception('Not authenticated');
      }

      // Get the target user's resident data
      final resident = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userId),
      );

      if (resident == null) {
        return null;
      }

      // Get user profile
      final userProfile = await UserProfile.db.findById(session, resident.id);
      if (userProfile == null) {
        return null;
      }

      // Check if blocked
      final isBlocked = await Block.db.findFirstRow(
        session,
        where: (t) => t.blockerId.equals(viewerId) & t.blockedId.equals(userId),
      );

      final hasBlockedMe = await Block.db.findFirstRow(
        session,
        where: (t) => t.blockerId.equals(userId) & t.blockedId.equals(viewerId),
      );

      // Get stats
      final messageCount = await Message.db.count(
        session,
        where: (t) => t.senderId.equals(resident.id),
      );

      final momentCount = await Moment.db.count(
        session,
        where: (t) => t.authorId.equals(resident.id),
      );

      final achievements = await UserAchievement.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.unlockedAt.notEquals(null),
      );

      // Get streak
      final streak = await UserStreak.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userId),
      );

      // Get recent moments
      final recentMoments = await Moment.db.find(
        session,
        where: (t) => t.authorId.equals(resident.id),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 6,
      );

      // Get mutual groups count
      final viewerGroups = await GroupMember.db.find(
        session,
        where: (t) => t.userId.equals(viewerId),
      );

      final targetGroups = await GroupMember.db.find(
        session,
        where: (t) => t.userId.equals(userId),
      );

      final viewerGroupIds = viewerGroups.map((g) => g.groupId).toSet();
      final targetGroupIds = targetGroups.map((g) => g.groupId).toSet();
      final mutualGroups = viewerGroupIds.intersection(targetGroupIds).length;

      return {
        'userId': userId,
        'userName': userProfile.userName,
        'userAvatar': userProfile.userAvatar,
        'floor': resident.floor,
        'creditScore': resident.creditScore,
        'totalMessages': messageCount,
        'totalMoments': momentCount,
        'achievementsUnlocked': achievements.length,
        'currentStreak': streak?.currentStreak ?? 0,
        'longestStreak': streak?.longestStreak ?? 0,
        'isBlocked': isBlocked != null,
        'hasBlockedMe': hasBlockedMe != null,
        'mutualGroups': mutualGroups,
        'recentMoments': recentMoments.map((m) => m.toJson()).toList(),
      };
    } catch (e) {
      session.log('Error getting user profile: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Block a user
  Future<bool> blockUser(Session session, String userId) async {
    try {
      final blockerId = await session.auth.authenticatedUserId;
      if (blockerId == null) {
        throw Exception('Not authenticated');
      }

      // Check if already blocked
      final existing = await Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(userId),
      );

      if (existing != null) {
        return true; // Already blocked
      }

      // Create block
      final block = Block(
        blockerId: blockerId,
        blockedId: userId,
        createdAt: DateTime.now(),
      );

      await Block.db.insertRow(session, block);
      return true;
    } catch (e) {
      session.log('Error blocking user: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(Session session, String userId) async {
    try {
      final blockerId = await session.auth.authenticatedUserId;
      if (blockerId == null) {
        throw Exception('Not authenticated');
      }

      final block = await Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(userId),
      );

      if (block == null) {
        return true; // Not blocked
      }

      await Block.db.deleteRow(session, block);
      return true;
    } catch (e) {
      session.log('Error unblocking user: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(Session session, String userId) async {
    try {
      final blockerId = await session.auth.authenticatedUserId;
      if (blockerId == null) {
        return false;
      }

      final block = await Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(userId),
      );

      return block != null;
    } catch (e) {
      session.log(
        'Error checking if user is blocked: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }
}
