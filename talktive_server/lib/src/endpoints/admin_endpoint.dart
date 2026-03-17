import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
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
      return resident.isAdmin;
    } catch (e) {
      return false;
    }
  }

  /// Check if the current user is a moderator
  Future<bool> isModerator(Session session) async {
    try {
      final resident = await getAuthenticatedResident(session);
      return resident.isModerator;
    } catch (e) {
      return false;
    }
  }

  /// Check if the current user is staff (Admin or Moderator)
  Future<bool> isStaff(Session session) async {
    try {
      final resident = await getAuthenticatedResident(session);
      return resident.isAdmin || resident.isModerator;
    } catch (e) {
      return false;
    }
  }

  // Helper to get user info removed: using Resident natively

  /// Get all pending reports with pagination
  Future<List<Map<String, dynamic>>> getPendingReports(
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

    final result = <Map<String, dynamic>>[];
    for (final report in reports) {
      // Get reporter info
      final reporter = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final target = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      result.add({
        'report': report.toJson(),
        'reporter': {
          'userId': report.reporterId.toString(),
          'userName': reporter?.userName ?? 'Unknown',
          'floor': reporter != null
              ? ApartmentService.computeEffectiveFloor(reporter)
              : 0,
        },
        'target': {
          'userId': report.targetId.toString(),
          'userName': target?.userName ?? 'Unknown',
          'floor': target != null
              ? ApartmentService.computeEffectiveFloor(target)
              : 0,
          'trustScore': target?.trustScore ?? 0,
          'level': target?.level ?? 0,
        },
      });
    }

    return result;
  }

  /// Get all reports (with status filter)
  Future<List<Map<String, dynamic>>> getAllReports(
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

    final result = <Map<String, dynamic>>[];
    for (final report in reports) {
      final reporter = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final target = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      result.add({
        'report': report.toJson(),
        'reporter': {
          'userId': report.reporterId.toString(),
          'userName': reporter?.userName ?? 'Unknown',
          'floor': reporter != null
              ? ApartmentService.computeEffectiveFloor(reporter)
              : 0,
        },
        'target': {
          'userId': report.targetId.toString(),
          'userName': target?.userName ?? 'Unknown',
          'floor': target != null
              ? ApartmentService.computeEffectiveFloor(target)
              : 0,
          'trustScore': target?.trustScore ?? 0,
          'level': target?.level ?? 0,
        },
      });
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
  Future<Map<String, dynamic>> getStatistics(Session session) async {
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

    final stats = {
      'totals': {
        'users': totalUsers,
        'messages': totalMessages,
        'moments': totalMoments,
        'groups': totalGroups,
        'reports': totalReports,
        'pendingReports': pendingReports,
      },
      'last24h': {
        'messages': messagesLast24h,
        'moments': momentsLast24h,
        'reports': reportsLast24h,
      },
      'last7d': {
        'messages': messagesLast7d,
        'moments': momentsLast7d,
        'activeUsers': activeUserIds.length,
      },
      'last30d': {
        'messages': messagesLast30d,
        'moments': momentsLast30d,
      },
    };

    // Store in cache for 5 minutes
    await CacheService.setStatistics(session, stats);

    return stats;
  }

  /// Search users by name or ID
  Future<List<Map<String, dynamic>>> searchUsers(
    Session session, {
    required String query,
    int limit = 20,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();
    await getStaffProfile(session);

    // Try to parse as UUID first
    UuidValue? searchUuid;
    try {
      searchUuid = UuidValue.fromString(query);
    } catch (e) {
      // Not a UUID, search by name
    }

    final residents = await protocol.Resident.db.find(
      session,
      where: searchUuid != null
          ? (t) => t.userInfoId.equals(searchUuid!)
          : null,
      limit: limit,
    );

    final result = <Map<String, dynamic>>[];
    for (final resident in residents) {
      // Filter by name if searching by name
      if (searchUuid == null && resident.userName != null) {
        if (!resident.userName!.toLowerCase().contains(query.toLowerCase())) {
          continue;
        }
      }

      // Count messages
      final messageCount = await protocol.Message.db.count(
        session,
        where: (t) => t.senderId.equals(
          resident.userInfoId,
        ), // Use userInfoId (UuidValue)
      );

      // Count moments
      final momentCount = await protocol.Moment.db.count(
        session,
        where: (t) =>
            t.authorId.equals(resident.userInfoId), // Use authorId (UuidValue)
      );

      // Count reports against this user
      final reportCount = await protocol.Report.db.count(
        session,
        where: (t) => t.targetId.equals(resident.userInfoId),
      );

      result.add({
        'userId': resident.userInfoId.toString(),
        'userName': resident.userName ?? 'Unknown',
        'floor': ApartmentService.computeEffectiveFloor(resident),
        'trustScore': resident.trustScore,
        'level': resident.level,
        'xp': resident.xp,
        'isAdmin': resident.isAdmin,
        'isModerator': resident.isModerator,
        'suspended': resident.suspended,
        'messageCount': messageCount,
        'momentCount': momentCount,
        'reportCount': reportCount,
        'createdAt': DateTime.now()
            .toIso8601String(), // Optional: could fetch Profile creation
      });
    }

    return result;
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

    resident.isAdmin = true;
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

    resident.isModerator = true;
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

    resident.isModerator = false;
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

    resident.isAdmin = false;
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
    group.isAdminLocked = true;
    await protocol.Group.db.updateRow(session, group);

    session.log('ADMIN: Group $groupId set to PRIVATE by admin.');
  }

  /// Get user details for admin view
  Future<Map<String, dynamic>> getUserDetails(
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
      where: (t) =>
          t.senderId.equals(resident.userInfoId), // Use userInfoId (UuidValue)
    );

    final recentMoments = await protocol.Moment.db.find(
      session,
      where: (t) =>
          t.authorId.equals(resident.userInfoId), // Use authorId (UuidValue)
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get reports against this user
    final reports = await protocol.Report.db.find(
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

    return {
      'user': {
        'userId': resident.userInfoId.toString(),
        'userName': resident.userName ?? 'Unknown',
        'floor': ApartmentService.computeEffectiveFloor(resident),
        'trustScore': resident.trustScore,
        'level': resident.level,
        'xp': resident.xp,
        'isAdmin': resident.isAdmin,
        'isModerator': resident.isModerator,
        'suspended': resident.suspended,
        'createdAt': DateTime.now().toIso8601String(),
      },
      'stats': {
        'totalMessages': await protocol.Message.db.count(
          session,
          where: (t) => t.senderId.equals(resident.userInfoId),
        ),
        'totalMoments': await protocol.Moment.db.count(
          session,
          where: (t) => t.authorId.equals(resident.userInfoId),
        ),
        'reportsAgainst': reports.length,
        'reportsMade': reportsMade.length,
      },
      'recentMessages': recentMessages.map((m) => m.toJson()).toList(),
      'recentMoments': recentMoments.map((m) => m.toJson()).toList(),
      'reportsAgainst': reports.map((r) => r.toJson()).toList(),
      'reportsMade': reportsMade.map((r) => r.toJson()).toList(),
    };
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
