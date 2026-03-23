import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/services/content_ephemerality_service.dart';

/// Periodic task for cleaning up ephemeral content (messages, moments, notifications, etc.).
/// This is scheduled to run every 24 hours at approximately 3 AM Eastern Time (07:00 UTC).
class DailyCleanupCall extends FutureCall {
  @override
  Future<void> invoke(Session session, dynamic object) async {
    session.log('TALKTIVE: Daily cleanup job triggered.', level: LogLevel.info);
    
    try {
      // 1. Run the heavy lifting in ContentEphemeralityService
      final stats = await ContentEphemeralityService.runCleanup(session);
      
      final total = stats.values.fold(0, (a, b) => a + b);
      session.log('TALKTIVE: Success. Summary of items removed: $stats. Total: $total', level: LogLevel.info);
    } catch (e, stack) {
      session.log('TALKTIVE: Error during daily cleanup: $e\n$stack', level: LogLevel.error);
    } finally {
      // 2. Schedule the NEXT cleanup for 3 AM Eastern (07:00 UTC) tomorrow
      final nextRun = getNextCleanupTime();
      await session.serverpod.futureCall(
        'dailyCleanup',
        null,
        at: nextRun,
      );
      session.log('TALKTIVE: Next cleanup scheduled for: $nextRun', level: LogLevel.info);
    }
  }

  /// Calculates the next occurrence of 7:00 AM UTC (3:00 AM EDT).
  static DateTime getNextCleanupTime() {
    final now = DateTime.now().toUtc();
    // Start with 7 AM UTC today
    var next = DateTime.utc(now.year, now.month, now.day, 7, 0);
    
    // If we've already passed 7 AM UTC today, schedule it for tomorrow
    if (now.isAfter(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
