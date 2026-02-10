import 'package:serverpod/serverpod.dart';
import 'package:uuid/uuid.dart'; // Added UUID import
import '../generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/rate_limit_service.dart';

class MessageEndpoint extends Endpoint {
  /// Sends a message to a channel (Plaza, Group, or Private).
  Future<protocol.Message> sendMessage(
    Session session,
    int channelId,
    String content, {
    String? imageUrl,
  }) async {
    try {
      final authenticationInfo = session.authenticated;
      final senderIdentifier = authenticationInfo?.userIdentifier;

      if (senderIdentifier == null) {
        session.log('sendMessage: User NOT authenticated');
        throw Exception('Not authenticated');
      }

      final senderUuid = UuidValue.fromString(senderIdentifier);

      // 1. Fetch channel to verify access and type
      final channel = await protocol.Channel.db.findById(session, channelId);
      if (channel == null) {
        session.log('sendMessage: Channel $channelId not found');
        throw Exception('Channel not found');
      }

      // 2. Fetch sender resident data
      final sender = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(senderUuid),
      );
      if (sender == null) {
        session.log('sendMessage: Resident not found for User $senderUuid');
        throw Exception('Resident not found');
      }

      // 3. Check for penalties (Muted)
      if (sender.creditScore <= 0) {
        throw Exception(
          'You are muted due to low credit score. Your score will restore automatically over time.',
        );
      }

      // 4. Check rate limiting based on floor level
      final rateLimitError = await RateLimitService.checkRateLimit(
        session,
        sender,
        channelId,
      );
      if (rateLimitError != null) {
        throw Exception(rateLimitError);
      }

      // 5. Floor-based content restrictions
      if (channel.type == protocol.ChannelType.plaza) {
        // Plaza (floor 0) restrictions: no images allowed
        if (imageUrl != null && imageUrl.isNotEmpty) {
          throw Exception(
            'Images are not allowed in Plaza. Only text messages.',
          );
        }
      }

      // 6. Create Message
      final message = protocol.Message(
        channelId: channelId,
        senderId: sender.userInfoId, // Use Resident UserInfoId (UUID)
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // 7. Save Message
      final savedMessage = await protocol.Message.db.insertRow(
        session,
        message,
      );

      // 8. Distribute Message via Streaming
      // Broadcast to all subscribers of this channel using the new API
      final streamKey = 'channel_$channelId';
      session.messages.postMessage(streamKey, savedMessage);

      // 9. Update message count and award credit
      sender.experienceMessageCount += 1;
      await ApartmentService.awardMessageCredit(session, sender);

      return savedMessage;
    } catch (e, stack) {
      print('FAILED to send message: $e');
      print(stack);
      rethrow;
    }
  }

  /// Subscribes to a channel to receive real-time messages.
  Stream<protocol.Message> subscribe(Session session, int channelId) async* {
    final authenticationInfo = session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('Not authenticated');
    }

    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    // final channel = await protocol.Channel.db.findById(session, channelId); // Optimization: skip DB check for stream?
    // If we want to enforce rules, we should check.

    // 2. Create stream from message bus
    final streamKey = 'channel_$channelId';

    // session.messages.createStream returns a Stream of SerializableModel
    final stream = session.messages.createStream(streamKey);

    await for (final message in stream) {
      if (message is protocol.Message) {
        yield message;
      }
    }
  }

  /// Fetches the history of messages for a channel.
  Future<List<protocol.Message>> listMessages(
    Session session,
    int channelId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null) {
      throw Exception('Channel not found');
    }

    // TODO: Add membership check for private/group channels

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
}
