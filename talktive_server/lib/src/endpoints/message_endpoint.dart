import 'package:serverpod/serverpod.dart';
// Removed redundant Auth Server import
// Added UUID import
import '../generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/gamification_service.dart';
import '../services/redis_rate_limit_service.dart';
import '../services/content_filter_service.dart';
import '../services/achievement_service.dart';
import '../services/streak_service.dart';
import '../services/input_validation_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../services/notification_service.dart';

class MessageEndpoint extends Endpoint with EndpointAuthMixin {
  /// Sends a message to a channel (Plaza, Group, or Private).
  Future<protocol.Message> sendMessage(
    Session session,
    int channelId, {
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    bool isSystem = false,
  }) async {
    try {
      // Validate inputs
      InputValidationService.validateId(
        channelId,
        'Channel ID',
      ).throwIfInvalid();

      if (content != null) {
        InputValidationService.validateMessageContent(content).throwIfInvalid();
      }

      if (imageUrl != null) {
        InputValidationService.validateUrl(imageUrl).throwIfInvalid();
      }

      if (mediaUrl != null) {
        InputValidationService.validateUrl(mediaUrl).throwIfInvalid();
      }

      final senderUuid = await getUserId(session);

      // 1. Fetch sender resident data
      final sender = await getResidentProfile(session, senderUuid);

      // Passively restore trustScore early (important for mute checks)
      await ApartmentService.restoreTrustScore(session, sender, save: false);

      // 2. Fetch channel to verify access and type
      final channel = await protocol.Channel.db.findById(session, channelId);
      if (channel == null) {
        throw protocol.TalktiveException(
          message: 'Channel not found.',
          code: 'CHANNEL_NOT_FOUND',
        );
      }

      // 3. User info and floor Computation
      final senderName = sender.userName;
      final senderAvatar = sender.avatar;
      final senderEffectiveFloor = ApartmentService.computeEffectiveFloor(
        sender,
      );

      // 4. Safety Checks (Muted / Suspended)
      if (ApartmentService.isMuted(sender)) {
        throw protocol.TalktiveException(
          message: ApartmentService.getMuteReason(sender),
          code: 'USER_MUTED',
        );
      }

      // 5. Content Validation (profanity and spam filtering)
      String? filteredContent = content;
      if (content != null && content.isNotEmpty) {
        final validation = await ContentFilterService.validateMessage(
          session,
          content,
          senderEffectiveFloor,
        );
        if (!validation.isValid) {
          throw protocol.TalktiveException(
            message: validation.reason ?? 'Invalid message content',
            code: 'CONTENT_FILTER_FAIL',
          );
        }

        // Check for repeated messages (spam detection)
        final isRepeated = await ContentFilterService.isRepeatedMessage(
          session,
          senderUuid.toString(),
          content,
        );
        if (isRepeated) {
          throw protocol.TalktiveException(
            message: 'Please don\'t send the same message repeatedly',
            code: 'SPAM_DETECTED',
          );
        }

        filteredContent = validation.filteredContent ?? content;
      }

      // 6. Check rate limiting with Redis (faster than database)
      final rateLimitError = await RedisRateLimitService.checkRateLimit(
        session,
        senderUuid.toString(),
        channelId,
        senderEffectiveFloor,
      );
      if (rateLimitError != null) {
        throw protocol.TalktiveException(
          message: rateLimitError,
          code: 'RATE_LIMIT_EXCEEDED',
        );
      }

      // 7. Floor-based content restrictions
      final hasMedia =
          (imageUrl != null && imageUrl.isNotEmpty) ||
          (mediaUrl != null && mediaUrl.isNotEmpty);
      if (channel.type == protocol.ChannelType.plaza && hasMedia) {
        // Plaza restrictions: images allowed only for Floor 2+
        if (senderEffectiveFloor < 2) {
          throw protocol.TalktiveException(
            message: 'You must reach Floor 2 to send images in the Plaza.',
            code: 'FLOOR_RESTRICTION',
          );
        }
      }

      // 8. Create Message object
      final message = protocol.Message(
        channelId: channelId,
        senderId: sender.userInfoId,
        content: filteredContent,
        imageUrl: imageUrl,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        isSystem: isSystem,
        createdAt: DateTime.now(),
        senderName: senderName ?? 'Resident',
        senderAvatar: senderAvatar,
        senderMood: sender.mood,
        senderFloor: senderEffectiveFloor,
        senderTrustScore: sender.trustScore,
      );

      // 9. Database Updates (Single transaction if possible or batched saves)
      final savedMessage = await protocol.Message.db.insertRow(
        session,
        message,
      );

      // Update lastMessageAt for private chats (Bubbling up)
      if (channel.type == protocol.ChannelType.private) {
        final privateChat = await protocol.PrivateChat.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channelId),
        );
        if (privateChat != null) {
          privateChat.lastMessageAt = DateTime.now();
          await protocol.PrivateChat.db.updateRow(session, privateChat);
        }
      }

