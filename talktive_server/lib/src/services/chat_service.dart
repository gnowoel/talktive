import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'apartment_service.dart';

class ChatService {
  /// Initiates a private chat between two residents.
  /// Checks floor rules and block status.
  static Future<protocol.Channel?> createPrivateChat(
    Session session, {
    required UuidValue senderId,
    required UuidValue receiverId,
  }) async {
    // 1. Fetch Residents details
    final sender = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderId),
    );
    final receiver = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(receiverId),
    );

    if (sender == null || receiver == null) {
      throw Exception('Resident not found');
    }

    // 2. Check Apartment Rules (Floor logic)
    if (!ApartmentService.canInvite(sender: sender, receiver: receiver)) {
      throw Exception('You cannot invite this user (Floor rules).');
    }

    // 3. Check Block Status
    final isBlocked = await protocol.Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(receiverId) & t.blockedId.equals(senderId),
    );
    if (isBlocked != null) {
      throw Exception('You are blocked by this user.');
    }

    // Check if sender blocked receiver? (Usually prevents interaction too)
    final hasBlocked = await protocol.Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(senderId) & t.blockedId.equals(receiverId),
    );
    if (hasBlocked != null) {
      throw Exception('You have blocked this user.');
    }

    // 4. Create Channel
    // Simplified: Create new channel
    final channel = protocol.Channel(
      type: protocol.ChannelType.private,
      createdAt: DateTime.now(),
      name: null, // Private 1on1 often has no name
    );
    final validChannel = await protocol.Channel.db.insertRow(session, channel);

    // 5. Add Members
    await protocol.ChannelMember.db.insertRow(
      session,
      protocol.ChannelMember(
        channelId: validChannel.id!,
        userInfoId: senderId,
        joinedAt: DateTime.now(),
        status: protocol.ChannelMemberStatus.joined, // Sender joins immediately
        role: 'owner',
      ),
    );

    await protocol.ChannelMember.db.insertRow(
      session,
      protocol.ChannelMember(
        channelId: validChannel.id!,
        userInfoId: receiverId,
        joinedAt: DateTime.now(),
        status: protocol.ChannelMemberStatus.invited, // Receiver is invited
        role: 'member',
      ),
    );

    return validChannel;
  }

  static Future<void> blockUser(
    Session session,
    UuidValue blockerId,
    UuidValue blockedId,
  ) async {
    await protocol.Block.db.insertRow(
      session,
      protocol.Block(
        blockerId: blockerId,
        blockedId: blockedId,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<int> getUnreadCount(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    final counts = await batchGetUnreadCounts(session, [channelId], userId);
    return counts[channelId] ?? 0;
  }

  static Future<Map<int, int>> batchGetUnreadCounts(
    Session session,
    List<int> channelIds,
    UuidValue userId,
  ) async {
    if (channelIds.isEmpty) return {};

    // 1. Get the membership records to find lastReadAt
    final memberships = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.inSet(channelIds.toSet()) & t.userInfoId.equals(userId),
    );

    if (memberships.isEmpty) return {};

    final result = <int, int>{};
    
    // We use a raw query here to avoid N+1 count calls.
    // Joining message and channel_member lets us filter messages per channel 
    // against EACH channel's lastReadAt in a single database round-trip.
    final sql = '''
      SELECT m."channelId", COUNT(m.id)
      FROM "message" m
      INNER JOIN "channel_member" cm ON m."channelId" = cm."channelId"
      WHERE m."channelId" IN (${channelIds.join(',')})
      AND cm."userInfoId" = '$userId'
      AND (cm."lastReadAt" IS NULL OR m."createdAt" > cm."lastReadAt")
      AND m."senderId" != '$userId'
      GROUP BY m."channelId"
    ''';

    try {
      final unreadCounts = await session.db.unsafeQuery(sql);
      for (final row in unreadCounts) {
        if (row.length >= 2) {
          result[row[0] as int] = row[1] as int;
        }
      }
    } catch (e) {
      session.log('Error executing batch unread counts query: $e', level: LogLevel.error);
      // Fallback for safety (though not efficient, prevents total failure)
      for (final channelId in channelIds) {
        result[channelId] = 0;
      }
    }

    return result;
  }

  /// Updates the denormalized 'last message' fields for a channel.
  static Future<void> updateLastMessage(
    Session session,
    int channelId, {
    required protocol.ChannelType channelType,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final now = DateTime.now();

    // Determine the preview text
    String? previewText;
    if (content != null && content.trim().isNotEmpty) {
      previewText = content.trim();
      // Truncate if too long (good for DB index performance)
      if (previewText.length > 100) {
        previewText = '${previewText.substring(0, 97)}...';
      }
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      previewText = '📷 Photo';
    } else if (mediaType == 'voice') {
      previewText = '🎙️ Voice message';
    } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
      previewText = '🎥 Video';
    }

    if (channelType == protocol.ChannelType.private) {
      final privateChat = await protocol.PrivateChat.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (privateChat != null) {
        privateChat.lastMessageAt = now;
        privateChat.lastMessage = previewText;
        await protocol.PrivateChat.db.updateRow(session, privateChat);
      }
    } else if (channelType == protocol.ChannelType.lounge) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        lounge.lastMessageAt = now;
        lounge.lastMessage = previewText;
        await protocol.Lounge.db.updateRow(session, lounge);
      }
    }
  }
}
