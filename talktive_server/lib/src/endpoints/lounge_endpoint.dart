import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/lounge_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';

/// Endpoint for managing interest-based lounges (Clubhouse).
class LoungeEndpoint extends Endpoint with EndpointAuthMixin {
  @override
  bool get requireLogin => true;

  /// Creates a new lounge.
  Future<protocol.Lounge> createLounge(
    Session session,
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) async {
    // 1. Validation
    InputValidationService.validateLoungeName(name).throwIfInvalid();
    InputValidationService.validateLoungeDescription(
      description,
    ).throwIfInvalid();
    InputValidationService.validateLoungeRules(rules).throwIfInvalid();
    InputValidationService.validateLoungeMemberLimit(
      maxMembers,
    ).throwIfInvalid();
    InputValidationService.validateStringList(
      interests,
      'Interests',
    ).throwIfInvalid();
    InputValidationService.validateStringList(
      languages,
      'Languages',
    ).throwIfInvalid();
    InputValidationService.validateCountry(country).throwIfInvalid();

    final currentUserId = await getUserId(session);
    final currentResident = await getAuthenticatedResident(session);

    // 2. Safety Checks
    if (ApartmentService.isMuted(currentResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(currentResident),
        code: 'USER_MUTED',
      );
    }

    if (ApartmentService.computeEffectiveFloor(currentResident) < 1) {
      throw protocol.TalktiveException(
        message: 'You must reach Floor 1 to create a lounge. Keep chatting!',
        code: 'FLOOR_TOO_LOW',
      );
    }

    // 3. Delegation
    return await LoungeService.createLounge(
      session,
      name: name,
      creatorId: currentUserId,
      description: description,
      emoji: emoji,
      isPublic: isPublic,
      maxMembers: maxMembers,
      interests: interests,
      languages: languages,
      country: country,
      rules: rules,
    );
  }

  /// Lists all lounges the user considers 'theirs' (joined, invited, applied).
  Future<List<protocol.LoungeWithMembership>> listMyLounges(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();
    final currentUserId = await getUserId(session);

    return await LoungeService.listMyLounges(
      session,
      currentUserId,
      limit: limit,
      offset: offset,
    );
  }

