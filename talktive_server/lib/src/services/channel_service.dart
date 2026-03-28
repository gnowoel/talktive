import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'resident_service.dart';

/// Generic service for managing Channels and ChannelMembers.
/// This consolidates logic used by Private Chats, Lounges, and the Plaza.
class ChannelService {
  /// Fetches a channel by ID.
  static Future<protocol.Channel?> getChannel(
    Session session,
    int channelId,
  ) async {
    return await protocol.Channel.db.findById(session, channelId);
  }

  /// Fetches a membership record.
  static Future<protocol.ChannelMember?> getMember(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    return await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId) & t.userInfoId.equals(userId),
    );
  }

  /// Ensures a user is marked as having read a channel up to now.
  static Future<void> markAsRead(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    final membership = await getMember(session, channelId, userId);
    if (membership != null) {
      final now = DateTime.now();
      membership.lastReadAt = now;
      await protocol.ChannelMember.db.updateRow(session, membership);

      // Broadcast ReadReceipt if user allows
      final resident = await ResidentService.getResident(session, userId);
      if (resident != null && resident.showReadReceipts) {
        await session.messages.postMessage(
          'channel_$channelId',
          protocol.ReadReceiptEvent(
            channelId: channelId,
            userId: userId,
            lastReadAt: now,
          ),
        );
      }
    }
  }

  /// Broadcasts a typing indicator.
  static Future<void> sendTypingIndicator(
    Session session,
    int channelId,
    UuidValue userId,
    String userName,
    bool isTyping,
  ) async {
    await session.messages.postMessage(
      'channel_$channelId',
      protocol.TypingIndicator(
        channelId: channelId,
        senderId: userId,
        userName: userName,
        isTyping: isTyping,
      ),
    );
  }

  /// Updates the persistence of a channel.
  static Future<protocol.Channel> updatePersistence(
    Session session,
    int channelId,
    bool isPersistent,
  ) async {
    final channel = await getChannel(session, channelId);
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }
    channel.isPersistent = isPersistent;
    return await protocol.Channel.db.updateRow(session, channel);
  }

  static Future<void> updateLastMessage(
    Session session,
    int channelId, {
    required protocol.ChannelType channelType,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    bool updateTimestamp = true,
  }) async {
    final now = DateTime.now();

    // Determine the preview text
    String? previewText;
    if (content != null && content.trim().isNotEmpty) {
      previewText = content.trim();
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
        if (updateTimestamp) {
          privateChat.lastMessageAt = now;
        }
        privateChat.lastMessage = previewText;
        await protocol.PrivateChat.db.updateRow(session, privateChat);
      }
    } else if (channelType == protocol.ChannelType.lounge) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        if (updateTimestamp) {
          lounge.lastMessageAt = now;
        }
        lounge.lastMessage = previewText;
        await protocol.Lounge.db.updateRow(session, lounge);
      }
    }
  }

  /// Batch fetches unread message counts for multiple channels.
  static Future<Map<int, int>> batchGetUnreadCounts(
    Session session,
    List<int> channelIds,
    UuidValue userId,
  ) async {
    if (channelIds.isEmpty) return {};

    final result = <int, int>{};
    for (var id in channelIds) {
      result[id] = 0;
    }

    // Joining message and channel_member to filter unread messages
    final sql =
        '''
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
      final queryResults = await session.db.unsafeQuery(sql);
      for (final row in queryResults) {
        if (row.length >= 2) {
          result[row[0] as int] = row[1] as int;
        }
      }
    } catch (e) {
      session.log('Error in batch unread counts: $e', level: LogLevel.error);
    }

    return result;
  }
}
