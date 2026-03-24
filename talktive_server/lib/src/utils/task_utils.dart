import 'package:serverpod/serverpod.dart';

/// Utilities for managing background tasks and session lifecycles.
class TaskUtils {
  /// Safely runs a background task with a temporary background session.
  /// This prevents 'Session is closed' errors for tasks that outlive the request.
  static void runBackground(
    Session session,
    Future<void> Function(Session backgroundSession) task,
  ) {
    // We don't await the background task so that the request can return immediately.
    Future.microtask(() async {
      // Create a background session linked to the same serverpod instance
      final backgroundSession = await session.serverpod.createSession();
      try {
        await task(backgroundSession);
      } catch (e) {
        // Log error to the background session.
        backgroundSession.log(
          'Background task error: $e',
          level: LogLevel.error,
        );
      } finally {
        // Ensure the background session is closed to free up resources
        await backgroundSession.close();
      }
    });
  }
}
