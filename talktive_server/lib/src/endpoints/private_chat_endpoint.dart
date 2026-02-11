import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

class PrivateChatEndpoint extends Endpoint {
  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);
    final otherUserUuid = UuidValue.fromString(otherUserId);

    // Ensure we don't create a chat with ourselves
    if (currentUserId == otherUserUuid) {
      throw Exception('Cannot create private chat with yourself');
    }

    // Check if both users exist
    final currentResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(currentUserId),
    );

    final otherResident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(otherUserUuid),
    );

    if (currentResident == null || otherResident == null) {
      throw Exception('User not found');
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
      lastMessageAt: null,
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
        status: protocol.ChannelMemberStatus.joined,
        joinedAt: DateTime.now(),
      ),
    );

    return savedPrivateChat;
  }

  /// Lists all private chats for the current user.
  Future<List<protocol.PrivateChat>> listPrivateChats(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Find all private chats where user is participant1 or participant2
    final chats = await protocol.PrivateChat.db.find(
      session,
      where: (t) =>
          t.participant1Id.equals(currentUserId) |
          t.participant2Id.equals(currentUserId),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    return chats;
  }

  /// Gets details about a private chat including the other participant's info.
  Future<Map<String, dynamic>> getPrivateChatDetails(
    Session session,
    int privateChatId,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    // Get the private chat
    final privateChat = await protocol.PrivateChat.db.findById(
      session,
      privateChatId,
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

    // Get unread message count (messages in channel after user's last read)
    // For now, we'll return 0 - implement read receipts later
    final unreadCount = 0;

    return {
      'privateChat': privateChat,
      'otherResident': otherResident,
      'unreadCount': unreadCount,
    };
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
}
