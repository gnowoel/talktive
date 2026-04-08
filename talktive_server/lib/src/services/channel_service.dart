import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:collection/collection.dart';

/// Generic service for managing Channels and ChannelMembers.
/// This consolidates logic used by Private Chats, Lounges, and the Plaza.
class ChannelService {
  /// Validates that a user is a member of a channel.
  /// Throws TalktiveException if not authorized.
  static Future<protocol.ChannelMember> validateMember(
    Session session,
    int channelId,
    UuidValue userId, {
    bool allowInvited = false,
  }) async {
    final membership = await getMember(session, channelId, userId);

    if (membership == null) {
      throw protocol.TalktiveException(
        message: 'Access denied: Not a member of this channel.',
        code: 'ACCESS_DENIED',
      );
    }

    final allowedStatuses = {
      protocol.ChannelMemberStatus.joined,
      if (allowInvited) protocol.ChannelMemberStatus.invited,
    };

    if (!allowedStatuses.contains(membership.status)) {
      throw protocol.TalktiveException(
        message: 'Access denied: Membership is not active.',
        code: 'ACCESS_INACTIVE',
      );
    }

    return membership;
  }

  /// Fetches a channel and verifies user access.
  static Future<protocol.Channel> getChannelWithAccess(
    Session session,
    int channelId,
    UuidValue userId, {
    bool allowInvited = false,
  }) async {
    final channel = await getChannel(session, channelId);
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    // Plaza is public
    if (channel.type != protocol.ChannelType.plaza) {
      await validateMember(
        session,
        channelId,
        userId,
        allowInvited: allowInvited,
      );
    }

    return channel;
  }

  /// Creates a new channel.
  static Future<protocol.Channel> createChannel(
    Session session, {
    required String name,
    required protocol.ChannelType type,
    bool isPersistent = false,
  }) async {
    final channel = protocol.Channel(
      name: name,
      type: type,
      createdAt: DateTime.now(),
      isPersistent: isPersistent,
    );
    return await protocol.Channel.db.insertRow(session, channel);
  }

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

  /// Checks if a user is blocked by the other participant in a private channel.
  static Future<void> validateNoBlockFlow(
    Session session, {
    required int channelId,
    required UuidValue senderId,
  }) async {
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (members.length == 2) {
      final otherMember = members.firstWhereOrNull(
        (m) => m.userInfoId != senderId,
      );
      if (otherMember != null) {
        final isBlocked = await protocol.Block.db.findFirstRow(
          session,
          where: (t) =>
              t.blockerId.equals(otherMember.userInfoId) &
              t.blockedId.equals(senderId),
        );
        if (isBlocked != null) {
          throw protocol.TalktiveException(
            message: 'Message not delivered. You are restricted.',
            code: 'PRIVACY_RESTRICTED',
          );
        }
      }
    }
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

      // Broadcast ReadReceipt
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
    DateTime? lastAt, // Optional custom timestamp
    bool updateTimestamp = true,
  }) async {
    final now = lastAt ?? DateTime.now();

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
        if (updateTimestamp) privateChat.lastMessageAt = now;
        privateChat.lastMessage = previewText;
        await protocol.PrivateChat.db.updateRow(session, privateChat);
      }
    } else if (channelType == protocol.ChannelType.lounge) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        if (updateTimestamp) lounge.lastMessageAt = now;
        lounge.lastMessage = previewText;
        await protocol.Lounge.db.updateRow(session, lounge);
      }
    }

    // Also update the core Channel's lastMessageAt for unified tracking
    if (updateTimestamp) {
      final channel = await getChannel(session, channelId);
      if (channel != null) {
        channel.lastMessageAt = now;
        await protocol.Channel.db.updateRow(session, channel);
      }
    }
  }

  /// Recalculates and updates the last message preview by fetching the latest non-recalled message from the DB.
  static Future<void> syncLastMessageFromDb(
    Session session,
    int channelId,
    protocol.ChannelType channelType,
  ) async {
    if (channelType == protocol.ChannelType.plaza) return;

    final lastMsg = await protocol.Message.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId) & t.isRecalled.equals(false),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    if (lastMsg != null) {
      await updateLastMessage(
        session,
        channelId,
        channelType: channelType,
        content: lastMsg.content,
        imageUrl: lastMsg.imageUrl,
        mediaUrl: lastMsg.mediaUrl,
        mediaType: lastMsg.mediaType,
        lastAt: lastMsg.createdAt,
        updateTimestamp: true,
      );
    } else {
      // No messages left or all recalled
      await updateLastMessage(
        session,
        channelId,
        channelType: channelType,
        content: null,
        updateTimestamp: false,
      );
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

  /// Generic method to update a member's status in a channel.
  static Future<protocol.ChannelMember> updateMemberStatus(
    Session session, {
    required int channelId,
    required UuidValue userId,
    required protocol.ChannelMemberStatus status,
    UuidValue? invitedBy,
    String? role,
  }) async {
    final DateTime now = DateTime.now();
    final member = await getMember(session, channelId, userId);
    if (member != null) {
      member.status = status;
      if (invitedBy != null) member.invitedBy = invitedBy;
      if (role != null) member.role = role;
      return await protocol.ChannelMember.db.updateRow(session, member);
    } else {
      return await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: channelId,
          userInfoId: userId,
          status: status,
          invitedBy: invitedBy,
          joinedAt: now,
          role: role ?? 'member',
        ),
      );
    }
  }

  /// Generic method to remove a member from a channel.
  static Future<void> removeMember(
    Session session, {
    required int channelId,
    required UuidValue userId,
  }) async {
    final member = await getMember(session, channelId, userId);
    if (member != null) {
      await protocol.ChannelMember.db.deleteRow(session, member);
    }
  }
}
