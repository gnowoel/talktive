import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

/// Service for archiving old data to reduce database size and costs.
/// Implements a simple archival strategy for messages older than 90 days.
class DataArchivalService {
  /// Archive messages older than the specified number of days.
  /// Default: 90 days (3 months)
  static Future<int> archiveOldMessages(
    Session session, {
    int daysOld = 90,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    try {
      // Find old messages
      final oldMessages = await protocol.Message.db.find(
        session,
        where: (t) => t.createdAt < cutoffDate,
        limit: 1000, // Process in batches to avoid memory issues
      );

      if (oldMessages.isEmpty) {
        session.log('No messages to archive');
        return 0;
      }

      // Delete old messages
      // In a production system, you might want to:
      // 1. Export to cold storage (S3, etc.) before deleting
      // 2. Keep a summary/count for analytics
      // 3. Preserve messages in active conversations
      int deletedCount = 0;
      for (final message in oldMessages) {
        await protocol.Message.db.deleteRow(session, message);
        deletedCount++;
      }

      session.log('Archived $deletedCount messages older than $daysOld days');
      return deletedCount;
    } catch (e, stack) {
      session.log(
        'Error archiving messages: $e\n$stack',
        level: LogLevel.error,
      );
      return 0;
    }
  }

  /// Archive old moments (photos) older than the specified number of days.
  /// Default: 180 days (6 months)
  static Future<int> archiveOldMoments(
    Session session, {
    int daysOld = 180,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    try {
      // Find old moments
      final oldMoments = await protocol.Moment.db.find(
        session,
        where: (t) => t.createdAt < cutoffDate,
        limit: 1000, // Process in batches
      );

      if (oldMoments.isEmpty) {
        session.log('No moments to archive');
        return 0;
      }

      int deletedCount = 0;
      for (final moment in oldMoments) {
        // Delete associated likes
        final likes = await protocol.MomentLike.db.find(
          session,
          where: (t) => t.momentId.equals(moment.id),
        );
        for (final like in likes) {
          await protocol.MomentLike.db.deleteRow(session, like);
        }

        // Delete associated comments
        final comments = await protocol.MomentComment.db.find(
          session,
          where: (t) => t.momentId.equals(moment.id),
        );
        for (final comment in comments) {
          await protocol.MomentComment.db.deleteRow(session, comment);
        }

        // Delete the moment
        await protocol.Moment.db.deleteRow(session, moment);
        deletedCount++;
      }

      session.log('Archived $deletedCount moments older than $daysOld days');
      return deletedCount;
    } catch (e, stack) {
      session.log(
        'Error archiving moments: $e\n$stack',
        level: LogLevel.error,
      );
      return 0;
    }
  }

  /// Archive resolved reports older than the specified number of days.
  /// Default: 30 days (1 month)
  static Future<int> archiveOldReports(
    Session session, {
    int daysOld = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    try {
      // Find old resolved reports
      final oldReports = await protocol.Report.db.find(
        session,
        where: (t) =>
            (t.status.equals(protocol.ReportStatus.approved) |
                t.status.equals(protocol.ReportStatus.rejected)) &
            t.resolvedAt.notEquals(null) &
            (t.resolvedAt! < cutoffDate),
        limit: 1000,
      );

      if (oldReports.isEmpty) {
        session.log('No reports to archive');
        return 0;
      }

      int deletedCount = 0;
      for (final report in oldReports) {
        await protocol.Report.db.deleteRow(session, report);
        deletedCount++;
      }

      session.log('Archived $deletedCount reports older than $daysOld days');
      return deletedCount;
    } catch (e, stack) {
      session.log(
        'Error archiving reports: $e\n$stack',
        level: LogLevel.error,
      );
      return 0;
    }
  }

  /// Archive old notifications older than the specified number of days.
  /// Default: 30 days (1 month)
  static Future<int> archiveOldNotifications(
    Session session, {
    int daysOld = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    try {
      // Find old read notifications
      final oldNotifications = await protocol.UserNotification.db.find(
        session,
        where: (t) => t.read.equals(true) & (t.createdAt < cutoffDate),
        limit: 1000,
      );

      if (oldNotifications.isEmpty) {
        session.log('No notifications to archive');
        return 0;
      }

      int deletedCount = 0;
      for (final notification in oldNotifications) {
        await protocol.UserNotification.db.deleteRow(session, notification);
        deletedCount++;
      }

      session.log(
        'Archived $deletedCount notifications older than $daysOld days',
      );
      return deletedCount;
    } catch (e, stack) {
      session.log(
        'Error archiving notifications: $e\n$stack',
        level: LogLevel.error,
      );
      return 0;
    }
  }

  /// Run all archival tasks.
  /// This should be called periodically (e.g., daily via cron job).
  static Future<Map<String, int>> runArchivalTasks(Session session) async {
    session.log('Starting data archival tasks...');

    final results = <String, int>{};

    results['messages'] = await archiveOldMessages(session);
    results['moments'] = await archiveOldMoments(session);
    results['reports'] = await archiveOldReports(session);
    results['notifications'] = await archiveOldNotifications(session);

    final totalArchived = results.values.reduce((a, b) => a + b);
    session.log(
      'Data archival completed. Total items archived: $totalArchived',
    );

    return results;
  }

  /// Get statistics about data that can be archived.
  static Future<Map<String, int>> getArchivalStats(Session session) async {
    final stats = <String, int>{};

    // Messages older than 90 days
    final messagesCount = await protocol.Message.db.count(
      session,
      where: (t) =>
          t.createdAt < DateTime.now().subtract(const Duration(days: 90)),
    );
    stats['archivableMessages'] = messagesCount;

    // Moments older than 180 days
    final momentsCount = await protocol.Moment.db.count(
      session,
      where: (t) =>
          t.createdAt < DateTime.now().subtract(const Duration(days: 180)),
    );
    stats['archivableMoments'] = momentsCount;

    // Resolved reports older than 30 days
    final reportsCount = await protocol.Report.db.count(
      session,
      where: (t) =>
          (t.status.equals(protocol.ReportStatus.approved) |
              t.status.equals(protocol.ReportStatus.rejected)) &
          t.resolvedAt.notEquals(null) &
          (t.resolvedAt! < DateTime.now().subtract(const Duration(days: 30))),
    );
    stats['archivableReports'] = reportsCount;

    // Read notifications older than 30 days
    final notificationsCount = await protocol.UserNotification.db.count(
      session,
      where: (t) =>
          t.read.equals(true) &
          (t.createdAt < DateTime.now().subtract(const Duration(days: 30))),
    );
    stats['archivableNotifications'] = notificationsCount;

    return stats;
  }
}
