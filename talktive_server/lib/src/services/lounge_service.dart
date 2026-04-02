import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'gamification_service.dart';
import 'notification_service.dart';
import 'resident_service.dart';
import 'channel_service.dart';
import 'cache_service.dart';
import 'admin_service.dart';
import '../utils/task_utils.dart';

/// Service for managing Lounge logic and discovery.
class LoungeService {
  /// Creates a new lounge and its associated channel and members.
  static Future<protocol.Lounge> createLounge(
    Session session, {
    required String name,
    required UuidValue creatorId,
    String? description,
    String? emoji,
    bool isPublic = true,
    int maxMembers = 50,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) async {
    // 1. Create a new channel for this lounge
    final savedChannel = await ChannelService.createChannel(
      session,
      name: name,
      type: protocol.ChannelType.lounge,
    );

    // 2. Create the lounge record
    final lounge = protocol.Lounge(
      channelId: savedChannel.id!,
      name: name,
      description: description,
      emoji: emoji,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      memberCount: 1,
      isPublic: isPublic,
      isStaffLocked: false,
      maxMembers: 50, // All new lounges start at 50 capacity
      interests: interests,
      languages: languages,
      country: country,
      rules: rules,
      level: 1,
      xp: 0,
    );

    final savedLounge = await protocol.Lounge.db.insertRow(session, lounge);

    // 3. Invalidate discovery cache so new lounge appears immediately
    await CacheService.invalidateDiscoveryCache(session);
    await ChannelService.updateMemberStatus(
      session,
      channelId: savedChannel.id!,
      userId: creatorId,
      status: protocol.ChannelMemberStatus.joined,
      role: 'admin',
    );

    // 4. Track achievement
    await GamificationService.trackProgress(
      session,
      creatorId,
      'community_builder',
    );

    return savedLounge;
  }

  /// Lists all lounges the user considers 'theirs' (joined, invited, applied).
  static Future<List<protocol.LoungeWithMembership>> listMyLounges(
    Session session,
    UuidValue userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final memberships = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.userInfoId.equals(userId) &
          t.status.inSet({
            protocol.ChannelMemberStatus.joined,
            protocol.ChannelMemberStatus.invited,
            protocol.ChannelMemberStatus.applied,
          }),
      limit: limit,
      offset: offset,
    );

    if (memberships.isEmpty) return [];

    final membershipMap = {for (var m in memberships) m.channelId: m};
    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) => t.channelId.inSet(membershipMap.keys.toSet()),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    final unreadCounts = await ChannelService.batchGetUnreadCounts(
      session,
      lounges.map((l) => l.channelId).toList(),
      userId,
    );

