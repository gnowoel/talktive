import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/cache_service.dart';
import '../services/lounge_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import 'dart:convert';

class SearchEndpoint extends Endpoint with EndpointAuthMixin {
  Expression _buildResidentFilters(
    protocol.ResidentTable t, {
    String? query,
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
  }) {
    var expr = t.suspended.equals(false) & t.allowDiscovery.equals(true);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      expr &= (t.userName.ilike('%$q%') |
          t.bio.ilike('%$q%') |
          Expression('interests::text ilike \'%$q%\''));
    }

    if (gender != null) expr &= t.gender.equals(gender);
    if (country != null) expr &= t.country.equals(country);
    if (ageRange != null) expr &= t.ageRange.equals(ageRange);
    if (isPremium != null) expr &= t.isPremium.equals(isPremium);

    if (language != null) {
      expr &= Expression('languages::jsonb ? \'${language.replaceAll("'", "''")}\'');
    }
    if (interest != null) {
      expr &= Expression('interests::jsonb ? \'${interest.replaceAll("'", "''")}\'');
    }
    
    return expr;
  }

  /// Search for users with advanced filtering
  Future<List<protocol.UserSummary>> searchUsers(
    Session session,
    String? query, {
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    int limit = 20,
  }) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final hasFilters = gender != null ||
        country != null ||
        language != null ||
        interest != null ||
        ageRange != null ||
        isPremium != null;

    final resident = await getAuthenticatedResident(session);

    if (hasQuery || hasFilters) {
      if (!resident.isPremium) {
        throw protocol.TalktiveException(
          message: 'Advanced Search is a Talktive Plus feature.',
          code: 'PREMIUM_REQUIRED',
        );
      }
      if (!resident.showNeighborsDiscovery) {
        throw protocol.TalktiveException(
          message: 'Advanced Search is disabled in Settings.',
          code: 'FEATURE_DISABLED',
        );
      }
    }

    if (!hasQuery) {
      // If no search term, return filtered recommendations (active users)
      return await getActiveUsers(
        session,
        gender: gender,
        country: country,
        language: language,
        interest: interest,
        ageRange: ageRange,
        isPremium: isPremium,
        limit: limit,
      );
    }

    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => _buildResidentFilters(
        t,
        query: query,
        gender: gender,
        country: country,
        language: language,
        interest: interest,
        ageRange: ageRange,
        isPremium: isPremium,
      ),
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit,
    );