      // 10. Distribute via Streaming (Real-time)
      final streamKey = 'channel_$channelId';
      await session.messages.postMessage(streamKey, savedMessage);

      // 10.1 Trigger Notifications (FCM / Activity Hub)
      String channelTypeStr = 'plaza';
      if (channel.type == protocol.ChannelType.private) {
        channelTypeStr = 'private';
      } else if (channel.type == protocol.ChannelType.group) {
        channelTypeStr = 'group';
      }

      // Only notify if not Plaza (or if you want to notify even in Plaza, though it might be spammy)
      if (channel.type != protocol.ChannelType.plaza) {
        final members = await protocol.ChannelMember.db.find(
          session,
          where: (t) =>
              t.channelId.equals(channelId) &
              t.userInfoId.notEquals(senderUuid) &
              t.isMuted.equals(false),
        );

        for (final member in members) {
          await NotificationService.sendMessageNotification(
            session,
            member.userInfoId,
            senderName ?? 'Resident',
            filteredContent ?? 'Sent a media',
            channelId,
            channelTypeStr,
          );
        }
      }

      // 11. Gamification & Stats Batching
      await GamificationService.awardXP(
        session,
        sender,
        GamificationService.XP_PER_MESSAGE,
        'Sent message',
        save: false,
      );
      sender.experienceMessageCount += 1;
      await GamificationService.updateMessageStreak(
        session,
        sender,
        save: false,
      );

      // FINAL SINGLE SAVE for the resident object
      await protocol.Resident.db.updateRow(session, sender);

      // 12. Achievement tracking (already uses batching internally)
      await AchievementService.trackMultipleProgress(
        session,
        sender.userInfoId,
        ['first_message', 'conversationalist', 'chatterbox'],
      );

      // Secondary checks
      await AchievementService.checkTimeBasedAchievements(
        session,
        sender.userInfoId,
      );
      await StreakService.updateStreak(session, sender.userInfoId);

      return savedMessage;
    } catch (e, stack) {
      session.log('FAILED to send message: $e', level: LogLevel.error);
      session.log(stack.toString(), level: LogLevel.error);
      rethrow;
    }
  }

  /// Subscribes to a channel to receive real-time messages.
  Stream<protocol.Message> subscribe(Session session, int channelId) async* {
    final authenticationInfo = session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('Not authenticated');
    }

    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    // final channel = await protocol.Channel.db.findById(session, channelId); // Optimization: skip DB check for stream?
    // If we want to enforce rules, we should check.

    // 2. Create stream from message bus
    final streamKey = 'channel_$channelId';

    // session.messages.createStream returns a Stream of SerializableModel
    final stream = session.messages.createStream(streamKey);

    await for (final message in stream) {
      if (message is protocol.Message) {
        yield message;
      }
    }
  }

  /// Fetches the history of messages for a channel.
  Future<List<protocol.Message>> listMessages(
    Session session,
    int channelId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // Validate inputs
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    // Check membership for private/group channels
    if (channel.type != protocol.ChannelType.plaza) {
      final userUuid = await getUserId(session);

      // Check if user is a member of this channel
      final membership = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(channelId) & t.userInfoId.equals(userUuid),
      );

      if (membership == null) {
        throw protocol.TalktiveException(
          message: 'Access denied: Not a member of this channel.',
          code: 'ACCESS_DENIED',
        );
      }

      // Check if membership is active or invited
      if (membership.status != protocol.ChannelMemberStatus.joined &&
          membership.status != protocol.ChannelMemberStatus.invited) {
        throw protocol.TalktiveException(
          message: 'Access denied: Membership is not active.',
          code: 'ACCESS_INACTIVE',
        );
      }
    }

    // 2. Fetch messages
    return await protocol.Message.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }
}
