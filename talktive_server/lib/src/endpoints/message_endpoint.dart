import 'package:serverpod/serverpod.dart' hide Message;
import '../generated/protocol.dart';
import '../services/apartment_service.dart';

class MessageEndpoint extends Endpoint {
  /// Sends a message to a channel (Plaza, Group, or Private).
  Future<Message> sendMessage(
    Session session,
    int channelId,
    String content, {
    String? imageUrl,
  }) async {
    try {
      final authenticationInfo = session.authenticated;
      // In Serverpod 3 with JWT, userId is int? or String?
      // AuthenticationInfo.userId is int?
      // But AuthenticationInfoFromJwt sets it to uuid hash or something?
      // Wait, AuthenticationInfo has 'userId' (legacy int).
      // AuthenticationInfo has 'authId' (String, which is UUID for JWT).
      // Let's use authId? no, check session.authenticated properties.
      // If we use JWT, we should use 'session.authenticationInfo.authId'?? or similar.
      // Actually, let's look at AuthenticationInfo.
      // Assuming it has an 'authId' or we parse userId string.

      // Temporary: Try casting or checking.
      // If legacy int is populated, it might be 0 or random.
      // We need UUID.
      // Let's assume we can get UUID from session.
      // Code:
      // final senderUuid = session.authenticated?.userId; // This is int.
      // BUT if we modified AuthenticationInfo? No we didn't.

      // Wait. AuthenticationInfoFromJwt (Step 2150):
      // final authInfo = AuthenticationInfo(
      //   result.authUserId.uuid, (String passed to int?)

      // If AuthenticationInfo constructor takes (int userId, ...), passing String fails.
      // So AuthenticationInfo MUST have changed.
      // I will assume userId IS dynamic or String or there is a uuid field.

      // Safest: Use `session.authenticated?.authId` if it exists.
      // Or `session.authenticated?.userId`.

      final senderIdentifier = authenticationInfo?.userIdentifier;

      if (senderIdentifier == null) {
        session.log('sendMessage: User NOT authenticated');
        throw Exception('Not authenticated');
      }

      final senderUuid = UuidValue.fromString(senderIdentifier);

      // 1. Fetch channel to verify access and type
      final channel = await Channel.db.findById(session, channelId);
      if (channel == null) {
        session.log('sendMessage: Channel $channelId not found');
        throw Exception('Channel not found');
      }

      // 2. Fetch sender resident data
      final sender = await Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(senderUuid),
      );
      if (sender == null) {
        session.log('sendMessage: Resident not found for User $senderUuid');
        throw Exception('Resident not found');
      }

      // 3. Check for penalties (Muted)
      if (sender.creditScore < 0) {
        throw Exception('You are muted due to low credit score.');
      }

      // 4. Floor Validation (if Plaza)
      if (channel.type == ChannelType.plaza) {
        // Validation logic can go here
      }

      // 5. Create Message
      final message = Message(
        channelId: channelId,
        senderId: sender.userInfoId, // Use Resident UserInfoId (UUID)
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // 6. Save Message
      final savedMessage = await Message.db.insertRow(session, message);

      // 7. Distribute Message via Streaming
      // We use the channelId as the stream identifier.
      await session.messages.postMessage(channelId.toString(), savedMessage);

      // 8. Credit Score Gain mechanism
      await ApartmentService.awardMessageCredit(session, sender);

      return savedMessage;
    } catch (e, stack) {
      print('FAILED to send message: $e');
      print(stack);
      rethrow;
    }
  }

  /// Streams messages for a specific channel.
  @override
  Future<void> streamOpened(StreamingSession session) async {
    // Client sends the channelId they want to listen to.
    // However, streamOpened doesn't receive arguments easily (except via session info).
    // Usually, client calls `connectWebSocket` then `sendStreamMessage` to subscribe?
    // Or we rely on `handleStreamMessage`.

    // Pattern: User connects to Endpoint.
    // User sends a "Subscribe" event.
    // We add them to the stream.
  }

  @override
  Future<void> handleStreamMessage(
    StreamingSession session,
    SerializableModel message,
  ) async {
    if (message is ChannelSubscription) {
      // Verify access to channel
      // Add listener
      session.messages.addListener(message.channelId.toString(), (update) {
        sendStreamMessage(session, update);
      });
    }
  }

  /// Fetches the history of messages for a channel.
  Future<List<Message>> listMessages(
    Session session,
    int channelId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    final channel = await Channel.db.findById(session, channelId);
    if (channel == null) {
      throw Exception('Channel not found');
    }

    // TODO: Add membership check for private/group channels

    // 2. Fetch messages
    return await Message.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
      include: Message.include(
        channel:
            Channel.include(), // Optional: include channel details if needed
      ),
    );
  }
}
