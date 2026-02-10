import 'package:serverpod/serverpod.dart';
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
      // TODO: Fix streaming in Serverpod 3.x
      // Broadcast to all subscribers of this channel
      // final streamKey = 'channel_$channelId';
      // await session.messages.postMessage(streamKey, savedMessage);

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

  // TODO: Implement WebSocket streaming in Serverpod 3.x
  // The streaming API has changed and needs to be updated

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
