import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'resident_service.dart';
import 'lounge_service.dart';

/// Service for handling administrative tasks, reporting, and statistics.
class AdminService {
  /// Cache for platform statistics to avoid expensive re-computation.
  static protocol.AdminStatistics? _cachedStats;
  static DateTime? _lastStatsUpdate;
  static const _statsCacheDuration = Duration(minutes: 15);

  /// Fetches all reports with optional status filtering.
  static Future<List<protocol.AdminReportSummary>> getAllReports(
    Session session, {
    protocol.ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final reports = await protocol.Report.db.find(
      session,
      where: (t) => status != null ? t.status.equals(status) : Constant.bool(true),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    if (reports.isEmpty) return [];

    final userIds = <UuidValue>{};
    for (final report in reports) {
      userIds.add(report.reporterId);
      userIds.add(report.targetId);
    }

    final residents = await ResidentService.getResidents(session, userIds.toList());
    final userCounts = await ResidentService.getBatchUserCounts(session, userIds.toList());
    final residentMap = {for (final r in residents) r.userInfoId.toString(): r};

    return reports.map((report) {
      final reporterResident = residentMap[report.reporterId.toString()];
      final targetResident = residentMap[report.targetId.toString()];

      final reporterSummary = reporterResident != null
          ? ResidentService.toAdminUserSummary(
              reporterResident,
              messageCount: userCounts[report.reporterId.toString()]?['messages'],
              momentCount: userCounts[report.reporterId.toString()]?['moments'],
              reportCount: userCounts[report.reporterId.toString()]?['reports'],
            )
          : null;

      final targetSummary = targetResident != null
          ? ResidentService.toAdminUserSummary(
              targetResident,
              messageCount: userCounts[report.targetId.toString()]?['messages'],
              momentCount: userCounts[report.targetId.toString()]?['moments'],
              reportCount: userCounts[report.targetId.toString()]?['reports'],
            )
          : null;

      return protocol.AdminReportSummary(
        report: report,
        reporter: reporterSummary ?? protocol.AdminUserSummary(
          userId: report.reporterId,
          userName: 'Unknown',
          floor: 0,
          trustScore: 0,
          level: 0,
          xp: 0,
          role: protocol.ResidentRole.user,
          suspended: false,
          messageCount: 0,
          momentCount: 0,
          reportCount: 0,
          createdAt: DateTime.now(),
        ),
        target: targetSummary ?? protocol.AdminUserSummary(
          userId: report.targetId,
          userName: 'Unknown',
          floor: 0,
          trustScore: 0,
          level: 0,
          xp: 0,
          role: protocol.ResidentRole.user,
          suspended: false,
          messageCount: 0,
          momentCount: 0,
          reportCount: 0,
          createdAt: DateTime.now(),
        ),
      );
    }).toList();
  }

  /// Computes platform-wide statistics.
  static Future<protocol.AdminStatistics> getStatistics(Session session) async {
    if (_cachedStats != null &&
        _lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!) < _statsCacheDuration) {
      return _cachedStats!;
    }

    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(days: 1));
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final results = await Future.wait([
      // Totals
      protocol.Resident.db.count(session),
      protocol.Message.db.count(session),
      protocol.Moment.db.count(session),
      protocol.Lounge.db.count(session),
      protocol.Report.db.count(session),
      protocol.Report.db.count(session, where: (t) => t.status.equals(protocol.ReportStatus.pending)),
      
      // Last 24h
      protocol.Message.db.count(session, where: (t) => t.createdAt >= dayAgo),
      protocol.Moment.db.count(session, where: (t) => t.createdAt >= dayAgo),
      protocol.Report.db.count(session, where: (t) => t.createdAt >= dayAgo),
      
      // Last 7d
      protocol.Message.db.count(session, where: (t) => t.createdAt >= weekAgo),
      protocol.Moment.db.count(session, where: (t) => t.createdAt >= weekAgo),
      protocol.Report.db.count(session, where: (t) => t.createdAt >= weekAgo),

      // Last 30d
      protocol.Message.db.count(session, where: (t) => t.createdAt >= monthAgo),
      protocol.Moment.db.count(session, where: (t) => t.createdAt >= monthAgo),
      protocol.Report.db.count(session, where: (t) => t.createdAt >= monthAgo),

      // Active Users (24h, 7d, 30d)
      protocol.Resident.db.count(session,
          where: (t) => (t.lastLoginDate >= dayAgo) | (t.lastMessageDate >= dayAgo)),
      protocol.Resident.db.count(session,
          where: (t) => (t.lastLoginDate >= weekAgo) | (t.lastMessageDate >= weekAgo)),
      protocol.Resident.db.count(session,
          where: (t) => (t.lastLoginDate >= monthAgo) | (t.lastMessageDate >= monthAgo)),
    ]);

    final totals = protocol.AdminTotals(
      users: results[0],
      messages: results[1],
      moments: results[2],
      lounges: results[3],
      reports: results[4],
      pendingReports: results[5],
    );

    final last24h = protocol.AdminActivity(
      messages: results[6],
      moments: results[7],
      reports: results[8],
      activeUsers: results[15],
    );

    final last7d = protocol.AdminActivity(
      messages: results[9],
      moments: results[10],
      reports: results[11],
      activeUsers: results[16],
    );

    final last30d = protocol.AdminActivity(
      messages: results[12],
      moments: results[13],
      reports: results[14],
      activeUsers: results[17],
    );

    final stats = protocol.AdminStatistics(
      totals: totals,
      last24h: last24h,
      last7d: last7d,
      last30d: last30d,
    );

    _cachedStats = stats;
    _lastStatsUpdate = now;

    return stats;
  }

