import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'cache_service.dart';
import 'resident_service.dart';
import 'dart:convert';

class SearchService {
  static String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");

  static Expression _buildResidentFilters(
    protocol.ResidentTable t, {
    String? query,
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
  }) {
    var expr = t.suspended.equals(false);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      final escapedQuery = _escapeSqlLiteral(q);
      expr &=
          (t.userName.ilike('%$escapedQuery%') |
          t.bio.ilike('%$escapedQuery%') |
          Expression("interests::text ilike '%$escapedQuery%'"));
    }

    if (gender != null) expr &= t.gender.equals(gender);
    if (country != null) expr &= t.country.equals(country);
    if (ageRange != null) expr &= t.ageRange.equals(ageRange);
    if (isPremium != null) expr &= t.isPremium.equals(isPremium);

    if (language != null) {
      expr &= Expression(
        'languages::jsonb ? \'${language.replaceAll("'", "''")}\'',
      );
    }
    if (interest != null) {
      expr &= Expression(
        'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'',
      );
    }

    return expr;
  }

  /// Search for users with advanced filtering
  static Future<List<protocol.UserSummary>> searchUsers(
    Session session,
    String? query, {
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    int limit = 20,
    required protocol.Resident currentUser,
  }) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final hasFilters =
        gender != null ||
        country != null ||
        language != null ||
        interest != null ||
        ageRange != null ||
        isPremium != null;

    if (hasFilters) {
      if (!ResidentService.isPlusMember(currentUser)) {
        throw protocol.TalktiveException(
          message: 'Advanced Search filters are a Talktive Plus feature.',
          code: 'PREMIUM_REQUIRED',
        );
      }
      if (!ResidentService.canUseAdvancedDiscovery(currentUser)) {
        throw protocol.TalktiveException(
          message: 'Advanced Search is disabled in your Settings.',
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
        currentUser: currentUser,
      );
    }

    final blockedIds = await ResidentService.getBlocksByUser(
      session,
      currentUser.userInfoId,
    );

    final residents = await protocol.Resident.db.find(
      session,
      where: (t) {
        var filter = _buildResidentFilters(
          t,
          query: query,
          gender: gender,
          country: country,
          language: language,
          interest: interest,
          ageRange: ageRange,
          isPremium: isPremium,
        );
        if (blockedIds.isNotEmpty) {
          filter &= t.userInfoId.notInSet(blockedIds);
        }
        return filter;
      },
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit,
    );

    return residents
        .map((r) => ResidentService.toUserSummary(r, viewer: currentUser))
        .toList();
  }

  static Expression _buildLoungeFilters(
    protocol.LoungeTable t, {
    String? query,
    String? interest,
    String? language,
    String? country,
  }) {
    var expr = t.isPublic.equals(true);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      final escapedQuery = _escapeSqlLiteral(q);
      expr &=
          (t.name.ilike('%$escapedQuery%') |
          t.description.ilike('%$escapedQuery%') |
          Expression("interests::text ilike '%$escapedQuery%'"));
    }

    if (country == 'GLOBAL') {
      expr &= t.country.equals(null);
    } else if (country != null) {
      expr &= t.country.equals(country);
    }

    if (interest != null) {
      expr &= Expression(
        'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'',
      );
    }
    if (language != null) {
      expr &= Expression(
        'languages::jsonb ? \'${language.replaceAll("'", "''")}\'',
      );
    }
    return expr;
  }

  /// Search for lounges with advanced filtering
  static Future<List<protocol.Lounge>> searchLounges(
    Session session,
    String? query, {
    String? interest,
    String? language,
    String? country,
    int limit = 20,
    required protocol.Resident currentUser,
  }) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final hasFilters = interest != null || language != null || country != null;

    if (hasFilters) {
      if (!ResidentService.isPlusMember(currentUser)) {
        throw protocol.TalktiveException(
          message: 'Advanced Search filters are a Talktive Plus feature.',
          code: 'PREMIUM_REQUIRED',
        );
      }
      if (!ResidentService.canUseAdvancedDiscovery(currentUser)) {
        throw protocol.TalktiveException(
          message: 'Advanced Search is disabled in your Settings.',
          code: 'FEATURE_DISABLED',
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

    final blockedIds = await ResidentService.getBlocksByUser(
      session,
      currentUser.userInfoId,
    );

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) {
        var filter = _buildLoungeFilters(
          t,
          query: query,
          interest: interest,
          language: language,
          country: country,
        );
        if (blockedIds.isNotEmpty) {
          filter &= t.creatorId.notInSet(blockedIds);
        }
        return filter;
      },
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
    );

    return lounges;
  }

  /// Get trending moments (most liked in last 7 days) - CACHED
  static Future<List<protocol.Moment>> getTrendingMoments(
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
  static Future<List<protocol.Lounge>> getPopularLounges(
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

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) {
        var expr = t.isPublic.equals(true);

        if (country == 'GLOBAL') {
          expr &= t.country.equals(null);
        } else if (country != null) {
          expr &= t.country.equals(country);
        }

        if (interest != null) {
          expr &= Expression(
            'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'',
          );
        }
        if (language != null) {
          expr &= Expression(
            'languages::jsonb ? \'${language.replaceAll("'", "''")}\'',
          );
        }
        return expr;
      },
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
    );

    if (interest == null && language == null && country == null) {
      final encoded = jsonEncode(lounges.map((g) => g.toJson()).toList());
      await CacheService.setPopularLounges(session, encoded);
    }

    return lounges;
  }

  /// Gets personalized lounge recommendations based on resident interests.
  static Future<List<protocol.Lounge>> getRecommendedLounges(
    Session session,
    protocol.Resident resident, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
    int offset = 0,
  }) async {
    final searchInterests = interest != null ? [interest] : resident.interests;
    final interestArray = searchInterests?.isNotEmpty == true
        ? searchInterests!.map((e) => "'${e.replaceAll("'", "''")}'").join(",")
        : null;

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) {
        var expr = t.isPublic.equals(true);

        if (country == 'GLOBAL') {
          expr &= t.country.equals(null);
        } else if (country != null) {
          expr &= t.country.equals(country);
        }

        if (language != null) {
          expr &= Expression(
            'languages::jsonb ? \'${language.replaceAll("'", "''")}\'',
          );
        }
        if (interestArray != null) {
          if (interest != null) {
            expr &= Expression(
              'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'',
            );
          } else {
            expr &= Expression('interests::jsonb ?| array[$interestArray]');
          }
        }
        return expr;
      },
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: 100, // Fetch candidates for matching score sorting
    );

    lounges.sort((a, b) {
      final aMatch =
          a.interests
              ?.where((i) => (resident.interests ?? []).contains(i))
              .length ??
          0;
      final bMatch =
          b.interests
              ?.where((i) => (resident.interests ?? []).contains(i))
              .length ??
          0;
      if (aMatch != bMatch) return bMatch.compareTo(aMatch);
      return b.memberCount.compareTo(a.memberCount);
    });

    return lounges.skip(offset).take(limit).toList();
  }

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  static Future<List<protocol.UserSummary>> getActiveUsers(
    Session session, {
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    int limit = 10,
    protocol.Resident? currentUser,
  }) async {
    final hasFilters =
        gender != null ||
        country != null ||
        language != null ||
        interest != null ||
        ageRange != null ||
        isPremium != null;

    if (hasFilters) {
      if (currentUser == null || !ResidentService.isPlusMember(currentUser)) {
        throw protocol.TalktiveException(
          message: 'Advanced filtering is a Talktive Plus feature.',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Refactored: Query Residents directly using DB-level filters and order by activity.
    // This avoids the 'fetch then filter' bottleneck.
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) =>
          _buildResidentFilters(
            t,
            gender: gender,
            country: country,
            language: language,
            interest: interest,
            ageRange: ageRange,
            isPremium: isPremium,
          ) &
          (t.lastMessageDate >= sevenDaysAgo),
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
      return fallbackResidents
          .map((r) => ResidentService.toUserSummary(r, viewer: currentUser))
          .toList();
    }

    return residents
        .map((r) => ResidentService.toUserSummary(r, viewer: currentUser))
        .toList();
  }

  /// Search all content (users, lounges, moments)
  static Future<protocol.SearchAllResults> searchAll(
    Session session,
    String query, {
    int limit = 10,
    required protocol.Resident currentUser,
  }) async {
    final futures = await Future.wait([
      searchUsers(session, query, limit: limit, currentUser: currentUser),
      searchLounges(session, query, limit: limit, currentUser: currentUser),
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
  static Future<List<protocol.UserSummary>> discoverUsersByInterests(
    Session session, {
    int limit = 20,
    required protocol.Resident currentUser,
  }) async {
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
          Expression('interests::jsonb ?| array[$interestList]'),
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit * 2,
    );

    final results = matchingResidents.map((resident) {
      final sharedInterests = currentUser.interests!
          .where((interest) => resident.interests!.contains(interest))
          .toList();

      return ResidentService.toUserSummary(
        resident,
        viewer: currentUser,
        sharedInterests: sharedInterests,
        matchScore: sharedInterests.length,
      );
    }).toList();

    results.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return results.take(limit).toList();
  }

  /// Discover users by shared languages
  static Future<List<protocol.UserSummary>> discoverUsersByLanguages(
    Session session, {
    int limit = 20,
    required protocol.Resident currentUser,
  }) async {
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
          Expression('languages::jsonb ?| array[$languageList]'),
      orderBy: (t) => t.lastSeen,
      orderDescending: true,
      limit: limit * 2,
    );

    final results = matchingResidents.map((resident) {
      final sharedLanguages = currentUser.languages!
          .where((language) => resident.languages!.contains(language))
          .toList();

      return ResidentService.toUserSummary(
        resident,
        viewer: currentUser,
        sharedLanguages: sharedLanguages,
        matchScore: sharedLanguages.length,
      );
    }).toList();

    results.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return results.take(limit).toList();
  }

  /// Get personalized discovery feed
  static Future<protocol.DiscoveryFeed> getDiscoveryFeed(
    Session session, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
    protocol.Resident? currentUser,
  }) async {
    final futures = await Future.wait([
      if (currentUser != null)
        discoverUsersByInterests(
          session,
          limit: limit,
          currentUser: currentUser,
        )
      else
        Future.value([]),
      if (currentUser != null)
        discoverUsersByLanguages(
          session,
          limit: limit,
          currentUser: currentUser,
        )
      else
        Future.value([]),
      getTrendingMoments(session, limit: limit),
      getPopularLounges(
        session,
        interest: interest,
        language: language,
        country: country,
        limit: limit,
      ),
      currentUser != null
          ? getRecommendedLounges(
              session,
              currentUser,
              interest: interest,
              language: language,
              country: country,
              limit: limit,
            )
          : getPopularLounges(
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
