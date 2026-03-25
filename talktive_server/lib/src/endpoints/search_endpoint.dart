import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/search_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class SearchEndpoint extends Endpoint with EndpointAuthMixin {

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
    final resident = await getAuthenticatedResident(session);
    return await SearchService.searchUsers(
      session,
      query,
      gender: gender,
      country: country,
      language: language,
      interest: interest,
      ageRange: ageRange,
      isPremium: isPremium,
      limit: limit,
      currentUser: resident,
    );
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
    final resident = await getAuthenticatedResident(session);
    return await SearchService.searchLounges(
      session,
      query,
      interest: interest,
      language: language,
      country: country,
      limit: limit,
      currentUser: resident,
    );
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
    return await SearchService.getDiscoveryFeed(
      session,
      interest: interest,
      language: language,
      country: country,
      limit: limit,
      currentUser: currentUser,
    );
  }

  /// Search all content (users, lounges, moments)
  Future<protocol.SearchAllResults> searchAll(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    final resident = await getAuthenticatedResident(session);
    return await SearchService.searchAll(
      session,
      query,
      limit: limit,
      currentUser: resident,
    );
  }

  /// Get trending moments (most liked in last 7 days) - CACHED
  Future<List<protocol.Moment>> getTrendingMoments(
    Session session, {
    int limit = 10,
  }) async {
    return await SearchService.getTrendingMoments(
      session,
      limit: limit,
    );
  }

  /// Get popular lounges (most members) - CACHED
  Future<List<protocol.Lounge>> getPopularLounges(
    Session session, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
  }) async {
    return await SearchService.getPopularLounges(
      session,
      interest: interest,
      language: language,
      country: country,
      limit: limit,
    );
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
    return await SearchService.getActiveUsers(
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
}
