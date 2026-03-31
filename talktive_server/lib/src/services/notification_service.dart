import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'dart:convert';
import 'fcm_service.dart';
import 'mention_service.dart';
import 'resident_service.dart';

class NotificationService {
  /// Sends a notification to a user.
  static Future<void> sendNotification(
    Session session,
    UuidValue userId,
    String type,
    String title,
    String body, {
    Map<String, dynamic>? data,
    bool saveToHistory = true,
  }) async {
    await sendBulkNotifications(
      session,
      [userId],
      type,
      title,
      body,
      data: data,
      saveToHistory: saveToHistory,
    );
  }

  /// Sends a notification to multiple users efficiently.
  static Future<void> sendBulkNotifications(
    Session session,
    List<UuidValue> userIds,
    String type,
    String title,
    String body, {
    Map<String, dynamic>? data,
    bool saveToHistory = true,
  }) async {
    if (userIds.isEmpty) return;

    // Prepare FCM payload
    final fcmData =
        data?.map((key, value) => MapEntry(key, value.toString())) ?? {};
    fcmData['appVersion'] = 'serverpod';

    // 1. Handle History (Batched)
    if (saveToHistory) {
      final notifications = userIds
          .map(
            (userId) => protocol.UserNotification(
              userId: userId,
              type: type,
              title: title,
              body: body,
              data: data != null ? jsonEncode(data) : null,
              read: false,
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      // Note: Serverpod doesn't have a direct batch insert that returns IDs easily
      // for all rows in a way we can map back to users for individual fcmData enrichment,
      // but since we only need notificationId for the payload if it's saved,
      // and usually bulk notifications (like messages) don't save to history,
      // we'll just insert and skip individual notificationId mapping for now unless it's a single user.

      if (userIds.length == 1) {
        final inserted = await protocol.UserNotification.db.insertRow(
          session,
          notifications.first,
        );
        fcmData['notificationId'] = inserted.id.toString();
      } else {
        await protocol.UserNotification.db.insert(session, notifications);
      }
    }

    // 2. Fetch all device tokens for all users in one query
    final tokens = await protocol.DeviceToken.db.find(
      session,
      where: (t) => t.userId.inSet(userIds.toSet()),
    );

    if (tokens.isEmpty) return;

    // 3. Send FCM push notifications in parallel
    // We send to all tokens. FCMService.sendToToken is already async.
    await Future.wait(
      tokens.map(
        (deviceToken) => FCMService.sendToToken(
          session,
          deviceToken.token,
          title,
          body,
          data: fcmData,
        ),
      ),
    );
  }

  /// Sends a message notification.
  static Future<void> sendMessageNotification(
    Session session,
    UuidValue recipientId,
    String senderName,
    String messagePreview,
    int channelId,
    String channelType, {
    int? loungeId,
  }) async {
    int? resolvedRouteId = loungeId ?? channelId;
    if (loungeId == null && channelType == 'lounge') {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        resolvedRouteId = lounge.id;
      }
    }

    await sendNotification(
      session,
      recipientId,
      'message',
      senderName,
      messagePreview,
      data: {
        'channelId': channelId,
        'channelType': channelType,
        'route': channelType == 'private'
            ? '/chats/thread/$resolvedRouteId'
            : (channelType == 'plaza'
                  ? '/plaza'
                  : '/lounges/chat/$resolvedRouteId'),
      },
      saveToHistory: false,
    );
  }

  /// Sends a message notification to multiple recipients efficiently.
  static Future<void> sendBulkMessageNotifications(
    Session session,
    List<UuidValue> recipientIds,
    String senderName,
    String messagePreview,
    int channelId,
    String channelType, {
    int? loungeId,
  }) async {
    if (recipientIds.isEmpty) return;

    int? resolvedRouteId = loungeId ?? channelId;
    if (loungeId == null && channelType == 'lounge') {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        resolvedRouteId = lounge.id;
      }
    }

    final route = channelType == 'private'
        ? '/chats/thread/$resolvedRouteId'
        : (channelType == 'plaza'
              ? '/plaza'
              : '/lounges/chat/$resolvedRouteId');

    await sendBulkNotifications(
      session,
      recipientIds,
      'message',
      senderName,
      messagePreview,
      data: {
        'channelId': channelId,
        'channelType': channelType,
        'route': route,
      },
      saveToHistory: false,
    );
  }