  /// Searches for residents based on username or identifier.
  static Future<List<protocol.AdminUserSummary>> searchUsers(
    Session session,
    String? query, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (query == null || query.trim().isEmpty) return [];

    final cleanQuery = query.trim();
    List<protocol.Resident> residents;

    // Try finding by UUID first
    UuidValue? uuid;
    try {
      uuid = UuidValue.fromString(cleanQuery);
    } catch (_) {}

    if (uuid != null) {
      final r = await ResidentService.getResident(session, uuid);
      residents = r != null ? [r] : [];
    } else {
      residents = await protocol.Resident.db.find(
        session,
        where: (t) => t.userName.ilike('%$cleanQuery%'),
        limit: limit,
        offset: offset,
        orderBy: (t) => t.lastLoginDate,
        orderDescending: true,
      );
    }

    if (residents.isEmpty) return [];

    final userIds = residents.map((r) => r.userInfoId).toList();
    final userCounts = await ResidentService.getBatchUserCounts(session, userIds);

    return residents.map((r) => ResidentService.toAdminUserSummary(
          r,
          messageCount: userCounts[r.userInfoId.toString()]?['messages'],
          momentCount: userCounts[r.userInfoId.toString()]?['moments'],
          reportCount: userCounts[r.userInfoId.toString()]?['reports'],
        )).toList();
  }

  /// Updates a lounge's privacy and status.
  static Future<void> setLoungeStatus(
    Session session,
    int loungeId, {
    bool? isPublic,
    bool? isStaffLocked,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) throw protocol.TalktiveException(message: 'Lounge not found');

    if (isPublic != null) lounge.isPublic = isPublic;
    if (isStaffLocked != null) lounge.isStaffLocked = isStaffLocked;

    await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Disbands a lounge by administrative action.
  static Future<void> disbandLounge(Session session, int loungeId) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) return;
    await LoungeService.deleteLounge(session, lounge);
  }

  /// Fetches detailed user information for administrative review (AdminUserDetails).
  static Future<protocol.AdminUserDetails?> getUserDetails(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await ResidentService.getResident(session, userId);
    if (resident == null) return null;

    final historyResults = await Future.wait([
      protocol.Message.db.find(session, where: (t) => t.senderId.equals(userId), limit: 20, orderDescending: true),
      protocol.Moment.db.find(session, where: (t) => t.authorId.equals(userId), limit: 10, orderDescending: true),
      protocol.Report.db.find(session, where: (t) => t.targetId.equals(userId), orderDescending: true),
      protocol.Report.db.find(session, where: (t) => t.reporterId.equals(userId), orderDescending: true),
    ]);

    final messages = historyResults[0] as List<protocol.Message>;
    final moments = historyResults[1] as List<protocol.Moment>;
    final reportsAgainst = historyResults[2] as List<protocol.Report>;
    final reportsMade = historyResults[3] as List<protocol.Report>;

    return protocol.AdminUserDetails(
      user: ResidentService.toAdminUserSummary(
        resident,
        messageCount: messages.length,
        momentCount: moments.length,
        reportCount: reportsAgainst.length,
      ),
      recentMessages: messages,
      recentMoments: moments,
      reportsAgainst: reportsAgainst,
      reportsMade: reportsMade,
    );
  }
  /// Deletes a message.
  static Future<void> deleteMessage(Session session, int messageId) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message != null) {
      await protocol.Message.db.deleteRow(session, message);
    }
  }

  /// Updates a user's suspension status.
  static Future<void> setSuspensionStatus(
    Session session,
    UuidValue userId, {
    required bool suspended,
  }) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.suspended = suspended;
    if (suspended) {
      resident.trustScore = 0;
    } else {
      resident.trustScore = 50; // Restore partial trust
    }
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Sets a user's mute status.
  static Future<void> setMuteStatus(
    Session session,
    UuidValue userId, {
    required DateTime? until,
  }) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.mutedUntil = until;
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Updates a user's role.
  static Future<void> setRole(
    Session session,
    UuidValue userId,
    protocol.ResidentRole role,
  ) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.role = role;
    await protocol.Resident.db.updateRow(session, resident);
  }

  /// Resets a user's reputation and clears mutes.
  static Future<void> resetReputation(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) throw protocol.TalktiveException(message: 'User not found');

    resident.trustScore = 100;
    resident.mutedUntil = null;
    await protocol.Resident.db.updateRow(session, resident);
  }
}
