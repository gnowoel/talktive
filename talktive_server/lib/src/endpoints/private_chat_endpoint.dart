import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/input_validation_service.dart';
import '../services/private_chat_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class PrivateChatEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates or retrieves a private chat between two residents.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId, {
    String? initialMessage,
  }) async {
    InputValidationService.validateUuid(otherUserId).throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    return await PrivateChatService.getOrCreatePrivateChat(
      session,
      sender: resident,
      otherUserId: UuidValue.fromString(otherUserId),
      initialMessage: initialMessage,
    );
  }

  /// Lists all private chats for the current resident.
  Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
  ) async {
    final currentUserId = await getUserId(session);
    return await PrivateChatService.listPrivateChats(session, currentUserId);
  }

  /// Gets details about a private chat including the other participant.
  Future<protocol.PrivateChatWithProfile?> getPrivateChatDetails(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    return await PrivateChatService.getPrivateChatDetails(
      session,
      channelId,
      currentUserId,
    );
  }

  /// Accepts or declines a private chat invitation.
  Future<void> respondToChatInvite(
    Session session,
    int channelId,
    bool accept,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await PrivateChatService.respondToChatInvite(
      session,
      channelId,
      currentUserId,
      accept,
    );
  }

  /// Leaves a private chat.
  Future<void> leaveChat(Session session, int channelId) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await PrivateChatService.leaveChat(session, channelId, currentUserId);
  }
}
