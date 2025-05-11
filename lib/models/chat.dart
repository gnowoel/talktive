import 'dart:math';

import '../helpers/time.dart';
import '../services/server_clock.dart';

abstract class Chat {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int messageCount;
  final String type; // 'chat' or 'topic'
  final int? readMessageCount;

  const Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.type,
    this.readMessageCount,
  });

  int get unreadCount => max(messageCount - (readMessageCount ?? 0), 0);

  int getTimeElapsed({int? now}) {
    now = now ?? ServerClock().now;
    return max(now - updatedAt, 0);
  }

  int getTimeLeft({int? now}) {
    now = now ?? ServerClock().now;
    final elapsed = getTimeElapsed(now: now);
    return max(activePeriod - elapsed, 0);
  }
}
