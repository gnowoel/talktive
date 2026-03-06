import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart' as protocol;
import '../services/achievement_service.dart';
import '../services/apartment_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class PrivateChatEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId,
  ) async {
    final currentUserId = await getUserId(session);
    final otherUserUuid = UuidValue.fromString(otherUserId);

    // Ensure we don't create a chat with ourselves
    if (currentUserId == otherUserUuid) {
      throw Exception('Cannot create private chat with yourself');
    }

    // Check if both users exist
    final currentResident = await getResidentProfile(session, currentUserId);

    final otherResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(otherUserUuid),
    );

    if (otherResident == null) {
      throw Exception('User not found');
    }

    // Safety: Check floor restrictions
    if (!ApartmentService.canInvite(
      sender: currentResident,
      receiver: otherResident,
    )) {
      throw Exception(
        'Residents can only invite people living on the same floor or below.',
      );
    }

    // Safety: Check blocking
    final blocked = await protocol.Block.db.findFirstRow(
      session,
      where: (t) =>
          (t.blockerId.equals(currentUserId) &
              t.blockedId.equals(otherUserUuid)) |
          (t.blockerId.equals(otherUserUuid) &
              t.blockedId.equals(currentUserId)),
    );

    if (blocked != null) {
      throw Exception('Cannot create chat with this user.');
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
      return privateChat;
    }

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

    final savedPrivateChat = await protocol.PrivateChat.db.insertRow(
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

    return savedPrivateChat;
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
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the private chat by channel id (used for deep links)
    final privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (privateChat == null) {
      throw Exception('Private chat not found');
    }

    // Verify user is a participant
    if (privateChat.participant1Id != currentUserId &&
        privateChat.participant2Id != currentUserId) {
      throw Exception('Not authorized to access this chat');
    }

    // Get the other participant's ID
    final otherUserId = privateChat.participant1Id == currentUserId
        ? privateChat.participant2Id
        : privateChat.participant1Id;

    // Get the other participant's resident info
    final otherResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(otherUserId),
    );

    if (otherResident == null) {
      throw Exception('Other participant not found');
    }

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
    final privateChat = await protocol.PrivateChat.db.findById(
      session,
      privateChatId,
    );

    if (privateChat == null) {
      throw Exception('Private chat not found');
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
    final currentUserId = await getUserId(session);

    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) &
          t.userInfoId.equals(currentUserId),
    );

    if (member == null) {
      throw Exception('Not a member of this chat');
    }

    if (member.status != protocol.ChannelMemberStatus.invited) {
      // Ignore if not invited (already joined, left, declined)
      return;
    }

    member.status = accept
        ? protocol.ChannelMemberStatus.joined
        : protocol.ChannelMemberStatus.declined;
    await protocol.ChannelMember.db.updateRow(session, member);
  }
}
