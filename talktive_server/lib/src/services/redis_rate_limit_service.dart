import 'package:serverpod/serverpod.dart';

/// Enhanced rate limiting service using Redis for better performance
class RedisRateLimitService {
  /// Rate limit configuration based on floor level
  static const Map<int, RateLimitConfig> floorLimits = {
    0: RateLimitConfig(
      messagesPerMinute: 5,
      messagesPerHour: 100,
      minSecondsBetweenMessages: 2,
    ),
    1: RateLimitConfig(
      messagesPerMinute: 10,
      messagesPerHour: 300,
      minSecondsBetweenMessages: 1,
    ),
    2: RateLimitConfig(
      messagesPerMinute: 15,
      messagesPerHour: 500,
      minSecondsBetweenMessages: 0,
    ),
  };

  static const RateLimitConfig unlimitedConfig = RateLimitConfig(
    messagesPerMinute: 1000,
    messagesPerHour: 10000,
    minSecondsBetweenMessages: 0,
  );

  /// Check rate limit using Redis (much faster than database)
  static Future<String?> checkRateLimit(
    Session session,
    String userId,
    int channelId,
    int floor,
  ) async {
    final config = _getConfigForFloor(floor);
    final now = DateTime.now();

    try {
      // Redis keys for rate limiting
      final minuteKey = 'ratelimit:$userId:$channelId:minute';
      final hourKey = 'ratelimit:$userId:$channelId:hour';
      final lastMessageKey = 'ratelimit:$userId:$channelId:last';

      // Check last message time
      final lastMessageStr = await session.redis.get(lastMessageKey);
      if (lastMessageStr != null) {
        final lastMessage = DateTime.parse(lastMessageStr);
        final secondsSince = now.difference(lastMessage).inSeconds;

        if (secondsSince < config.minSecondsBetweenMessages) {
          return 'Please wait ${config.minSecondsBetweenMessages - secondsSince} seconds.';
        }
      }

      // Check minute limit
      final minuteCount = await session.redis.get(minuteKey);
      if (minuteCount != null &&
          int.parse(minuteCount) >= config.messagesPerMinute) {
        return 'Rate limit: ${config.messagesPerMinute} messages per minute. Please slow down.';
      }

      // Check hour limit
      final hourCount = await session.redis.get(hourKey);
      if (hourCount != null && int.parse(hourCount) >= config.messagesPerHour) {
        return 'Rate limit: ${config.messagesPerHour} messages per hour. Take a break!';
      }

      // Increment counters
      await session.redis.incr(minuteKey);
      await session.redis.expire(minuteKey, const Duration(minutes: 1));

      await session.redis.incr(hourKey);
      await session.redis.expire(hourKey, const Duration(hours: 1));

      await session.redis.setEx(
        lastMessageKey,
        now.toIso8601String(),
        const Duration(minutes: 5),
      );

      return null; // No rate limit hit
    } catch (e) {
      session.log('Redis rate limit error: $e', level: LogLevel.warning);
      // Fallback to allowing the message if Redis fails
      return null;
    }
  }

  static RateLimitConfig _getConfigForFloor(int floor) {
    if (floor >= 3) return unlimitedConfig;
    return floorLimits[floor] ?? floorLimits[0]!;
  }

  /// Get current rate limit status for a user
  static Future<Map<String, dynamic>> getRateLimitStatus(
    Session session,
    String userId,
    int channelId,
  ) async {
    try {
      final minuteKey = 'ratelimit:$userId:$channelId:minute';
      final hourKey = 'ratelimit:$userId:$channelId:hour';

      final minuteCount = await session.redis.get(minuteKey);
      final hourCount = await session.redis.get(hourKey);

      return {
        'messagesThisMinute': minuteCount != null ? int.parse(minuteCount) : 0,
        'messagesThisHour': hourCount != null ? int.parse(hourCount) : 0,
      };
    } catch (e) {
      return {
        'messagesThisMinute': 0,
        'messagesThisHour': 0,
      };
    }
  }

  /// Clear rate limits for a user (admin function)
  static Future<void> clearRateLimits(
    Session session,
    String userId,
    int channelId,
  ) async {
    try {
      final minuteKey = 'ratelimit:$userId:$channelId:minute';
      final hourKey = 'ratelimit:$userId:$channelId:hour';
      final lastMessageKey = 'ratelimit:$userId:$channelId:last';

      await session.redis.delete([minuteKey, hourKey, lastMessageKey]);
    } catch (e) {
      session.log('Error clearing rate limits: $e', level: LogLevel.warning);
    }
  }
}

/// Rate limit configuration
class RateLimitConfig {
  final int messagesPerMinute;
  final int messagesPerHour;
  final int minSecondsBetweenMessages;

  const RateLimitConfig({
    required this.messagesPerMinute,
    required this.messagesPerHour,
    required this.minSecondsBetweenMessages,
  });
}
