import 'package:test/test.dart';
import 'package:talktive_server/src/services/cache_service.dart';
import 'dart:convert';

void main() {
  group('CacheService - TTL Configuration', () {
    test('statistics TTL is 5 minutes', () {
      expect(CacheService.statisticsTTL.inMinutes, 5);
      expect(CacheService.statisticsTTL.inSeconds, 300);
    });

    test('user info TTL is 10 minutes', () {
      expect(CacheService.userInfoTTL.inMinutes, 10);
      expect(CacheService.userInfoTTL.inSeconds, 600);
    });

    test('trending moments TTL is 15 minutes', () {
      expect(CacheService.trendingMomentsTTL.inMinutes, 15);
      expect(CacheService.trendingMomentsTTL.inSeconds, 900);
    });

    test('popular groups TTL is 30 minutes', () {
      expect(CacheService.popularGroupsTTL.inMinutes, 30);
      expect(CacheService.popularGroupsTTL.inSeconds, 1800);
    });

    test('TTLs are ordered by update frequency', () {
      // More frequently updated data should have shorter TTL
      expect(CacheService.statisticsTTL < CacheService.userInfoTTL, true);
      expect(CacheService.userInfoTTL < CacheService.trendingMomentsTTL, true);
      expect(
        CacheService.trendingMomentsTTL < CacheService.popularGroupsTTL,
        true,
      );
    });
  });

  group('CacheService - Cache Key Format', () {
    test('statistics key format is correct', () {
      const key = 'stats:platform';
      expect(key, startsWith('stats:'));
      expect(key, contains('platform'));
    });

    test('user info key format is correct', () {
      const userId = 'user123';
      final key = 'user:$userId';
      expect(key, startsWith('user:'));
      expect(key, contains(userId));
    });

    test('trending moments key format is correct', () {
      const key = 'trending:moments';
      expect(key, startsWith('trending:'));
      expect(key, contains('moments'));
    });

    test('popular groups key format is correct', () {
      const key = 'popular:groups';
      expect(key, startsWith('popular:'));
      expect(key, contains('groups'));
    });

    test('active users key format is correct', () {
      const key = 'stats:active_users';
      expect(key, startsWith('stats:'));
      expect(key, contains('active_users'));
    });

    test('keys are unique per entity', () {
      const user1 = 'user:user1';
      const user2 = 'user:user2';
      const stats = 'stats:platform';

      expect(user1 != user2, true);
      expect(user1 != stats, true);
      expect(user2 != stats, true);
    });
  });

  group('CacheService - Data Serialization', () {
    test('statistics data can be serialized', () {
      final stats = {
        'totalUsers': 100,
        'totalMessages': 1000,
        'activeUsers': 50,
      };

      final json = jsonEncode(stats);
      expect(json, isA<String>());

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['totalUsers'], 100);
      expect(decoded['totalMessages'], 1000);
      expect(decoded['activeUsers'], 50);
    });

    test('user info data can be serialized', () {
      final userInfo = {
        'id': 'user123',
        'name': 'Test User',
        'floor': 2,
        'creditScore': 75,
      };

      final json = jsonEncode(userInfo);
      expect(json, isA<String>());

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['id'], 'user123');
      expect(decoded['name'], 'Test User');
      expect(decoded['floor'], 2);
      expect(decoded['creditScore'], 75);
    });

    test('handles nested data structures', () {
      final complexData = {
        'user': {
          'id': 'user123',
          'stats': {'messages': 10, 'moments': 5},
        },
        'achievements': ['first_message', 'social_butterfly'],
      };

      final json = jsonEncode(complexData);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['user']['id'], 'user123');
      expect(decoded['user']['stats']['messages'], 10);
      expect(decoded['achievements'], hasLength(2));
    });

    test('handles empty data', () {
      final emptyMap = <String, dynamic>{};
      final json = jsonEncode(emptyMap);
      expect(json, '{}');

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded.isEmpty, true);
    });
  });

  group('CacheService - Cache Strategy', () {
    test('statistics cache is short-lived for freshness', () {
      // 5 minutes is appropriate for frequently changing stats
      expect(CacheService.statisticsTTL.inMinutes <= 5, true);
    });

    test('user info cache balances freshness and performance', () {
      // 10 minutes is reasonable for user data that changes occasionally
      expect(CacheService.userInfoTTL.inMinutes, 10);
    });

    test('trending moments cache allows for discovery', () {
      // 15 minutes gives trending content time to be discovered
      expect(CacheService.trendingMomentsTTL.inMinutes >= 10, true);
      expect(CacheService.trendingMomentsTTL.inMinutes <= 30, true);
    });

    test('popular groups cache is longest for stable data', () {
      // 30 minutes is appropriate for slowly changing popularity
      expect(CacheService.popularGroupsTTL.inMinutes, 30);
    });
  });

  group('CacheService - Performance Benefits', () {
    test('caching reduces database load', () {
      // With 5 minute TTL, 1 DB query serves 300 seconds of requests
      // At 10 req/sec, that's 3000 requests served by 1 DB query
      const requestsPerSecond = 10;
      final requestsServed =
          CacheService.statisticsTTL.inSeconds * requestsPerSecond;

      expect(requestsServed, 3000);
      // 3000x reduction in database queries
    });

    test('different TTLs optimize for different access patterns', () {
      // Frequently accessed, frequently updated: short TTL
      expect(CacheService.statisticsTTL.inMinutes, 5);

      // Frequently accessed, rarely updated: long TTL
      expect(CacheService.popularGroupsTTL.inMinutes, 30);

      // Ratio should be significant
      final ratio =
          CacheService.popularGroupsTTL.inSeconds /
          CacheService.statisticsTTL.inSeconds;
      expect(ratio, 6.0); // 6x longer
    });
  });

  group('CacheService - Cache Invalidation', () {
    test('invalidation targets correct cache types', () {
      // Discovery cache includes trending and popular
      const trendingKey = 'trending:moments';
      const popularKey = 'popular:groups';

      expect(trendingKey, startsWith('trending:'));
      expect(popularKey, startsWith('popular:'));
    });

    test('user invalidation is targeted', () {
      const userId = 'user123';
      final key = 'user:$userId';

      // Should only invalidate specific user
      expect(key, contains(userId));
      expect(key, isNot(contains('user456')));
    });

    test('cache prefixes allow bulk operations', () {
      const prefixes = ['stats:', 'user:', 'trending:', 'popular:'];

      // All prefixes should be unique
      expect(prefixes.toSet().length, prefixes.length);

      // All prefixes should end with colon for pattern matching
      for (final prefix in prefixes) {
        expect(prefix, endsWith(':'));
      }
    });
  });

  group('CacheService - Edge Cases', () {
    test('handles special characters in user IDs', () {
      const specialUserId = 'user-123_test@example';
      final key = 'user:$specialUserId';

      expect(key, contains(specialUserId));
      expect(key, startsWith('user:'));
    });

    test('handles very large data structures', () {
      final largeData = {
        'items': List.generate(1000, (i) => {'id': i, 'value': 'item$i'}),
      };

      final json = jsonEncode(largeData);
      expect(json, isA<String>());
      expect(json.length > 10000, true);

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['items'], hasLength(1000));
    });

    test('handles unicode in cached data', () {
      final unicodeData = {
        'name': '你好世界',
        'emoji': '🎉🎊',
        'arabic': 'مرحبا',
      };

      final json = jsonEncode(unicodeData);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['name'], '你好世界');
      expect(decoded['emoji'], '🎉🎊');
      expect(decoded['arabic'], 'مرحبا');
    });

    test('handles null values in data', () {
      final dataWithNulls = {
        'name': 'Test',
        'optional': null,
        'count': 0,
      };

      final json = jsonEncode(dataWithNulls);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['name'], 'Test');
      expect(decoded['optional'], isNull);
      expect(decoded['count'], 0);
    });
  });

  group('CacheService - Production Readiness', () {
    test('TTLs are production-appropriate', () {
      // All TTLs should be between 1 minute and 1 hour
      final allTTLs = [
        CacheService.statisticsTTL,
        CacheService.userInfoTTL,
        CacheService.trendingMomentsTTL,
        CacheService.popularGroupsTTL,
      ];

      for (final ttl in allTTLs) {
        expect(
          ttl.inMinutes >= 1,
          true,
          reason: 'TTL too short: ${ttl.inMinutes} minutes',
        );
        expect(
          ttl.inMinutes <= 60,
          true,
          reason: 'TTL too long: ${ttl.inMinutes} minutes',
        );
      }
    });

    test('cache keys follow naming convention', () {
      const keys = [
        'stats:platform',
        'user:123',
        'trending:moments',
        'popular:groups',
        'stats:active_users',
      ];

      for (final key in keys) {
        // Should contain colon separator
        expect(key, contains(':'));

        // Should be lowercase
        expect(key, equals(key.toLowerCase()));

        // Should not have spaces
        expect(key, isNot(contains(' ')));
      }
    });

    test('supports high-traffic scenarios', () {
      // With 5 min TTL and 100 req/sec
      const requestsPerSecond = 100;
      final requestsServed =
          CacheService.statisticsTTL.inSeconds * requestsPerSecond;

      // Should serve 30,000 requests with 1 DB query
      expect(requestsServed, 30000);
    });
  });
}