  /// Gets details about a specific lounge.
  Future<protocol.Lounge> getLounge(Session session, int loungeId) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }
    return lounge;
  }

  /// Searches for public lounges based on a query.
  Future<List<protocol.Lounge>> searchPublicLounges(
    Session session,
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = await getUserIdOptional(session);

    if (query.trim().isEmpty && userId != null) {
      final resident = await ResidentService.getResident(session, userId);
      if (resident != null) {
        return await LoungeService.getRecommendedLounges(
          session,
          resident,
          limit: limit,
          offset: offset,
        );
      }
    }

    return await LoungeService.searchLounges(
      session,
      query,
      limit: limit,
      offset: offset,
    );
  }

  /// Applies to join a public lounge.
  Future<void> applyToLounge(Session session, int loungeId) async {
    final lounge = await getLounge(session, loungeId);
    final resident = await getAuthenticatedResident(session);

    if (ApartmentService.isMuted(resident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(resident),
      );
    }

    await LoungeService.applyToLounge(
      session,
      lounge: lounge,
      resident: resident,
    );
  }

  /// Invites a user to a lounge.
  Future<void> inviteUserToLounge(
    Session session,
    int loungeId,
    String targetUserIdString,
  ) async {
    final inviter = await getAuthenticatedResident(session);
    final lounge = await getLounge(session, loungeId);
    final targetUserId = UuidValue.fromString(targetUserIdString);

    if (inviter.userInfoId == targetUserId) {
      throw protocol.TalktiveException(message: 'Cannot invite yourself');
    }

    if (ApartmentService.isMuted(inviter)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(inviter),
      );
    }

    // Verify inviter is a member
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(inviter.userInfoId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(
        message: 'You are not a member of this lounge',
      );
    }

    final target = await ResidentService.getResident(session, targetUserId);
    if (target == null)
      throw protocol.TalktiveException(message: 'User profile not found');

    await LoungeService.inviteUser(
      session,
      lounge: lounge,
      inviter: inviter,
      target: target,
    );
  }

  /// Responds to a lounge invite.
  Future<void> respondToLoungeInvite(
    Session session,
    int loungeId,
    bool accept,
  ) async {
    final currentUserId = await getUserId(session);
    await LoungeService.respondToInvite(
      session,
      loungeId: loungeId,
      userId: currentUserId,
      accept: accept,
    );
  }

  /// Approves or rejects a pending lounge application (creator only).
  Future<void> approveLoungeApplication(
    Session session,
    int loungeId,
    String targetUserIdString,
    bool approve,
  ) async {
    final currentUserId = await getUserId(session);
    final targetUserId = UuidValue.fromString(targetUserIdString);

    await LoungeService.approveApplication(
      session,
      loungeId: loungeId,
      creatorId: currentUserId,
      targetId: targetUserId,
      approve: approve,
    );
  }

  /// Leaves a lounge.
  Future<void> leaveLounge(
    Session session,
    int loungeId,
  ) async {
    final currentUserId = await getUserId(session);

    await LoungeService.leaveLounge(
      session,
      loungeId: loungeId,
      userId: currentUserId,
    );
  }

  /// Toggles mute status for lounge notifications.
  Future<void> toggleMuteLounge(
    Session session,
    int loungeId,
    bool isMuted,
  ) async {
    final currentUserId = await getUserId(session);
    await LoungeService.toggleMute(session, loungeId, currentUserId, isMuted);
  }

  /// Gets all active members of a lounge.
  Future<List<protocol.LoungeMemberWithProfile>> getLoungeMembers(
    Session session,
    int loungeId,
  ) async {
    final lounge = await getLounge(session, loungeId);
    return await LoungeService.getMembersByStatus(
      session,
      lounge.channelId,
      protocol.ChannelMemberStatus.joined,
    );
  }

  /// Gets all pending applications for a lounge (creator only).
  Future<List<protocol.LoungeMemberWithProfile>> getPendingApplications(
    Session session,
    int loungeId,
  ) async {
    final currentUserId = await getUserId(session);
    final lounge = await getLounge(session, loungeId);

    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can view applications',
      );
    }

    return await LoungeService.getMembersByStatus(
      session,
      lounge.channelId,
      protocol.ChannelMemberStatus.applied,
    );
  }

  /// Updates lounge metadata (admin only).
  Future<protocol.Lounge> updateLounge(
    Session session,
    int loungeId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) async {
    final currentUserId = await getUserId(session);
    final lounge = await getLounge(session, loungeId);

    // Verify admin role in lounge
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null || member.role != 'admin') {
      throw protocol.TalktiveException(
        message: 'Only lounge admins can update details',
      );
    }

    // Validation
    if (name != null)
      InputValidationService.validateLoungeName(name).throwIfInvalid();
    if (description != null)
      InputValidationService.validateLoungeDescription(
        description,
      ).throwIfInvalid();
    if (maxMembers != null)
      InputValidationService.validateLoungeMemberLimit(
        maxMembers,
      ).throwIfInvalid();
    if (interests != null)
      InputValidationService.validateStringList(
        interests,
        'Interests',
      ).throwIfInvalid();
    if (languages != null)
      InputValidationService.validateStringList(
        languages,
        'Languages',
      ).throwIfInvalid();
    if (country != null)
      InputValidationService.validateCountry(country).throwIfInvalid();
    if (rules != null)
      InputValidationService.validateLoungeRules(rules).throwIfInvalid();

    if (isPublic != null && isPublic && lounge.isStaffLocked) {
      throw protocol.TalktiveException(
        message: 'This lounge is locked to private by staff.',
      );
    }

    return await LoungeService.updateLounge(
      session,
      lounge,
      name: name,
      description: description,
      emoji: emoji,
      isPublic: isPublic,
      maxMembers: maxMembers,
      interests: interests,
      languages: languages,
      country: country,
      rules: rules,
    );
  }

  /// Deletes a lounge (creator only).
  Future<void> deleteLounge(Session session, int loungeId) async {
    final currentUserId = await getUserId(session);
    final lounge = await getLounge(session, loungeId);

    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can delete the lounge',
      );
    }

    await LoungeService.deleteLounge(session, lounge);
  }

  /// Kicks a member from a lounge (creator only).
  Future<void> kickMember(
    Session session, {
    required int loungeId,
    required UuidValue targetUserId,
  }) async {
    final adminResident = await getAuthenticatedResident(session);
    await LoungeService.kickMember(
      session,
      loungeId: loungeId,
      targetId: targetUserId,
      creatorId: adminResident.userInfoId,
    );
  }
}
