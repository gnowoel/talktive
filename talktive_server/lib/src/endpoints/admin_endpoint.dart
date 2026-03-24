import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/admin_service.dart';
import '../services/resident_service.dart';
import '../services/report_service.dart';
import '../services/lounge_service.dart';
import '../utils/endpoint_auth_mixin.dart';

/// Endpoint for administrative and moderation tasks.
class AdminEndpoint extends Endpoint with EndpointAuthMixin {
  @override
  bool get requireLogin => true;

  /// Fetches pending reports with detailed user summaries.
  Future<List<protocol.AdminReportSummary>> getPendingReports(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) async {
    await getStaffProfile(session);
    return await AdminService.getAllReports(session,
        status: protocol.ReportStatus.pending, limit: limit, offset: offset);
  }

  /// Fetches all reports with optional status filtering.
  Future<List<protocol.AdminReportSummary>> listReports(
    Session session, {
    protocol.ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    await getStaffProfile(session);
    return await AdminService.getAllReports(session,
        status: status, limit: limit, offset: offset);
  }

  /// Legacy helper for getAllReports
  Future<List<protocol.AdminReportSummary>> getAllReports(
    Session session, {
    protocol.ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async => listReports(session, status: status, limit: limit, offset: offset);

  /// Resolves a report, optionally taking action against the target.
  Future<void> resolveReport(
    Session session, {
    required int reportId,
    required protocol.ReportStatus status,
    String? reason,
  }) async {
    await getStaffProfile(session);
    await ReportService.resolveReport(
      session,
      reportId: reportId,
      status: status,
      adminNotes: reason,
    );
  }

  /// Suspends a user account.
  Future<void> suspendUser(Session session, {required UuidValue userId, String? reason}) async {
    await getAdminProfile(session);
    await ResidentService.setSuspensionStatus(session, userId, suspended: true);
  }

  /// Unsuspends a user account.
  Future<void> unsuspendUser(Session session, {required UuidValue userId}) async {
    await getAdminProfile(session);
    await ResidentService.setSuspensionStatus(session, userId, suspended: false);
  }

  /// Mutes a user for a specified duration.
  Future<void> muteUser(
    Session session, {
    required UuidValue userId,
    int? minutes,
    int? durationHours, // For FE compatibility
    String? reason,
  }) async {
    await getStaffProfile(session);
    final totalMinutes = minutes ?? (durationHours != null ? durationHours * 60 : 60);
    final until = DateTime.now().add(Duration(minutes: totalMinutes));
    await ResidentService.setMuteStatus(session, userId, until: until);
  }

  /// Unmutes a user immediately.
  Future<void> unmuteUser(Session session, {required UuidValue userId}) async {
    await getStaffProfile(session);
    await ResidentService.setMuteStatus(session, userId, until: null);
  }

  /// Deletes a message.
  Future<void> deleteMessage(Session session, {required int messageId}) async {
    await getStaffProfile(session);
    await AdminService.deleteMessage(session, messageId);
  }

  /// Resets a user's reputation to default.
  Future<void> resetReputation(Session session, {required UuidValue userId, String? reason}) async {
    await getStaffProfile(session);
    await ResidentService.resetReputation(session, userId);
  }

  /// Computes platform-wide statistics.
  Future<protocol.AdminStatistics> getStatistics(Session session) async {
    await getAdminProfile(session);
    return await AdminService.getStatistics(session);
  }

  /// Searches for users by name or specific ID.
  Future<List<protocol.AdminUserSummary>> searchUsers(
    Session session, {
    String? query,
    int? limit,
    int? offset,
  }) async {
    await getStaffProfile(session);
    return await AdminService.searchUsers(session, query);
  }

  /// Promotes a user to Admin role.
  Future<void> promoteToAdmin(Session session, {required UuidValue userId}) async {
    await getAdminProfile(session);
    await ResidentService.setRole(session, userId, protocol.ResidentRole.admin);
  }

  /// Demotes an Admin to Moderator or regular user.
  Future<void> demoteFromAdmin(Session session, {required UuidValue userId}) async {
    await getAdminProfile(session);
    await ResidentService.setRole(session, userId, protocol.ResidentRole.moderator);
  }

  /// Promotes a user to Moderator role.
  Future<void> promoteToModerator(Session session, {required UuidValue userId}) async {
    await getAdminProfile(session);
    await ResidentService.setRole(session, userId, protocol.ResidentRole.moderator);
  }

  /// Demotes a moderator back to a regular user.
  Future<void> demoteFromModerator(Session session, {required UuidValue userId}) async {
    await getAdminProfile(session);
    await ResidentService.setRole(session, userId, protocol.ResidentRole.user);
  }

  /// Makes a lounge private/locked by staff.
  Future<void> makeLoungePrivate(Session session, int loungeId) async {
    await getStaffProfile(session);
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge != null) {
      lounge.isPublic = false;
      lounge.isStaffLocked = true;
      await protocol.Lounge.db.updateRow(session, lounge);
    }
  }

  /// Disbands a lounge.
  Future<void> disbandLounge(Session session, {required int loungeId, String? reason}) async {
    await getStaffProfile(session);
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge != null) {
      await LoungeService.deleteLounge(session, lounge);
    }
  }

  /// Checks if the current user is a staff member.
  Future<bool> isStaff(Session session) async {
    try {
      await getStaffProfile(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches detailed user information and history for administrative review.
  Future<protocol.AdminUserDetails> getUserDetails(
    Session session, {
    required UuidValue userId,
  }) async {
    await getStaffProfile(session);
    final detail = await AdminService.getUserDetails(session, userId);
    if (detail == null) throw protocol.TalktiveException(message: 'User not found');
    return detail;
  }
}
