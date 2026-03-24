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
    int? duration,
    int? fileSize,
    bool isSystem = false,
  }) async {
    try {
      // 1. Basic Input Validation
      InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
      
      final bool hasContent = content != null && content.trim().isNotEmpty;
      final bool hasImageUrl = imageUrl != null && imageUrl.trim().isNotEmpty;
      final bool hasMediaUrl = mediaUrl != null && mediaUrl.trim().isNotEmpty;
      final bool hasMedia = hasImageUrl || hasMediaUrl;

      if (!hasContent && !hasMedia) {
        throw protocol.TalktiveException(
          message: 'Message cannot be empty',
          code: 'VALIDATION_ERROR',
        );
      }

      if (hasContent) {
        InputValidationService.validateMessageContent(content!).throwIfInvalid();
      }

      // Media & Voice Validation
      if (fileSize != null) {
        InputValidationService.validateFileSize(fileSize, fieldName: 'Media file').throwIfInvalid();
      }

      if (mediaType == 'voice' && duration != null) {
        InputValidationService.validateVoiceDuration(duration).throwIfInvalid();
      }

      // 2. Auth & Resident Fetch
      final senderUuid = await getUserId(session);
      final sender = await getResidentProfile(session, senderUuid);

      // 3. Channel Fetch & Access Verification
      final channel = await protocol.Channel.db.findById(session, channelId);
      if (channel == null) {
        throw protocol.TalktiveException(
          message: 'Channel not found.',
          code: 'CHANNEL_NOT_FOUND',
        );
      }

      // 4. Detailed Validation (Mute, Floor, Filter, Privacy)
      final filteredContent = await ChatService.validateMessage(
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

      // 5. Create & Save Message
      final message = protocol.Message(
        channelId: channelId,
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

      final savedMessage = await protocol.Message.db.insertRow(session, message);

      // 6. Handle side effects (async) - DON'T AWAIT (Run in background)
      runBackground(session, (backgroundSession) async {
        // Send notifications (includes mentions, push, and lounge logic)
        final channel = await protocol.Channel.db.findById(backgroundSession, savedMessage.channelId);
        if (channel != null) {
          await _triggerNotifications(
            backgroundSession,
            channel,
            savedMessage,
            sender,
          );

          // Side effects: Broadcast, Recents, Gamification
          await ChatService.onMessageSaved(
            backgroundSession,
            message: savedMessage,
            channel: channel,
            sender: sender,
          );
        }
      });

      return savedMessage;
    } catch (e, stack) {
      session.log('FAILED to send message: $e', level: LogLevel.error);
      session.log(stack.toString(), level: LogLevel.error);
      rethrow;
    }
   }

  /// Subscribes to a channel to receive real-time updates (Messages, Typing, etc).
  Stream<SerializableModel> subscribe(Session session, int channelId) async* {
    await getUserId(session);
    final streamKey = 'channel_$channelId';
    yield* session.messages.createStream(streamKey);
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
      // Only broadcast if the user has opted in to sharing read receipts
      final resident = await getResidentProfile(session, userUuid);
      if (resident.showReadReceipts) {
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
  }

  /// Sends a typing indicator to a channel.
  Future<void> sendTypingIndicator(
    Session session,
    int channelId,
    bool isTyping,
  ) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    // Only broadcast if the user has opted in to sharing typing status
    if (resident.showTypingIndicator) {
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

    final isPlaza = channel.type == protocol.ChannelType.plaza;
    final channelId = channel.id!;
    final senderUuid = sender.userInfoId;
    final senderName = sender.userName ?? 'Resident';

    // 1. Resolve lounge once for all notifications
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

    // Remove sender
    mentionedUserIds.remove(senderUuid);

    final loungeName = channel.name ?? (isPlaza ? 'Plaza' : 'Chat');

    // 3. Notify mentions (Parallel)
    final mentionFutures = mentionedUserIds.map((mentionedId) =>
        NotificationService.sendMentionNotification(
          session,
          mentionedId,
          senderName,
          content,
          channelId,
          loungeName,
          loungeId: loungeId,
        ));

    // 4. Notify other members (Private/Lounge only)
    Future? bulkMemberFuture;
    if (!isPlaza) {
      final String channelTypeStr =
          channel.type == protocol.ChannelType.private ? 'private' : 'lounge';
      final mentionIdSet = mentionedUserIds.toSet();

      // Batch fetch users who have blocked the sender
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
        if (member.isMuted || mentionIdSet.contains(member.userInfoId)) continue;
        
        // Check if the recipient has blocked the sender (using fetched batch)
        if (blockedBySet.contains(member.userInfoId)) continue;

        recipientIds.add(member.userInfoId);
      }

      if (recipientIds.isNotEmpty) {
        bulkMemberFuture = NotificationService.sendBulkMessageNotifications(
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

    // Run all notifications in parallel
    await Future.wait([
      ...mentionFutures,
      if (bulkMemberFuture != null) bulkMemberFuture,
    ]);
  }

  /// Updates the persistence setting of a channel.
  Future<protocol.Channel> updateChannelPersistence(
    Session session,
    int channelId,
    bool isPersistent,
  ) async {
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    if (!resident.isPremium) {
      throw protocol.TalktiveException(
        message: 'Chat persistence is a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }

    // Verify membership for private/lounge channels
    if (channel.type != protocol.ChannelType.plaza) {
      final membership = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId) & t.userInfoId.equals(userUuid),
      );
      if (membership == null) {
        throw protocol.TalktiveException(
          message: 'Access denied: Not a member of this channel.',
          code: 'ACCESS_DENIED',
        );
      }
    }

    channel.isPersistent = isPersistent;
    return await protocol.Channel.db.updateRow(session, channel);
  }
}
