import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/cache_service.dart';
import '../services/lounge_service.dart';
import '../services/resident_service.dart';
import 'dart:convert';

class SearchEndpoint extends Endpoint {
  /// Search for users by name (optimized with early limit)
  Future<List<protocol.UserSummary>> searchUsers(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();

      // Get more to account for name filtering
      final residents = await protocol.Resident.db.find(
        session,
        where: (t) => t.userName.ilike('%$queryLower%'),
        limit: limit,
      );

      return residents.map((r) => ResidentService.toUserSummary(r)).toList();
    } catch (e) {
      session.log('Error searching users: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Search for lounges by name or description
  Future<List<protocol.Lounge>> searchLounges(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    try {
      return await LoungeService.searchLounges(session, query, limit: limit);
    } catch (e) {
      session.log('Error searching lounges: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get trending moments (most liked in last 7 days) - CACHED
  Future<List<protocol.Moment>> getTrendingMoments(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final cached = await CacheService.getTrendingMoments(session);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((m) => protocol.Moment.fromJson(m)).toList();
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final moments = await protocol.Moment.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.likesCount,
        orderDescending: true,
        limit: limit,
      );

      final encoded = jsonEncode(moments.map((m) => m.toJson()).toList());
      await CacheService.setTrendingMoments(session, encoded);

      return moments;
    } catch (e) {
      session.log('Error getting trending moments: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get popular lounges (most members) - CACHED
  Future<List<protocol.Lounge>> getPopularLounges(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final cached = await CacheService.getPopularLounges(session);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((g) => protocol.Lounge.fromJson(g)).toList();
      }

      final lounges = await LoungeService.getPopularLounges(session, limit: limit);

      final encoded = jsonEncode(lounges.map((g) => g.toJson()).toList());
      await CacheService.setPopularLounges(session, encoded);

      return lounges;
    } catch (e) {
      session.log('Error getting popular lounges: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  Future<List<protocol.UserSummary>> getActiveUsers(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final messages = await protocol.Message.db.find(
        session,
        where: (t) => t.createdAt >= sevenDaysAgo,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1000, 
      );

      final messageCounts = <UuidValue, int>{};
      for (final message in messages) {
        messageCounts[message.senderId] = (messageCounts[message.senderId] ?? 0) + 1;
      }

      final sortedSenders = messageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final activeUsers = <protocol.UserSummary>[];
      for (final entry in sortedSenders.take(limit)) {
        final resident = await ResidentService.getResident(session, entry.key);
        if (resident != null) {
          activeUsers.add(ResidentService.toUserSummary(resident, messageCount: entry.value));
        }
      }

      return activeUsers;
    } catch (e) {
      session.log('Error getting active users: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Search all content (users, lounges, moments)
  Future<protocol.SearchAllResults> searchAll(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    try {
      final users = await searchUsers(session, query, limit: limit);
      final lounges = await searchLounges(session, query, limit: limit);

      final moments = await protocol.Moment.db.find(
        session,
        where: (t) => t.caption.ilike('%$query%'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: limit,
      );

      return protocol.SearchAllResults(
        users: users,
        lounges: lounges,
        moments: moments,
      );
    } catch (e) {
      session.log('Error searching all: $e', level: LogLevel.error);
      return protocol.SearchAllResults(users: [], lounges: [], moments: []);
    }
  }

  /// Discover users by shared interests
  Future<List<protocol.UserSummary>> discoverUsersByInterests(
    Session session, {
    int limit = 20,
  }) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) throw protocol.TalktiveException(message: 'Not authenticated');

    final userId = UuidValue.fromString(userIdentifier);
    final currentUser = await ResidentService.getResident(session, userId);

    if (currentUser == null || currentUser.interests?.isEmpty != false) return [];

    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId),
      limit: limit * 5, 
    );

    final matches = <protocol.UserSummary>[];
    for (final resident in allResidents) {
      if (matches.length >= limit) break;
      if (resident.interests == null || resident.interests!.isEmpty) continue;

      final sharedInterests = currentUser.interests!
          .where((interest) => resident.interests!.contains(interest))
          .toList();

      if (sharedInterests.isNotEmpty) {
        matches.add(ResidentService.toUserSummary(
          resident,
          sharedInterests: sharedInterests,
          matchScore: sharedInterests.length,
        ));
      }
    }

    matches.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return matches;
  }

  /// Discover users by shared languages
  Future<List<protocol.UserSummary>> discoverUsersByLanguages(
    Session session, {
    int limit = 20,
  }) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) throw protocol.TalktiveException(message: 'Not authenticated');

    final userId = UuidValue.fromString(userIdentifier);
    final currentUser = await ResidentService.getResident(session, userId);

    if (currentUser == null || currentUser.languages?.isEmpty != false) return [];

    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId),
      limit: limit * 5,
    );

    final matches = <protocol.UserSummary>[];
    for (final resident in allResidents) {
      if (matches.length >= limit) break;
      if (resident.languages == null || resident.languages!.isEmpty) continue;

      final sharedLanguages = currentUser.languages!
          .where((language) => resident.languages!.contains(language))
          .toList();

      if (sharedLanguages.isNotEmpty) {
        matches.add(ResidentService.toUserSummary(
          resident,
          sharedLanguages: sharedLanguages,
          matchScore: sharedLanguages.length,
        ));
      }
    }

    matches.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return matches;
  }

  /// Get personalized discovery feed
  Future<protocol.DiscoveryFeed> getDiscoveryFeed(
    Session session, {
    int limit = 10,
  }) async {
    try {
      final usersByInterests = await discoverUsersByInterests(session, limit: limit);
      final usersByLanguages = await discoverUsersByLanguages(session, limit: limit);
      final trendingMoments = await getTrendingMoments(session, limit: limit);
      final popularLounges = await getPopularLounges(session, limit: limit);

      final userIdentifier = session.authenticated?.userIdentifier;
      protocol.Resident? currentUser;
      if (userIdentifier != null) {
        currentUser = await ResidentService.getResident(session, UuidValue.fromString(userIdentifier));
      }

      final recommendedLounges = currentUser != null
          ? await LoungeService.getRecommendedLounges(session, currentUser, limit: limit)
          : await LoungeService.getPopularLounges(session, limit: limit);

      return protocol.DiscoveryFeed(
        usersByInterests: usersByInterests,
        usersByLanguages: usersByLanguages,
        trendingMoments: trendingMoments,
        popularLounges: popularLounges,
        recommendedLounges: recommendedLounges,
      );
    } catch (e) {
      session.log('Error getting discovery feed: $e', level: LogLevel.error);
      return protocol.DiscoveryFeed(
        usersByInterests: [],
        usersByLanguages: [],
        trendingMoments: [],
        popularLounges: [],
      );
    }
  }

}
