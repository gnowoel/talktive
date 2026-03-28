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
      throw protocol.TalktiveException(
        message:
            'You must reach Floor 1 to report users. Keep chatting and maintain a good Trust Score!',
      );
    }

    // Fetch target
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target user not found');
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
