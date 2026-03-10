import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart' as protocol;
import '../services/achievement_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import 'message_endpoint.dart';

class PrivateChatEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId, {
    String? initialMessage,
  }) async {
    InputValidationService.validateUuid(otherUserId).throwIfInvalid();
    final currentUserId = await getUserId(session);
    final otherUserUuid = UuidValue.fromString(otherUserId);

    // Ensure we don't create a chat with ourselves
    if (currentUserId == otherUserUuid) {
      throw protocol.TalktiveException(
        message: 'Cannot create private chat with yourself.',
        code: 'SELF_CHAT_NOT_ALLOWED',
      );
    }

    // Check if both users exist
    final currentResident = await getAuthenticatedResident(session);
    final otherResident = await getResidentProfile(session, otherUserUuid);

    // Safety: Check floor restrictions
    if (!ApartmentService.canInvite(
      sender: currentResident,
      receiver: otherResident,
    )) {
      throw protocol.TalktiveException(
        message: ApartmentService.cannotInviteReason(
          sender: currentResident,
          receiver: otherResident,
        ),
        code: 'INVITE_RESTRICTED',
      );
    }

    // Safety: Check blocking (both ways)
    if (await ResidentService.isBlocked(session, blockerId: currentUserId, blockedId: otherUserUuid)) {
      throw protocol.TalktiveException(
        message: 'You have blocked this user.',
        code: 'USER_BLOCKED',
      );
    }

    if (await ResidentService.isBlocked(session, blockerId: otherUserUuid, blockedId: currentUserId)) {
      throw protocol.TalktiveException(
        message: 'This user has blocked you.',
        code: 'BLOCKED_BY_USER',
      );
    }


    // Order participants consistently (smaller UUID first) to avoid duplicates
    final participant1 = currentUserId.uuid.compareTo(otherUserUuid.uuid) < 0
        ? currentUserId
        : otherUserUuid;
    final participant2 = currentUserId.uuid.compareTo(otherUserUuid.uuid) < 0
        ? otherUserUuid
        : currentUserId;

    // Check if private chat already exists
    var privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) =>
          t.participant1Id.equals(participant1) &
          t.participant2Id.equals(participant2),
    );

    if (privateChat != null) {
      // Handle re-inviting
      var currentMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(privateChat!.channelId) & t.userInfoId.equals(currentUserId),
      );
      var otherMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(privateChat!.channelId) & t.userInfoId.equals(otherUserUuid),
      );

      if (currentMember != null && currentMember.status == protocol.ChannelMemberStatus.left) {
        currentMember.status = protocol.ChannelMemberStatus.joined;
        await protocol.ChannelMember.db.updateRow(session, currentMember);
      }

      if (otherMember != null && (otherMember.status == protocol.ChannelMemberStatus.left || otherMember.status == protocol.ChannelMemberStatus.declined)) {
        otherMember.status = protocol.ChannelMemberStatus.invited;
        otherMember.invitedBy = currentUserId;
        await protocol.ChannelMember.db.updateRow(session, otherMember);
      }
    } else {
      // Create a new channel for this private chat
      final channel = protocol.Channel(
        name: 'Private Chat',
        type: protocol.ChannelType.private,
        createdAt: DateTime.now(),
      );

      final savedChannel = await protocol.Channel.db.insertRow(session, channel);

      // Create the private chat record
      privateChat = protocol.PrivateChat(
        channelId: savedChannel.id!,
        participant1Id: participant1,
        participant2Id: participant2,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      privateChat = await protocol.PrivateChat.db.insertRow(
        session,
        privateChat,
      );

      // Add both users as channel members
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: savedChannel.id!,
          userInfoId: currentUserId,
          status: protocol.ChannelMemberStatus.joined,
          joinedAt: DateTime.now(),
        ),
      );

      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: savedChannel.id!,
          userInfoId: otherUserUuid,
          status: protocol.ChannelMemberStatus.invited,
          joinedAt: DateTime.now(),
        ),
      );

      // Track achievement for starting a private chat
      await AchievementService.trackProgress(
        session,
        currentUserId,
        'private_chat',
      );
    }
    
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      try {
        final messageEndpoint = MessageEndpoint();
        await messageEndpoint.sendMessage(session, privateChat.channelId, content: initialMessage);
      } catch (e) {
        session.log('Warning: Failed to send initial message: $e', level: LogLevel.warning);
      }
    }

    return privateChat;
  }

  /// Lists all private chats for the current user.
  Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
  ) async {
    final currentUserId = await getUserId(session);

    // Find all private chats where user is participant1 or participant2
    final chats = await protocol.PrivateChat.db.find(
      session,
      where: (t) =>
          t.participant1Id.equals(currentUserId) |
          t.participant2Id.equals(currentUserId),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    final result = <protocol.PrivateChatWithProfile>[];

    for (final chat in chats) {
      final otherUserId = chat.participant1Id.uuid == currentUserId.uuid
          ? chat.participant2Id
          : chat.participant1Id;

      // Get channel members to check statuses
      final currentMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(chat.channelId) &
            t.userInfoId.equals(currentUserId),
      );

      final otherMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(chat.channelId) &
            t.userInfoId.equals(otherUserId),
      );

      // Skip declined or left chats
      if (currentMember != null &&
          (currentMember.status == protocol.ChannelMemberStatus.left ||
              currentMember.status == protocol.ChannelMemberStatus.declined)) {
        continue;
      }

      final otherResident = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(otherUserId),
      );

      if (otherResident != null) {
        final userInfo = await UserInfo.db.findFirstRow(
          session,
          where: (t) => t.userIdentifier.equals(otherUserId.toString()),
        );

        result.add(
          protocol.PrivateChatWithProfile(
            chat: chat,
            otherResident: otherResident,
            otherUserName: otherResident.userName ?? userInfo?.userName,
            otherUserAvatar: otherResident.avatar ?? userInfo?.imageUrl,
            otherUserMood: otherResident.mood,
            currentMemberStatus: currentMember?.status,
            otherMemberStatus: otherMember?.status,
          ),
        );
      }
    }

    return result;
  }

  /// Gets details about a private chat including the other participant's info.
  Future<protocol.PrivateChatWithProfile> getPrivateChatDetails(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);

    // Get the private chat by channel id (used for deep links)
    final privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (privateChat == null) {
      throw protocol.TalktiveException(
        message: 'Private chat not found.',
        code: 'CHAT_NOT_FOUND',
      );
    }

    // Verify user is a participant
    if (privateChat.participant1Id != currentUserId &&
        privateChat.participant2Id != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Access denied: Not a participant in this chat.',
        code: 'ACCESS_DENIED',
      );
    }

    // Get the other participant's ID
    final otherUserId = privateChat.participant1Id == currentUserId
        ? privateChat.participant2Id
        : privateChat.participant1Id;

    // Get the other participant's resident info
    final otherResident = await getResidentProfile(session, otherUserId);


    // Include the user info fallback if the resident data lacks name/avatar
    final userInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(otherUserId.toString()),
    );

    // Get channel members to check statuses
    final currentMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(privateChat.channelId) &
          t.userInfoId.equals(currentUserId),
    );

    final otherMember = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(privateChat.channelId) &
          t.userInfoId.equals(otherUserId),
    );

    return protocol.PrivateChatWithProfile(
      chat: privateChat,
      otherResident: otherResident,
      otherUserName: otherResident.userName ?? userInfo?.userName,
      otherUserAvatar: otherResident.avatar ?? userInfo?.imageUrl,
      otherUserMood: otherResident.mood,
      currentMemberStatus: currentMember?.status,
      otherMemberStatus: otherMember?.status,
    );
  }

  /// Updates the lastMessageAt timestamp for a private chat.
  Future<void> updateLastMessageTime(
    Session session,
    int privateChatId,
  ) async {
    InputValidationService.validateId(privateChatId, 'Private Chat ID').throwIfInvalid();
    final privateChat = await protocol.PrivateChat.db.findById(
      session,
      privateChatId,
    );

    if (privateChat == null) {
      throw protocol.TalktiveException(
        message: 'Private chat not found',
        code: 'CHAT_NOT_FOUND',
      );
    }

    privateChat.lastMessageAt = DateTime.now();
    await protocol.PrivateChat.db.updateRow(session, privateChat);
  }

  /// Accepts or declines a private chat invitation
  Future<void> respondToChatInvite(
    Session session,
    int channelId,
    bool accept,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (member == null) {
      throw protocol.TalktiveException(
        message: 'You are not a member of this chat.',
        code: 'NOT_A_MEMBER',
      );
    }


    if (member.status != protocol.ChannelMemberStatus.invited) {
      // Ignore if not invited (already joined, left, declined)
      return;
    }

    member.status = accept
        ? protocol.ChannelMemberStatus.joined
        : protocol.ChannelMemberStatus.declined;
    await protocol.ChannelMember.db.updateRow(session, member);

    if (!accept) {
      try {
        await MessageEndpoint().sendMessage(session, channelId, content: "I'm not available to chat right now.");
      } catch (e) {
        session.log('Warning: Failed to send decline message: $e', level: LogLevel.warning);
      }
    }
  }

  /// Leaves a private chat.
  Future<void> leaveChat(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (member == null) {
      throw protocol.TalktiveException(
        message: 'You are not a member of this chat.',
        code: 'NOT_A_MEMBER',
      );
    }

    if (member.status != protocol.ChannelMemberStatus.joined) {
      return;
    }

    // Send a message before leaving
    try {
      await MessageEndpoint().sendMessage(session, channelId, content: "I've left the chat.");
    } catch (e) {
      session.log('Warning: Failed to send leave message: $e', level: LogLevel.warning);
    }

    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);
  }
}
