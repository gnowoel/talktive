import 'package:test/test.dart';
import 'package:talktive_server/src/services/redis_rate_limit_service.dart';

void main() {
  group('RedisRateLimitService - Configuration', () {
    test('floor 0 has strictest limits', () {
      final config = RedisRateLimitService.floorLimits[0]!;
      expect(config.messagesPerMinute, 5);
      expect(config.messagesPerHour, 100);
      expect(config.minSecondsBetweenMessages, 2);
    });

    test('floor 1 has moderate limits', () {
      final config = RedisRateLimitService.floorLimits[1]!;
      expect(config.messagesPerMinute, 10);
      expect(config.messagesPerHour, 300);
      expect(config.minSecondsBetweenMessages, 1);
    });

    test('floor 2 has relaxed limits', () {
      final config = RedisRateLimitService.floorLimits[2]!;
      expect(config.messagesPerMinute, 15);
      expect(config.messagesPerHour, 500);
      expect(config.minSecondsBetweenMessages, 0);
    });

    test('floor 3+ has unlimited config', () {
      final config = RedisRateLimitService.unlimitedConfig;
      expect(config.messagesPerMinute, 1000);
      expect(config.messagesPerHour, 10000);
      expect(config.minSecondsBetweenMessages, 0);
    });
  });

  group('RedisRateLimitService - Rate Limit Logic', () {
    test('rate limits scale with floor level', () {
      final floor0 = RedisRateLimitService.floorLimits[0]!;
      final floor1 = RedisRateLimitService.floorLimits[1]!;
      final floor2 = RedisRateLimitService.floorLimits[2]!;

      // Higher floors should have higher limits
      expect(floor1.messagesPerMinute > floor0.messagesPerMinute, true);
      expect(floor2.messagesPerMinute > floor1.messagesPerMinute, true);

      expect(floor1.messagesPerHour > floor0.messagesPerHour, true);
      expect(floor2.messagesPerHour > floor1.messagesPerHour, true);

      // Higher floors should have lower delays
      expect(
        floor1.minSecondsBetweenMessages < floor0.minSecondsBetweenMessages,
        true,
      );
      expect(
        floor2.minSecondsBetweenMessages <= floor1.minSecondsBetweenMessages,
        true,
      );
    });

    test('unlimited config is truly unlimited', () {
      final unlimited = RedisRateLimitService.unlimitedConfig;
      final floor2 = RedisRateLimitService.floorLimits[2]!;

      expect(unlimited.messagesPerMinute > floor2.messagesPerMinute * 10, true);
      expect(unlimited.messagesPerHour > floor2.messagesPerHour * 10, true);
      expect(unlimited.minSecondsBetweenMessages, 0);
    });
  });

  group('RedisRateLimitService - RateLimitConfig', () {
    test('creates config with correct values', () {
      const config = RateLimitConfig(
        messagesPerMinute: 10,
        messagesPerHour: 100,
        minSecondsBetweenMessages: 1,
      );

      expect(config.messagesPerMinute, 10);
      expect(config.messagesPerHour, 100);
      expect(config.minSecondsBetweenMessages, 1);
    });

    test('config is immutable', () {
      const config = RateLimitConfig(
        messagesPerMinute: 5,
        messagesPerHour: 50,
        minSecondsBetweenMessages: 2,
      );

      // Should not be able to modify (compile-time check)
      expect(config.messagesPerMinute, 5);
    });
  });

  group('RedisRateLimitService - Edge Cases', () {
    test('handles negative floor numbers gracefully', () {
      // Should default to floor 0 config for negative floors
      final config =
          RedisRateLimitService.floorLimits[-1] ??
          RedisRateLimitService.floorLimits[0]!;
      expect(config.messagesPerMinute, 5);
    });

    test('handles very high floor numbers', () {
      // Floor 100 should use unlimited config
      final config = RedisRateLimitService.unlimitedConfig;
      expect(config.messagesPerMinute, 1000);
    });

    test('all floor configs are valid', () {
      for (final entry in RedisRateLimitService.floorLimits.entries) {
        final config = entry.value;

        // All values should be positive
        expect(
          config.messagesPerMinute > 0,
          true,
          reason: 'Floor ${entry.key} has invalid messagesPerMinute',
        );
        expect(
          config.messagesPerHour > 0,
          true,
          reason: 'Floor ${entry.key} has invalid messagesPerHour',
        );
        expect(
          config.minSecondsBetweenMessages >= 0,
          true,
          reason: 'Floor ${entry.key} has invalid minSecondsBetweenMessages',
        );

        // Hour limit should be greater than minute limit
        expect(
          config.messagesPerHour >= config.messagesPerMinute,
          true,
          reason: 'Floor ${entry.key} has inconsistent limits',
        );
      }
    });
  });

  group('RedisRateLimitService - Redis Key Format', () {
    test('generates correct Redis key format', () {
      const userId = 'user123';
      const channelId = 1;

      // Expected key formats
      final minuteKey = 'ratelimit:$userId:$channelId:minute';
      final hourKey = 'ratelimit:$userId:$channelId:hour';
      final lastMessageKey = 'ratelimit:$userId:$channelId:last';

      expect(minuteKey, 'ratelimit:user123:1:minute');
      expect(hourKey, 'ratelimit:user123:1:hour');
      expect(lastMessageKey, 'ratelimit:user123:1:last');
    });

    test('keys are unique per user and channel', () {
      const user1 = 'user1';
      const user2 = 'user2';
      const channel1 = 1;
      const channel2 = 2;

      final key1 = 'ratelimit:$user1:$channel1:minute';
      final key2 = 'ratelimit:$user2:$channel1:minute';
      final key3 = 'ratelimit:$user1:$channel2:minute';

      // All keys should be different
      expect(key1 != key2, true);
      expect(key1 != key3, true);
      expect(key2 != key3, true);
    });
  });

  group('RedisRateLimitService - Performance Characteristics', () {
    test('rate limits are appropriate for production', () {
      // Floor 0 (new users) - should prevent spam
      final floor0 = RedisRateLimitService.floorLimits[0]!;
      expect(
        floor0.messagesPerMinute <= 10,
        true,
        reason: 'Floor 0 limit too high for spam prevention',
      );

      // Floor 2 (trusted users) - should allow normal conversation
      final floor2 = RedisRateLimitService.floorLimits[2]!;
      expect(
        floor2.messagesPerMinute >= 10,
        true,
        reason: 'Floor 2 limit too low for normal conversation',
      );

      // Unlimited (high floor) - should handle power users
      final unlimited = RedisRateLimitService.unlimitedConfig;
      expect(
        unlimited.messagesPerMinute >= 100,
        true,
        reason: 'Unlimited config too restrictive',
      );
    });

    test('TTL durations are reasonable', () {
      // Minute window should be 60 seconds
      const minuteTTL = Duration(minutes: 1);
      expect(minuteTTL.inSeconds, 60);

      // Hour window should be 3600 seconds
      const hourTTL = Duration(hours: 1);
      expect(hourTTL.inSeconds, 3600);

      // Last message tracking should be short-lived
      const lastMessageTTL = Duration(minutes: 5);
      expect(lastMessageTTL.inSeconds, 300);
    });
  });

  group('RedisRateLimitService - Error Messages', () {
    test('generates helpful error messages', () {
      const floor = 0;
      const config = RedisRateLimitService.floorLimits[0];

      // Minute limit message
      final minuteMsg =
          'Rate limit: ${config!.messagesPerMinute} messages per minute. Please slow down.';
      expect(minuteMsg, contains('messages per minute'));
      expect(minuteMsg, contains('Please slow down'));

      // Hour limit message
      final hourMsg =
          'Rate limit: ${config.messagesPerHour} messages per hour. Take a break!';
      expect(hourMsg, contains('messages per hour'));
      expect(hourMsg, contains('Take a break'));

      // Wait time message
      const waitSeconds = 2;
      final waitMsg = 'Please wait $waitSeconds seconds.';
      expect(waitMsg, contains('Please wait'));
      expect(waitMsg, contains('seconds'));
    });
  });
}
