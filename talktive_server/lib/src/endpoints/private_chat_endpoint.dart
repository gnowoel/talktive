import 'package:serverpod/serverpod.dart';
import 'package:collection/collection.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/gamification_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../services/chat_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../services/notification_service.dart';
import 'message_endpoint.dart';

class PrivateChatEndpoint extends Endpoint with EndpointAuthMixin {
  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session,
    String otherUserId, {
    String? initialMessage,
  }) async {
    InputValidationService.validateUuid(otherUserId).throwIfInvalid();
    final resident = await getAuthenticatedResident(session);

    return await ChatService.getOrCreatePrivateChat(
      session,
      sender: resident,
      otherUserId: UuidValue.fromString(otherUserId),
      initialMessage: initialMessage,
    );
  }

  /// Lists all private chats for the current user.
  /// Lists all private chats for the current user.
  Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
  ) async {
    final currentUserId = await getUserId(session);
    return await ChatService.listPrivateChats(session, currentUserId);
  }

  /// Gets details about a private chat including the other participant's info.
  /// Gets details about a private chat including the other participant's info.
  Future<protocol.PrivateChatWithProfile> getPrivateChatDetails(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    return await ChatService.getPrivateChatDetails(session, channelId, currentUserId);
  }

  /// Accepts or declines a private chat invitation
  /// Accepts or declines a private chat invitation
  Future<void> respondToChatInvite(
    Session session,
    int channelId,
    bool accept,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await ChatService.respondToChatInvite(session, channelId, currentUserId, accept);
  }

  /// Leaves a private chat.
  /// Leaves a private chat.
  Future<void> leaveChat(
    Session session,
    int channelId,
  ) async {
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    final currentUserId = await getUserId(session);
    await ChatService.leaveChat(session, channelId, currentUserId);
  }
}
