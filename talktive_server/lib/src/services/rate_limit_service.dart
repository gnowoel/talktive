import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';

/// Enhanced rate limiting service using Redis (Serverpod cache) for high performance.
/// Detects user floor level to adjust limits.
class RateLimitService {
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

  /// Check rate limit using Redis cache (falling back to database/memory via Serverpod).
  static Future<String?> checkRateLimit(
    Session session,
    String userId,
    int channelId,
    int floor,
  ) async {
    final config = _getConfigForFloor(floor);
    final now = DateTime.now();

    try {
      // Redis keys for rate limiting - using simple counters with TTL
      final minuteKey = 'ratelimit:$userId:$channelId:minute:${now.minute}';
      final hourKey = 'ratelimit:$userId:$channelId:hour:${now.hour}';
      final lastMessageKey = 'ratelimit:$userId:$channelId:last';

      // Check last message time (minimum interval)
      final lastMessageEntry = await session.caches.global.get<CacheString>(
        lastMessageKey,
      );
      if (lastMessageEntry != null) {
        final lastMessage = DateTime.parse(lastMessageEntry.value);
        final secondsSince = now.difference(lastMessage).inSeconds;

        if (secondsSince < config.minSecondsBetweenMessages) {
          return 'Please wait ${config.minSecondsBetweenMessages - secondsSince} seconds.';
        }
      }

      // Check minute limit
      final minuteEntry = await session.caches.global.get<CacheInt>(minuteKey);
      final minuteCount = minuteEntry?.value ?? 0;

      if (minuteCount >= config.messagesPerMinute) {
        return 'Rate limit: ${config.messagesPerMinute} messages per minute. Please slow down.';
      }

      // Check hour limit
      final hourEntry = await session.caches.global.get<CacheInt>(hourKey);
      final hourCount = hourEntry?.value ?? 0;

      if (hourCount >= config.messagesPerHour) {
        return 'Rate limit: ${config.messagesPerHour} messages per hour. Take a break!';
      }

      // Increment counters and update TTL
      await session.caches.global.put(
        minuteKey,
        CacheInt(value: minuteCount + 1),
        lifetime: const Duration(minutes: 2),
      );

      await session.caches.global.put(
        hourKey,
        CacheInt(value: hourCount + 1),
        lifetime: const Duration(hours: 2),
      );

      await session.caches.global.put(
        lastMessageKey,
        CacheString(value: now.toIso8601String()),
        lifetime: const Duration(minutes: 5),
      );

      return null; // No rate limit hit
    } catch (e) {
      session.log('Rate limit check error: $e', level: LogLevel.warning);
      // Fallback to allowing the message if cache fails (availability over restriction)
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
      final now = DateTime.now();
      final minuteKey = 'ratelimit:$userId:$channelId:minute:${now.minute}';
      final hourKey = 'ratelimit:$userId:$channelId:hour:${now.hour}';

      final minuteEntry = await session.caches.global.get<CacheInt>(minuteKey);
      final hourEntry = await session.caches.global.get<CacheInt>(hourKey);

      return {
        'messagesThisMinute': minuteEntry?.value ?? 0,
        'messagesThisHour': hourEntry?.value ?? 0,
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
      final now = DateTime.now();
      final minuteKey = 'ratelimit:$userId:$channelId:minute:${now.minute}';
      final hourKey = 'ratelimit:$userId:$channelId:hour:${now.hour}';
      final lastMessageKey = 'ratelimit:$userId:$channelId:last';

      await session.caches.global.invalidateKey(minuteKey);
      await session.caches.global.invalidateKey(hourKey);
      await session.caches.global.invalidateKey(lastMessageKey);
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
