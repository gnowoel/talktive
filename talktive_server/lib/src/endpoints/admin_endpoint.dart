import 'package:serverpod/serverpod.dart';
import 'package:uuid/uuid.dart';
import '../generated/protocol.dart';
import '../services/cache_service.dart';

class AdminEndpoint extends Endpoint {
  /// Check if the current user is an admin
  Future<bool> isAdmin(Session session) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) return false;

    final userUuid = UuidValue.fromString(userIdentifier);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    return resident?.isAdmin ?? false;
  }

  /// Require admin authentication
  Future<Resident> _requireAdmin(Session session) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userUuid = UuidValue.fromString(userIdentifier);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    if (!resident.isAdmin) {
      throw Exception('Admin access required');
    }

    return resident;
  }

  /// Get all pending reports with pagination
  Future<List<Map<String, dynamic>>> getPendingReports(
    Session session, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _requireAdmin(session);

    final reports = await Report.db.find(
      session,
      where: (t) => t.status.equals(ReportStatus.pending),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    final result = <Map<String, dynamic>>[];
    for (final report in reports) {
      // Get reporter info
      final reporter = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final reporterInfo = await session.auth.getUserInfo(report.reporterId);

      // Get target info
      final target = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      final targetInfo = await session.auth.getUserInfo(report.targetId);

      result.add({
        'report': report.toJson(),
        'reporter': {
          'userId': report.reporterId.uuid,
          'userName': reporterInfo?.userName ?? 'Unknown',
          'floor': reporter?.floor ?? 0,
        },
        'target': {
          'userId': report.targetId.uuid,
          'userName': targetInfo?.userName ?? 'Unknown',
          'floor': target?.floor ?? 0,
          'creditScore': target?.creditScore ?? 0,
        },
      });
    }

    return result;
  }

  /// Get all reports (with status filter)
  Future<List<Map<String, dynamic>>> getAllReports(
    Session session, {
    ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    await _requireAdmin(session);

    final reports = await Report.db.find(
      session,
      where: status != null ? (t) => t.status.equals(status) : null,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    final result = <Map<String, dynamic>>[];
    for (final report in reports) {
      final reporter = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.reporterId),
      );
      final reporterInfo = await session.auth.getUserInfo(report.reporterId);

      final target = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(report.targetId),
      );
      final targetInfo = await session.auth.getUserInfo(report.targetId);

      result.add({
        'report': report.toJson(),
        'reporter': {
          'userId': report.reporterId.uuid,
          'userName': reporterInfo?.userName ?? 'Unknown',
          'floor': reporter?.floor ?? 0,
        },
        'target': {
          'userId': report.targetId.uuid,
          'userName': targetInfo?.userName ?? 'Unknown',
          'floor': target?.floor ?? 0,
          'creditScore': target?.creditScore ?? 0,
        },
      });
    }

    return result;
  }

  /// Resolve a report (approve or reject)
  Future<void> resolveReport(
    Session session, {
    required int reportId,
    required ReportStatus status,
    String? adminNotes,
  }) async {
    await _requireAdmin(session);

    final report = await Report.db.findById(session, reportId);
    if (report == null) {
      throw Exception('Report not found');
    }

    report.status = status;
    report.adminNotes = adminNotes;
    report.resolvedAt = DateTime.now();

    await Report.db.updateRow(session, report);
  }

  /// Ban a user (set credit score to -1000)
  Future<void> banUser(
    Session session, {
    required String userId,
    String? reason,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    resident.creditScore = -1000;
    resident.isBanned = true;
    await Resident.db.updateRow(session, resident);

    session.log('Admin banned user: $userId. Reason: $reason');
  }

  /// Unban a user (restore credit score to 50)
  Future<void> unbanUser(
    Session session, {
    required String userId,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    resident.creditScore = 50;
    resident.isBanned = false;
    await Resident.db.updateRow(session, resident);

    session.log('Admin unbanned user: $userId');
  }

  /// Mute a user (set credit score to 0)
  Future<void> muteUser(
    Session session, {
    required String userId,
    String? reason,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    resident.creditScore = 0;
    await Resident.db.updateRow(session, resident);

    session.log('Admin muted user: $userId. Reason: $reason');
  }

  /// Delete a message
  Future<void> deleteMessage(
    Session session, {
    required int messageId,
    String? reason,
  }) async {
    await _requireAdmin(session);

    final message = await Message.db.findById(session, messageId);
    if (message == null) {
      throw Exception('Message not found');
    }

    await Message.db.deleteRow(session, message);
    session.log('Admin deleted message: $messageId. Reason: $reason');
  }

  /// Delete a moment
  Future<void> deleteMoment(
    Session session, {
    required int momentId,
    String? reason,
  }) async {
    await _requireAdmin(session);

    final moment = await Moment.db.findById(session, momentId);
    if (moment == null) {
      throw Exception('Moment not found');
    }

    // Delete associated likes and comments
    await MomentLike.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );
    await MomentComment.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );

    await Moment.db.deleteRow(session, moment);
    session.log('Admin deleted moment: $momentId. Reason: $reason');
  }

  /// Get platform statistics - OPTIMIZED with caching
  Future<Map<String, dynamic>> getStatistics(Session session) async {
    await _requireAdmin(session);

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
    final totalUsers = await Resident.db.count(session);
    final totalMessages = await Message.db.count(session);
    final totalMoments = await Moment.db.count(session);
    final totalGroups = await Group.db.count(session);
    final totalReports = await Report.db.count(session);
    final pendingReports = await Report.db.count(
      session,
      where: (t) => t.status.equals(ReportStatus.pending),
    );

    // Recent activity (last 24 hours)
    final messagesLast24h = await Message.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );
    final momentsLast24h = await Moment.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );
    final reportsLast24h = await Report.db.count(
      session,
      where: (t) => t.createdAt >= oneDayAgo,
    );

    // Weekly activity
    final messagesLast7d = await Message.db.count(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
    );
    final momentsLast7d = await Moment.db.count(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
    );

    // Monthly activity
    final messagesLast30d = await Message.db.count(
      session,
      where: (t) => t.createdAt >= thirtyDaysAgo,
    );
    final momentsLast30d = await Moment.db.count(
      session,
      where: (t) => t.createdAt >= thirtyDaysAgo,
    );

    // Active users (users who sent messages in last 7 days) - OPTIMIZED
    // Limit to last 1000 messages to prevent memory issues
    final recentMessages = await Message.db.find(
      session,
      where: (t) => t.createdAt >= sevenDaysAgo,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 1000,
    );
    final activeUserIds = <int>{};
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
    await _requireAdmin(session);

    // Try to parse as UUID first
    UuidValue? searchUuid;
    try {
      searchUuid = UuidValue.fromString(query);
    } catch (e) {
      // Not a UUID, search by name
    }

    final residents = await Resident.db.find(
      session,
      where: searchUuid != null
          ? (t) => t.userInfoId.equals(searchUuid!)
          : null,
      limit: limit,
    );

    final result = <Map<String, dynamic>>[];
    for (final resident in residents) {
      final userInfo = await session.auth.getUserInfo(resident.userInfoId);

      // Filter by name if searching by name
      if (searchUuid == null && userInfo?.userName != null) {
        if (!userInfo!.userName!.toLowerCase().contains(query.toLowerCase())) {
          continue;
        }
      }

      // Count messages
      final messageCount = await Message.db.count(
        session,
        where: (t) => t.senderId.equals(resident.id!),
      );

      // Count moments
      final momentCount = await Moment.db.count(
        session,
        where: (t) => t.residentId.equals(resident.id!),
      );

      // Count reports against this user
      final reportCount = await Report.db.count(
        session,
        where: (t) => t.targetId.equals(resident.userInfoId),
      );

      result.add({
        'userId': resident.userInfoId.uuid,
        'userName': userInfo?.userName ?? 'Unknown',
        'floor': resident.floor,
        'creditScore': resident.creditScore,
        'isAdmin': resident.isAdmin,
        'isBanned': resident.isBanned,
        'messageCount': messageCount,
        'momentCount': momentCount,
        'reportCount': reportCount,
        'createdAt': resident.createdAt.toIso8601String(),
      });
    }

    return result;
  }

  /// Promote user to admin
  Future<void> promoteToAdmin(
    Session session, {
    required String userId,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    resident.isAdmin = true;
    await Resident.db.updateRow(session, resident);

    session.log('Admin promoted user to admin: $userId');
  }

  /// Demote admin to regular user
  Future<void> demoteFromAdmin(
    Session session, {
    required String userId,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    resident.isAdmin = false;
    await Resident.db.updateRow(session, resident);

    session.log('Admin demoted user from admin: $userId');
  }

  /// Get user details for admin view
  Future<Map<String, dynamic>> getUserDetails(
    Session session, {
    required String userId,
  }) async {
    await _requireAdmin(session);

    final userUuid = UuidValue.fromString(userId);
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('User not found');
    }

    final userInfo = await session.auth.getUserInfo(resident.userInfoId);

    // Get recent messages
    final recentMessages = await Message.db.find(
      session,
      where: (t) => t.senderId.equals(resident.id!),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get recent moments
    final recentMoments = await Moment.db.find(
      session,
      where: (t) => t.residentId.equals(resident.id!),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get reports against this user
    final reports = await Report.db.find(
      session,
      where: (t) => t.targetId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    // Get reports made by this user
    final reportsMade = await Report.db.find(
      session,
      where: (t) => t.reporterId.equals(resident.userInfoId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 10,
    );

    return {
      'user': {
        'userId': resident.userInfoId.uuid,
        'userName': userInfo?.userName ?? 'Unknown',
        'floor': resident.floor,
        'creditScore': resident.creditScore,
        'isAdmin': resident.isAdmin,
        'isBanned': resident.isBanned,
        'createdAt': resident.createdAt.toIso8601String(),
      },
      'stats': {
        'totalMessages': await Message.db.count(
          session,
          where: (t) => t.senderId.equals(resident.id!),
        ),
        'totalMoments': await Moment.db.count(
          session,
          where: (t) => t.residentId.equals(resident.id!),
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
}
