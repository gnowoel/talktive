import 'dart:async';
import 'package:serverpod/serverpod.dart';
// Removed redundant Auth Server import
// Added UUID import
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';

import '../services/input_validation_service.dart';
import '../services/mention_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../utils/task_utils.dart';
import '../services/notification_service.dart';
import '../services/resident_service.dart';
import '../services/channel_service.dart';
import '../services/messaging_service.dart';

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
      InputValidationService.validateId(
        channelId,
        'Channel ID',
      ).throwIfInvalid();

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
        InputValidationService.validateMessageContent(content).throwIfInvalid();
      }

      // Media & Voice Validation
      if (fileSize != null) {
        InputValidationService.validateFileSize(
          fileSize,
          fieldName: 'Media file',
        ).throwIfInvalid();
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
      final filteredContent = await MessagingService.validateMessage(
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

      final savedMessage = await protocol.Message.db.insertRow(
        session,
        message,
      );

      // 6. Handle side effects (async) - DON'T AWAIT (Run in background)
      TaskUtils.runBackground(session, (backgroundSession) async {
        // Send notifications (includes mentions, push, and lounge logic)
        final channel = await ChannelService.getChannel(
          backgroundSession,
          savedMessage.channelId,
        );
        if (channel != null) {
          await NotificationService.triggerMessageNotifications(
            backgroundSession,
            channel: channel,
            message: savedMessage,
            sender: sender,
          );

          // Side effects: Broadcast, Recents, Gamification
          await MessagingService.onMessageSaved(
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
    await ChannelService.markAsRead(session, channelId, userUuid);
  }

  /// Sends a typing indicator to a channel.
  Future<void> sendTypingIndicator(
    Session session,
    int channelId,
    bool isTyping,
  ) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    if (resident.showTypingIndicator) {
      await ChannelService.sendTypingIndicator(
        session,
        channelId,
        userUuid,
        resident.userName ?? 'Resident',
        isTyping,
      );
    }
  }

  /// Updates the persistence setting of a channel.
  Future<protocol.Channel> updateChannelPersistence(
    Session session,
    int channelId,
    bool isPersistent,
  ) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    if (!resident.isPremium) {
      throw protocol.TalktiveException(
        message: 'Chat persistence is a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }

    // Verify membership for private/lounge channels
    final channel = await ChannelService.getChannel(session, channelId);
    if (channel != null && channel.type != protocol.ChannelType.plaza) {
      final membership = await ChannelService.getMember(
        session,
        channelId,
        userUuid,
      );
      if (membership == null) {
        throw protocol.TalktiveException(
          message: 'Access denied: Not a member of this channel.',
          code: 'ACCESS_DENIED',
        );
      }
    }

    return await ChannelService.updatePersistence(
      session,
      channelId,
      isPersistent,
    );
  }

  /// Gets the currently pinned message for a channel.
  Future<protocol.Message?> getPinnedMessage(
    Session session,
    int channelId,
  ) async {
    return await protocol.Message.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId) & t.isPinned.equals(true),
    );
  }

  /// Pins a message to the top of its channel.
  Future<protocol.Message> pinMessage(Session session, int messageId) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    return await MessagingService.pinMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }

  /// Unpins a message.
  Future<protocol.Message> unpinMessage(Session session, int messageId) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    return await MessagingService.unpinMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }

  /// Recalls a message.
  Future<protocol.Message> recallMessage(Session session, int messageId) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    return await MessagingService.recallMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }
}
