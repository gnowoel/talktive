import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'apartment_service.dart';
import 'resident_service.dart';
import 'gamification_service.dart';
import 'content_filter_service.dart';
import 'input_validation_service.dart';
import 'rate_limit_service.dart';
import 'channel_service.dart';
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
      InputValidationService.validateFileSize(fileSize, fieldName: 'Media file')
          .throwIfInvalid();
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
    final hasMedia = (imageUrl != null && imageUrl.isNotEmpty) ||
        (mediaUrl != null && mediaUrl.isNotEmpty);

    if (hasMedia) {
      // Plaza restrictions: images/media allowed only for Floor 2+
      if (channel.type == protocol.ChannelType.plaza &&
          senderEffectiveFloor < 2) {
        throw protocol.TalktiveException(
          message: 'You must reach Floor 2 to send media in the Plaza.',
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
            t.channelId.equals(channel.id!) & t.userInfoId.notEquals(senderUuid),
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
            message: 'Message not delivered. You are currently restricted by this resident.',
            code: 'PRIVACY_RESTRICTED',
          );
        }
      }
    }

    return filteredContent;
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
    final senderMembership = await ChannelService.getMember(session, channelId, senderUuid);
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

    // Achievement Progress (Background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      await GamificationService.trackMultipleProgress(
        backgroundSession,
        senderUuid,
        ['first_message', 'conversationalist', 'chatterbox'],
      );
      await GamificationService.checkTimeBasedAchievements(backgroundSession, senderUuid);
    });
  }
}
