import 'dart:math';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/notification_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class ReportEndpoint extends Endpoint with EndpointAuthMixin {
  /// Reports a user for inappropriate behavior.
  /// Implements abuse prevention:
  /// - Floor 0 users cannot report
  /// - Max 5 reports per day per user
  /// - 30-minute cooldown between reports
  /// - Cannot report the same user more than once per day
  Future<void> reportUser(
    Session session, {
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) async {
    // Validate inputs
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    InputValidationService.validateReportReason(reason).throwIfInvalid();
    if (channelId != null) {
      InputValidationService.validateId(
        channelId,
        'Channel ID',
      ).throwIfInvalid();
    }
    if (messageId != null) {
      InputValidationService.validateId(
        messageId,
        'Message ID',
      ).throwIfInvalid();
    }

    final reporterUuid = await getUserId(session);
    final targetUuid = UuidValue.fromString(targetUserId);

    // Cannot report yourself
    if (reporterUuid == targetUuid) {
      throw protocol.TalktiveException(message: 'You cannot report yourself.');
    }

    // Fetch reporter
    final reporter = await getResidentProfile(session, reporterUuid);

    // Effective floor ≥ 1 required to report (prevents abuse from new
    // accounts and from trustScore-restricted users)
    if (ApartmentService.computeEffectiveFloor(reporter) < 1) {
      throw protocol.TalktiveException(message: 'You must reach Floor 1 to report users. Keep chatting and maintain good trustScore!',);
    }

    // Fetch target
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target user not found');
    }

    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));

    // Check if already reported this user EVER (One-Vote Rule)
    final existingReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) & t.targetId.equals(targetUuid),
    );
    if (existingReport != null) {
      throw protocol.TalktiveException(message: 'You have already reported this user.');
    }

    // Check if they liked the user EVER (One-Vote Rule)
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) =>
          t.senderId.equals(reporterUuid) & t.receiverId.equals(targetUuid),
    );
    if (existingLike != null) {
      throw protocol.TalktiveException(message: 'You cannot report a user you have vouched for. Please unlike them first.',);
    }

    // Check cooldown (30 minutes between any reports)
    final recentReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) & (t.createdAt > thirtyMinutesAgo),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
    if (recentReport != null) {
      final minutesLeft = 30 - now.difference(recentReport.createdAt).inMinutes;
      throw protocol.TalktiveException(message: 'Please wait $minutesLeft minutes before reporting again.',);
    }

    // Check daily report limit (3 per day)
    final todayReports = await protocol.Report.db.count(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) & (t.createdAt > oneDayAgo),
    );
    if (todayReports >= 3) {
      throw protocol.TalktiveException(message: 'Daily report limit reached (3 reports per day).');
    }

    // Create report
    final report = protocol.Report(
      reporterId: reporterUuid,
      targetId: targetUuid,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
      createdAt: now,
      status: protocol.ReportStatus.pending,
    );
    await protocol.Report.db.insertRow(session, report);

    // Apply penalty to target
    ApartmentService.applyReportPenalty(
      reporter: reporter,
      target: target,
    );

    // Check for auto-escalation based on recent reports
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentReports7Days = await protocol.Report.db.count(
      session,
      where: (t) =>
          t.targetId.equals(targetUuid) & (t.createdAt > sevenDaysAgo),
    );

    final recentReports30Days = await protocol.Report.db.count(
      session,
      where: (t) =>
          t.targetId.equals(targetUuid) & (t.createdAt > thirtyDaysAgo),
    );

    // Auto-escalation thresholds
    if (recentReports30Days >= 10) {
      // 10 reports in 30 days: Severe penalty
      target.trustScore = 0; // Muted until trustScore restores
      session.log(
        'User ${target.userInfoId} received 10+ reports in 30 days. Reputation set to 0.',
      );
      // Notify user of severe penalty
      try {
        await NotificationService.sendSafetyNotification(
          session,
          target.userInfoId,
          'Account Restricted ❌',
          'Your account has been restricted due to multiple reports. Your reputation has been reset.',
        );
      } catch (e) {
        session.log('Failed to send severe penalty notification: $e');
      }
    } else if (recentReports7Days >= 5) {
      // 5 reports in 7 days: 24-hour mute
      target.mutedUntil = now.add(const Duration(hours: 24));
      session.log(
        'User ${target.userInfoId} received 5+ reports in 7 days. Muted for 24 hours.',
      );
      
      // Notify user of mute
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
        'User ${target.userInfoId} received 3+ reports in 7 days. Warning issued.',
      );
      
      // Send warning notification
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

    await protocol.Resident.db.updateRow(session, target);

    session.log(
      'User ${reporter.userInfoId} reported ${target.userInfoId}. '
      'Penalty: ${max(1, reporter.level)} trustScore points. New trustScore: ${target.trustScore}',
    );
  }

  /// Gets the number of reports a user has received (for moderation).
  Future<int> getReportCount(
    Session session,
    String userId,
  ) async {
    final userUuid = UuidValue.fromString(userId);
    return await protocol.Report.db.count(
      session,
      where: (t) =>
          t.targetId.equals(userUuid) &
          t.status.equals(protocol.ReportStatus.pending),
    );
  }

  /// Lists recent reports for moderation (admin only).
  Future<List<protocol.Report>> listReports(
    Session session, {
    int limit = 50,
    bool onlyUnresolved = true,
  }) async {
    await getAdminProfile(session);

    return await protocol.Report.db.find(
      session,
      where: onlyUnresolved
          ? (t) => t.status.equals(protocol.ReportStatus.pending)
          : null,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Marks a report as resolved (admin only).
  Future<void> resolveReport(
    Session session,
    int reportId,
    bool approved,
  ) async {
    await getAdminProfile(session);

    final report = await protocol.Report.db.findById(session, reportId);
    if (report == null) {
      throw protocol.TalktiveException(message: 'Report not found');
    }

    report.status = approved
        ? protocol.ReportStatus.approved
        : protocol.ReportStatus.rejected;
    report.resolvedAt = DateTime.now();

    await protocol.Report.db.updateRow(session, report);
  }

  /// Gets detailed report information with user context (admin only).
  Future<Map<String, dynamic>> getReportDetails(
    Session session,
    int reportId,
  ) async {
    // Validate inputs
    InputValidationService.validateId(reportId, 'Report ID').throwIfInvalid();

    await getAdminProfile(session);

    final report = await protocol.Report.db.findById(session, reportId);
    if (report == null) {
      throw protocol.TalktiveException(message: 'Report not found');
    }

    // Get reporter info
    final reporter = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(report.reporterId),
    );

    // Get target info
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(report.targetId),
    );

    // Get message if available
    protocol.Message? message;
    if (report.messageId != null) {
      message = await protocol.Message.db.findById(session, report.messageId!);
    }

    return {
      'report': report.toJson(),
      'reporter': {
        'userId': reporter?.userInfoId.toString(),
        'floor': reporter != null
            ? ApartmentService.computeEffectiveFloor(reporter)
            : null,
        'trustScore': reporter?.trustScore,
      },
      'target': {
        'userId': target?.userInfoId.toString(),
        'floor': target != null
            ? ApartmentService.computeEffectiveFloor(target)
            : null,
        'trustScore': target?.trustScore,
      },
      'message': message?.toJson(),
    };
  }
}
