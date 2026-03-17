import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/notification_service.dart';
import '../services/resident_service.dart';
import '../services/chat_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class GroupEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates a new group.
  Future<protocol.Group> createGroup(
    Session session,
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
  }) async {
    // Validate inputs
    InputValidationService.validateGroupName(name).throwIfInvalid();
    InputValidationService.validateGroupDescription(
      description,
    ).throwIfInvalid();
    InputValidationService.validateGroupMemberLimit(
      maxMembers,
    ).throwIfInvalid();

    final currentUserId = await getUserId(session);
    final currentResident = await getAuthenticatedResident(session);

    // Safety: muted or suspended users cannot create groups
    if (ApartmentService.isMuted(currentResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(currentResident),
        code: 'USER_MUTED',
      );
    }

    // Safety: must be at least Floor 1 to create a group
    if (ApartmentService.computeEffectiveFloor(currentResident) < 1) {
      throw protocol.TalktiveException(
        message: 'You must reach Floor 1 to create a group. Keep chatting!',
        code: 'FLOOR_TOO_LOW',
      );
    }

    // Create a new channel for this group
    final channel = protocol.Channel(
      name: name,
      type: protocol.ChannelType.group,
      createdAt: DateTime.now(),
    );

    final savedChannel = await protocol.Channel.db.insertRow(session, channel);

    // Create the group record
    final group = protocol.Group(
      channelId: savedChannel.id!,
      name: name,
      description: description,
      emoji: emoji,
      creatorId: currentUserId,
      createdAt: DateTime.now(),
      memberCount: 1,
      isPublic: isPublic,
      maxMembers: maxMembers,
      interests: interests,
    );

    final savedGroup = await protocol.Group.db.insertRow(session, group);

    // Add creator as first member with admin role
    await protocol.ChannelMember.db.insertRow(
      session,
      protocol.ChannelMember(
        channelId: savedChannel.id!,
        userInfoId: currentUserId,
        status: protocol.ChannelMemberStatus.joined,
        joinedAt: DateTime.now(),
        role: 'admin',
      ),
    );

    // Track achievement
    await GamificationService.trackProgress(
      session,
      currentUserId,
      'community_builder',
    );

    return savedGroup;
  }

  /// Lists all groups the user considers 'theirs' (joined, invited, applied).
  Future<List<protocol.GroupWithMembership>> listMyGroups(
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

    // Get all groups where user is a tracked member
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

    final groups = await protocol.Group.db.find(
      session,
      where: (t) => t.channelId.inSet(membershipMap.keys.toSet()),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    return Future.wait(groups.map((g) async {
      final member = membershipMap[g.channelId];
      return protocol.GroupWithMembership(
        group: g,
        membershipStatus: member?.status ?? protocol.ChannelMemberStatus.left,
        membershipRole: member?.role,
        isMuted: member?.isMuted,
        unreadCount: await ChatService.getUnreadCount(
          session,
          g.channelId,
          currentUserId,
        ),
      );
    }));
  }

  /// Gets details about a specific group.
  Future<protocol.Group> getGroup(Session session, int groupId) async {
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    return group;
  }

  /// Searches for public groups based on a query.
  Future<List<protocol.Group>> searchPublicGroups(
    Session session,
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;
    UuidValue? currentUserId;
    if (currentUserIdentifier != null) {
      currentUserId = UuidValue.fromString(currentUserIdentifier);
    }

    // If query is empty and user is logged in, show personalized recommendations
    if (query.trim().isEmpty && currentUserId != null) {
      final resident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(currentUserId!),
      );

      if (resident != null &&
          resident.interests != null &&
          resident.interests!.isNotEmpty) {
        // Find public groups
        final allPublicGroups = await protocol.Group.db.find(
          session,
          where: (t) => t.isPublic.equals(true),
          limit: 100, // Limit the scan for personalization
        );

        // Sort by interest match count
        allPublicGroups.sort((a, b) {
          final aMatch =
              a.interests
                  ?.where((i) => resident.interests!.contains(i))
                  .length ??
              0;
          final bMatch =
              b.interests
                  ?.where((i) => resident.interests!.contains(i))
                  .length ??
              0;
          if (aMatch != bMatch)
            return bMatch.compareTo(aMatch); // More matches first
          return b.memberCount.compareTo(
            a.memberCount,
          ); // Then more members first
        });

        return allPublicGroups.skip(offset).take(limit).toList();
      }
    }

    if (query.trim().isEmpty) {
      return [];
    }

    final sanitizedQuery = query.trim().toLowerCase();

    // Find all public groups that contain the query string in name or description
    final groups = await protocol.Group.db.find(
      session,
      where: (t) =>
          t.isPublic.equals(true) &
          (t.name.ilike('%$sanitizedQuery%') |
              t.description.ilike('%$sanitizedQuery%')),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    return groups;
  }

  /// Applies to join a public group.
  Future<void> applyToGroup(Session session, int groupId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    if (!group.isPublic) {
      throw protocol.TalktiveException(message: 'Cannot apply to a private group');
    }

    // Check if group is full
    if (group.memberCount >= group.maxMembers) {
      throw protocol.TalktiveException(message: 'Group is full');
    }

    // Fetch current resident profile for safety checks
    final currentResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );
    if (currentResident == null) {
      throw protocol.TalktiveException(message: 'User profile not found');
    }

    // Safety: muted or suspended users cannot apply to groups
    if (ApartmentService.isMuted(currentResident)) {
      throw protocol.TalktiveException(message: ApartmentService.getMuteReason(currentResident));
    }

    // Check if user is already a member or has already applied
    final existingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (existingMember != null) {
      if (existingMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'Already a member of this group');
      } else if (existingMember.status ==
          protocol.ChannelMemberStatus.applied) {
        throw protocol.TalktiveException(message: 'Already applied to this group');
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
          channelId: group.channelId,
          userInfoId: currentUserId,
          status: protocol.ChannelMemberStatus.applied,
          joinedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Invites a user to a group (by any current member or creator).
  Future<void> inviteUserToGroup(
    Session session,
    int groupId,
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

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
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
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (currentUserMemberResult == null) {
      throw protocol.TalktiveException(
        message: 'You are not a member of this group',
      );
    }

    // Check if group is full
    if (group.memberCount >= group.maxMembers) {
      throw protocol.TalktiveException(message: 'Group is full');
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

    // Check if target is already in the group
    final targetMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
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
          channelId: group.channelId,
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
        await NotificationService.sendGroupInviteNotification(
          session,
          targetUserId,
          inviter.userName ?? 'Someone',
          group.name,
          group.emoji ?? '👥',
          group.id!,
        );
      }
    } catch (e) {
      session.log('Failed to send group invite notification: $e');
    }
  }

  /// Responds to a group invite (accept or decline).
  Future<void> respondToGroupInvite(
    Session session,
    int groupId,
    bool accept,
  ) async {
    final currentUserId = await getUserId(session);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
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
    if (member.invitedBy == group.creatorId) {
      if (group.memberCount >= group.maxMembers) {
        throw protocol.TalktiveException(message: 'Group is full');
      }
      member.status = protocol.ChannelMemberStatus.joined;
      await protocol.ChannelMember.db.updateRow(session, member);

      group.memberCount += 1;
      await protocol.Group.db.updateRow(session, group);

      await GamificationService.trackProgress(
        session,
        currentUserId,
        'social_butterfly',
      );

      // Award XP for joining group
      final resident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(currentUserId),
      );
      if (resident != null) {
        await GamificationService.awardXP(
          session,
          resident,
          25,
          'Joined group',
        );
      }
    } else {
      // Invited by a regular member, they transition to "applied" and wait for the Host to approve.
      member.status = protocol.ChannelMemberStatus.applied;
      await protocol.ChannelMember.db.updateRow(session, member);
    }
  }

  /// Approves or rejects a pending group application (creator only).
  Future<void> approveGroupApplication(
    Session session,
    int groupId,
    String targetUserIdString,
    bool approve,
  ) async {
    final currentUserId = await getUserId(session);
    final targetUserId = UuidValue.fromString(targetUserIdString);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Enforce creator access control
    if (group.creatorId != currentUserId) {
      throw protocol.TalktiveException(message: 'Only the creator can approve applications');
    }

    final pendingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
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
    if (group.memberCount >= group.maxMembers) {
      throw protocol.TalktiveException(message: 'Group is full');
    }

    pendingMember.status = protocol.ChannelMemberStatus.joined;
    await protocol.ChannelMember.db.updateRow(session, pendingMember);

    group.memberCount += 1;
    await protocol.Group.db.updateRow(session, group);

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

  /// Kicks a member from the group (creator only).
  Future<void> kickMember(
    Session session,
    int groupId,
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
      throw protocol.TalktiveException(message: 'You cannot kick yourself. Use leaveGroup instead.');
    }

    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    if (group.creatorId != currentUserId) {
      throw protocol.TalktiveException(message: 'Only the creator can kick members');
    }

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(targetUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'User is not a member of the group');
    }

    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    group.memberCount = (group.memberCount - 1).clamp(0, group.maxMembers);
    await protocol.Group.db.updateRow(session, group);
  }

  /// Leaves a group.
  Future<void> leaveGroup(Session session, int groupId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Check if user is a member
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'Not a member of this group');
    }

    // Update member status
    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    // Decrement member count
    group.memberCount = (group.memberCount - 1).clamp(0, group.maxMembers);
    await protocol.Group.db.updateRow(session, group);
  }

  /// Gets all members of a group with their profiles.
  Future<void> toggleMuteGroup(
    Session session,
    int groupId,
    bool isMuted,
  ) async {
    final currentUserId = await getUserId(session);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Check if user is a member
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) {
      throw protocol.TalktiveException(message: 'Not a member of this group');
    }

    member.isMuted = isMuted;
    await protocol.ChannelMember.db.updateRow(session, member);
  }

  /// Gets all members of a group with their profiles.
  Future<List<protocol.GroupMemberWithProfile>> getGroupMembersWithProfiles(
    Session session,
    int groupId,
  ) async {
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Get all active members
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
      orderBy: (t) => t.joinedAt,
    );

    final userIds = members.map((m) => m.userInfoId).toSet();
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(userIds),
    );

    // Map resident profiles by ID for quick lookup
    final profileMap = {for (var r in residents) r.userInfoId: r};

    final results = <protocol.GroupMemberWithProfile>[];
    for (final member in members) {
      final resident = profileMap[member.userInfoId];
      if (resident != null) {
        results.add(
          protocol.GroupMemberWithProfile(
            resident: resident,
            status: member.status,
            role: member.role,
            joinedAt: member.joinedAt,
          ),
        );
      }
    }

    return results;
  }

  /// Gets all pending applications for a group (creator only).
  Future<List<protocol.GroupMemberWithProfile>>
  getPendingApplicationsWithProfiles(
    Session session,
    int groupId,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    if (group.creatorId != currentUserId) {
      throw protocol.TalktiveException(message: 'Only the creator can view pending applications');
    }

    // Get all applied members
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.status.equals(protocol.ChannelMemberStatus.applied),
      orderBy: (t) => t.joinedAt, // reuse joinedAt for application time
    );

    final userIds = members.map((m) => m.userInfoId).toSet();
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(userIds),
    );

    // Map resident profiles by ID for quick lookup
    final profileMap = {for (var r in residents) r.userInfoId: r};

    final results = <protocol.GroupMemberWithProfile>[];
    for (final member in members) {
      final resident = profileMap[member.userInfoId];
      if (resident != null) {
        results.add(
          protocol.GroupMemberWithProfile(
            resident: resident,
            status: member.status,
            role: member.role,
            joinedAt: member.joinedAt,
          ),
        );
      }
    }
    return results;
  }

  /// Gets all members of a group.
  Future<List<protocol.Resident>> getGroupMembers(
    Session session,
    int groupId,
  ) async {
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Get all active members
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    // Get resident info for each member
    final residents = <protocol.Resident>[];
    for (final member in members) {
      final resident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(member.userInfoId),
      );
      if (resident != null) {
        residents.add(resident);
      }
    }

    return residents;
  }

  /// Updates group details (admin only).
  Future<protocol.Group> updateGroup(
    Session session,
    int groupId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
    List<String>? interests,
  }) async {
    final currentUserId = await getUserId(session);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Check if user is admin
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null || member.role != 'admin') {
      throw protocol.TalktiveException(
        message: 'Only admins can update group details',
        code: 'ACCESS_DENIED',
      );
    }

    // Validate inputs if provided
    if (name != null) {
      InputValidationService.validateGroupName(name).throwIfInvalid();
    }
    if (description != null) {
      InputValidationService.validateGroupDescription(
        description,
      ).throwIfInvalid();
    }
    if (maxMembers != null) {
      InputValidationService.validateGroupMemberLimit(
        maxMembers,
      ).throwIfInvalid();
    }

    // Update fields
    if (name != null && name.trim().isNotEmpty) {
      group.name = name;
    }

    if (description != null) {
      group.description = description;
    }

    if (emoji != null) {
      group.emoji = emoji;
    }

    if (isPublic != null) {
      if (isPublic && group.isStaffLocked) {
        throw protocol.TalktiveException(
          message:
              'This lounge has been locked to private by an administrator and cannot be made public.',
          code: 'ADMIN_LOCKED',
        );
      }
      group.isPublic = isPublic;
    }

    if (maxMembers != null) {
      if (maxMembers < group.memberCount) {
        throw protocol.TalktiveException(
          message: 'Cannot set max members below current member count',
          code: 'INVALID_INPUT',
        );
      }
      group.maxMembers = maxMembers;
    }

    if (interests != null) {
      group.interests = interests;
    }

    return await protocol.Group.db.updateRow(session, group);
  }

  /// Deletes a group (creator only).
  Future<void> deleteGroup(Session session, int groupId) async {
    final currentUserId = await getUserId(session);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw protocol.TalktiveException(
        message: 'Group not found',
        code: 'GROUP_NOT_FOUND',
      );
    }

    // Check if user is the creator
    if (group.creatorId != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can delete the group',
        code: 'ACCESS_DENIED',
      );
    }

    // Delete all channel members
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(group.channelId),
    );

    for (final member in members) {
      await protocol.ChannelMember.db.deleteRow(session, member);
    }

    // Delete the group
    await protocol.Group.db.deleteRow(session, group);

    // Delete the channel
    final channel = await protocol.Channel.db.findById(
      session,
      group.channelId,
    );
    if (channel != null) {
      await protocol.Channel.db.deleteRow(session, channel);
    }
  }
}