    return residents
        .map((r) => ResidentService.toUserSummary(r))
        .toList();
  }

  Expression _buildLoungeFilters(
    protocol.LoungeTable t, {
    String? query,
    String? interest,
    String? language,
    String? country,
  }) {
    var expr = t.isPublic.equals(true);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      expr &= (t.name.ilike('%$q%') |
          t.description.ilike('%$q%') |
          Expression('interests::text ilike \'%$q%\''));
    }

    if (country != null) expr &= t.country.equals(country);
    
    if (interest != null) {
      expr &= Expression('interests::jsonb ? \'${interest.replaceAll("'", "''")}\'');
    }
    if (language != null) {
      expr &= Expression('languages::jsonb ? \'${language.replaceAll("'", "''")}\'');
    }
    return expr;
  }

  /// Search for lounges with advanced filtering
  Future<List<protocol.Lounge>> searchLounges(
    Session session,
    String? query, {
    String? interest,
    String? language,
    String? country,
    int limit = 20,
  }) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final hasFilters = interest != null || language != null || country != null;

    final resident = await getAuthenticatedResident(session);

    if (hasQuery || hasFilters) {
      if (!resident.isPremium) {
        throw protocol.TalktiveException(
          message: 'Advanced Search is a Talktive Plus feature.',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    if (!hasQuery) {
      // If no search term, return popular lounges with filters
      return await getPopularLounges(
        session,
        interest: interest,
        language: language,
        country: country,
        limit: limit,
      );
    }

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) => _buildLoungeFilters(
        t,
        query: query,
        interest: interest,
        language: language,
        country: country,
      ),
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
    );

    return lounges;
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
    String? interest,
    String? language,
    String? country,
    int limit = 10,
  }) async {
    // Basic caching only for non-filtered popular lounges
    if (interest == null && language == null && country == null) {
      final cached = await CacheService.getPopularLounges(session);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((g) => protocol.Lounge.fromJson(g)).toList();
      }
    }

    final lounges = await LoungeService.getPopularLounges(
      session,
      interest: interest,
      language: language,
      country: country,
      limit: limit,
    );

    if (interest == null && language == null && country == null) {
      final encoded = jsonEncode(lounges.map((g) => g.toJson()).toList());
      await CacheService.setPopularLounges(session, encoded);
    }

    return lounges;
  }

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  Future<List<protocol.UserSummary>> getActiveUsers(
    Session session, {
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    int limit = 10,
  }) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Refactored: Query Residents directly using DB-level filters and order by activity.
    // This avoids the 'fetch then filter' bottleneck.
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => _buildResidentFilters(
        t,
        gender: gender,
        country: country,
        language: language,
        interest: interest,
        ageRange: ageRange,
        isPremium: isPremium,
      ) & (t.lastMessageDate >= sevenDaysAgo),
      orderBy: (t) => t.lastMessageDate,
      orderDescending: true,
      limit: limit,
    );

    // Fallback: if no active users in 7 days, get latest seen users with same filters
    if (residents.isEmpty) {
      final fallbackResidents = await protocol.Resident.db.find(
        session,
        where: (t) => _buildResidentFilters(
          t,
          gender: gender,
          country: country,
          language: language,
          interest: interest,
          ageRange: ageRange,
          isPremium: isPremium,
        ),
        orderBy: (t) => t.lastSeen,
        orderDescending: true,
        limit: limit,
      );
      return fallbackResidents.map((r) => ResidentService.toUserSummary(r)).toList();
    }

    return residents
        .map((r) => ResidentService.toUserSummary(r))
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
    final interestList = currentUser.interests!
        .map((e) => "'${e.replaceAll("'", "''")}'")
        .join(",");

    // Find residents who share AT LEAST ONE interest using Postgres ?| operator
    final matchingResidents = await protocol.Resident.db.find(
      session,
      where: (t) =>
          t.userInfoId.notEquals(userId) &
          t.suspended.equals(false) &
          t.allowDiscovery.equals(true) &
          Expression('interests::jsonb ?| array[$interestList]'),
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit * 2,
    );

    final results = matchingResidents
        .map((resident) {
          final sharedInterests = currentUser.interests!
              .where((interest) => resident.interests!.contains(interest))
              .toList();

          return ResidentService.toUserSummary(
            resident,
            sharedInterests: sharedInterests,
            matchScore: sharedInterests.length,
          );
        })
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
    final languageList = currentUser.languages!
        .map((e) => "'${e.replaceAll("'", "''")}'")
        .join(",");

    // Find residents who share AT LEAST ONE language using Postgres ?| operator
    final matchingResidents = await protocol.Resident.db.find(
      session,
      where: (t) =>
          t.userInfoId.notEquals(userId) &
          t.suspended.equals(false) &
          t.allowDiscovery.equals(true) &
          Expression('languages::jsonb ?| array[$languageList]'),
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit * 2,
    );

    final results = matchingResidents
        .map((resident) {
          final sharedLanguages = currentUser.languages!
              .where((language) => resident.languages!.contains(language))
              .toList();

          return ResidentService.toUserSummary(
            resident,
            sharedLanguages: sharedLanguages,
            matchScore: sharedLanguages.length,
          );
        })
        .toList();

    results.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return results.take(limit).toList();
  }

  /// Get personalized discovery feed
  Future<protocol.DiscoveryFeed> getDiscoveryFeed(
    Session session, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
  }) async {
    final currentUser = await getResidentOptional(session);

    final futures = await Future.wait([
      discoverUsersByInterests(session, limit: limit),
      discoverUsersByLanguages(session, limit: limit),
      getTrendingMoments(session, limit: limit),
      getPopularLounges(
        session,
        interest: interest,
        language: language,
        country: country,
        limit: limit,
      ),
      currentUser != null
          ? LoungeService.getRecommendedLounges(
              session,
              currentUser,
              interest: interest,
              language: language,
              country: country,
              limit: limit,
            )
          : LoungeService.getPopularLounges(
              session,
              interest: interest,
              language: language,
              country: country,
              limit: limit,
            ),
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
