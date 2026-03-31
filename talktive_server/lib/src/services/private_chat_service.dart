import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:collection/collection.dart';
import 'apartment_service.dart';
import 'resident_service.dart';
import 'gamification_service.dart';
import 'notification_service.dart';
import 'messaging_service.dart';
import 'channel_service.dart';

/// Specialized service for managing Private Chats between residents.
class PrivateChatService {
  /// Creates or retrieves a private chat between two users.
  /// Handles validation, re-inviting, and optional initial message.
  static Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session, {
    required protocol.Resident sender,
    required UuidValue otherUserId,
    String? initialMessage,
  }) async {
    final currentUserId = sender.userInfoId;

    if (currentUserId == otherUserId) {
      throw protocol.TalktiveException(
        message: 'Cannot create private chat with yourself.',
        code: 'SELF_CHAT_NOT_ALLOWED',
      );
    }

    final otherResident = await ResidentService.getResident(
      session,
      otherUserId,
    );
    if (otherResident == null) {
      throw protocol.TalktiveException(
        message: 'Resident not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }

    if (!ApartmentService.canInvite(sender: sender, receiver: otherResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.cannotInviteReason(
          sender: sender,
          receiver: otherResident,
        ),
        code: 'INVITE_RESTRICTED',
      );
    }

    if (await ResidentService.isBlocked(
      session,
      blockerId: currentUserId,
      blockedId: otherUserId,
    )) {
      throw protocol.TalktiveException(
        message: 'You have blocked this resident.',
        code: 'USER_BLOCKED',
      );
    }

    if (await ResidentService.isBlocked(
      session,
      blockerId: otherUserId,
      blockedId: currentUserId,
    )) {
      throw protocol.TalktiveException(
        message: 'This resident has restricted their messages.',
        code: 'BLOCKED_BY_USER',
      );
    }

    // Order participants consistently
    final participant1 = currentUserId.uuid.compareTo(otherUserId.uuid) < 0
        ? currentUserId
        : otherUserId;
    final participant2 = currentUserId.uuid.compareTo(otherUserId.uuid) < 0
        ? otherUserId
        : currentUserId;

    var privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) =>
          t.participant1Id.equals(participant1) &
          t.participant2Id.equals(participant2),
    );

    bool isCurrentlyInvited = false;
    bool wasJustInvited = false;

    if (privateChat != null) {
      final members = await protocol.ChannelMember.db.find(
        session,
        where: (t) => t.channelId.equals(privateChat!.channelId),
      );
      final currentMember = members.firstWhereOrNull(
        (m) => m.userInfoId == currentUserId,
      );
      final otherMember = members.firstWhereOrNull(
        (m) => m.userInfoId == otherUserId,
      );

      if (currentMember != null &&
          (currentMember.status == protocol.ChannelMemberStatus.left ||
              currentMember.status == protocol.ChannelMemberStatus.declined)) {
        await ChannelService.updateMemberStatus(
          session,
          channelId: privateChat.channelId,
          userId: currentUserId,
          status: protocol.ChannelMemberStatus.joined,
        );
      }

      if (otherMember != null) {
        if (otherMember.status == protocol.ChannelMemberStatus.invited) {
          isCurrentlyInvited = true;
        } else if (otherMember.status == protocol.ChannelMemberStatus.left ||
            otherMember.status == protocol.ChannelMemberStatus.declined) {
          await ChannelService.updateMemberStatus(
            session,
            channelId: privateChat.channelId,
            userId: otherUserId,
            status: protocol.ChannelMemberStatus.invited,
            invitedBy: currentUserId,
          );
          wasJustInvited = true;
        }
      }
    } else {
      // Create new private chat
      final channel = await protocol.Channel.db.insertRow(
        session,
        protocol.Channel(
          name: 'Private Chat',
          type: protocol.ChannelType.private,
          createdAt: DateTime.now(),
        ),
      );

      privateChat = await protocol.PrivateChat.db.insertRow(
        session,
        protocol.PrivateChat(
          channelId: channel.id!,
          participant1Id: participant1,
          participant2Id: participant2,
          createdAt: DateTime.now(),
          lastMessageAt: DateTime.now(),
        ),
      );

      await ChannelService.updateMemberStatus(
        session,
        channelId: channel.id!,
        userId: currentUserId,
        status: protocol.ChannelMemberStatus.joined,
        role: 'owner',
      );

      await ChannelService.updateMemberStatus(
        session,
        channelId: channel.id!,
        userId: otherUserId,
        status: protocol.ChannelMemberStatus.invited,
        invitedBy: currentUserId,
      );

      await GamificationService.trackProgress(
        session,
        currentUserId,
        'private_chat',
      );
      wasJustInvited = true;
    }

    if (wasJustInvited) {
      try {
        await NotificationService.sendChatInviteNotification(
          session,
          otherUserId,
          sender.userName ?? 'Someone',
          privateChat.channelId,
        );
      } catch (e) {
        session.log(
          'Failed to send invite notification: $e',
          level: LogLevel.error,
        );
      }
    }

    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      await _handleInitialMessage(
        session,
        sender,
        privateChat.channelId,
        initialMessage,
        isCurrentlyInvited && !wasJustInvited,
      );
    }

    return privateChat;
  }

  static Future<void> _handleInitialMessage(
    Session session,
    protocol.Resident sender,
    int channelId,
    String content,
    bool isReKnock,
  ) async {
    try {
      final channel = await ChannelService.getChannel(session, channelId);
      if (channel == null) return;

      if (isReKnock) {
        final lastMessage = await protocol.Message.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(channelId) &
              t.senderId.equals(sender.userInfoId),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        );

        if (lastMessage != null) {
          lastMessage.content = content;
          await protocol.Message.db.updateRow(session, lastMessage);
          await session.messages.postMessage('channel_$channelId', lastMessage);

          // Update denormalized preview if needed
          await ChannelService.updateLastMessage(
            session,
            channelId,
            channelType: channel.type,
            content: content,
          );
          return;
        }
      }

      // Consolidate messaging logic
      await MessagingService.sendMessage(
        session,
        sender: sender,
        channel: channel,
        content: content,
      );
    } catch (e) {
      session.log('Initial message error: $e', level: LogLevel.warning);
    }
  }

  /// Lists all private chats for a user.
  static Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
    UuidValue userId,
  ) async {
    final currentResident = await ResidentService.getResident(session, userId);
    final canSeeReadReceipts =
        currentResident != null &&
        ResidentService.canSeeOthersReadReceipts(currentResident);

    final chats = await protocol.PrivateChat.db.find(
      session,
      where: (t) =>
          t.participant1Id.equals(userId) | t.participant2Id.equals(userId),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    if (chats.isEmpty) return [];

    final channelIds = chats.map((c) => c.channelId).toList();
    final results = await Future.wait([
      protocol.ChannelMember.db.find(
        session,
        where: (t) => t.channelId.inSet(channelIds.toSet()),
      ),
      ChannelService.batchGetUnreadCounts(session, channelIds, userId),
      protocol.Channel.db.find(
        session,
        where: (t) => t.id.inSet(channelIds.toSet()),
      ),
    ]);

    final allMembers = results[0] as List<protocol.ChannelMember>;
    final unreadCounts = results[1] as Map<int, int>;
    final channels = results[2] as List<protocol.Channel>;

    final channelMap = {for (var c in channels) c.id: c};
    final items = <protocol.PrivateChatWithProfile>[];

    for (final chat in chats) {
      final members = allMembers
          .where((m) => m.channelId == chat.channelId)
          .toList();
      final currentMember = members.firstWhereOrNull(
        (m) => m.userInfoId == userId,
      );
      if (currentMember == null ||
          currentMember.status == protocol.ChannelMemberStatus.left ||
          currentMember.status == protocol.ChannelMemberStatus.declined) {
        continue;
      }

      final otherId = chat.participant1Id == userId
          ? chat.participant2Id
          : chat.participant1Id;
      final otherMember = members.firstWhereOrNull(
        (m) => m.userInfoId == otherId,
      );
      final otherResident = await ResidentService.getResident(session, otherId);

      if (otherResident != null) {
        items.add(
          protocol.PrivateChatWithProfile(
            chat: chat,
            otherResident: ResidentService.gateResident(
              otherResident,
              viewer: currentResident,
            ),
            otherUserName: otherResident.userName,
            otherUserAvatar:
                otherResident.customAvatarUrl ?? otherResident.avatar,
            otherUserMood: otherResident.mood,
            currentMemberStatus: currentMember.status,
            otherMemberStatus: otherMember?.status,
            otherUserLastReadAt: canSeeReadReceipts
                ? otherMember?.lastReadAt
                : null,
            unreadCount: unreadCounts[chat.channelId] ?? 0,
            channel: channelMap[chat.channelId],
          ),
        );
      }
    }
    return items;
  }

  /// Gets full details for a private chat.
  static Future<protocol.PrivateChatWithProfile?> getPrivateChatDetails(
    Session session,
    int channelId,
    UuidValue currentUserId,
  ) async {
    final currentResident = await ResidentService.getResident(
      session,
      currentUserId,
    );
    final canSeeReadReceipts =
        currentResident != null &&
        ResidentService.canSeeOthersReadReceipts(currentResident);

    final chat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
    if (chat == null) return null;

    if (chat.participant1Id != currentUserId &&
        chat.participant2Id != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Access denied.',
        code: 'ACCESS_DENIED',
      );
    }

    final otherId = chat.participant1Id == currentUserId
        ? chat.participant2Id
        : chat.participant1Id;
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
    final currentMember = members.firstWhereOrNull(
      (m) => m.userInfoId == currentUserId,
    );
    final otherMember = members.firstWhereOrNull(
      (m) => m.userInfoId == otherId,
    );
    final resident = await ResidentService.getResident(session, otherId);

    if (resident == null) return null;

    return protocol.PrivateChatWithProfile(
      chat: chat,
      otherResident: ResidentService.gateResident(
        resident,
        viewer: currentResident,
      ),
      otherUserName: resident.userName,
      otherUserAvatar: resident.customAvatarUrl ?? resident.avatar,
      otherUserMood: resident.mood,
      currentMemberStatus: currentMember?.status,
      otherMemberStatus: otherMember?.status,
      otherUserLastReadAt: canSeeReadReceipts ? otherMember?.lastReadAt : null,
      unreadCount:
          (await ChannelService.batchGetUnreadCounts(session, [
            channelId,
          ], currentUserId))[channelId] ??
          0,
      channel: await ChannelService.getChannel(session, channelId),
    );
  }

  /// Responds to a private chat invitation.
  static Future<void> respondToChatInvite(
    Session session,
    int channelId,
    UuidValue userId,
    bool accept,
  ) async {
    final member = await ChannelService.getMember(session, channelId, userId);
    if (member == null ||
        member.status != protocol.ChannelMemberStatus.invited) {
      return;
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: channelId,
      userId: userId,
      status: accept
          ? protocol.ChannelMemberStatus.joined
          : protocol.ChannelMemberStatus.declined,
    );
  }

  /// Leaves a private chat.
  static Future<void> leaveChat(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    await ChannelService.updateMemberStatus(
      session,
      channelId: channelId,
      userId: userId,
      status: protocol.ChannelMemberStatus.left,
    );
  }
}
