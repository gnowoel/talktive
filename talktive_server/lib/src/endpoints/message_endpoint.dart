import 'dart:async';
import 'package:serverpod/serverpod.dart';
// Removed redundant Auth Server import
// Added UUID import
import 'package:talktive_server/src/generated/protocol.dart' as protocol;

import '../services/input_validation_service.dart';
import '../utils/endpoint_auth_mixin.dart';
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
    // 1. Auth & Resident Fetch
    final senderUuid = await getUserId(session);
    final sender = await getResidentProfile(session, senderUuid);

    // 2. Fetch Channel & Verify Access
    final channel = await ChannelService.getChannelWithAccess(
      session,
      channelId,
      senderUuid,
    );

    // 3. Send Message via Service
    return await MessagingService.sendMessage(
      session,
      sender: sender,
      channel: channel,
      content: content,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      duration: duration,
      fileSize: fileSize,
      isSystem: isSystem,
    );
  }

  /// Subscribes to a channel to receive real-time updates (Messages, Typing, etc).
  Stream<SerializableModel> subscribe(Session session, int channelId) async* {
    final resident = await getAuthenticatedResident(session);
    final streamKey = 'channel_$channelId';

    final canSeeTyping = ResidentService.canSeeOthersTypingIndicators(resident);
    final canSeeRead = ResidentService.canSeeOthersReadReceipts(resident);

    yield* session.messages.createStream(streamKey).where((event) {
      if (event is protocol.TypingIndicator) return canSeeTyping;
      if (event is protocol.ReadReceiptEvent) return canSeeRead;
      return true;
    }).cast<SerializableModel>();
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

    final userUuid = await getUserId(session);

    // 1. Fetch Channel & Verify Access (Plaza is public, Floor 0 is Floor 0)
    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      userUuid,
      allowInvited: true, // Allow fetching history for invited users
    );

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

    await ChannelService.sendTypingIndicator(
      session,
      channelId,
      userUuid,
      resident.userName ?? 'Resident',
      isTyping,
    );
  }

  /// Updates the persistence setting of a channel.
  Future<protocol.Channel> updateChannelPersistence(
    Session session,
    int channelId,
    bool isPersistent,
  ) async {
    final userUuid = await getUserId(session);
    final resident = await getResidentProfile(session, userUuid);

    if (!ResidentService.canKeepPrivateChats(resident)) {
      throw protocol.TalktiveException(
        message: 'Chat persistence is a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }

    // Verify membership for private/lounge channels
    await ChannelService.getChannelWithAccess(session, channelId, userUuid);

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
