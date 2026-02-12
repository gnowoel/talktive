import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart' as protocol;

class UserProfileEndpoint extends Endpoint {
  /// Get a user's profile by their user ID
  Future<Map<String, dynamic>?> getUserProfile(
    Session session,
    String userId,
  ) async {
    try {
      // Get the viewing user's ID
      final viewerIdentifier = session.authenticated?.userIdentifier;
      if (viewerIdentifier == null) {
        throw Exception('Not authenticated');
      }
      final viewerId = UuidValue.fromString(viewerIdentifier);
      final targetId = UuidValue.fromString(userId);

      // Get the target user's resident data
      final resident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(targetId),
      );

      if (resident == null) {
        return null;
      }

      // Get user info (name, avatar) from Auth module
      final userInfo = await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.userIdentifier.equals(targetId.toString()),
      );

      if (userInfo == null) {
        return null; // Should not happen if resident exists
      }

      // Check if blocked
      final isBlocked = await protocol.Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(viewerId) & t.blockedId.equals(targetId),
      );

      final hasBlockedMe = await protocol.Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(targetId) & t.blockedId.equals(viewerId),
      );

      // Get stats
      final messageCount = await protocol.Message.db.count(
        session,
        where: (t) => t.senderId.equals(resident.userInfoId),
      );

      final momentCount = await protocol.Moment.db.count(
        session,
        where: (t) => t.authorId.equals(resident.id),
      );

      final achievements = await protocol.UserAchievement.db.find(
        session,
        where: (t) => t.userId.equals(targetId) & t.unlockedAt.notEquals(null),
      );

      // Get streak
      final streak = await protocol.UserStreak.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(targetId),
      );

      // Get recent moments
      final recentMoments = await protocol.Moment.db.find(
        session,
        where: (t) => t.authorId.equals(resident.id),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 6,
      );

      // Get mutual groups count
      final viewerGroups = await protocol.ChannelMember.db.find(
        session,
        where: (t) => t.userInfoId.equals(viewerId),
      );

      final targetGroups = await protocol.ChannelMember.db.find(
        session,
        where: (t) => t.userInfoId.equals(targetId),
      );

      final viewerGroupIds = viewerGroups.map((g) => g.channelId).toSet();
      final targetGroupIds = targetGroups.map((g) => g.channelId).toSet();
      final mutualGroups = viewerGroupIds.intersection(targetGroupIds).length;

      return {
        'userId': userId,
        'userName': userInfo.userName,
        'userAvatar': userInfo.imageUrl,
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
      final blockerIdentifier = session.authenticated?.userIdentifier;
      if (blockerIdentifier == null) {
        throw Exception('Not authenticated');
      }

      final blockerId = UuidValue.fromString(blockerIdentifier);
      final targetId = UuidValue.fromString(userId);

      // Check if already blocked
      final existing = await protocol.Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(targetId),
      );

      if (existing != null) {
        return true; // Already blocked
      }

      // Create block
      final block = protocol.Block(
        blockerId: blockerId,
        blockedId: targetId,
        createdAt: DateTime.now(),
      );

      await protocol.Block.db.insertRow(session, block);
      return true;
    } catch (e) {
      session.log('Error blocking user: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(Session session, String userId) async {
    try {
      final blockerIdentifier = session.authenticated?.userIdentifier;
      if (blockerIdentifier == null) {
        throw Exception('Not authenticated');
      }

      final blockerId = UuidValue.fromString(blockerIdentifier);
      final targetId = UuidValue.fromString(userId);

      final block = await protocol.Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(targetId),
      );

      if (block == null) {
        return true; // Not blocked
      }

      await protocol.Block.db.deleteRow(session, block);
      return true;
    } catch (e) {
      session.log('Error unblocking user: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(Session session, String userId) async {
    try {
      final blockerIdentifier = session.authenticated?.userIdentifier;
      if (blockerIdentifier == null) {
        return false;
      }

      final blockerId = UuidValue.fromString(blockerIdentifier);
      final targetId = UuidValue.fromString(userId);

      final block = await protocol.Block.db.findFirstRow(
        session,
        where: (t) =>
            t.blockerId.equals(blockerId) & t.blockedId.equals(targetId),
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
