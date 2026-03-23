import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/services/content_ephemerality_service.dart';

/// Periodic task for cleaning up ephemeral content (messages, moments, notifications, etc.).
/// This is scheduled to run every 24 hours.
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
      // 2. Schedule the NEXT cleanup for 24 hours from now
      final tomorrow = DateTime.now().add(const Duration(hours: 24));
      await session.serverpod.futureCall(
        'dailyCleanup',
        null,
        at: tomorrow,
      );
      session.log('TALKTIVE: Next cleanup scheduled for: $tomorrow', level: LogLevel.info);
    }
  }
}
