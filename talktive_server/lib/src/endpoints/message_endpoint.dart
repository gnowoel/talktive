import 'dart:async';
import 'package:serverpod/serverpod.dart';
// Removed redundant Auth Server import
// Added UUID import
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/gamification_service.dart';
import '../services/rate_limit_service.dart';
import '../services/content_filter_service.dart';

import '../services/input_validation_service.dart';
import '../services/chat_service.dart';
import '../services/mention_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../services/notification_service.dart';
import '../services/resident_service.dart';

class MessageEndpoint extends Endpoint with EndpointAuthMixin {
  /// Sends a message to a channel (Plaza, Lounge, or Private).
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

      if (content != null && content.trim().isNotEmpty) {
        InputValidationService.validateMessageContent(content).throwIfInvalid();
      }

      if ((content == null || content.trim().isEmpty) &&
          (imageUrl == null || imageUrl.trim().isEmpty) &&
          (mediaUrl == null || mediaUrl.trim().isEmpty)) {
        throw protocol.TalktiveException(
          message: 'Message cannot be empty',
          code: 'VALIDATION_ERROR',
        );
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
      final senderAvatar = sender.customAvatarUrl ?? sender.avatar;
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

      // 6. Check rate limiting (faster than database)
      final rateLimitError = await RateLimitService.checkRateLimit(
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

      // 7. Floor-based and Premium content restrictions
      final hasMedia =
          (imageUrl != null && imageUrl.isNotEmpty) ||
          (mediaUrl != null && mediaUrl.isNotEmpty);
      
      if (hasMedia) {
        // Plaza restrictions: images/media allowed only for Floor 2+
        if (channel.type == protocol.ChannelType.plaza && senderEffectiveFloor < 2) {
          throw protocol.TalktiveException(
            message: 'You must reach Floor 2 to send media in the Plaza.',
            code: 'FLOOR_RESTRICTION',
          );
        }

        // Voice message premium check
        if (mediaType == 'voice' && !sender.isPremium) {
          throw protocol.TalktiveException(
            message: 'Voice messages are a Premium feature. 🎙️ Upgrade in Settings!',
            code: 'PREMIUM_REQUIRED',
          );
        }
      }

      // 7.1. Privacy Check: Blocked status (Private Chats)
      if (channel.type == protocol.ChannelType.private) {
        final members = await protocol.ChannelMember.db.find(
          session,
          where: (t) => t.channelId.equals(channelId) & t.userInfoId.notEquals(senderUuid),
        );
        if (members.isNotEmpty) {
          final otherUserUuid = members.first.userInfoId;
          // Check if the other user has blocked the sender
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

      // 9.1 Update sender's lastReadAt to current time
      final senderMembership = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId) & t.userInfoId.equals(senderUuid),
      );
      if (senderMembership != null) {
        senderMembership.lastReadAt = savedMessage.createdAt;
        await protocol.ChannelMember.db.updateRow(session, senderMembership);
      }

      // 9.2 Update lastMessage denormalized fields (Bubbling up)
      if (channel.type != protocol.ChannelType.plaza) {
        await ChatService.updateLastMessage(
          session,
          channelId,
          channelType: channel.type,
          content: filteredContent,
          imageUrl: imageUrl,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        );
      }

      // 10. Distribute via Streaming (Real-time)
      final streamKey = 'channel_$channelId';
      await session.messages.postMessage(streamKey, savedMessage);

      // 10.1 Trigger Notifications (FCM / Activity Hub) - DO NOT AWAIT
      // We offload this to avoid blocking the sender's UI
      unawaited(_triggerNotifications(
        session,
        channel,
        savedMessage,
        sender,
      ).catchError((e) => session.log('Notification error: $e', level: LogLevel.error)));

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
      unawaited(GamificationService.trackMultipleProgress(
        session,
        sender.userInfoId,
        ['first_message', 'conversationalist', 'chatterbox'],
      ));

      // Secondary checks
      await GamificationService.checkTimeBasedAchievements(
        session,
        sender.userInfoId,
      );

      return savedMessage;
    } catch (e, stack) {
      session.log('FAILED to send message: $e', level: LogLevel.error);
      session.log(stack.toString(), level: LogLevel.error);
      rethrow;
    }
  }

  /// Subscribes to a channel to receive real-time updates (Messages, Typing, etc).
  Stream<SerializableModel> subscribe(Session session, int channelId) {
    final streamKey = 'channel_$channelId';
    return session.messages.createStream(streamKey);
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

    // Check membership for private/lounge channels
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

  /// Marks all messages in a channel as read for the current user.
  Future<void> markChannelAsRead(Session session, int channelId) async {
    final userUuid = await getUserId(session);

    // Find the membership record
    final membership = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) & t.userInfoId.equals(userUuid),
    );

    if (membership != null) {
      final now = DateTime.now();
      membership.lastReadAt = now;
      await protocol.ChannelMember.db.updateRow(session, membership);

      // Broadcast ReadReceiptEvent to other channel members
      await session.messages.postMessage(
        'channel_$channelId',
        protocol.ReadReceiptEvent(
          channelId: channelId,
          userId: userUuid,
          lastReadAt: now,
        ),
      );
    }
  }

  /// Sends a typing indicator to a channel.
  Future<void> sendTypingIndicator(
    Session session,
    int channelId,
    bool isTyping,
  ) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    await session.messages.postMessage(
      'channel_$channelId',
      protocol.TypingIndicator(
        channelId: channelId,
        senderId: userUuid,
        userName: resident.userName ?? 'Resident',
        isTyping: isTyping,
      ),
    );
  }

  /// Internal helper to trigger notifications in the background.
  Future<void> _triggerNotifications(
    Session session,
    protocol.Channel channel,
    protocol.Message message,
    protocol.Resident sender,
  ) async {
    final content = message.content;
    if (content == null || content.isEmpty) return;

    final channelId = channel.id!;
    final senderUuid = sender.userInfoId;
    final senderName = sender.userName ?? 'Resident';

    // 1. Detect mentions
    final mentionedUserIds = await MentionService.getMentionedUserIds(
      session,
      channelId,
      content,
    );

    // Remove sender
    mentionedUserIds.remove(senderUuid);

    final isPlaza = channel.type == protocol.ChannelType.plaza;
    final loungeName = channel.name ?? (isPlaza ? 'Plaza' : 'Chat');

    // 2. Notify mentions (Parallel)
    final mentionFutures = mentionedUserIds.map((mentionedId) =>
        NotificationService.sendMentionNotification(
          session,
          mentionedId,
          senderName,
          content,
          channelId,
          loungeName,
        ));

    // 3. Notify other members (Private/Lounge only)
    List<Future> memberFutures = [];
    if (!isPlaza) {
      final String channelTypeStr =
          channel.type == protocol.ChannelType.private ? 'private' : 'lounge';
      final mentionIdSet = mentionedUserIds.toSet();

      final otherMembers = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channelId) &
            t.userInfoId.notEquals(senderUuid) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      );

      for (final member in otherMembers) {
        if (member.isMuted || mentionIdSet.contains(member.userInfoId)) continue;
        
        // Check if the recipient has blocked the sender
        final isRecipientBlockingSender = await ResidentService.isBlocked(
          session,
          blockerId: member.userInfoId,
          blockedId: senderUuid,
        );
        if (isRecipientBlockingSender) continue;

        memberFutures.add(NotificationService.sendMessageNotification(
          session,
          member.userInfoId,
          senderName,
          content,
          channelId,
          channelTypeStr,
        ));
      }
    }

    // Run all notifications in parallel
    await Future.wait([...mentionFutures, ...memberFutures]);
  }
}
