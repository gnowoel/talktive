import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class SearchEndpoint extends Endpoint {
  /// Search for users by name (optimized with early limit)
  Future<List<Map<String, dynamic>>> searchUsers(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Limit the initial query to reduce memory usage
      // Get 3x limit to account for filtering
      final residents = await Resident.db.find(
        session,
        limit: limit * 3,
      );

      // Filter by name with early exit
      final results = <Map<String, dynamic>>[];
      for (final resident in residents) {
        if (results.length >= limit) break; // Early exit when limit reached

        final userInfo = await session.auth.getUserInfo(resident.userInfoId);
        if (userInfo != null &&
            userInfo.userName != null &&
            userInfo.userName!.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'userId': resident.userInfoId.uuid,
            'userName': userInfo.userName,
            'userAvatar': userInfo.userName?.substring(0, 1),
            'floor': resident.floor,
            'creditScore': resident.creditScore,
          });
        }
      }

      return results;
    } catch (e) {
      session.log('Error searching users: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Search for groups by name or description
  Future<List<Group>> searchGroups(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final groups = await Group.db.find(
        session,
        where: (t) =>
            t.name.ilike('%$query%') | t.description.ilike('%$query%'),
        orderBy: (t) => t.memberCount,
        orderDescending: true,
        limit: limit,
      );

      return groups;
    } catch (e) {
      session.log('Error searching groups: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get trending moments (most liked in last 7 days)
  Future<List<Moment>> getTrendingMoments(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final moments = await Moment.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.likesCount,
        orderDescending: true,
        limit: limit,
      );

      return moments;
    } catch (e) {
      session.log('Error getting trending moments: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get popular groups (most members)
  Future<List<Group>> getPopularGroups(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final groups = await Group.db.find(
        session,
        where: (t) => t.isPublic.equals(true),
        orderBy: (t) => t.memberCount,
        orderDescending: true,
        limit: limit,
      );

      return groups;
    } catch (e) {
      session.log('Error getting popular groups: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  Future<List<Map<String, dynamic>>> getActiveUsers(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Limit messages to prevent memory issues (get last 1000 messages)
      final messages = await Message.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1000, // Limit to prevent loading all messages
      );

      // Count messages per sender
      final messageCounts = <int, int>{};
      for (final message in messages) {
        messageCounts[message.senderId] =
            (messageCounts[message.senderId] ?? 0) + 1;
      }

      // Sort by count and get top users
      final sortedSenders = messageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final activeUsers = <Map<String, dynamic>>[];
      for (final entry in sortedSenders.take(limit)) {
        final resident = await Resident.db.findById(session, entry.key);
        if (resident != null) {
          final userInfo = await session.auth.getUserInfo(resident.userInfoId);
          if (userInfo != null) {
            activeUsers.add({
              'userId': resident.userInfoId.uuid,
              'userName': userInfo.userName,
              'userAvatar': userInfo.userName?.substring(0, 1),
              'floor': resident.floor,
              'messageCount': entry.value,
            });
          }
        }
      }

      return activeUsers;
    } catch (e) {
      session.log('Error getting active users: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get recent moments (for discovery feed)
  Future<List<Moment>> getRecentMoments(
    Session session, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final moments = await Moment.db.find(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: limit,
        offset: offset,
      );

      return moments;
    } catch (e) {
      session.log('Error getting recent moments: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Search all content (users, groups, moments)
  Future<Map<String, dynamic>> searchAll(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    try {
      final users = await searchUsers(session, query, limit: limit);
      final groups = await searchGroups(session, query, limit: limit);

      // Search moments by caption
      final moments = await Moment.db.find(
        session,
        where: (t) => t.caption.ilike('%$query%'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: limit,
      );

      return {
        'users': users,
        'groups': groups.map((g) => g.toJson()).toList(),
        'moments': moments.map((m) => m.toJson()).toList(),
      };
    } catch (e) {
      session.log('Error searching all: $e', level: LogLevel.error);
      return {
        'users': [],
        'groups': [],
        'moments': [],
      };
    }
  }
}
