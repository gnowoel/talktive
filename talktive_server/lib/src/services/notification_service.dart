import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import 'dart:convert';
import 'fcm_service.dart';

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
    // Create notification record
    if (saveToHistory) {
      final notification = protocol.UserNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data != null ? jsonEncode(data) : null,
        read: false,
        createdAt: DateTime.now(),
      );

      await protocol.UserNotification.db.insertRow(session, notification);
    }

    // Get user's device tokens
    final tokens = await protocol.DeviceToken.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (tokens.isEmpty) {
      return; // User has no registered devices
    }

    // Prepare FCM payload with dual-boot safety flag
    final fcmData =
        data?.map((key, value) => MapEntry(key, value.toString())) ?? {};
    fcmData['appVersion'] = 'serverpod';

    // Send FCM push notification to each token
    for (final deviceToken in tokens) {
      await FCMService.sendToToken(
        session,
        deviceToken.token,
        title,
        body,
        data: fcmData,
      );
    }
  }

  /// Sends a message notification.
  static Future<void> sendMessageNotification(
    Session session,
    UuidValue recipientId,
    String senderName,
    String messagePreview,
    int channelId,
    String channelType, // 'private', 'group', 'plaza'
  ) async {
    int? routeId = channelId;
    if (channelType == 'group') {
      final group = await protocol.Group.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (group != null) {
        routeId = group.id;
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
            ? '/chats/thread/$routeId'
            : (channelType == 'plaza' ? '/plaza' : '/groups/chat/$routeId'),
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
        'route': '/profile',
      },
    );
  }

  /// Sends a group invite notification.
  static Future<void> sendGroupInviteNotification(
    Session session,
    UuidValue recipientId,
    String inviterName,
    String groupName,
    String groupEmoji,
    int groupId,
  ) async {
    await sendNotification(
      session,
      recipientId,
      'group_invite',
      '$inviterName invited you to $groupEmoji $groupName',
      'Tap to join',
      data: {
        'groupId': groupId,
        'route':
            '/groups/profile/$groupId', // Usually group invites go to the group profile to apply/join
      },
      saveToHistory: false,
    );
  }

  /// Sends a mention notification.
  static Future<void> sendMentionNotification(
    Session session,
    UuidValue recipientId,
    String senderName,
    String messagePreview,
    int channelId,
    String groupName,
  ) async {
    // Mentions are recorded in history and bypass mute
    await sendNotification(
      session,
      recipientId,
      'mention',
      'Mentioned by $senderName',
      '@$senderName: $messagePreview',
      data: {
        'channelId': channelId,
        'groupName': groupName,
        'route': '/groups/chat/$channelId',
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
    for (final id in notificationIds) {
      final notification = await protocol.UserNotification.db.findById(
        session,
        id,
      );
      if (notification != null) {
        notification.read = true;
        await protocol.UserNotification.db.updateRow(session, notification);
      }
    }
  }

  /// Gets unread notification count.
  static Future<int> getUnreadCount(
    Session session,
    UuidValue userId,
  ) async {
    final unread = await protocol.UserNotification.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.read.equals(false),
    );
    return unread.length;
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
}
