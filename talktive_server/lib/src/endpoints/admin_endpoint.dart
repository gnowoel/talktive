import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/cache_service.dart';
import '../services/data_archival_service.dart';
import '../services/input_validation_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class AdminEndpoint extends Endpoint with EndpointAuthMixin {
  /// Check if the current user is an admin
  Future<bool> isAdmin(Session session) async {
    try {
      final resident = await getAuthenticatedResident(session);
      return resident.role == protocol.ResidentRole.admin;
    } catch (e) {
      return false;
    }
  }

  /// Check if the current user is a moderator
  Future<bool> isModerator(Session session) async {
    try {
      final resident = await getAuthenticatedResident(session);
      return resident.role == protocol.ResidentRole.moderator;
    } catch (e) {
      return false;
    }
  }

  /// Check if the current user is staff (Admin or Moderator)
  Future<bool> isStaff(Session session) async {
    try {
      final resident = await getAuthenticatedResident(session);
      return resident.role == protocol.ResidentRole.admin ||
          resident.role == protocol.ResidentRole.moderator;
    } catch (e) {
      return false;
    }
  }

  // Helper to get user info removed: using Resident natively

  /// Get all pending reports with pagination
  Future<List<protocol.AdminReportSummary>> getPendingReports(
    Session session, {
    int limit = 20,
    int offset = 0,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();
    await getStaffProfile(session);

    final reports = await protocol.Report.db.find(
      session,
      where: (t) => t.status.equals(protocol.ReportStatus.pending),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    final result = <protocol.AdminReportSummary>[];
    for (final report in reports) {
      final reporter = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final target = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      
      result.add(protocol.AdminReportSummary(
        report: report,
        reporter: await _getUserSummary(session, reporter, report.reporterId.toString()),
        target: await _getUserSummary(session, target, report.targetId.toString()),
      ));
    }

    return result;
  }

  /// Get all reports (with status filter)
  Future<List<protocol.AdminReportSummary>> getAllReports(
    Session session, {
    protocol.ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();
    await getStaffProfile(session);

    final reports = await protocol.Report.db.find(
      session,
      where: status != null ? (t) => t.status.equals(status) : null,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    final result = <protocol.AdminReportSummary>[];
    for (final report in reports) {
      final reporter = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final target = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      
      result.add(protocol.AdminReportSummary(
        report: report,
        reporter: await _getUserSummary(session, reporter, report.reporterId.toString()),
        target: await _getUserSummary(session, target, report.targetId.toString()),
      ));
    }

    return result;
  }

  /// Resolve a report (approve or reject)
  Future<void> resolveReport(
    Session session, {
    required int reportId,
    required protocol.ReportStatus status,
    String? adminNotes,
  }) async {
    InputValidationService.validateId(reportId, 'Report ID').throwIfInvalid();
    await getStaffProfile(session);

    final report = await protocol.Report.db.findById(session, reportId);
    if (report == null) {
      throw protocol.TalktiveException(message: 'Report not found');
    }

    report.status = status;
    report.adminNotes = adminNotes;
    report.resolvedAt = DateTime.now();

    await protocol.Report.db.updateRow(session, report);
  }

  /// Suspend a user (disable account)
  Future<void> suspendUser(
    Session session, {
    required String userId,
    String? reason,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getStaffProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.suspended = true;
    resident.trustScore = 0;
    await protocol.Resident.db.updateRow(session, resident);

    session.log('ADMIN: User $userId suspended by admin. Reason: $reason');
  }

  /// Unsuspend a user (re-enable account)
  Future<void> unsuspendUser(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getStaffProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.suspended = false;
    resident.trustScore = 50; // Restore some trustScore
    await protocol.Resident.db.updateRow(session, resident);

    session.log('ADMIN: User $userId unsuspended by admin.');
  }

  /// Manually mutes a user for a specified duration.
  Future<void> muteUser(
    Session session, {
    required String userId,
    required int durationHours,
    required String reason,
  }) async {
    await getStaffProfile(session);
    InputValidationService.validateUuid(userId).throwIfInvalid();
    InputValidationService.validateId(durationHours, 'Duration').throwIfInvalid();

    final targetUuid = UuidValue.fromString(userId);
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) throw protocol.TalktiveException(message: 'User not found');

    target.mutedUntil = DateTime.now().add(Duration(hours: durationHours));
    await protocol.Resident.db.updateRow(session, target);
    
    session.log('ADMIN: User $userId muted for $durationHours hours by admin. Reason: $reason');
  }

  /// Manually unmutes a user.
  Future<void> unmuteUser(Session session, String userId) async {
    await getStaffProfile(session);
    InputValidationService.validateUuid(userId).throwIfInvalid();

    final targetUuid = UuidValue.fromString(userId);
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) throw protocol.TalktiveException(message: 'User not found');

    target.mutedUntil = null;
    await protocol.Resident.db.updateRow(session, target);

    session.log('ADMIN: User $userId unmuted by admin.');
  }

  /// Reset user trustScore to 100 (for appeals)
  Future<void> resetReputation(
    Session session, {
    required String userId,
    String? reason,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getStaffProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.trustScore = 100;
    resident.mutedUntil = null; // Clear any temporary mutes
    await protocol.Resident.db.updateRow(session, resident);

    session.log('Admin reset trustScore for user: $userId. Reason: $reason');
  }

  /// Delete a message
  Future<void> deleteMessage(
    Session session, {
    required int messageId,
    String? reason,
  }) async {
    InputValidationService.validateId(messageId, 'Message ID').throwIfInvalid();
    await getStaffProfile(session);

    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(message: 'Message not found');
    }

    await protocol.Message.db.deleteRow(session, message);
    session.log('Admin deleted message: $messageId. Reason: $reason');
  }

  /// Delete a moment
  Future<void> deleteMoment(
    Session session, {
    required int momentId,
    String? reason,
  }) async {
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();
    await getStaffProfile(session);

    final moment = await protocol.Moment.db.findById(session, momentId);
    if (moment == null) {
      throw protocol.TalktiveException(message: 'Moment not found');
    }

    // Delete associated likes and comments
    await protocol.MomentLike.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );
    await protocol.MomentComment.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );

    await protocol.Moment.db.deleteRow(session, moment);
    session.log('Admin deleted moment: $momentId. Reason: $reason');
  }

  /// Get platform statistics - OPTIMIZED with caching
  Future<protocol.AdminStatistics> getStatistics(Session session) async {
    await getAdminProfile(session);

    // Try to get from cache first
    final cached = await CacheService.getStatistics(session);
    if (cached != null) {
      return cached;
    }

    // Cache miss - compute statistics
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Total counts
    final totalUsers = await protocol.Resident.db.count(session);
    final totalMessages = await protocol.Message.db.count(session);
    final totalMoments = await protocol.Moment.db.count(session);
    final totalGroups = await protocol.Group.db.count(session);
    final totalReports = await protocol.Report.db.count(session);
    final pendingReports = await protocol.Report.db.count(
      session,
      where: (t) => t.status.equals(protocol.ReportStatus.pending),
    );

    // Recent activity (last 24 hours)
    final messagesLast24h = await protocol.Message.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );
    final momentsLast24h = await protocol.Moment.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );
    final reportsLast24h = await protocol.Report.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );

    // Weekly activity
    final messagesLast7d = await protocol.Message.db.count(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
    );
    final momentsLast7d = await protocol.Moment.db.count(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
    );

    // Monthly activity
    final messagesLast30d = await protocol.Message.db.count(
      session,
      where: (t) => t.createdAt >= thirtyDaysAgo,
    );
    final momentsLast30d = await protocol.Moment.db.count(
      session,
      where: (t) => t.createdAt >= thirtyDaysAgo,
    );

    // Active users (users who sent messages in last 7 days) - OPTIMIZED
    // Limit to last 1000 messages to prevent memory issues
    final recentMessages = await protocol.Message.db.find(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 1000,
    );
    final activeUserIds = <UuidValue>{};
    for (final message in recentMessages) {
      activeUserIds.add(message.senderId);
    }

    final stats = protocol.AdminStatistics(
      totals: protocol.AdminTotals(
        users: totalUsers,
        messages: totalMessages,
        moments: totalMoments,
        groups: totalGroups,
        reports: totalReports,
        pendingReports: pendingReports,
      ),
      last24h: protocol.AdminActivity(
        messages: messagesLast24h,
        moments: momentsLast24h,
        reports: reportsLast24h,
        activeUsers: 0, // Not calculated for 24h in original, setting to 0
      ),
      last7d: protocol.AdminActivity(
        messages: messagesLast7d,
        moments: momentsLast7d,
        reports: 0, // Not calculated for 7d in original, setting to 0
        activeUsers: activeUserIds.length,
      ),
      last30d: protocol.AdminActivity(
        messages: messagesLast30d,
        moments: momentsLast30d,
        reports: 0, // Not calculated for 30d in original, setting to 0
        activeUsers: 0, // Not calculated for 30d in original, setting to 0
      ),
    );

    // Store in cache for 5 minutes
    await CacheService.setStatistics(session, stats);

    return stats;
  }

  /// Search users by name or ID
  Future<List<protocol.AdminUserSummary>> searchUsers(
    Session session, {
    required String query,
    int limit = 20,
  }) async {
    session.log('ADMIN: searchUsers called with query: "$query"');
    try {
      await getStaffProfile(session);
      
      // Try to parse as UUID first
      UuidValue? searchUuid;
      try {
        if (query.length >= 32) {
          searchUuid = UuidValue.fromString(query);
        }
      } catch (e) {
        // Not a UUID
      }

      List<protocol.Resident> residents;
      if (searchUuid != null) {
        residents = await protocol.Resident.db.find(
          session,
          where: (t) => t.userInfoId.equals(searchUuid),
          limit: 1,
        );
      } else if (query.isNotEmpty) {
        residents = await protocol.Resident.db.find(
          session,
          where: (t) => t.userName.ilike('%$query%'),
          limit: limit,
          orderBy: (t) => t.id,
        );
      } else {
        residents = await protocol.Resident.db.find(
          session,
          limit: limit,
          orderBy: (t) => t.id,
        );
      }

      final result = <protocol.AdminUserSummary>[];
      for (final r in residents) {
        // Count messages
        int messageCount = 0;
        try {
          messageCount = await protocol.Message.db.count(
            session,
            where: (t) => t.senderId.equals(r.userInfoId),
          );
        } catch (e) {
          session.log('ADMIN Error counting messages for ${r.userInfoId}: $e');
        }

        // Count moments
        int momentCount = 0;
        try {
          momentCount = await protocol.Moment.db.count(
            session,
            where: (t) => t.authorId.equals(r.userInfoId),
          );
        } catch (e) {
          session.log('ADMIN Error counting moments for ${r.userInfoId}: $e');
        }

        // Count reports
        int reportCount = 0;
        try {
          reportCount = await protocol.Report.db.count(
            session,
            where: (t) => t.targetId.equals(r.userInfoId),
          );
        } catch (e) {
          session.log('ADMIN Error counting reports for ${r.userInfoId}: $e');
        }

        result.add(protocol.AdminUserSummary(
          userId: r.userInfoId.toString(),
          userName: r.userName,
          floor: ApartmentService.computeEffectiveFloor(r),
          trustScore: r.trustScore,
          level: r.level,
          xp: r.xp,
          role: r.role,
          suspended: r.suspended,
          messageCount: messageCount,
          momentCount: momentCount,
          reportCount: reportCount,
          createdAt: r.createdAt,
          lastSeen: r.lastSeen,
        ));
      }
      
      return result;
    } catch (e, stack) {
      session.log('ADMIN Error in searchUsers: $e', level: LogLevel.error, stackTrace: stack);
      rethrow;
    }
  }

  /// Promote user to admin
  Future<void> promoteToAdmin(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getAdminProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.role = protocol.ResidentRole.admin;
    await protocol.Resident.db.updateRow(session, resident);

    session.log('Admin promoted user to admin: $userId');
  }

  /// Promote user to moderator
  Future<void> promoteToModerator(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getAdminProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.role = protocol.ResidentRole.moderator;
    await protocol.Resident.db.updateRow(session, resident);

    session.log('Admin promoted user to moderator: $userId');
  }

  /// Demote user from moderator
  Future<void> demoteFromModerator(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getAdminProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, resident);

    session.log('Admin demoted user from moderator: $userId');
  }

  /// Demote admin to regular user
  Future<void> demoteFromAdmin(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getAdminProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    resident.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, resident);

    session.log('Admin demoted user from admin: $userId');
  }

  // --- Group Moderation ---

  /// Disbands a group immediately.
  Future<void> disbandGroup(
    Session session, {
    required int groupId,
    required String reason,
  }) async {
    await getStaffProfile(session);
    InputValidationService.validateId(groupId, 'Group ID').throwIfInvalid();

    final group = await protocol.Group.db.findById(session, groupId);
    if (group == null) throw protocol.TalktiveException(message: 'Group not found');

    // Delete group members first
    await protocol.ChannelMember.db.deleteWhere(
      session,
      where: (t) => t.channelId.equals(groupId),
    );

    // Delete group
    await protocol.Group.db.deleteRow(session, group);

    session.log('ADMIN: Group $groupId disbanded by admin. Reason: $reason');
  }

  /// Forces a group to become private.
  Future<void> makeGroupPrivate(Session session, int groupId) async {
    await getStaffProfile(session);
    InputValidationService.validateId(groupId, 'Group ID').throwIfInvalid();

    final group = await protocol.Group.db.findById(session, groupId);
    if (group == null) throw protocol.TalktiveException(message: 'Group not found');

    group.isPublic = false;
    group.isStaffLocked = true;
    await protocol.Group.db.updateRow(session, group);

    session.log('ADMIN: Group $groupId set to PRIVATE by admin.');
  }

  /// Get user details for admin view
  Future<protocol.AdminUserDetails> getUserDetails(
    Session session, {
    required String userId,
  }) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    await getStaffProfile(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw protocol.TalktiveException(message: 'User not found');
    }

    // Get recent messages
    final recentMessages = await protocol.Message.db.find(
      session,
      where: (t) => t.senderId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 20,
    );

    final recentMoments = await protocol.Moment.db.find(
      session,
      where: (t) => t.authorId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get reports against this user
    final reportsAgainst = await protocol.Report.db.find(
      session,
      where: (t) => t.targetId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get reports made by this user
    final reportsMade = await protocol.Report.db.find(
      session,
      where: (t) => t.reporterId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    return protocol.AdminUserDetails(
      user: await _getUserSummary(session, resident, userId),
      recentMessages: recentMessages,
      recentMoments: recentMoments,
      reportsAgainst: reportsAgainst,
      reportsMade: reportsMade,
    );
  }

  Future<protocol.AdminUserSummary> _getUserSummary(Session session, protocol.Resident? resident, String userId) async {
    if (resident == null) {
      return protocol.AdminUserSummary(
        userId: userId,
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
      );
    }
    
    return protocol.AdminUserSummary(
      userId: resident.userInfoId.toString(),
      userName: resident.userName,
      floor: ApartmentService.computeEffectiveFloor(resident),
      trustScore: resident.trustScore,
      level: resident.level,
      xp: resident.xp,
      role: resident.role,
      suspended: resident.suspended,
      messageCount: 0,
      momentCount: 0,
      reportCount: 0,
      createdAt: resident.createdAt,
      lastSeen: resident.lastSeen,
    );
  }

  /// Run data archival tasks (admin only).
  Future<Map<String, int>> runArchival(Session session) async {
    await getAdminProfile(session);
    return await DataArchivalService.runArchivalTasks(session);
  }

  /// Get archival statistics (admin only).
  Future<Map<String, int>> getArchivalStats(Session session) async {
    await getAdminProfile(session);
    return await DataArchivalService.getArchivalStats(session);
  }
}
