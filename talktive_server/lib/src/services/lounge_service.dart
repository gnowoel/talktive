import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'gamification_service.dart';
import 'notification_service.dart';
import 'resident_service.dart';
import 'chat_service.dart';
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
  }) async {
    // 1. Create a new channel for this lounge
    final channel = protocol.Channel(
      name: name,
      type: protocol.ChannelType.lounge,
      createdAt: DateTime.now(),
    );

    final savedChannel = await protocol.Channel.db.insertRow(session, channel);

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
      maxMembers: maxMembers,
      interests: interests,
      languages: languages,
      country: country,
    );

    final savedLounge = await protocol.Lounge.db.insertRow(session, lounge);
    
    // 3. Invalidate discovery cache so new lounge appears immediately
    await CacheService.invalidateDiscoveryCache(session);
    await protocol.ChannelMember.db.insertRow(
      session,
      protocol.ChannelMember(
        channelId: savedChannel.id!,
        userInfoId: creatorId,
        status: protocol.ChannelMemberStatus.joined,
        joinedAt: DateTime.now(),
        role: 'admin',
      ),
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

    final unreadCounts = await ChatService.batchGetUnreadCounts(
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

  /// Gets popular lounges (most members).
  static Future<List<protocol.Lounge>> getPopularLounges(
    Session session, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
  }) async {
    return await protocol.Lounge.db.find(
      session,
      where: (t) {
        var expr = t.isPublic.equals(true);
        if (country != null) {
          expr &= t.country.equals(country);
        }
        if (interest != null) {
          expr &= Expression(
              'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'');
        }
        if (language != null) {
          expr &= Expression(
              'languages::jsonb ? \'${language.replaceAll("'", "''")}\'');
        }
        return expr;
      },
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Gets personalized lounge recommendations based on resident interests.
  static Future<List<protocol.Lounge>> getRecommendedLounges(
    Session session,
    protocol.Resident resident, {
    String? interest,
    String? language,
    String? country,
    int limit = 10,
    int offset = 0,
  }) async {
    final searchInterests = interest != null ? [interest] : resident.interests;
    final interestArray = searchInterests?.isNotEmpty == true
        ? searchInterests!.map((e) => "'${e.replaceAll("'", "''")}'").join(",")
        : null;

    final lounges = await protocol.Lounge.db.find(
      session,
      where: (t) {
        var expr = t.isPublic.equals(true);
        if (country != null) {
          expr &= t.country.equals(country);
        }
        if (language != null) {
          expr &= Expression(
              'languages::jsonb ? \'${language.replaceAll("'", "''")}\'');
        }
        if (interestArray != null) {
          // If a specific interest was requested, use strict containment.
          // Otherwise, if using resident interests, use 'any of' (?| operator)
          if (interest != null) {
            expr &= Expression(
                'interests::jsonb ? \'${interest.replaceAll("'", "''")}\'');
          } else {
            expr &= Expression('interests::jsonb ?| array[$interestArray]');
          }
        }
        return expr;
      },
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: 100, // Fetch candidates for matching score sorting
    );

    var filtered = lounges;

    filtered.sort((a, b) {
      final aMatch =
          a.interests?.where((i) => (resident.interests ?? []).contains(i)).length ??
          0;
      final bMatch =
          b.interests?.where((i) => (resident.interests ?? []).contains(i)).length ??
          0;
      if (aMatch != bMatch) return bMatch.compareTo(aMatch);
      return b.memberCount.compareTo(a.memberCount);
    });

    return filtered.skip(offset).take(limit).toList();
  }

  /// Applies to join a public lounge.
  static Future<void> applyToLounge(
    Session session, {
    required protocol.Lounge lounge,
    required protocol.Resident resident,
  }) async {
    if (!lounge.isPublic) {
      throw protocol.TalktiveException(message: 'Cannot apply to a private lounge');
    }

    if (lounge.memberCount >= lounge.maxMembers) {
      throw protocol.TalktiveException(message: 'Lounge is full');
    }

    final userId = resident.userInfoId;

    final existingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) & t.userInfoId.equals(userId),
    );

    if (existingMember != null) {
      if (existingMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'Already a member of this lounge');
      } else if (existingMember.status == protocol.ChannelMemberStatus.applied) {
        throw protocol.TalktiveException(message: 'Already applied to this lounge');
      }

      existingMember.status = protocol.ChannelMemberStatus.applied;
      existingMember.joinedAt = DateTime.now();
      await protocol.ChannelMember.db.updateRow(session, existingMember);
    } else {
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: lounge.channelId,
          userInfoId: userId,
          status: protocol.ChannelMemberStatus.applied,
          joinedAt: DateTime.now(),
        ),
      );
    }
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

    if (inviterId == targetId) throw protocol.TalktiveException(message: 'Cannot invite yourself');
    if (lounge.memberCount >= lounge.maxMembers) throw protocol.TalktiveException(message: 'Lounge is full');

    if (await ResidentService.isBlocked(session, blockerId: targetId, blockedId: inviterId)) {
      throw protocol.TalktiveException(message: 'You cannot invite this user.');
    }

    final targetMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) & t.userInfoId.equals(targetId),
    );

    if (targetMember != null) {
      if (targetMember.status == protocol.ChannelMemberStatus.joined) {
        throw protocol.TalktiveException(message: 'User is already a member');
      } else if (targetMember.status == protocol.ChannelMemberStatus.invited) {
        throw protocol.TalktiveException(message: 'User is already invited');
      }

      targetMember.status = protocol.ChannelMemberStatus.invited;
      targetMember.invitedBy = inviterId;
      targetMember.joinedAt = DateTime.now();
      await protocol.ChannelMember.db.updateRow(session, targetMember);
    } else {
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: lounge.channelId,
          userInfoId: targetId,
          status: protocol.ChannelMemberStatus.invited,
          invitedBy: inviterId,
          joinedAt: DateTime.now(),
        ),
      );
    }

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
    if (lounge == null) throw protocol.TalktiveException(message: 'Lounge not found');

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(userId) &
          t.status.equals(protocol.ChannelMemberStatus.invited),
    );

    if (member == null) throw protocol.TalktiveException(message: 'No pending invitation found');

    if (!accept) {
      member.status = protocol.ChannelMemberStatus.declined;
      await protocol.ChannelMember.db.updateRow(session, member);
      return;
    }

    if (member.invitedBy == lounge.creatorId) {
      if (lounge.memberCount >= lounge.maxMembers) throw protocol.TalktiveException(message: 'Lounge is full');
      member.status = protocol.ChannelMemberStatus.joined;
      await protocol.ChannelMember.db.updateRow(session, member);

      lounge.memberCount += 1;
      await protocol.Lounge.db.updateRow(session, lounge);

      await GamificationService.trackProgress(session, userId, 'social_butterfly');
      final resident = await ResidentService.getResident(session, userId);
      if (resident != null) await GamificationService.awardXP(session, resident, 25, 'Joined lounge');
    } else {
      member.status = protocol.ChannelMemberStatus.applied;
      await protocol.ChannelMember.db.updateRow(session, member);
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
    if (lounge == null) throw protocol.TalktiveException(message: 'Lounge not found');
    if (lounge.creatorId != creatorId) throw protocol.TalktiveException(message: 'Only the creator can approve applications');

    final pendingMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(targetId) &
          t.status.equals(protocol.ChannelMemberStatus.applied),
    );

    if (pendingMember == null) throw protocol.TalktiveException(message: 'No pending application found');

    if (!approve) {
      pendingMember.status = protocol.ChannelMemberStatus.declined;
      await protocol.ChannelMember.db.updateRow(session, pendingMember);
      return;
    }

    if (lounge.memberCount >= lounge.maxMembers) throw protocol.TalktiveException(message: 'Lounge is full');

    pendingMember.status = protocol.ChannelMemberStatus.joined;
    await protocol.ChannelMember.db.updateRow(session, pendingMember);

    lounge.memberCount += 1;
    await protocol.Lounge.db.updateRow(session, lounge);

    await GamificationService.trackProgress(session, targetId, 'social_butterfly');
    final resident = await ResidentService.getResident(session, targetId);
    if (resident != null) await GamificationService.awardXP(session, resident, 25, 'Application approved');
  }

  /// Leaves or kicks from a lounge.
  static Future<void> leaveLounge(
    Session session, {
    required int loungeId,
    required UuidValue userId,
  }) async {
    final lounge = await protocol.Lounge.db.findById(session, loungeId);
    if (lounge == null) return;

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(userId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) return;

    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);

    lounge.memberCount = (lounge.memberCount - 1).clamp(0, lounge.maxMembers);
    await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Fetches members profiles for a specific status.
  static Future<List<protocol.LoungeMemberWithProfile>> getMembersByStatus(
    Session session,
    int channelId,
    protocol.ChannelMemberStatus status,
  ) async {
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
            resident: resident,
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
    if (lounge == null) throw protocol.TalktiveException(message: 'Lounge not found');

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(lounge.channelId) &
          t.userInfoId.equals(userId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (member == null) throw protocol.TalktiveException(message: 'Not a member');

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
  }) async {
    if (name != null && name.trim().isNotEmpty) lounge.name = name;
    if (description != null) lounge.description = description;
    if (emoji != null) lounge.emoji = emoji;
    if (isPublic != null) lounge.isPublic = isPublic;
    if (maxMembers != null) lounge.maxMembers = maxMembers;
    if (interests != null) lounge.interests = interests;
    if (languages != null) lounge.languages = languages;
    if (country != null) lounge.country = country;

    return await protocol.Lounge.db.updateRow(session, lounge);
  }

  /// Deletes a lounge and all associated data, including messages and media files.
  static Future<void> deleteLounge(Session session, protocol.Lounge lounge) async {
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
    await session.db.unsafeQuery('DELETE FROM "channel_member" WHERE "channelId" = $channelId');

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
    if (lounge == null) throw protocol.TalktiveException(message: 'Lounge not found');
    if (lounge.creatorId != creatorId) throw protocol.TalktiveException(message: 'Only the creator can kick members');

    await leaveLounge(session, loungeId: loungeId, userId: targetId);
  }
}
