import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/resident_service.dart';
import '../services/report_service.dart';
import '../services/input_validation_service.dart';
import '../utils/endpoint_auth_mixin.dart';

/// Endpoint for peer-to-peer social interactions (Likes, Blocks, Reports).
class SocialEndpoint extends Endpoint with EndpointAuthMixin {
  @override
  bool get requireLogin => true;

  // --- Liking / Vouching ---

  /// Vouch/Like a user.
  Future<void> likeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final resident = await getAuthenticatedResident(session);
    final targetId = UuidValue.fromString(targetUserId);

    await ResidentService.vouchForUser(
      session,
      sender: resident,
      targetId: targetId,
    );
  }

  /// Remove a Vouch/Like.
  Future<void> unlikeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final callerId = await getUserId(session);
    final targetId = UuidValue.fromString(targetUserId);

    await ResidentService.removeVouch(
      session,
      senderId: callerId,
      targetId: targetId,
    );
  }

  /// Get list of user IDs liked by current user.
  Future<List<String>> getMyLikedUserIds(Session session) async {
    final callerId = await getUserId(session);
    final likes = await protocol.UserLike.db.find(
      session,
      where: (t) => t.senderId.equals(callerId),
    );
    return likes.map((e) => e.receiverId.toString()).toList();
  }

  // --- Blocking ---

  /// Blocks a user.
  Future<bool> blockUser(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    if (blockerId == targetId) {
      throw protocol.TalktiveException(message: 'You cannot block yourself.');
    }

    await ResidentService.setBlockStatus(
      session,
      blockerId: blockerId,
      targetId: targetId,
      block: true,
    );
    return true;
  }

  /// Unblocks a user.
  Future<bool> unblockUser(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    await ResidentService.setBlockStatus(
      session,
      blockerId: blockerId,
      targetId: targetId,
      block: false,
    );
    return true;
  }

  /// Checks if a user is blocked.
  Future<bool> isUserBlocked(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    return await ResidentService.isBlocked(
      session,
      blockerId: blockerId,
      blockedId: targetId,
    );
  }

  /// Gets list of user IDs blocked by current user.
  Future<List<String>> getBlockedUserIds(Session session) async {
    final blockerId = await getUserId(session);
    final blocks = await protocol.Block.db.find(
      session,
      where: (t) => t.blockerId.equals(blockerId),
    );
    return blocks.map((b) => b.blockedId.toString()).toList();
  }

  // --- Reporting ---

  /// Reports a user for inappropriate behavior.
  Future<void> reportUser(
    Session session, {
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    InputValidationService.validateReportReason(reason).throwIfInvalid();

    final reporterUuid = await getUserId(session);
    final targetUuid = UuidValue.fromString(targetUserId);

    if (reporterUuid == targetUuid) {
      throw protocol.TalktiveException(message: 'You cannot report yourself.');
    }

    final reporter = await getResidentProfile(session, reporterUuid);
    final target = await ResidentService.getResident(session, targetUuid);
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target user not found');
    }

    await ReportService.createReport(
      session,
      reporter: reporter,
      target: target,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
    );
  }
}
