import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/notification_service.dart';
import '../services/lounge_service.dart';
import '../services/resident_service.dart';
import '../services/chat_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class LoungeEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates a new lounge.
  Future<protocol.Lounge> createLounge(
    Session session,
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
  }) async {
    // Validate inputs
    InputValidationService.validateLoungeName(name).throwIfInvalid();
    InputValidationService.validateLoungeDescription(
      description,
    ).throwIfInvalid();
    InputValidationService.validateLoungeMemberLimit(
      maxMembers,
    ).throwIfInvalid();

    final currentUserId = await getUserId(session);
    final currentResident = await getAuthenticatedResident(session);

    // Safety: muted or suspended users cannot create lounges
    if (ApartmentService.isMuted(currentResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(currentResident),
        code: 'USER_MUTED',
      );
    }

    // Safety: must be at least Floor 1 to create a lounge
    if (ApartmentService.computeEffectiveFloor(currentResident) < 1) {
      throw protocol.TalktiveException(
        message: 'You must reach Floor 1 to create a lounge. Keep chatting!',
        code: 'FLOOR_TOO_LOW',
      );
    }

    return await LoungeService.createLounge(
      session,
      name: name,
      creatorId: currentUserId,
      description: description,
      emoji: emoji,
      isPublic: isPublic,
      maxMembers: maxMembers,
      interests: interests,
    );
  }

  /// Lists all lounges the user considers 'theirs' (joined, invited, applied).
  Future<List<protocol.LoungeWithMembership>> listMyLounges(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    final currentUserId = await getUserId(session);

    // Get all lounges where user is a tracked member
    final memberships = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.userInfoId.equals(currentUserId) &
          t.status.inSet({
            protocol.ChannelMemberStatus.joined,
            protocol.ChannelMemberStatus.invited,
            protocol.ChannelMemberStatus.applied,
          }),
      limit: limit,
      offset: offset,
    );

    final membershipMap = {
      for (var m in memberships) m.channelId: m,
    };

    if (membershipMap.isEmpty) {
      return [];
    }

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) => t.channelId.inSet(membershipMap.keys.toSet()),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    final unreadCounts = await ChatService.batchGetUnreadCounts(
      session,
      lounges.map((l) => l.channelId).toList(),
      currentUserId,
    );

    return lounges.map((g) {
      final member = membershipMap[g.channelId];
      return protocol.LoungeWithMembership(
        lounge: g,
        membershipStatus: member?.status ?? protocol.ChannelMemberStatus.left,
        membershipRole: member?.role,
        isMuted: member?.isMuted,
        unreadCount: unreadCounts[g.channelId] ?? 0,
      );
    }).toList();
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
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    // If query is empty and user is logged in, show personalized recommendations
    if (query.trim().isEmpty && currentUserIdentifier != null) {
      final currentUserId = UuidValue.fromString(currentUserIdentifier);
      final resident = await ResidentService.getResident(session, currentUserId);

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
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    if (!lounge.isPublic) {
      throw protocol.TalktiveException(message: 'Cannot apply to a private lounge');
    }

    // Check if lounge is full
    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    // Fetch current resident profile for safety checks
    final currentResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );
    if (currentResident == null) {
      throw protocol.TalktiveException(message: 'User profile not found');
    }

    // Safety: muted or suspended users cannot apply to lounges
    if (ApartmentService.isMuted(currentResident)) {
      throw protocol.TalktiveException(message: ApartmentService.getMuteReason(currentResident));
    }

    // Check if user is already a member or has already applied
    final existingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (existingMember != null) {
      if (existingMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'Already a member of this lounge');
      } else if (existingMember.status ==
          protocol.ChannelMemberStatus.applied) {
        throw protocol.TalktiveException(message: 'Already applied to this lounge');
      }

      // Update status if previously left or declined
      existingMember.status = protocol.ChannelMemberStatus.applied;
      existingMember.joinedAt = DateTime.now();
      await protocol.ChannelMember.db.updateRow(session, existingMember);
    } else {
      // Add as new applied member
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: lounge.channelId,
          userInfoId: currentUserId,
          status: protocol.ChannelMemberStatus.applied,
          joinedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Invites a user to a lounge (by any current member or creator).
  Future<void> inviteUserToLounge(
    Session session,
    int loungeId,
    String targetUserIdString,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);
    final targetUserId = UuidValue.fromString(targetUserIdString);

    if (currentUserId == targetUserId) {
      throw protocol.TalktiveException(message: 'Cannot invite yourself');
    }

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Verify current user is a joined member and not muted
    final currentUserResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );
    if (currentUserResident == null) {
      throw protocol.TalktiveException(message: 'User profile not found');
    }

    if (ApartmentService.isMuted(currentUserResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(currentUserResident),
      );
    }

    final currentUserMemberResult = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (currentUserMemberResult == null) {
      throw protocol.TalktiveException(
        message: 'You are not a member of this lounge',
      );
    }

    // Check if lounge is full
    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    // Check if target has blocked inviter
    if (await ResidentService.isBlocked(
      session,
      blockerId: targetUserId,
      blockedId: currentUserId,
    )) {
      throw protocol.TalktiveException(
        message: 'You cannot invite this user.',
      );
    }

    // Check if target is already in the lounge
    final targetMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(targetUserId),
    );

    if (targetMember != null) {
      if (targetMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'User is already a member');
      } else if (targetMember.status == protocol.ChannelMemberStatus.invited) {
        throw protocol.TalktiveException(message: 'User is already invited');
      }

      targetMember.status = protocol.ChannelMemberStatus.invited;
      targetMember.invitedBy = currentUserId;
      targetMember.joinedAt = DateTime.now();
      await protocol.ChannelMember.db.updateRow(session, targetMember);
    } else {
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: lounge.channelId,
          userInfoId: targetUserId,
          status: protocol.ChannelMemberStatus.invited,
          invitedBy: currentUserId,
          joinedAt: DateTime.now(),
        ),
      );
    }

    // Send notification
    try {
      final inviter = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(currentUserId),
      );

      if (inviter != null) {
        await NotificationService.sendLoungeInviteNotification(
          session,
          targetUserId,
          inviter.userName ?? 'Someone',
          lounge.name,
          lounge.emoji ?? '👥',
          lounge.id!,
        );
      }
    } catch (e) {
      session.log('Failed to send lounge invite notification: $e');
    }
  }

  /// Responds to a lounge invite (accept or decline).
  Future<void> respondToLoungeInvite(
    Session session,
    int loungeId,
    bool accept,
  ) async {
    final currentUserId = await getUserId(session);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.invited),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'No pending invitation found');
    }

    if (!accept) {
      member.status = protocol.ChannelMemberStatus.declined;
      await protocol.ChannelMember.db.updateRow(session, member);
      return;
    }

    // The user accepted.
    // If they were invited by the creator (host), they bypass approval and join instantly.
    if (member.invitedBy == lounge.creatorId) {
      if (lounge.memberCount >= lounge.maxMembers) {
        throw protocol.TalktiveException(message: 'Lounge is full');
      }
      member.status = protocol.ChannelMemberStatus.joined;
      await protocol.ChannelMember.db.updateRow(session, member);

      lounge.memberCount += 1;
      await protocol.Lounge.db.updateRow(session, lounge);

      await GamificationService.trackProgress(
        session,
        currentUserId,
        'social_butterfly',
      );

      // Award XP for joining lounge
      final resident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(currentUserId),
      );
      if (resident != null) {
        await GamificationService.awardXP(
          session,
          resident,
          25,
          'Joined lounge',
        );
      }
    } else {
      // Invited by a regular member, they transition to "applied" and wait for the Host to approve.
      member.status = protocol.ChannelMemberStatus.applied;
      await protocol.ChannelMember.db.updateRow(session, member);
    }
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

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Enforce creator access control
    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(message: 'Only the creator can approve applications');
    }

    final pendingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(targetUserId) &
          t.status.equals(protocol.ChannelMemberStatus.applied),
    );

    if (pendingMember == null) {
      throw protocol.TalktiveException(message: 'No pending application found for this user');
    }

    if (!approve) {
      pendingMember.status = protocol.ChannelMemberStatus.declined;
      await protocol.ChannelMember.db.updateRow(session, pendingMember);
      return;
    }

    // Approve user
    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    pendingMember.status = protocol.ChannelMemberStatus.joined;
    await protocol.ChannelMember.db.updateRow(session, pendingMember);

    lounge.memberCount += 1;
    await protocol.Lounge.db.updateRow(session, lounge);

    await GamificationService.trackProgress(
      session,
      targetUserId,
      'social_butterfly',
    );

    // Award XP to the approved user
    final targetResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(targetUserId),
    );
    if (targetResident != null) {
      await GamificationService.awardXP(
        session,
        targetResident,
        25,
        'Application approved',
      );
    }
  }

  /// Kicks a member from the lounge (creator only).
  Future<void> kickMember(
    Session session,
    int loungeId,
    String targetUserIdString,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);
    final targetUserId = UuidValue.fromString(targetUserIdString);

    if (currentUserId == targetUserId) {
      throw protocol.TalktiveException(message: 'You cannot kick yourself. Use leaveLounge instead.');
    }

    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(message: 'Only the creator can kick members');
    }

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(targetUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'User is not a member of the lounge');
    }

    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    lounge.memberCount = (lounge.memberCount - 1).clamp(0, lounge.maxMembers);
    await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Leaves a lounge.
  Future<void> leaveLounge(Session session, int loungeId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Check if user is a member
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'Not a member of this lounge');
    }

    // Update member status
    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    // Decrement member count
    lounge.memberCount = (lounge.memberCount - 1).clamp(0, lounge.maxMembers);
    await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Gets all members of a lounge with their profiles.
  Future<void> toggleMuteLounge(
    Session session,
    int loungeId,
    bool isMuted,
  ) async {
    final currentUserId = await getUserId(session);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Check if user is a member
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'Not a member of this lounge');
    }

    member.isMuted = isMuted;
    await protocol.ChannelMember.db.updateRow(session, member);
  }

  /// Gets all members of a lounge with their profiles.
  Future<List<protocol.LoungeMemberWithProfile>> getLoungeMembersWithProfiles(
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
  Future<List<protocol.LoungeMemberWithProfile>>
  getPendingApplicationsWithProfiles(
    Session session,
    int loungeId,
  ) async {
    final currentUserId = await getUserId(session);
    final lounge = await getLounge(session, loungeId);

    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can view pending applications',
      );
    }

    return await LoungeService.getMembersByStatus(
      session,
      lounge.channelId,
      protocol.ChannelMemberStatus.applied,
    );
  }

  /// Gets all members of a lounge.
  Future<List<protocol.Resident>> getLoungeMembers(
    Session session,
    int loungeId,
  ) async {
    final lounge = await getLounge(session, loungeId);

    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
      orderBy: (t) => t.joinedAt,
    );

    if (members.isEmpty) return [];

    final userIds = members.map((m) => m.userInfoId).toSet().toList();
    return await ResidentService.getResidents(session, userIds);
  }

  /// Updates lounge details (admin only).
  Future<protocol.Lounge> updateLounge(
    Session session,
    int loungeId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
    List<String>? interests,
  }) async {
    final currentUserId = await getUserId(session);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Check if user is admin
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null || member.role != 'admin') {
      throw protocol.TalktiveException(
        message: 'Only admins can update lounge details',
        code: 'ACCESS_DENIED',
      );
    }

    // Validate inputs if provided
    if (name != null) {
      InputValidationService.validateLoungeName(name).throwIfInvalid();
    }
    if (description != null) {
      InputValidationService.validateLoungeDescription(
        description,
      ).throwIfInvalid();
    }
    if (maxMembers != null) {
      InputValidationService.validateLoungeMemberLimit(
        maxMembers,
      ).throwIfInvalid();
    }

    // Update fields
    if (name != null && name.trim().isNotEmpty) {
      lounge.name = name;
    }

    if (description != null) {
      lounge.description = description;
    }

    if (emoji != null) {
      lounge.emoji = emoji;
    }

    if (isPublic != null) {
      if (isPublic && lounge.isStaffLocked) {
        throw protocol.TalktiveException(
          message:
              'This lounge has been locked to private by an administrator and cannot be made public.',
          code: 'ADMIN_LOCKED',
        );
      }
      lounge.isPublic = isPublic;
    }

    if (maxMembers != null) {
      if (maxMembers < lounge.memberCount) {
        throw protocol.TalktiveException(
          message: 'Cannot set max members below current member count',
          code: 'INVALID_INPUT',
        );
      }
      lounge.maxMembers = maxMembers;
    }

    if (interests != null) {
      lounge.interests = interests;
    }

    return await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Deletes a lounge (creator only).
  Future<void> deleteLounge(Session session, int loungeId) async {
    final currentUserId = await getUserId(session);

    // Get the lounge
    final lounge = await protocol.Lounge.db.findById(session, loungeId);

    if (lounge == null) {
      throw protocol.TalktiveException(
        message: 'Lounge not found',
        code: 'LOUNGE_NOT_FOUND',
      );
    }

    // Check if user is the creator
    if (lounge.creatorId != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can delete the lounge',
        code: 'ACCESS_DENIED',
      );
    }

    // Delete all channel members
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(lounge.channelId),
    );

    for (final member in members) {
      await protocol.ChannelMember.db.deleteRow(session, member);
    }

    // Delete the lounge
    await protocol.Lounge.db.deleteRow(session, lounge);

    // Delete the channel
    final channel = await protocol.Channel.db.findById(
      session,
      lounge.channelId,
    );
    if (channel != null) {
      await protocol.Channel.db.deleteRow(session, channel);
    }
  }
}
