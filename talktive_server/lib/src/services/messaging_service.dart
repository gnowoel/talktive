import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'apartment_service.dart';
import 'resident_service.dart';
import 'gamification_service.dart';
import 'content_filter_service.dart';
import 'input_validation_service.dart';
import 'rate_limit_service.dart';
import 'channel_service.dart';
import 'lounge_service.dart';
import 'notification_service.dart';
import '../utils/task_utils.dart';

/// Service for handling message validation and post-save operations.
class MessagingService {
  /// Validates a message before it is saved.
  /// Checks safety (muted/suspended), content filtering, rate limiting, and floor rules.
  static Future<String?> validateMessage(
    Session session, {
    required protocol.Resident sender,
    required protocol.Channel channel,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
  }) async {
    final senderUuid = sender.userInfoId;
    final senderEffectiveFloor = ApartmentService.computeEffectiveFloor(sender);

    // 1. Safety Checks (Muted / Suspended)
    if (ApartmentService.isMuted(sender)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(sender),
        code: 'USER_MUTED',
      );
    }

    // 2. Basic Input Validation (Length/Size/Duration)
    if (content != null && content.isNotEmpty) {
      InputValidationService.validateMessageContent(content).throwIfInvalid();
    }

    if (fileSize != null) {
      InputValidationService.validateFileSize(
        fileSize,
        fieldName: 'Media file',
      ).throwIfInvalid();
    }

    if (mediaType == 'voice' && duration != null) {
      InputValidationService.validateVoiceDuration(duration).throwIfInvalid();
    }

    // 3. Content Validation (profanity and spam filtering)
    String? filteredContent = content;
    if (content != null && content.isNotEmpty) {
      final validation = await ContentFilterService.validateMessage(
        session,
        content,
        senderEffectiveFloor,
      );
      if (!validation.isValid) {
        throw protocol.TalktiveException(
          message: validation.error ?? 'Invalid message content',
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
          message: "Please don't send the same message repeatedly",
          code: 'SPAM_DETECTED',
        );
      }

      filteredContent = validation.filteredContent ?? content;
    }

    // 4. Check rate limiting
    final rateLimitError = await RateLimitService.checkRateLimit(
      session,
      senderUuid.toString(),
      channel.id!,
      senderEffectiveFloor,
    );
    if (rateLimitError != null) {
      throw protocol.TalktiveException(
        message: rateLimitError,
        code: 'RATE_LIMIT_EXCEEDED',
      );
    }

    // 5. Floor-based and Premium content restrictions
    final hasMedia =
        (imageUrl != null && imageUrl.isNotEmpty) ||
        (mediaUrl != null && mediaUrl.isNotEmpty);

    if (hasMedia) {
      // Plaza and Lounge restrictions: images/media allowed only for Floor 2+
      if ((channel.type == protocol.ChannelType.plaza ||
              channel.type == protocol.ChannelType.lounge) &&
          senderEffectiveFloor < 2) {
        throw protocol.TalktiveException(
          message: 'You must reach Floor 2 to send media in public spaces. 🏢',
          code: 'FLOOR_RESTRICTION',
        );
      }

      // Voice message premium check
      if (mediaType == 'voice' && !sender.isPremium) {
        throw protocol.TalktiveException(
          message:
              'Voice messages are a Premium feature. 🎙️ Upgrade in Settings!',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    // 6. Privacy Check: Blocked status (Private Chats)
    if (channel.type == protocol.ChannelType.private) {
      final members = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channel.id!) &
            t.userInfoId.notEquals(senderUuid),
      );
      if (members.isNotEmpty) {
        final otherUserUuid = members.first.userInfoId;
        final isBlocked = await ResidentService.isBlocked(
          session,
          blockerId: otherUserUuid,
          blockedId: senderUuid,
        );
        if (isBlocked) {
          throw protocol.TalktiveException(
            message:
                'Message not delivered. You are currently restricted by this resident.',
            code: 'PRIVACY_RESTRICTED',
          );
        }
      }
    }

    return filteredContent;
  }

