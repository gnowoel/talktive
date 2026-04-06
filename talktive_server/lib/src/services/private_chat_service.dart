import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'messaging_service.dart';

/// Backward-compatible private chat service facade.
class PrivateChatService {
  static Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session, {
    required protocol.Resident sender,
    required UuidValue otherUserId,
    String? initialMessage,
  }) async {
    return await MessagingService.getOrCreatePrivateChat(
      session,
      sender: sender,
      otherUserId: otherUserId,
      initialMessage: initialMessage,
    );
  }

  static Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
    UuidValue userId,
  ) async {
    return await MessagingService.listPrivateChats(session, userId);
  }

  static Future<protocol.PrivateChatWithProfile?> getPrivateChatDetails(
    Session session,
    int channelId,
    UuidValue currentUserId,
  ) async {
    return await MessagingService.getPrivateChatDetails(
      session,
      channelId,
      currentUserId,
    );
  }

  static Future<void> respondToChatInvite(
    Session session,
    int channelId,
    UuidValue userId,
    bool accept,
  ) async {
    await MessagingService.respondToChatInvite(
      session,
      channelId,
      userId,
      accept,
    );
  }

  static Future<void> leaveChat(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    await MessagingService.leaveChat(session, channelId, userId);
  }
}