    return lounges.map((lounge) {
      final member = membershipMap[lounge.channelId];
      return protocol.LoungeWithMembership(
        lounge: lounge,
        membershipStatus: member?.status ?? protocol.ChannelMemberStatus.left,
        membershipRole: member?.role,
        isMuted: member?.isMuted ?? false,
        unreadCount: unreadCounts[lounge.channelId] ?? 0,
      );
    }).toList();
  }

  /// Searches for public lounges by name or description.
  static Future<List<protocol.Lounge>> searchLounges(
    Session session,
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return [];

    return await protocol.Lounge.db.find(
      session,
      where: (t) =>
          t.isPublic.equals(true) &
          (t.name.ilike('%$query%') | t.description.ilike('%$query%')),
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Applies to join a public lounge.
  static Future<void> applyToLounge(
    Session session, {
    required protocol.Lounge lounge,
    required protocol.Resident resident,
  }) async {
    if (!lounge.isPublic) {
      throw protocol.TalktiveException(
        message: 'Cannot apply to a private lounge',
      );
    }

    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    final existingMember = await ChannelService.getMember(
      session,
      lounge.channelId,
      resident.userInfoId,
    );

    if (existingMember != null) {
      if (existingMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(
          message: 'Already a member of this lounge',
        );
      } else if (existingMember.status ==
          protocol.ChannelMemberStatus.applied) {
        throw protocol.TalktiveException(
          message: 'Already applied to this lounge',
        );
      }
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: lounge.channelId,
      userId: resident.userInfoId,
      status: protocol.ChannelMemberStatus.applied,
    );
  }

  /// Invites a user to a lounge.
  static Future<void> inviteUser(
    Session session, {
    required protocol.Lounge lounge,
    required protocol.Resident inviter,
    required protocol.Resident target,
  }) async {
    final inviterId = inviter.userInfoId;
    final targetId = target.userInfoId;

    if (inviterId == targetId) {
      throw protocol.TalktiveException(message: 'Cannot invite yourself');
    }
    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    if (await ResidentService.isBlocked(
      session,
      blockerId: targetId,
      blockedId: inviterId,
    )) {
      throw protocol.TalktiveException(message: 'You cannot invite this user.');
    }

    final targetMember = await ChannelService.getMember(
      session,
      lounge.channelId,
      targetId,
    );

    if (targetMember != null) {
      if (targetMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'User is already a member');
      } else if (targetMember.status == protocol.ChannelMemberStatus.invited) {
        throw protocol.TalktiveException(message: 'User is already invited');
      }
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: lounge.channelId,
      userId: targetId,
      status: protocol.ChannelMemberStatus.invited,
      invitedBy: inviterId,
    );

    // Track achievement
    await GamificationService.trackProgress(
      session,
      inviterId,
      'community_connector',
    );

    // Notify target in background
    TaskUtils.runBackground(session, (backgroundSession) async {
      try {
        await NotificationService.sendLoungeInviteNotification(
          backgroundSession,
          targetId,
          inviter.userName ?? 'Someone',
          lounge.name,
          lounge.emoji ?? '👥',
          lounge.id!,
        );
      } catch (e) {
        backgroundSession.log('Failed to send lounge invite notification: $e');
      }
    });
  }

  /// Responds to a lounge invite.
  static Future<void> respondToInvite(
    Session session, {
    required int loungeId,
    required UuidValue userId,
    required bool accept,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) {
      throw protocol.TalktiveException(message: 'Lounge not found');
    }

    final member = await ChannelService.getMember(
      session,
      lounge.channelId,
      userId,
    );

    if (member == null ||
        member.status != protocol.ChannelMemberStatus.invited) {
      throw protocol.TalktiveException(message: 'No pending invitation found');
    }

    if (!accept) {
      await ChannelService.updateMemberStatus(
        session,
        channelId: lounge.channelId,
        userId: userId,
        status: protocol.ChannelMemberStatus.declined,
      );
      return;
    }

    if (member.invitedBy == lounge.creatorId) {
      if (lounge.memberCount >= lounge.maxMembers) {
        throw protocol.TalktiveException(message: 'Lounge is full');
      }

      await ChannelService.updateMemberStatus(
        session,
        channelId: lounge.channelId,
        userId: userId,
        status: protocol.ChannelMemberStatus.joined,
      );

      lounge.memberCount += 1;
      await protocol.Lounge.db.updateRow(session, lounge);

      await GamificationService.trackProgress(
        session,
        userId,
        'social_butterfly',
      );
      final resident = await ResidentService.getResident(session, userId);
      if (resident != null) {
        await GamificationService.awardXP(
          session,
          resident,
          25,
          'Joined lounge',
        );
      }

      // Award Lounge XP
      await awardLoungeXP(session, lounge.channelId, 5, 'Member joined');
    } else {
      await ChannelService.updateMemberStatus(
        session,
        channelId: lounge.channelId,
        userId: userId,
        status: protocol.ChannelMemberStatus.applied,
      );
    }
  }

  /// Approves a lounge application.
  static Future<void> approveApplication(
    Session session, {
    required int loungeId,
    required UuidValue creatorId,
    required UuidValue targetId,
    required bool approve,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) {
      throw protocol.TalktiveException(message: 'Lounge not found');
    }
    if (lounge.creatorId != creatorId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can approve applications',
      );
    }

    final pendingMember = await ChannelService.getMember(
      session,
      lounge.channelId,
      targetId,
    );

    if (pendingMember == null ||
        pendingMember.status != protocol.ChannelMemberStatus.applied) {
      throw protocol.TalktiveException(message: 'No pending application found');
    }

    if (!approve) {
      await ChannelService.updateMemberStatus(
        session,
        channelId: lounge.channelId,
        userId: targetId,
        status: protocol.ChannelMemberStatus.declined,
      );
      return;
    }

    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: lounge.channelId,
      userId: targetId,
      status: protocol.ChannelMemberStatus.joined,
    );

    lounge.memberCount += 1;
    await protocol.Lounge.db.updateRow(session, lounge);

    await GamificationService.trackProgress(
      session,
      targetId,
      'social_butterfly',
    );
    final resident = await ResidentService.getResident(session, targetId);
    if (resident != null) {
      await GamificationService.awardXP(
        session,
        resident,
        25,
        'Application approved',
      );
    }

    // Award Lounge XP
    await awardLoungeXP(session, lounge.channelId, 5, 'Member joined');
  }

  /// Leaves or kicks from a lounge.
  static Future<void> leaveLounge(
    Session session, {
    required int loungeId,
    required UuidValue userId,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) return;

    final member = await ChannelService.getMember(
      session,
      lounge.channelId,
      userId,
    );

    if (member == null ||
        member.status != protocol.ChannelMemberStatus.joined) {
      return;
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: lounge.channelId,
      userId: userId,
      status: protocol.ChannelMemberStatus.left,
    );

    lounge.memberCount = (lounge.memberCount - 1).clamp(0, lounge.maxMembers);
    await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Fetches members profiles for a specific status.
  static Future<List<protocol.LoungeMemberWithProfile>> getMembersByStatus(
    Session session,
    int channelId,
    protocol.ChannelMemberStatus status, {
    protocol.Resident? viewer,
  }) async {
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId) & t.status.equals(status),
      orderBy: (t) => t.joinedAt,
    );

    if (members.isEmpty) return [];

    final userIds = members.map((m) => m.userInfoId).toList();
    final residents = await ResidentService.getResidents(session, userIds);
    final residentMap = {for (final r in residents) r.userInfoId.toString(): r};

    return members
        .map((member) {
          final resident = residentMap[member.userInfoId.toString()];
          if (resident == null) return null;
          return protocol.LoungeMemberWithProfile(
            resident: ResidentService.gateResident(resident, viewer: viewer),
            status: member.status,
            role: member.role,
            joinedAt: member.joinedAt,
          );
        })
        .whereType<protocol.LoungeMemberWithProfile>()
        .toList();
  }

  /// Updates a user's mute status for a specific lounge.
  static Future<void> toggleMute(
    Session session,
    int loungeId,
    UuidValue userId,
    bool isMuted,
  ) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) {
      throw protocol.TalktiveException(message: 'Lounge not found');
    }

    final member = await ChannelService.getMember(
      session,
      lounge.channelId,
      userId,
    );

    if (member == null ||
        member.status != protocol.ChannelMemberStatus.joined) {
      throw protocol.TalktiveException(message: 'Not a member');
    }

    member.isMuted = isMuted;
    await protocol.ChannelMember.db.updateRow(session, member);
  }

  /// Updates lounge metadata.
  static Future<protocol.Lounge> updateLounge(
    Session session,
    protocol.Lounge lounge, {
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
    if (name != null && name.trim().isNotEmpty) lounge.name = name;
    if (description != null) lounge.description = description;
    if (emoji != null) lounge.emoji = emoji;
    if (isPublic != null) lounge.isPublic = isPublic;
    if (interests != null) lounge.interests = interests;
    if (languages != null) lounge.languages = languages;
    if (country != null) lounge.country = country;
    if (rules != null) lounge.rules = rules;

    return await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Deletes a lounge and all associated data, including messages and media files.
  static Future<void> deleteLounge(
    Session session,
    protocol.Lounge lounge,
  ) async {
    final channelId = lounge.channelId;

    // 1. Delete all messages and their media files
    // Use a batch fetch approach for media cleanup
    const int batchSize = 100;
    bool hasMore = true;
    while (hasMore) {
      final messages = await protocol.Message.db.find(
        session,
        where: (t) => t.channelId.equals(channelId),
        limit: batchSize,
      );

      if (messages.isEmpty) {
        hasMore = false;
        break;
      }

      for (final message in messages) {
        await AdminService.deleteMessage(session, message);
      }

      if (messages.length < batchSize) {
        hasMore = false;
      }
    }

    // 2. Delete members
    await protocol.ChannelMember.db.deleteWhere(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    // 3. Delete lounge
    await protocol.Lounge.db.deleteRow(session, lounge);

    // 4. Delete channel
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel != null) await protocol.Channel.db.deleteRow(session, channel);
  }

  /// Kicks a member from a lounge.
  static Future<void> kickMember(
    Session session, {
    required int loungeId,
    required UuidValue creatorId,
    required UuidValue targetId,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) {
      throw protocol.TalktiveException(message: 'Lounge not found');
    }
    if (lounge.creatorId != creatorId) {
      throw protocol.TalktiveException(
        message: 'Only the creator can kick members',
      );
    }

    await leaveLounge(session, loungeId: loungeId, userId: targetId);
  }

  /// Awards XP to a lounge and handles leveling up.
  static Future<void> awardLoungeXP(
    Session session,
    int channelId,
    int amount,
    String reason,
  ) async {
    final lounge = await protocol.Lounge.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (lounge == null) return;

    lounge.xp += amount;

    // 3. Milestone Check: Award XP to creator for member growth (every 10 members)
    if (reason == 'Member joined' && lounge.memberCount % 10 == 0) {
      TaskUtils.runBackground(session, (backgroundSession) async {
        try {
          final creator = await ResidentService.getResident(
            backgroundSession,
            lounge.creatorId,
          );
          if (creator != null) {
            // Milestone reward: 25 XP per 10 members
            await GamificationService.awardXP(
              backgroundSession,
              creator,
              25,
              'Milestone: ${lounge.memberCount} members in "${lounge.name}"! 🚀',
            );

            // Notify creator
            await NotificationService.sendNotification(
              backgroundSession,
              lounge.creatorId,
              'lounge_milestone',
              '🎉 Lounge Milestone!',
              'Your lounge "${lounge.name}" reached ${lounge.memberCount} members! You earned 25 XP.',
              data: {
                'loungeId': lounge.id.toString(),
                'route': '/lounges/profile/${lounge.id}',
              },
            );
          }
        } catch (e) {
          backgroundSession.log(
            'Failed to reward lounge creator for milestone: $e',
          );
        }
      });
    }

    // 4. Level Check: Did the lounge level up?
    // We use a cumulative XP system: XP required for level N = (N-1) * 100
    final totalCumulativeXp = lounge.xp;
    final nextLevel = (totalCumulativeXp / 100).floor() + 1;

    if (nextLevel > lounge.level) {
      lounge.level = nextLevel;

      // Increase capacity on level up: base 50 + (level-1)*20
      lounge.maxMembers = 50 + (lounge.level - 1) * 20;

      session.log(
        'Lounge "${lounge.name}" leveled up to ${lounge.level}! Capacity is now ${lounge.maxMembers}.',
      );

      // Notify creator and award XP in background
      TaskUtils.runBackground(session, (backgroundSession) async {
        try {
          // 1. Award XP to creator for lounge management success
          final creator = await ResidentService.getResident(
            backgroundSession,
            lounge.creatorId,
          );
          if (creator != null) {
            await GamificationService.awardXP(
              backgroundSession,
              creator,
              50, // Reward creator with 50 XP for leveling up their lounge
              'Lounge "${lounge.name}" leveled up to ${lounge.level}!',
            );
          }

          // 2. Send real-time notification
          await NotificationService.sendNotification(
            backgroundSession,
            lounge.creatorId,
            'lounge_levelup',
            '🏠 Lounge Level Up!',
            'Your lounge "${lounge.name}" is now Level ${lounge.level}! Capacity increased to ${lounge.maxMembers}.',
            data: {
              'loungeId': lounge.id.toString(),
              'route': '/lounges/profile/${lounge.id}',
            },
          );
        } catch (e) {
          backgroundSession.log(
            'Failed to reward or notify lounge creator for level up: $e',
          );
        }
      });
    }

    await protocol.Lounge.db.updateRow(session, lounge);
  }
}
