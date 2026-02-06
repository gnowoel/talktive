import 'package:serverpod/serverpod.dart' hide Message;
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
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
    final authenticationInfo = session.authenticated;
    final senderId = authenticationInfo?.userId;

    session.log(
      'sendMessage: Auth Info: $authenticationInfo, Sender ID: $senderId',
    );

    if (senderId == null) {
      session.log('sendMessage: User NOT authenticated');
      throw Exception('Not authenticated');
    }

    // 1. Fetch channel to verify access and type
    final channel = await Channel.db.findById(session, channelId);
    if (channel == null) {
      session.log('sendMessage: Channel $channelId not found');
      throw Exception('Channel not found');
    }

    // 2. Fetch sender resident data for floor checks
    final sender = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderId),
    );
    if (sender == null) {
      session.log('sendMessage: Resident not found for User $senderId');
      throw Exception('Resident not found');
    }

    // 3. Check for penalties (Muted)
    if (sender.creditScore < 0) {
      // Allow posting ONLY if recovering credit?
      // Requirement: "Grounded: Credit <= 0... cannot initiate private chats".
      // "Muted: Credit < 0... cannot send messages ANYWHERE."
      throw Exception('You are muted due to low credit score.');
    }

    // 4. Floor Validation (if Plaza)
    if (channel.type == ChannelType.plaza) {
      // Any specific plaza rules?
      // "Floor 0 (Plaza) ... Public space."
      // "Downstairs -> Upstairs: Forbidden." (This applies to inviting/visiting, but Plaza is Floor 0).
      // Everyone can speak in Plaza? User requirements implied Plaza is accessible.
    }

    // 5. Create Message
    final message = Message(
      channelId: channelId,
      senderId: senderId,
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
