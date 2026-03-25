import 'package:serverpod/serverpod.dart' hide Message;
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/report_service.dart';
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
      throw protocol.TalktiveException(message: 'You must reach Floor 1 to report users. Keep chatting and maintain a good Trust Score!',);
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

    // Create report and apply automated moderation using ReportService
    await ReportService.createReport(
      session,
      reporter: reporter,
      target: target,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
    );

    session.log(
      'User ${reporter.userInfoId} reported ${target.userInfoId}. '
      'Penalty applied via ReportService. New Trust Score: ${target.trustScore}',
    );
  }

}
