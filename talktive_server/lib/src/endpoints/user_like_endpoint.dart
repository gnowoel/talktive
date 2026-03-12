import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/input_validation_service.dart';
import 'dart:math';

class UserLikeEndpoint extends Endpoint {
  /// Vouch/Like a user.
  /// Implements One-Vote Rule and adds +10 to target's Trust Score.
  Future<void> likeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final callerIdentifier = session.authenticated?.userIdentifier;
    if (callerIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final callerUuid = UuidValue.fromString(callerIdentifier);
    final targetUuid = UuidValue.fromString(targetUserId);

    if (callerUuid == targetUuid) {
      throw protocol.TalktiveException(message: 'You cannot like yourself.');
    }

    // Fetch caller
    final caller = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(callerUuid),
    );
    if (caller == null) {
      throw protocol.TalktiveException(message: 'Caller profile not found');
    }

    // Fetch target
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target user not found');
    }

    // One-Vote Rule: Check if already liked
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) =>
          t.senderId.equals(callerUuid) & t.receiverId.equals(targetUuid),
    );
    if (existingLike != null) {
      throw protocol.TalktiveException(message: 'You have already vouched for this user.');
    }

    // One-Vote Rule: Check if already reported
    final existingReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) =>
          t.reporterId.equals(callerUuid) & t.targetId.equals(targetUuid),
    );
    if (existingReport != null) {
      throw protocol.TalktiveException(message: 'You cannot vouch for a user you have reported.');
    }

    // Insert to UserLike
    final userLike = protocol.UserLike(
      senderId: callerUuid,
      receiverId: targetUuid,
      createdAt: DateTime.now(),
    );
    await protocol.UserLike.db.insertRow(session, userLike);

    // Give target +10 Trust Score
    target.trustScore += 10;
    await protocol.Resident.db.updateRow(session, target);

    session.log(
      'User $callerUuid liked user $targetUuid. Target Trust Score is now ${target.trustScore}',
    );
  }

  /// Remove a Vouch/Like from a user.
  /// Removes -10 from target's Trust Score.
  Future<void> unlikeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final callerIdentifier = session.authenticated?.userIdentifier;
    if (callerIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final callerUuid = UuidValue.fromString(callerIdentifier);
    final targetUuid = UuidValue.fromString(targetUserId);

    // Fetch target
    final target = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUuid),
    );
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target user not found');
    }

    // Check if like exists
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) =>
          t.senderId.equals(callerUuid) & t.receiverId.equals(targetUuid),
    );
    if (existingLike == null) {
      throw protocol.TalktiveException(message: 'Like not found');
    }

    // Remove from UserLike
    await protocol.UserLike.db.deleteRow(session, existingLike);

    // Subtract 10 Trust Score (minimum 0)
    target.trustScore = max(0, target.trustScore - 10);
    await protocol.Resident.db.updateRow(session, target);

    session.log(
      'User $callerUuid unliked user $targetUuid. Target Trust Score is now ${target.trustScore}',
    );
  }

  /// Get the list of UUIDs that the current user has liked.
  Future<List<String>> getMyLikedUserIds(Session session) async {
    final callerIdentifier = session.authenticated?.userIdentifier;
    if (callerIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final callerUuid = UuidValue.fromString(callerIdentifier);

    final likes = await protocol.UserLike.db.find(
      session,
      where: (t) => t.senderId.equals(callerUuid),
    );

    return likes.map((e) => e.receiverId.toString()).toList();
  }
}
