import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/achievement_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';

class GroupEndpoint extends Endpoint {
  /// Creates a new group.
  Future<protocol.Group> createGroup(
    Session session,
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
  }) async {
    // Validate inputs
    InputValidationService.validateGroupName(name).throwIfInvalid();
    InputValidationService.validateGroupDescription(
      description,
    ).throwIfInvalid();
    InputValidationService.validateGroupMemberLimit(
      maxMembers,
    ).throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Verify user exists
    final currentResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );

    if (currentResident == null) {
      throw Exception('User not found');
    }

    // Safety: muted or suspended users cannot create groups
    if (ApartmentService.isMuted(currentResident)) {
      throw Exception(ApartmentService.getMuteReason(currentResident));
    }

    // Safety: must be at least Floor 1 to create a group
    if (ApartmentService.computeReputation(currentResident) < 1) {
      throw Exception(
        'You must reach Floor 1 to create a group. Keep chatting!',
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
    await AchievementService.trackProgress(
      session,
      currentUserId,
      'community_builder',
    );

    return savedGroup;
  }

  /// Lists all groups (public groups + groups user is a member of).
  Future<List<protocol.Group>> listGroups(
    Session session, {
    int limit = 50,
    int offset = 0,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get all groups where user is a member
    final memberChannelIds = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.userInfoId.equals(currentUserId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    final memberChannelIdList = memberChannelIds
        .map((m) => m.channelId)
        .toList();

    // Get all public groups OR groups where user is a member
    final groups = await protocol.Group.db.find(
      session,
      where: (t) =>
          t.isPublic.equals(true) |
          (memberChannelIdList.isNotEmpty
              ? t.channelId.inSet(memberChannelIdList.toSet())
              : t.channelId.equals(
                  -1,
                )), // Impossible condition if no memberships
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );

    return groups;
  }

  /// Gets details about a specific group.
  Future<protocol.Group> getGroup(Session session, int groupId) async {
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
    }

    return group;
  }

  /// Joins a group.
  Future<void> joinGroup(Session session, int groupId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
    }

    // Check if group is full
    if (group.memberCount >= group.maxMembers) {
      throw Exception('Group is full');
    }

    // Fetch current resident profile for safety checks
    final currentResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );
    if (currentResident == null) {
      throw Exception('User profile not found');
    }

    // Safety: muted or suspended users cannot join groups
    if (ApartmentService.isMuted(currentResident)) {
      throw Exception(ApartmentService.getMuteReason(currentResident));
    }

    // Check if user is already a member
    final existingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(group.channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (existingMember != null) {
      if (existingMember.status == protocol.ChannelMemberStatus.joined) {
        throw Exception('Already a member of this group');
      }
      // Update status if previously left
      existingMember.status = protocol.ChannelMemberStatus.joined;
      existingMember.joinedAt = DateTime.now();
      await protocol.ChannelMember.db.updateRow(session, existingMember);
    } else {
      // Add as new member
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: group.channelId,
          userInfoId: currentUserId,
          status: protocol.ChannelMemberStatus.joined,
          joinedAt: DateTime.now(),
        ),
      );
    }

    // Increment member count
    group.memberCount += 1;
    await protocol.Group.db.updateRow(session, group);

    // Track achievement
    await AchievementService.trackProgress(
      session,
      currentUserId,
      'social_butterfly',
    );
  }

  /// Leaves a group.
  Future<void> leaveGroup(Session session, int groupId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
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
      throw Exception('Not a member of this group');
    }

    // Update member status
    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    // Decrement member count
    group.memberCount = (group.memberCount - 1).clamp(0, group.maxMembers);
    await protocol.Group.db.updateRow(session, group);
  }

  /// Gets all members of a group.
  Future<List<protocol.Resident>> getGroupMembers(
    Session session,
    int groupId,
  ) async {
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
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
  }) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
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
      throw Exception('Only admins can update group details');
    }

    // Update fields
    if (name != null && name.trim().isNotEmpty) {
      if (name.length > 50) {
        throw Exception('Group name must be 50 characters or less');
      }
      group.name = name;
    }

    if (description != null) {
      group.description = description;
    }

    if (emoji != null) {
      group.emoji = emoji;
    }

    if (isPublic != null) {
      group.isPublic = isPublic;
    }

    if (maxMembers != null) {
      if (maxMembers < group.memberCount) {
        throw Exception('Cannot set max members below current member count');
      }
      if (maxMembers < 2 || maxMembers > 500) {
        throw Exception('Max members must be between 2 and 500');
      }
      group.maxMembers = maxMembers;
    }

    return await protocol.Group.db.updateRow(session, group);
  }

  /// Deletes a group (creator only).
  Future<void> deleteGroup(Session session, int groupId) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the group
    final group = await protocol.Group.db.findById(session, groupId);

    if (group == null) {
      throw Exception('Group not found');
    }

    // Check if user is the creator
    if (group.creatorId != currentUserId) {
      throw Exception('Only the creator can delete the group');
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
