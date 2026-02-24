import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:uuid/uuid.dart'; // Added UUID import
import '../generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/gamification_service.dart';
import '../services/rate_limit_service.dart';
import '../services/redis_rate_limit_service.dart';
import '../services/content_filter_service.dart';
import '../services/achievement_service.dart';
import '../services/streak_service.dart';
import '../services/input_validation_service.dart';

class MessageEndpoint extends Endpoint {
  /// Sends a message to a channel (Plaza, Group, or Private).
  Future<protocol.Message> sendMessage(
    Session session,
    int channelId,
    String content, {
    String? imageUrl,
  }) async {
    try {
      // Validate inputs
      InputValidationService.validateId(
        channelId,
        'Channel ID',
      ).throwIfInvalid();
      InputValidationService.validateMessageContent(content).throwIfInvalid();
      if (imageUrl != null) {
        InputValidationService.validateUrl(imageUrl).throwIfInvalid();
      }

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

      // Fetch UserInfo for denormalization
      final userInfo = await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.userIdentifier.equals(senderIdentifier),
      );

      final senderName = userInfo?.userName ?? 'Resident';
      final senderAvatar = userInfo?.imageUrl;

      // Compute effective floor (hybrid: min of XP level and trustScore tier)
      final senderEffectiveFloor = ApartmentService.computeEffectiveFloor(
        sender,
      );

      // Try to restore trustScore first (passive restoration)
      await ApartmentService.restoreTrustScore(session, sender);

      // 3. Check for penalties (Muted)
      if (ApartmentService.isMuted(sender)) {
        throw Exception(ApartmentService.getMuteReason(sender));
      }

      // 4. Validate content (profanity and spam filtering)
      final validation = await ContentFilterService.validateMessage(
        session,
        content,
        senderEffectiveFloor,
      );
      if (!validation.isValid) {
        throw Exception(validation.reason ?? 'Invalid message content');
      }

      // Check for repeated messages (spam detection)
      final isRepeated = await ContentFilterService.isRepeatedMessage(
        session,
        senderIdentifier,
        content,
      );
      if (isRepeated) {
        throw Exception('Please don\'t send the same message repeatedly');
      }

      // Use filtered content
      final filteredContent = validation.filteredContent ?? content;

      // 5. Check rate limiting with Redis (faster than database)
      final rateLimitError = await RedisRateLimitService.checkRateLimit(
        session,
        senderIdentifier,
        channelId,
        senderEffectiveFloor,
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

      // 6. Create Message with filtered content
      final message = protocol.Message(
        channelId: channelId,
        senderId: sender.userInfoId, // Use Resident UserInfoId (UUID)
        content: filteredContent, // Use filtered content instead of raw content
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        senderName: senderName,
        senderAvatar: senderAvatar,
        senderFloor: senderEffectiveFloor, // Use computed effective floor
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

      // 9. Award XP and update message count
      await GamificationService.awardXP(
        session,
        sender,
        GamificationService.XP_PER_MESSAGE,
        'Sent message',
      );
      sender.experienceMessageCount += 1;
      await GamificationService.updateMessageStreak(session, sender);

      // 10. Track achievements
      await AchievementService.trackProgress(
        session,
        sender.userInfoId,
        'first_message',
      );
      await AchievementService.trackProgress(
        session,
        sender.userInfoId,
        'conversationalist',
      );
      await AchievementService.trackProgress(
        session,
        sender.userInfoId,
        'chatterbox',
      );
      await AchievementService.checkTimeBasedAchievements(
        session,
        sender.userInfoId,
      );

      // 11. Update streak
      await StreakService.updateStreak(session, sender.userInfoId);

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
    // Validate inputs
    InputValidationService.validateId(channelId, 'Channel ID').throwIfInvalid();
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    // 1. Verify access (optional: check if user is member of channel)
    // For Plaza (floor 0), it's public. For others, check membership.
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null) {
      throw Exception('Channel not found');
    }

    // Check membership for private/group channels
    if (channel.type != protocol.ChannelType.plaza) {
      final userIdentifier = session.authenticated?.userIdentifier;
      if (userIdentifier == null) {
        throw Exception('Authentication required for private channels');
      }

      final userUuid = UuidValue.fromString(userIdentifier);

      // Check if user is a member of this channel
      // Fixed: use userInfoId instead of userId
      final membership = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(channelId) & t.userInfoId.equals(userUuid),
      );

      if (membership == null) {
        throw Exception('Access denied: Not a member of this channel');
      }

      // Check if membership is active
      if (membership.status != protocol.ChannelMemberStatus.joined) {
        throw Exception('Access denied: Membership is not active');
      }
    }

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
