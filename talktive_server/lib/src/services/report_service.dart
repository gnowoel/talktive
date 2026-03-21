import 'package:serverpod/serverpod.dart' hide Message;
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'apartment_service.dart';
import 'notification_service.dart';

/// Service for managing reports and automated moderation.
class ReportService {
  /// Create a new report and handle automated escalation.
  static Future<protocol.Report> createReport(
    Session session, {
    required protocol.Resident reporter,
    required protocol.Resident target,
    required String reason,
    int? channelId,
    int? messageId,
  }) async {
    final now = DateTime.now();

    // 1. Create the report
    final report = protocol.Report(
      reporterId: reporter.userInfoId,
      targetId: target.userInfoId,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
      createdAt: now,
      status: protocol.ReportStatus.pending,
    );
    final savedReport = await protocol.Report.db.insertRow(session, report);

    // 2. Apply initial penalty via ApartmentService
    ApartmentService.applyReportPenalty(
      reporter: reporter,
      target: target,
    );

    // 3. Automated moderation based on report frequency
    await _handleAutoModeration(session, target);

    // 4. Update the target resident
    await protocol.Resident.db.updateRow(session, target);

    return savedReport;
  }

  /// Handles automated penalties based on report thresholds.
  static Future<void> _handleAutoModeration(
    Session session,
    protocol.Resident target,
  ) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Fetch recent report counts
    final recentReports7Days = await protocol.Report.db.count(
      session,
      where: (t) =>
          t.targetId.equals(target.userInfoId) & (t.createdAt > sevenDaysAgo),
    );

    final recentReports30Days = await protocol.Report.db.count(
      session,
      where: (t) =>
          t.targetId.equals(target.userInfoId) & (t.createdAt > thirtyDaysAgo),
    );

    // Auto-escalation thresholds
    if (recentReports30Days >= 10) {
      // 10 reports in 30 days: Severe penalty (Trust Score 0)
      target.trustScore = 0;
      session.log(
        'User ${target.userInfoId} reached severe report threshold (10+ reports in 30d). Trust Score set to 0.',
      );
      
      try {
        await NotificationService.sendSafetyNotification(
          session,
          target.userInfoId,
          'Account Restricted ❌',
          'Your account has been restricted due to multiple reports. Reputation set to 0.',
        );
      } catch (e) {
        session.log('Failed to send severe penalty notification: $e');
      }
    } else if (recentReports7Days >= 5) {
      // 5 reports in 7 days: 24-hour mute
      target.mutedUntil = now.add(const Duration(hours: 24));
      session.log(
        'User ${target.userInfoId} reached mute threshold (5+ reports in 7d). Muted for 24h.',
      );
      
      try {
        await NotificationService.sendSafetyNotification(
          session,
          target.userInfoId,
          'Temporarily Muted ⏳',
          'Your account is muted for 24 hours due to community reports. Please review our guidelines.',
        );
      } catch (e) {
        session.log('Failed to send mute notification: $e');
      }
    } else if (recentReports7Days >= 3) {
      // 3 reports in 7 days: Warning
      session.log(
        'User ${target.userInfoId} reached warning threshold (3+ reports in 7d).',
      );
      
      try {
        await NotificationService.sendWarningNotification(
          session,
          target.userInfoId,
          'You have received several reports recently. Please be mindful of our community rules.',
        );
      } catch (e) {
        session.log('Failed to send warning notification: $e');
      }
    }
  }

  /// Resolves a report with optional admin note.
  static Future<protocol.Report> resolveReport(
    Session session, {
    required int reportId,
    required protocol.ReportStatus status,
    String? adminNotes,
  }) async {
    final report = await protocol.Report.db.findById(session, reportId);
    if (report == null) {
      throw protocol.TalktiveException(message: 'Report not found');
    }

    report.status = status;
    report.adminNotes = adminNotes;
    report.resolvedAt = DateTime.now();

    return await protocol.Report.db.updateRow(session, report);
  }
}
