import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'apartment_service.dart';

/// Smart rate limiting service that adjusts limits based on user floor level.
class RateLimitService {
  /// Rate limit configuration based on floor level.
  /// Higher floors get more generous limits.
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
    // Floor 3+ has no practical limits
  };

  /// Default config for floors 3 and above.
  static const RateLimitConfig unlimitedConfig = RateLimitConfig(
    messagesPerMinute: 1000,
    messagesPerHour: 10000,
    minSecondsBetweenMessages: 0,
  );

  /// Checks if a user can send a message based on their floor level.
  /// Returns null if allowed, or an error message if rate limited.
  static Future<String?> checkRateLimit(
    Session session,
    Resident resident,
    int channelId,
  ) async {
    final now = DateTime.now();
    final config = _getConfigForFloor(
      ApartmentService.computeReputation(resident),
    );

    // Get or create rate limit record
    var rateLimit = await RateLimit.db.findFirstRow(
      session,
      where: (t) =>
          t.userInfoId.equals(resident.userInfoId) &
          t.channelId.equals(channelId),
    );

    if (rateLimit == null) {
      // First message in this channel
      rateLimit = RateLimit(
        userInfoId: resident.userInfoId,
        channelId: channelId,
        messageCount: 1,
        windowStart: now,
        lastMessageAt: now,
      );
      await RateLimit.db.insertRow(session, rateLimit);
      return null;
    }

    // Check minimum time between messages
    final secondsSinceLastMessage = now
        .difference(rateLimit.lastMessageAt)
        .inSeconds;
    if (secondsSinceLastMessage < config.minSecondsBetweenMessages) {
      return 'Please wait ${config.minSecondsBetweenMessages - secondsSinceLastMessage} seconds before sending another message.';
    }

    // Check if we need to reset the window (1 hour)
    final hoursSinceWindowStart = now.difference(rateLimit.windowStart).inHours;
    if (hoursSinceWindowStart >= 1) {
      // Reset window
      rateLimit.windowStart = now;
      rateLimit.messageCount = 1;
      rateLimit.lastMessageAt = now;
      await RateLimit.db.updateRow(session, rateLimit);
      return null;
    }

    // Check hourly limit
    if (rateLimit.messageCount >= config.messagesPerHour) {
      final minutesUntilReset =
          60 - now.difference(rateLimit.windowStart).inMinutes;
      return 'Hourly message limit reached. Try again in $minutesUntilReset minutes.';
    }

    // Check per-minute limit
    final minutesSinceWindowStart = now
        .difference(rateLimit.windowStart)
        .inMinutes;
    if (minutesSinceWindowStart == 0) {
      // Still in the first minute
      if (rateLimit.messageCount >= config.messagesPerMinute) {
        return 'Sending too fast. Please wait a moment.';
      }
    }

    // Update rate limit
    rateLimit.messageCount += 1;
    rateLimit.lastMessageAt = now;
    await RateLimit.db.updateRow(session, rateLimit);

    return null;
  }

  /// Gets the rate limit configuration for a given floor.
  static RateLimitConfig _getConfigForFloor(int floor) {
    if (floor >= 3) {
      return unlimitedConfig;
    }
    return floorLimits[floor] ?? floorLimits[0]!;
  }
}

/// Configuration for rate limiting.
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
