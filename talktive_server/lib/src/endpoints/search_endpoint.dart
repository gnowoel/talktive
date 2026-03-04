import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/cache_service.dart';
import '../services/input_validation_service.dart';
import 'dart:convert';

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
      final residents = await protocol.Resident.db.find(
        session,
        limit: limit * 3,
      );

      // Filter by name with early exit
      final results = <Map<String, dynamic>>[];
      for (final resident in residents) {
        if (results.length >= limit) break; // Early exit when limit reached

        final userName = resident.userName ?? 'Resident';

        if (userName.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'userId': resident.userInfoId.toString(),
            'userName': userName,
            'userAvatar': resident.avatar ?? '👤',
            'floor': ApartmentService.computeEffectiveFloor(resident),
            'trustScore': resident.trustScore,
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
  Future<List<protocol.Group>> searchGroups(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final groups = await protocol.Group.db.find(
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

  /// Get trending moments (most liked in last 7 days) - CACHED
  Future<List<protocol.Moment>> getTrendingMoments(
    Session session, {
    int limit = 10,
  }) async {
    try {
      // Try cache first
      final cached = await CacheService.getTrendingMoments(session);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((m) => protocol.Moment.fromJson(m)).toList();
      }

      // Cache miss - query database
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final moments = await protocol.Moment.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.likesCount,
        orderDescending: true,
        limit: limit,
      );

      // Store in cache
      final encoded = jsonEncode(moments.map((m) => m.toJson()).toList());
      await CacheService.setTrendingMoments(session, encoded);

      return moments;
    } catch (e) {
      session.log('Error getting trending moments: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get popular groups (most members) - CACHED
  Future<List<protocol.Group>> getPopularGroups(
    Session session, {
    int limit = 10,
  }) async {
    try {
      // Try cache first
      final cached = await CacheService.getPopularGroups(session);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((g) => protocol.Group.fromJson(g)).toList();
      }

      // Cache miss - query database
      final groups = await protocol.Group.db.find(
        session,
        where: (t) => t.isPublic.equals(true),
        orderBy: (t) => t.memberCount,
        orderDescending: true,
        limit: limit,
      );

      // Store in cache
      final encoded = jsonEncode(groups.map((g) => g.toJson()).toList());
      await CacheService.setPopularGroups(session, encoded);

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
      final messages = await protocol.Message.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1000, // Limit to prevent loading all messages
      );

      // Count messages per sender (senderId is UuidValue)
      final messageCounts = <UuidValue, int>{};
      for (final message in messages) {
        messageCounts[message.senderId] =
            (messageCounts[message.senderId] ?? 0) + 1;
      }

      // Sort by count and get top users
      final sortedSenders = messageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final activeUsers = <Map<String, dynamic>>[];
      for (final entry in sortedSenders.take(limit)) {
        // Find resident by userInfoId (key is UuidValue)
        final resident = await protocol.Resident.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(entry.key),
        );

        if (resident != null) {
          activeUsers.add({
            'userId': resident.userInfoId.toString(),
            'userName': resident.userName ?? 'Resident',
            'userAvatar': resident.avatar ?? '👤',
            'userMood': resident.mood,
            'floor': ApartmentService.computeEffectiveFloor(resident),
            'messageCount': entry.value,
          });
        }
      }

      return activeUsers;
    } catch (e) {
      session.log('Error getting active users: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get recent moments (for discovery feed)
  Future<List<protocol.Moment>> getRecentMoments(
    Session session, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final moments = await protocol.Moment.db.find(
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
      final moments = await protocol.Moment.db.find(
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

  /// Discover users by shared interests
  Future<List<Map<String, dynamic>>> discoverUsersByInterests(
    Session session, {
    int limit = 20,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();

    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Get current user's interests
    final currentUser = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );

    if (currentUser == null || currentUser.interests?.isEmpty != false) {
      return [];
    }

    // Find users with matching interests
    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId), // Exclude self
      limit: limit * 3, // Get more to filter
    );

    final matches = <Map<String, dynamic>>[];
    for (final resident in allResidents) {
      if (matches.length >= limit) break;

      // Skip if resident has no interests
      if (resident.interests == null || resident.interests!.isEmpty) {
        continue;
      }

      // Calculate interest overlap
      final sharedInterests = currentUser.interests!
          .where((interest) => resident.interests!.contains(interest))
          .toList();

      if (sharedInterests.isNotEmpty) {
        matches.add({
          'userId': resident.userInfoId.toString(),
          'userName': resident.userName ?? 'Resident',
          'userAvatar': resident.avatar ?? '👤',
          'floor': ApartmentService.computeEffectiveFloor(resident),
          'sharedInterests': sharedInterests,
          'matchScore': sharedInterests.length,
        });
      }
    }

    // Sort by match score (most shared interests first)
    matches.sort(
      (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
    );

    return matches;
  }

  /// Discover users by shared languages
  Future<List<Map<String, dynamic>>> discoverUsersByLanguages(
    Session session, {
    int limit = 20,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();

    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Get current user's languages
    final currentUser = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );

    if (currentUser == null || currentUser.languages?.isEmpty != false) {
      return [];
    }

    // Find users with matching languages
    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId), // Exclude self
      limit: limit * 3, // Get more to filter
    );

    final matches = <Map<String, dynamic>>[];
    for (final resident in allResidents) {
      if (matches.length >= limit) break;

      // Skip if resident has no languages
      if (resident.languages == null || resident.languages!.isEmpty) {
        continue;
      }

      // Calculate language overlap
      final sharedLanguages = currentUser.languages!
          .where((language) => resident.languages!.contains(language))
          .toList();

      if (sharedLanguages.isNotEmpty) {
        matches.add({
          'userId': resident.userInfoId.toString(),
          'userName': resident.userName ?? 'Resident',
          'userAvatar': resident.avatar ?? '👤',
          'floor': ApartmentService.computeEffectiveFloor(resident),
          'sharedLanguages': sharedLanguages,
          'matchScore': sharedLanguages.length,
        });
      }
    }

    // Sort by match score (most shared languages first)
    matches.sort(
      (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
    );

    return matches;
  }

  /// Get personalized discovery feed (combines interests, languages, and activity)
  Future<Map<String, dynamic>> getDiscoveryFeed(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final usersByInterests = await discoverUsersByInterests(
        session,
        limit: limit,
      );

      final usersByLanguages = await discoverUsersByLanguages(
        session,
        limit: limit,
      );

      final trendingMoments = await getTrendingMoments(
        session,
        limit: limit,
      );

      final popularGroups = await getPopularGroups(
        session,
        limit: limit,
      );

      return {
        'usersByInterests': usersByInterests,
        'usersByLanguages': usersByLanguages,
        'trendingMoments': trendingMoments.map((m) => m.toJson()).toList(),
        'popularGroups': popularGroups.map((g) => g.toJson()).toList(),
      };
    } catch (e) {
      session.log('Error getting discovery feed: $e', level: LogLevel.error);
      return {
        'usersByInterests': [],
        'usersByLanguages': [],
        'trendingMoments': [],
        'popularGroups': [],
      };
    }
  }
}
