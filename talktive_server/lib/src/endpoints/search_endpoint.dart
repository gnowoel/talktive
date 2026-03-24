import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/cache_service.dart';
import '../services/lounge_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import 'dart:convert';

class SearchEndpoint extends Endpoint with EndpointAuthMixin {
  /// Search for users by name (optimized with early limit)
  Future<List<protocol.UserSummary>> searchUsers(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userName.ilike('%${query.trim()}%'),
      limit: limit,
    );

    return residents.map((r) => ResidentService.toUserSummary(r)).toList();
  }

  /// Search for lounges by name or description
  Future<List<protocol.Lounge>> searchLounges(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    return await LoungeService.searchLounges(session, query, limit: limit);
  }

  /// Get trending moments (most liked in last 7 days) - CACHED
  Future<List<protocol.Moment>> getTrendingMoments(
    Session session, {
    int limit = 10,
  }) async {
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
  }

  /// Get popular lounges (most members) - CACHED
  Future<List<protocol.Lounge>> getPopularLounges(
    Session session, {
    int limit = 10,
  }) async {
    final cached = await CacheService.getPopularLounges(session);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.map((g) => protocol.Lounge.fromJson(g)).toList();
    }

    final lounges = await LoungeService.getPopularLounges(session, limit: limit);

    final encoded = jsonEncode(lounges.map((g) => g.toJson()).toList());
    await CacheService.setPopularLounges(session, encoded);

    return lounges;
  }

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  Future<List<protocol.UserSummary>> getActiveUsers(
    Session session, {
    int limit = 10,
  }) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Get a sample of recent messages to identify active senders
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

    final sortedSenderIds = messageCounts.keys.toList()
      ..sort((a, b) => messageCounts[b]!.compareTo(messageCounts[a]!));

    final topSenderIds = sortedSenderIds.take(limit).toList();
    if (topSenderIds.isEmpty) return [];

    final residents = await ResidentService.getResidents(session, topSenderIds);
    final residentMap = {for (final r in residents) r.userInfoId: r};

    return topSenderIds
        .map((id) {
          final resident = residentMap[id];
          if (resident == null) return null;
          return ResidentService.toUserSummary(resident, messageCount: messageCounts[id]);
        })
        .whereType<protocol.UserSummary>()
        .toList();
  }

  /// Search all content (users, lounges, moments)
  Future<protocol.SearchAllResults> searchAll(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    final futures = await Future.wait([
      searchUsers(session, query, limit: limit),
      searchLounges(session, query, limit: limit),
      protocol.Moment.db.find(
        session,
        where: (t) => t.caption.ilike('%$query%'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: limit,
      ),
    ]);

    return protocol.SearchAllResults(
      users: futures[0] as List<protocol.UserSummary>,
      lounges: futures[1] as List<protocol.Lounge>,
      moments: futures[2] as List<protocol.Moment>,
    );
  }

  /// Discover users by shared interests
  Future<List<protocol.UserSummary>> discoverUsersByInterests(
    Session session, {
    int limit = 20,
  }) async {
    final currentUser = await getAuthenticatedResident(session);
    if (currentUser.interests?.isEmpty != false) return [];

    final userId = currentUser.userInfoId;
    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId),
      limit: limit * 5,
    );

    final results = allResidents
        .map((resident) {
          if (resident.interests == null || resident.interests!.isEmpty) return null;

          final sharedInterests = currentUser.interests!
              .where((interest) => resident.interests!.contains(interest))
              .toList();

          if (sharedInterests.isEmpty) return null;

          return ResidentService.toUserSummary(
            resident,
            sharedInterests: sharedInterests,
            matchScore: sharedInterests.length,
          );
        })
        .whereType<protocol.UserSummary>()
        .toList();

    results.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return results.take(limit).toList();
  }

  /// Discover users by shared languages
  Future<List<protocol.UserSummary>> discoverUsersByLanguages(
    Session session, {
    int limit = 20,
  }) async {
    final currentUser = await getAuthenticatedResident(session);
    if (currentUser.languages?.isEmpty != false) return [];

    final userId = currentUser.userInfoId;
    final allResidents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.notEquals(userId),
      limit: limit * 5,
    );

    final results = allResidents
        .map((resident) {
          if (resident.languages == null || resident.languages!.isEmpty) return null;

          final sharedLanguages = currentUser.languages!
              .where((language) => resident.languages!.contains(language))
              .toList();

          if (sharedLanguages.isEmpty) return null;

          return ResidentService.toUserSummary(
            resident,
            sharedLanguages: sharedLanguages,
            matchScore: sharedLanguages.length,
          );
        })
        .whereType<protocol.UserSummary>()
        .toList();

    results.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return results.take(limit).toList();
  }

  /// Get personalized discovery feed
  Future<protocol.DiscoveryFeed> getDiscoveryFeed(
    Session session, {
    int limit = 10,
  }) async {
    final currentUser = await getResidentOptional(session);

    final futures = await Future.wait([
      discoverUsersByInterests(session, limit: limit),
      discoverUsersByLanguages(session, limit: limit),
      getTrendingMoments(session, limit: limit),
      getPopularLounges(session, limit: limit),
      currentUser != null
          ? LoungeService.getRecommendedLounges(session, currentUser, limit: limit)
          : LoungeService.getPopularLounges(session, limit: limit),
    ]);

    return protocol.DiscoveryFeed(
      usersByInterests: futures[0] as List<protocol.UserSummary>,
      usersByLanguages: futures[1] as List<protocol.UserSummary>,
      trendingMoments: futures[2] as List<protocol.Moment>,
      popularLounges: futures[3] as List<protocol.Lounge>,
      recommendedLounges: futures[4] as List<protocol.Lounge>,
    );
  }
}
