import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/apartment_service.dart';

class ReportEndpoint extends Endpoint {
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
    final reporterIdentifier = session.authenticated?.userIdentifier;
    if (reporterIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final reporterUuid = UuidValue.fromString(reporterIdentifier);
    final targetUuid = UuidValue.fromString(targetUserId);

    // Cannot report yourself
    if (reporterUuid == targetUuid) {
      throw Exception('You cannot report yourself.');
    }

    // Fetch reporter
    final reporter = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(reporterUuid),
    );
    if (reporter == null) {
      throw Exception('Reporter profile not found');
    }

    // Floor 0 users cannot report (prevent abuse from new accounts)
    if (reporter.floor < 1) {
      throw Exception(
        'You must be at least Floor 1 to report users. Keep chatting to level up!',
      );
    }

    // Fetch target
    final target = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) {
      throw Exception('Target user not found');
    }

    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));

    // Check if already reported this user today
    final existingReport = await Report.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) &
          t.targetId.equals(targetUuid) &
          (t.createdAt > oneDayAgo),
    );
    if (existingReport != null) {
      throw Exception('You have already reported this user today.');
    }

    // Check cooldown (30 minutes between any reports)
    final recentReport = await Report.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) & (t.createdAt > thirtyMinutesAgo),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
    if (recentReport != null) {
      final minutesLeft = 30 - now.difference(recentReport.createdAt).inMinutes;
      throw Exception(
        'Please wait $minutesLeft minutes before reporting again.',
      );
    }

    // Check daily report limit (5 per day)
    final todayReports = await Report.db.count(
      session,
      where: (t) =>
          t.reporterId.equals(reporterUuid) & (t.createdAt > oneDayAgo),
    );
    if (todayReports >= 5) {
      throw Exception('Daily report limit reached (5 reports per day).');
    }

    // Create report
    final report = Report(
      reporterId: reporterUuid,
      targetId: targetUuid,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
      createdAt: now,
      resolved: false,
    );
    await Report.db.insertRow(session, report);

    // Apply penalty to target
    ApartmentService.applyReportPenalty(
      reporter: reporter,
      target: target,
    );

    // Update target's floor
    target.floor = ApartmentService.calculateFloor(
      messageCount: target.experienceMessageCount,
      creditScore: target.creditScore,
    );

    await Resident.db.updateRow(session, target);

    session.log(
      'User ${reporter.userInfoId} reported ${target.userInfoId}. '
      'Penalty: ${reporter.floor} points. New credit: ${target.creditScore}',
    );
  }

  /// Gets the number of reports a user has received (for moderation).
  Future<int> getReportCount(
    Session session,
    String userId,
  ) async {
    final userUuid = UuidValue.fromString(userId);
    return await Report.db.count(
      session,
      where: (t) => t.targetId.equals(userUuid) & t.resolved.equals(false),
    );
  }

  /// Lists recent reports for moderation (admin only).
  Future<List<Report>> listReports(
    Session session, {
    int limit = 50,
    bool onlyUnresolved = true,
  }) async {
    // TODO: Add admin role check
    final reporterIdentifier = session.authenticated?.userIdentifier;
    if (reporterIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final reporterUuid = UuidValue.fromString(reporterIdentifier);
    final reporter = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(reporterUuid),
    );

    if (reporter?.role != 'admin') {
      throw Exception('Admin access required');
    }

    return await Report.db.find(
      session,
      where: onlyUnresolved ? (t) => t.resolved.equals(false) : null,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Marks a report as resolved (admin only).
  Future<void> resolveReport(
    Session session,
    int reportId,
  ) async {
    // TODO: Add admin role check
    final reporterIdentifier = session.authenticated?.userIdentifier;
    if (reporterIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final reporterUuid = UuidValue.fromString(reporterIdentifier);
    final reporter = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(reporterUuid),
    );

    if (reporter?.role != 'admin') {
      throw Exception('Admin access required');
    }

    final report = await Report.db.findById(session, reportId);
    if (report == null) {
      throw Exception('Report not found');
    }

    report.resolved = true;
    await Report.db.updateRow(session, report);
  }
}
