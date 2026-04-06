import 'dart:async';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/channel_service.dart';
import '../services/input_validation_service.dart';
import '../services/messaging_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';

/// Unified endpoint for all Resident communication (Plaza, Lounges, Private).
class MessageEndpoint extends Endpoint with EndpointAuthMixin {
  @override
  bool get requireLogin => true;

  Future<String> ping(Session session) async {
    return 'pong';
  }

  // --- Messaging Actions ---

  /// Sends a message to a specific channel.
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
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    final channel = await ChannelService.getChannelWithAccess(
      session,
      channelId,
      resident.userInfoId,
    );

    return await MessagingService.sendMessage(
      session,
      sender: resident,
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

  /// Subscribes to a channel to receive live updates.
  Stream<SerializableModel> subscribe(Session session, int channelId) async* {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      resident.userInfoId,
      allowInvited: true,
    );

    final canSeeTyping = ResidentService.canSeeOthersTypingIndicators(resident);
    final canSeeRead = ResidentService.canSeeOthersReadReceipts(resident);
    final blockedIds = await ResidentService.getBlocksByUser(
      session,
      resident.userInfoId,
    );
    final streamKey = 'channel_$channelId';

    yield* session.messages.createStream(streamKey).where((event) {
      if (event is protocol.Message && blockedIds.contains(event.senderId)) {
        return false;
      }
      if (event is protocol.TypingIndicator) {
        if (blockedIds.contains(event.senderId)) return false;
        return canSeeTyping;
      }
      if (event is protocol.ReadReceiptEvent) {
        if (blockedIds.contains(event.userId)) return false;
        return canSeeRead;
      }
      return true;
    }).cast<SerializableModel>();
  }

  /// Lists message history for a channel.
  Future<List<protocol.Message>> listMessages(
    Session session,
    int channelId, {
    int limit = 50,
    int offset = 0,
    int? beforeId,
  }) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    final userId = await getUserId(session);

    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      userId,
      allowInvited: true,
    );

    final blockedIds = await ResidentService.getBlocksByUser(session, userId);

    return await protocol.Message.db.find(
      session,
      where: (t) {
        var filter = t.channelId.equals(channelId);
        if (beforeId != null) {
          filter &= (t.id < beforeId);
        }
        if (blockedIds.isNotEmpty) {
          filter &= t.senderId.notInSet(blockedIds);
        }
        return filter;
      },
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Marks all messages in a channel as read for the current resident.
  Future<void> markChannelAsRead(Session session, int channelId) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final userId = await getUserId(session);
    await ChannelService.markAsRead(session, channelId, userId);
  }

  /// Sends a typing indicator to a channel.
  Future<void> sendTypingIndicator(
    Session session,
    int channelId,
    bool isTyping,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      resident.userInfoId,
      allowInvited: true,
    );

    await ChannelService.sendTypingIndicator(
      session,
      channelId,
      resident.userInfoId,
      resident.userName ?? 'Resident',
      isTyping,
    );
  }

  /// Updates channel-specific settings like persistence.
  Future<protocol.Channel> updateChannelPersistence(
    Session session,
    int channelId,
    bool isPersistent,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      resident.userInfoId,
    );

    await MessagingService.updatePersistence(
      session,
      resident: resident,
      channelId: channelId,
      isPersistent: isPersistent,
    );

    return (await ChannelService.getChannel(session, channelId))!;
  }

  /// Gets the currently pinned message for a channel.
  Future<protocol.Message?> getPinnedMessage(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final userId = await getUserId(session);

    await ChannelService.getChannelWithAccess(
      session,
      channelId,
      userId,
      allowInvited: true,
    );

    return await protocol.Message.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId) & t.isPinned.equals(true),
    );
  }

  /// Pins a message in a channel.
  Future<protocol.Message> pinMessage(Session session, int messageId) async {
    final resident = await getAuthenticatedResident(session);
    return await MessagingService.pinMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }

  /// Unpins a message.
  Future<protocol.Message> unpinMessage(Session session, int messageId) async {
    final resident = await getAuthenticatedResident(session);
    return await MessagingService.unpinMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }

  /// Recalls (deletes) a message.
  Future<protocol.Message> recallMessage(Session session, int messageId) async {
    final resident = await getAuthenticatedResident(session);
    return await MessagingService.recallMessage(
      session,
      messageId: messageId,
      resident: resident,
    );
  }

  // --- 1:1 Private Chat Operations ---

  /// Starts or resumes a 1:1 chat session.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId, {
    String? initialMessage,
  }) async {
    InputValidationService.validateUuid(otherUserId).throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    return await MessagingService.getOrCreatePrivateChat(
      session,
      sender: resident,
      otherUserId: UuidValue.fromString(otherUserId),
      initialMessage: initialMessage,
    );
  }

  /// Lists all private chats (Peep-hole preview mode enabled).
  Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
  ) async {
    final currentUserId = await getUserId(session);
    return await MessagingService.listPrivateChats(session, currentUserId);
  }

  /// Gets details about a private chat including the other participant.
  Future<protocol.PrivateChatWithProfile?> getPrivateChatDetails(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    return await MessagingService.getPrivateChatDetails(
      session,
      channelId,
      currentUserId,
    );
  }

  /// Responds to a knock/invite.
  Future<void> respondToChatInvite(
    Session session,
    int channelId,
    bool accept,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await MessagingService.respondToChatInvite(
      session,
      channelId,
      currentUserId,
      accept,
    );
  }

  /// Leaves a private thread.
  Future<void> leaveChat(Session session, int channelId) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await MessagingService.leaveChat(session, channelId, currentUserId);
  }
}