  /// Creates, saves, and triggers post-save processes for a new message.
  /// This is the primary entry point for sending a message from any endpoint.
  static Future<protocol.Message> sendMessage(
    Session session, {
    required protocol.Resident sender,
    required protocol.Channel channel,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
    bool isSystem = false,
  }) async {
    // 1. Validate the content and permissions
    final filteredContent = await validateMessage(
      session,
      sender: sender,
      channel: channel,
      content: content,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      duration: duration,
      fileSize: fileSize,
    );

    // 2. Build the message object
    final message = protocol.Message(
      channelId: channel.id!,
      senderId: sender.userInfoId,
      content: filteredContent,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      isSystem: isSystem,
      createdAt: DateTime.now(),
      duration: duration,
      fileSize: fileSize,
      senderName: sender.userName ?? 'Resident',
      senderAvatar: sender.customAvatarUrl ?? sender.avatar,
      senderMood: sender.mood,
      senderFloor: ApartmentService.computeEffectiveFloor(sender),
      senderTrustScore: sender.trustScore,
    );

    // 3. Save to database
    final savedMessage = await protocol.Message.db.insertRow(session, message);

    // 4. Handle side effects (asynchronously in background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      // Re-fetch channel for background session scope safety if needed,
      // though for most listeners this might be overkill, it keeps it robust.
      final channelReloaded = await ChannelService.getChannel(
        backgroundSession,
        channel.id!,
      );
      if (channelReloaded != null) {
        // Trigger notifications (Push, mentioning, etc.)
        await NotificationService.triggerMessageNotifications(
          backgroundSession,
          channel: channelReloaded,
          message: savedMessage,
          sender: sender,
        );

        // Handle other save life-cycle events (Real-time broadcast, unread counts, XP, Streaks)
        await onMessageSaved(
          backgroundSession,
          message: savedMessage,
          channel: channelReloaded,
          sender: sender,
        );
      }
    });

    return savedMessage;
  }

  /// Handles all post-message-save operations: broadcasts, notifications, gamification.
  static Future<void> onMessageSaved(
    Session session, {
    required protocol.Message message,
    required protocol.Channel channel,
    required protocol.Resident sender,
  }) async {
    final senderUuid = sender.userInfoId;
    final channelId = channel.id!;

    // 1. Update sender's lastReadAt
    final senderMembership = await ChannelService.getMember(
      session,
      channelId,
      senderUuid,
    );
    if (senderMembership != null) {
      senderMembership.lastReadAt = message.createdAt;
      await protocol.ChannelMember.db.updateRow(session, senderMembership);
    }

    // 2. Update denormalized last message fields (not for Plaza)
    if (channel.type != protocol.ChannelType.plaza) {
      await ChannelService.updateLastMessage(
        session,
        channelId,
        channelType: channel.type,
        content: message.content,
        imageUrl: message.imageUrl,
        mediaUrl: message.mediaUrl,
        mediaType: message.mediaType,
      );
    }

    // 3. Broadcast real-time message
    await session.messages.postMessage('channel_$channelId', message);

    // 4. Trigger Gamification
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
    await ResidentService.updateResident(session, sender);

    // 5. Award Lounge XP
    if (channel.type == protocol.ChannelType.lounge) {
      await LoungeService.awardLoungeXP(
        session,
        channelId,
        1,
        'Message sent',
      );
    }

    // Achievement Progress (Background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      await GamificationService.trackMultipleProgress(
        backgroundSession,
        senderUuid,
        ['first_message', 'conversationalist', 'chatterbox'],
      );
      await GamificationService.checkTimeBasedAchievements(
        backgroundSession,
        senderUuid,
      );
    });
  }

  /// Pins a message to the top of its channel.
  static Future<protocol.Message> pinMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    bool canPin = false;
    if (resident.role == protocol.ResidentRole.admin ||
        resident.role == protocol.ResidentRole.moderator) {
      if (channel.type != protocol.ChannelType.private) {
        canPin = true;
      }
    }

    if (!canPin) {
      if (channel.type == protocol.ChannelType.lounge) {
        final lounge = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (lounge != null && lounge.creatorId == resident.userInfoId) {
          canPin = true;
        }
      } else if (channel.type == protocol.ChannelType.private) {
        final privateChat = await protocol.PrivateChat.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (privateChat != null &&
            (privateChat.participant1Id == resident.userInfoId ||
                privateChat.participant2Id == resident.userInfoId)) {
          canPin = true;
        }
      }
    }

    if (!canPin) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to pin messages in this channel.',
        code: 'ACCESS_DENIED',
      );
    }

    final existingPinned = await protocol.Message.db.find(
      session,
      where: (t) =>
          t.channelId.equals(message.channelId) & t.isPinned.equals(true),
    );

    if (existingPinned.isNotEmpty) {
      await protocol.Message.db.updateWhere(
        session,
        where: (t) =>
            t.channelId.equals(message.channelId) & t.isPinned.equals(true),
        columnValues: (t) => [t.isPinned(false)],
      );

      for (final oldMessage in existingPinned) {
        oldMessage.isPinned = false;
        await session.messages.postMessage(
          'channel_${message.channelId}',
          oldMessage,
        );
      }
    }

    message.isPinned = true;
    message.pinnedAt = DateTime.now();
    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );
    return updatedMessage;
  }

  /// Unpins a message.
  static Future<protocol.Message> unpinMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    bool canUnpin = false;
    if (resident.role == protocol.ResidentRole.admin ||
        resident.role == protocol.ResidentRole.moderator) {
      if (channel.type != protocol.ChannelType.private) {
        canUnpin = true;
      }
    }

    if (!canUnpin) {
      if (channel.type == protocol.ChannelType.lounge) {
        final lounge = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (lounge != null && lounge.creatorId == resident.userInfoId) {
          canUnpin = true;
        }
      } else if (channel.type == protocol.ChannelType.private) {
        final privateChat = await protocol.PrivateChat.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (privateChat != null &&
            (privateChat.participant1Id == resident.userInfoId ||
                privateChat.participant2Id == resident.userInfoId)) {
          canUnpin = true;
        }
      }
    }

    if (!canUnpin) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to unpin messages in this channel.',
        code: 'ACCESS_DENIED',
      );
    }

    message.isPinned = false;
    message.pinnedAt = null;
    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );
    return updatedMessage;
  }

  /// Recalls a message.
  static Future<protocol.Message> recallMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    if (message.isRecalled) {
      return message;
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    bool canRecall = false;

    // 1. Own message can always be recalled
    if (message.senderId == resident.userInfoId) {
      canRecall = true;
    }

    // 2. Staff (Admin/Moderator) can recall in non-private spaces
    if (!canRecall &&
        (resident.role == protocol.ResidentRole.admin ||
            resident.role == protocol.ResidentRole.moderator)) {
      if (channel.type != protocol.ChannelType.private) {
        canRecall = true;
      }
    }

    // 3. Lounge Creator can recall in their lounge
    if (!canRecall && channel.type == protocol.ChannelType.lounge) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channel.id!),
      );
      if (lounge != null && lounge.creatorId == resident.userInfoId) {
        canRecall = true;
      }
    }

    if (!canRecall) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to recall this message.',
        code: 'ACCESS_DENIED',
      );
    }

    // Mark as recalled
    message.isRecalled = true;
    message.recalledAt = DateTime.now();
    message.content = null;
    message.imageUrl = null;
    message.mediaUrl = null;
    message.mediaType = null;
    message.duration = null;
    message.fileSize = null;

    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    // Update Denormalized Info (Preview text) if it was the last message
    if (channel.type != protocol.ChannelType.plaza) {
      bool isLast = false;
      if (channel.type == protocol.ChannelType.private) {
        final pc = await protocol.PrivateChat.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (pc != null && pc.lastMessageAt != null) {
          // Approximate check: if recalled message was the latest according to time
          // Better: We could just check if there's any message newer than this one.
          final newerMsg = await protocol.Message.db.findFirstRow(
            session,
            where: (t) =>
                t.channelId.equals(channel.id!) &
                (t.createdAt > message.createdAt),
          );
          if (newerMsg == null) isLast = true;
        }
      } else if (channel.type == protocol.ChannelType.lounge) {
        final lounge = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channel.id!),
        );
        if (lounge != null && lounge.lastMessageAt != null) {
          final newerMsg = await protocol.Message.db.findFirstRow(
            session,
            where: (t) =>
                t.channelId.equals(channel.id!) &
                (t.createdAt > message.createdAt),
          );
          if (newerMsg == null) isLast = true;
        }
      }

      if (isLast) {
        await ChannelService.updateLastMessage(
          session,
          channel.id!,
          channelType: channel.type,
          content: 'Message recalled 🔄',
          updateTimestamp: false,
        );
      }
    }

    // Broadcast update
    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );

    return updatedMessage;
  }
}
