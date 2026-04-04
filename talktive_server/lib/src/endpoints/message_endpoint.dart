import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/messaging_service.dart';
import '../services/channel_service.dart';
import '../services/input_validation_service.dart';
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
     Session session, {
     required int channelId,
     String? content,
     String? imageUrl,
     String? mediaUrl,
     String? mediaType,
     int? duration,
     int? fileSize,
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
     );
   }
 
   /// Lists message history for a channel.
   Future<List<protocol.Message>> listMessages(
     Session session,
     int channelId, {
     int? limit,
     int? offset,
     int? beforeId,
   }) async {
     InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
     final userId = await getUserId(session);
 
     await ChannelService.getChannelWithAccess(session, channelId, userId);
 
     return await protocol.Message.db.find(
       session,
       where: (t) =>
           (beforeId == null)
               ? t.channelId.equals(channelId)
               : t.channelId.equals(channelId) & (t.id < beforeId),
       orderBy: (t) => t.id,
       orderDescending: true,
       limit: limit ?? 50,
       offset: offset,
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
 
   /// Marks a channel as read for the current user.
   Future<void> markChannelAsRead(Session session, int channelId) async {
     final userId = await getUserId(session);
     await ChannelService.markAsRead(session, channelId, userId);
   }
 
   /// Updates channel-specific settings like persistence.
   Future<void> updateChannelPersistence(
     Session session,
     int channelId,
     bool isPersistent,
   ) async {
     final resident = await getAuthenticatedResident(session);
     await MessagingService.updatePersistence(
       session,
       resident: resident,
       channelId: channelId,
       isPersistent: isPersistent,
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
