import 'package:serverpod/serverpod.dart';
import 'dart:convert';

/// Cache service for frequently accessed data using Redis
class CacheService {
  /// Cache TTL (Time To Live) constants
  static const Duration statisticsTTL = Duration(minutes: 5);
  static const Duration userInfoTTL = Duration(minutes: 10);
  static const Duration trendingMomentsTTL = Duration(minutes: 15);
  static const Duration popularGroupsTTL = Duration(minutes: 30);

  /// Cache key prefixes
  static const String _statsPrefix = 'stats:';
  static const String _userPrefix = 'user:';
  static const String _trendingPrefix = 'trending:';
  static const String _popularPrefix = 'popular:';

  /// Get platform statistics from cache or compute
  static Future<Map<String, dynamic>?> getStatistics(Session session) async {
    final key = '${_statsPrefix}platform';

    try {
      final cached = await session.redis.get(key);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (e) {
      session.log('Cache get error: $e', level: LogLevel.warning);
    }

    return null;
  }

  /// Set platform statistics in cache
  static Future<void> setStatistics(
    Session session,
    Map<String, dynamic> stats,
  ) async {
    final key = '${_statsPrefix}platform';

    try {
      await session.redis.setEx(
        key,
        jsonEncode(stats),
        statisticsTTL,
      );
    } catch (e) {
      session.log('Cache set error: $e', level: LogLevel.warning);
    }
  }

  /// Get user info from cache
  static Future<Map<String, dynamic>?> getUserInfo(
    Session session,
    String userId,
  ) async {
    final key = '$_userPrefix$userId';

    try {
      final cached = await session.redis.get(key);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (e) {
      session.log('Cache get error: $e', level: LogLevel.warning);
    }

    return null;
  }

  /// Set user info in cache
  static Future<void> setUserInfo(
    Session session,
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    final key = '$_userPrefix$userId';

    try {
      await session.redis.setEx(
        key,
        jsonEncode(userInfo),
        userInfoTTL,
      );
    } catch (e) {
      session.log('Cache set error: $e', level: LogLevel.warning);
    }
  }

  /// Invalidate user info cache
  static Future<void> invalidateUserInfo(
    Session session,
    String userId,
  ) async {
    final key = '$_userPrefix$userId';

    try {
      await session.redis.delete(key);
    } catch (e) {
      session.log('Cache delete error: $e', level: LogLevel.warning);
    }
  }

  /// Get trending moments from cache
  static Future<String?> getTrendingMoments(Session session) async {
    final key = '${_trendingPrefix}moments';

    try {
      return await session.redis.get(key);
    } catch (e) {
      session.log('Cache get error: $e', level: LogLevel.warning);
      return null;
    }
  }

  /// Set trending moments in cache
  static Future<void> setTrendingMoments(
    Session session,
    String momentsJson,
  ) async {
    final key = '${_trendingPrefix}moments';

    try {
      await session.redis.setEx(
        key,
        momentsJson,
        trendingMomentsTTL,
      );
    } catch (e) {
      session.log('Cache set error: $e', level: LogLevel.warning);
    }
  }

  /// Get popular groups from cache
  static Future<String?> getPopularGroups(Session session) async {
    final key = '${_popularPrefix}groups';

    try {
      return await session.redis.get(key);
    } catch (e) {
      session.log('Cache get error: $e', level: LogLevel.warning);
      return null;
    }
  }

  /// Set popular groups in cache
  static Future<void> setPopularGroups(
    Session session,
    String groupsJson,
  ) async {
    final key = '${_popularPrefix}groups';

    try {
      await session.redis.setEx(
        key,
        groupsJson,
        popularGroupsTTL,
      );
    } catch (e) {
      session.log('Cache set error: $e', level: LogLevel.warning);
    }
  }

  /// Invalidate all trending/popular caches (call when new content is created)
  static Future<void> invalidateDiscoveryCache(Session session) async {
    try {
      await session.redis.delete('${_trendingPrefix}moments');
      await session.redis.delete('${_popularPrefix}groups');
    } catch (e) {
      session.log('Cache invalidation error: $e', level: LogLevel.warning);
    }
  }

  /// Get active users from cache
  static Future<String?> getActiveUsers(Session session) async {
    final key = '${_statsPrefix}active_users';

    try {
      return await session.redis.get(key);
    } catch (e) {
      session.log('Cache get error: $e', level: LogLevel.warning);
      return null;
    }
  }

  /// Set active users in cache
  static Future<void> setActiveUsers(
    Session session,
    String usersJson,
  ) async {
    final key = '${_statsPrefix}active_users';

    try {
      await session.redis.setEx(
        key,
        usersJson,
        Duration(minutes: 10),
      );
    } catch (e) {
      session.log('Cache set error: $e', level: LogLevel.warning);
    }
  }

  /// Clear all caches (use for testing or maintenance)
  static Future<void> clearAll(Session session) async {
    try {
      // Get all keys with our prefixes
      final patterns = [
        _statsPrefix,
        _userPrefix,
        _trendingPrefix,
        _popularPrefix,
      ];

      for (final pattern in patterns) {
        // Note: In production, use SCAN instead of KEYS for better performance
        final keys = await session.redis.keys('$pattern*');
        if (keys.isNotEmpty) {
          await session.redis.delete(keys);
        }
      }
    } catch (e) {
      session.log('Cache clear error: $e', level: LogLevel.warning);
    }
  }
}