  /// Sends a moment like notification.
  static Future<void> sendMomentLikeNotification(
    Session session,
    UuidValue recipientId,
    String likerName,
    int momentId,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'moment_like',
      '$likerName liked your moment',
      'Tap to view',
      data: {
        'momentId': momentId,
        'route': '/moments',
      },
    );
  }

  /// Sends a moment comment notification.
  static Future<void> sendMomentCommentNotification(
    Session session,
    UuidValue recipientId,
    String commenterName,
    String commentText,
    int momentId,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'moment_comment',
      '$commenterName commented on your moment',
      commentText,
      data: {
        'momentId': momentId,
        'route': '/moments',
      },
    );
  }

  /// Sends an achievement unlock notification.
  static Future<void> sendAchievementNotification(
    Session session,
    UuidValue userId,
    String achievementName,
    String achievementEmoji,
    int points,
  ) async {
    await sendNotification(
      session,
      userId,
      'achievement',
      'Achievement Unlocked! $achievementEmoji',
      '$achievementName (+$points points)',
      data: {
        'route': '/activity',
      },
    );
  }

  /// Sends a streak reminder notification.
  static Future<void> sendStreakReminderNotification(
    Session session,
    UuidValue userId,
    int currentStreak,
  ) async {
    await sendNotification(
      session,
      userId,
      'streak',
      'Don\'t break your streak! 🔥',
      'You\'re on a $currentStreak day streak. Come back today to keep it going!',
      data: {
        'route': '/my-profile',
      },
    );
  }

  /// Sends a level up notification.
  static Future<void> sendLevelUpNotification(
    Session session,
    UuidValue userId,
    int newLevel,
  ) async {
    await sendNotification(
      session,
      userId,
      'level_up',
      'Level Up! ✨',
      'You just reached Floor $newLevel! Your reputation and access have increased.',
      data: {
        'level': newLevel,
        'route': '/activity',
      },
    );
  }

  /// Sends a chat invite notification.
  static Future<void> sendChatInviteNotification(
    Session session,
    UuidValue recipientId,
    String inviterName,
    int channelId,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'chat_invite',
      '$inviterName knocked on your door 🚪',
      'Wants to start a private chat with you.',
      data: {
        'channelId': channelId,
        'route': '/chats/thread/$channelId',
      },
      saveToHistory: true, // Doorbell always shows in activity
    );
  }

  /// Sends a lounge invite notification.
  static Future<void> sendLoungeInviteNotification(
    Session session,
    UuidValue recipientId,
    String inviterName,
    String loungeName,
    String loungeEmoji,
    int loungeId,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'lounge_invite',
      '$inviterName invited you to $loungeEmoji $loungeName',
      'Tap to join',
      data: {
        'loungeId': loungeId,
        'route': '/lounges/profile/$loungeId',
      },
      saveToHistory: true, // Now saved to history as per user request
    );
  }

  /// Sends a mention notification.
  static Future<void> sendMentionNotification(
    Session session,
    UuidValue recipientId,
    String senderName,
    String messagePreview,
    int channelId,
    String loungeName, {
    int? loungeId,
  }) async {
    // Resolve loungeId from channelId if not provided
    int? resolvedLoungeId = loungeId;
    if (resolvedLoungeId == null) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        resolvedLoungeId = lounge.id;
      }
    }

    // Resolve route based on channel type
    String route = '/lounges';
    if (resolvedLoungeId != null) {
      route = '/lounges/chat/$resolvedLoungeId';
    } else {
      final channel = await protocol.Channel.db.findById(session, channelId);
      if (channel?.type == protocol.ChannelType.private) {
        route = '/chats/thread/$channelId';
      }
    }

    // Mentions are recorded in history and bypass mute
    await sendNotification(
      session,
      recipientId,
      'mention',
      'Mentioned by $senderName',
      '@$senderName: $messagePreview',
      data: {
        'channelId': channelId,
        'loungeName': loungeName,
        'loungeId': loungeId,
        'route': route,
      },
      saveToHistory: true,
    );
  }

  /// Gets user's notifications.
  static Future<List<protocol.UserNotification>> getUserNotifications(
    Session session,
    UuidValue userId, {
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    return await protocol.UserNotification.db.find(
      session,
      where: unreadOnly
          ? (t) => t.userId.equals(userId) & t.read.equals(false)
          : (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Marks notifications as read.
  static Future<void> markAsRead(
    Session session,
    List<int> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return;

    final notifications = await protocol.UserNotification.db.find(
      session,
      where: (t) => t.id.inSet(notificationIds.toSet()),
    );

    for (final notification in notifications) {
      notification.read = true;
    }

    await protocol.UserNotification.db.update(session, notifications);
  }

  /// Gets unread notification count.
  static Future<int> getUnreadCount(
    Session session,
    UuidValue userId,
  ) async {
    return await protocol.UserNotification.db.count(
      session,
      where: (t) => t.userId.equals(userId) & t.read.equals(false),
    );
  }

  /// Registers a device token.
  static Future<void> registerDeviceToken(
    Session session,
    UuidValue userId,
    String token,
    String platform,
  ) async {
    // Check if token already exists
    final existing = await protocol.DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.token.equals(token),
    );

    if (existing != null) {
      // Update last used
      existing.lastUsed = DateTime.now();
      await protocol.DeviceToken.db.updateRow(session, existing);
    } else {
      // Create new token
      final deviceToken = protocol.DeviceToken(
        userId: userId,
        token: token,
        platform: platform,
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await protocol.DeviceToken.db.insertRow(session, deviceToken);
    }
  }

  /// Unregisters a device token.
  static Future<void> unregisterDeviceToken(
    Session session,
    String token,
  ) async {
    final existing = await protocol.DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.token.equals(token),
    );

    if (existing != null) {
      await protocol.DeviceToken.db.deleteRow(session, existing);
    }
  }

  /// Sends a vouch/like notification.
  static Future<void> sendVouchNotification(
    Session session,
    UuidValue recipientId,
    String senderName,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'vouch',
      'New Vouch! 🤝',
      '$senderName has vouched for you. Your trust score has increased!',
      data: {
        'route': '/my-profile',
      },
      saveToHistory: true,
    );
  }

  /// Sends a safety-related notification (e.g., mute, suspension).
  static Future<void> sendSafetyNotification(
    Session session,
    UuidValue userId,
    String title,
    String body,
  ) async {
    await sendNotification(
      session,
      userId,
      'safety',
      title,
      body,
      data: {
        'route': '/activity',
      },
      saveToHistory: true,
    );
  }

  /// Sends a warning notification.
  static Future<void> sendWarningNotification(
    Session session,
    UuidValue userId,
    String body,
  ) async {
    await sendNotification(
      session,
      userId,
      'warning',
      'Community Warning ⚠️',
      body,
      data: {
        'route': '/activity',
      },
      saveToHistory: true,
    );
  }

  /// Orchestrates all notifications for a new message (mentions, push, etc).
  static Future<void> triggerMessageNotifications(
    Session session, {
    required protocol.Channel channel,
    required protocol.Message message,
    required protocol.Resident sender,
  }) async {
    final content = message.content;
    if (content == null || content.isEmpty) return;

    final isPlaza = channel.type == protocol.ChannelType.plaza;
    final channelId = channel.id!;
    final senderUuid = sender.userInfoId;
    final senderName = sender.userName ?? 'Resident';

    // 1. Resolve loungeId if applicable
    int? loungeId;
    if (!isPlaza) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      loungeId = lounge?.id;
    }

    // 2. Detect mentions
    final mentionedUserIds = await MentionService.getMentionedUserIds(
      session,
      channelId,
      content,
    );
    mentionedUserIds.remove(senderUuid);

    final loungeName = channel.name ?? (isPlaza ? 'Plaza' : 'Chat');

    // 3. Notify mentions (Parallel)
    final mentionFutures = mentionedUserIds.map(
      (mentionedId) => sendMentionNotification(
        session,
        mentionedId,
        senderName,
        content,
        channelId,
        loungeName,
        loungeId: loungeId,
      ),
    );

    // 4. Notify other members (Private/Lounge only)
    Future? bulkMemberFuture;
    if (!isPlaza) {
      final String channelTypeStr =
          channel.type == protocol.ChannelType.private ? 'private' : 'lounge';

      final mentionIdSet = mentionedUserIds.toSet();
      final blockedBySet = await ResidentService.getBlocksAgainstUser(
        session,
        senderUuid,
      );

      final otherMembers = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channelId) &
            t.userInfoId.notEquals(senderUuid) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      );

      final recipientIds = <UuidValue>[];
      for (final member in otherMembers) {
        if (member.isMuted || mentionIdSet.contains(member.userInfoId)) {
          continue;
        }
        if (blockedBySet.contains(member.userInfoId)) continue;
        recipientIds.add(member.userInfoId);
      }

      if (recipientIds.isNotEmpty) {
        bulkMemberFuture = sendBulkMessageNotifications(
          session,
          recipientIds,
          senderName,
          content,
          channelId,
          channelTypeStr,
          loungeId: loungeId,
        );
      }
    }

    await Future.wait([
      ...mentionFutures,
      ?bulkMemberFuture,
    ]);
  }
}
