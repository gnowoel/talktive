import 'dart:async';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:collection/collection.dart';
import 'apartment_service.dart';
import 'resident_service.dart';
import 'gamification_service.dart';
import 'notification_service.dart';
import 'content_filter_service.dart';
import 'input_validation_service.dart';
import 'rate_limit_service.dart';

class ChatService {
  /// Creates or retrieves a private chat between two users.
  /// Handles validation, re-inviting, and optional initial message.
  static Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session, {
    required protocol.Resident sender,
    required UuidValue otherUserId,
    String? initialMessage,
  }) async {
    final currentUserId = sender.userInfoId;

    // Ensure we don't create a chat with ourselves
    if (currentUserId == otherUserId) {
      throw protocol.TalktiveException(
        message: 'Cannot create private chat with yourself.',
        code: 'SELF_CHAT_NOT_ALLOWED',
      );
    }

    // Fetch the other resident
    final otherResident = await ResidentService.getResident(session, otherUserId);
    if (otherResident == null) {
      throw protocol.TalktiveException(
        message: 'Resident not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }

    // Safety: Check floor restrictions
    if (!ApartmentService.canInvite(
      sender: sender,
      receiver: otherResident,
    )) {
      throw protocol.TalktiveException(
        message: ApartmentService.cannotInviteReason(
          sender: sender,
          receiver: otherResident,
        ),
        code: 'INVITE_RESTRICTED',
      );
    }

    // Safety: Check blocking (both ways)
    if (await ResidentService.isBlocked(
      session,
      blockerId: currentUserId,
      blockedId: otherUserId,
    )) {
      throw protocol.TalktiveException(
        message: 'You have blocked this resident.',
        code: 'USER_BLOCKED',
      );
    }

    if (await ResidentService.isBlocked(
      session,
      blockerId: otherUserId,
      blockedId: currentUserId,
    )) {
      throw protocol.TalktiveException(
        message: 'This resident has restricted their messages.',
        code: 'BLOCKED_BY_USER',
      );
    }

    // Order participants consistently (smaller UUID first) to avoid duplicates
    final participant1 = currentUserId.uuid.compareTo(otherUserId.uuid) < 0
        ? currentUserId
        : otherUserId;
    final participant2 = currentUserId.uuid.compareTo(otherUserId.uuid) < 0
        ? otherUserId
        : currentUserId;

    // Check if private chat already exists
    var privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) =>
          t.participant1Id.equals(participant1) &
          t.participant2Id.equals(participant2),
    );

    bool isCurrentlyInvited = false;
    bool wasJustInvited = false;

    if (privateChat != null) {
      // Handle re-inviting if either member had left or declined
      var currentMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(privateChat!.channelId) &
            t.userInfoId.equals(currentUserId),
      );
      var otherMember = await protocol.ChannelMember.db.findFirstRow(
        session,
        where: (t) =>
            t.channelId.equals(privateChat!.channelId) &
            t.userInfoId.equals(otherUserId),
      );

      if (currentMember != null &&
          (currentMember.status == protocol.ChannelMemberStatus.left ||
              currentMember.status == protocol.ChannelMemberStatus.declined)) {
        currentMember.status = protocol.ChannelMemberStatus.joined;
        await protocol.ChannelMember.db.updateRow(session, currentMember);
      }

      if (otherMember != null) {
        if (otherMember.status == protocol.ChannelMemberStatus.invited) {
          isCurrentlyInvited = true;
        } else if (otherMember.status == protocol.ChannelMemberStatus.left ||
            otherMember.status == protocol.ChannelMemberStatus.declined) {
          otherMember.status = protocol.ChannelMemberStatus.invited;
          otherMember.invitedBy = currentUserId;
          await protocol.ChannelMember.db.updateRow(session, otherMember);
          wasJustInvited = true;
        }
      }
    } else {
      // Create a new channel for this private chat
      final channel = protocol.Channel(
        name: 'Private Chat',
        type: protocol.ChannelType.private,
        createdAt: DateTime.now(),
      );

      final savedChannel = await protocol.Channel.db.insertRow(
        session,
        channel,
      );

      // Create the private chat record
      privateChat = protocol.PrivateChat(
        channelId: savedChannel.id!,
        participant1Id: participant1,
        participant2Id: participant2,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      privateChat = await protocol.PrivateChat.db.insertRow(
        session,
        privateChat,
      );

      // Add both users as channel members
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: savedChannel.id!,
          userInfoId: currentUserId,
          status: protocol.ChannelMemberStatus.joined,
          joinedAt: DateTime.now(),
          role: 'owner',
        ),
      );

      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: savedChannel.id!,
          userInfoId: otherUserId,
          status: protocol.ChannelMemberStatus.invited,
          invitedBy: currentUserId,
          joinedAt: DateTime.now(),
          role: 'member',
        ),
      );

      // Track achievement for starting a private chat
      await GamificationService.trackProgress(
        session,
        currentUserId,
        'private_chat',
      );

      wasJustInvited = true;
    }

    if (wasJustInvited) {
      // Notify the recipient of the doorbell knock
      try {
        await NotificationService.sendChatInviteNotification(
          session,
          otherUserId,
          sender.userName ?? 'Someone',
          privateChat.channelId,
        );
      } catch (e) {
        session.log('Failed to send chat invite notification: $e', level: LogLevel.error);
      }
    }

    // Handle initial optional message
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      try {
        final channel = await protocol.Channel.db.findById(session, privateChat.channelId);
        if (channel != null) {
          if (isCurrentlyInvited && !wasJustInvited) {
            // Re-knocking: Overwrite our last message instead of spamming.
            var lastMessageRows = await protocol.Message.db.find(
              session,
              where: (t) =>
                  t.channelId.equals(privateChat!.channelId) &
                  t.senderId.equals(currentUserId),
              orderBy: (t) => t.createdAt,
              orderDescending: true,
              limit: 1,
            );

            if (lastMessageRows.isNotEmpty) {
              var lastMessage = lastMessageRows.first;
              lastMessage.content = initialMessage;
              await protocol.Message.db.updateRow(session, lastMessage);
              
              // Broadcast update
              await session.messages.postMessage('channel_${channel.id}', lastMessage);
            } else {
              await _sendInitialMessage(session, sender, channel, initialMessage);
            }
          } else {
            // New invite or already joined/re-invited
            await _sendInitialMessage(session, sender, channel, initialMessage);
          }
        }
      } catch (e) {
        session.log('Warning: Failed to send initial message: $e', level: LogLevel.warning);
      }
    }

    return privateChat;
  }

  /// Internal helper to send the first message in a chat without full endpoint overhead.
  static Future<void> _sendInitialMessage(
    Session session,
    protocol.Resident sender,
    protocol.Channel channel,
    String content,
  ) async {
    // Basic validation
    final filteredContent = await validateMessage(
      session,
      sender: sender,
      channel: channel,
      content: content,
    );

    // Save message
    final message = protocol.Message(
      channelId: channel.id!,
      senderId: sender.userInfoId,
      senderName: sender.userName ?? 'Anonymous',
      senderAvatar: sender.customAvatarUrl ?? sender.avatar,
      senderFloor: ApartmentService.computeEffectiveFloor(sender),
      senderTrustScore: sender.trustScore,
      isSystem: false,
      content: filteredContent ?? content,
      createdAt: DateTime.now(),
    );

    final savedMessage = await protocol.Message.db.insertRow(session, message);

    // Handle post-save (broadcast, XP, etc.)
    await onMessageSaved(
      session,
      message: savedMessage,
      channel: channel,
      sender: sender,
    );
  }

  static Future<void> blockUser(
    Session session,
    UuidValue blockerId,
    UuidValue blockedId,
  ) async {
    await protocol.Block.db.insertRow(
      session,
      protocol.Block(
        blockerId: blockerId,
        blockedId: blockedId,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<int> getUnreadCount(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    final counts = await batchGetUnreadCounts(session, [channelId], userId);
    return counts[channelId] ?? 0;
  }

  static Future<Map<int, int>> batchGetUnreadCounts(
    Session session,
    List<int> channelIds,
    UuidValue userId,
  ) async {
    if (channelIds.isEmpty) return {};

    // 1. Get the membership records to find lastReadAt
    final memberships = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.inSet(channelIds.toSet()) & t.userInfoId.equals(userId),
    );

    if (memberships.isEmpty) return {};

    final result = <int, int>{};
    
    // We use a raw query here to avoid N+1 count calls.
    // Joining message and channel_member lets us filter messages per channel 
    // against EACH channel's lastReadAt in a single database round-trip.
    final sql = '''
      SELECT m."channelId", COUNT(m.id)
      FROM "message" m
      INNER JOIN "channel_member" cm ON m."channelId" = cm."channelId"
      WHERE m."channelId" IN (${channelIds.join(',')})
      AND cm."userInfoId" = '$userId'
      AND (cm."lastReadAt" IS NULL OR m."createdAt" > cm."lastReadAt")
      AND m."senderId" != '$userId'
      GROUP BY m."channelId"
    ''';

    try {
      final unreadCounts = await session.db.unsafeQuery(sql);
      for (final row in unreadCounts) {
        if (row.length >= 2) {
          result[row[0] as int] = row[1] as int;
        }
      }
    } catch (e) {
      session.log('Error executing batch unread counts query: $e', level: LogLevel.error);
      // Fallback for safety (though not efficient, prevents total failure)
      for (final channelId in channelIds) {
        result[channelId] = 0;
      }
    }

    return result;
  }

  /// Updates the denormalized 'last message' fields for a channel.
  static Future<void> updateLastMessage(
    Session session,
    int channelId, {
    required protocol.ChannelType channelType,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final now = DateTime.now();

    // Determine the preview text
    String? previewText;
    if (content != null && content.trim().isNotEmpty) {
      previewText = content.trim();
      // Truncate if too long (good for DB index performance)
      if (previewText.length > 100) {
        previewText = '${previewText.substring(0, 97)}...';
      }
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      previewText = '📷 Photo';
    } else if (mediaType == 'voice') {
      previewText = '🎙️ Voice message';
    } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
      previewText = '🎥 Video';
    }

    if (channelType == protocol.ChannelType.private) {
      final privateChat = await protocol.PrivateChat.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (privateChat != null) {
        privateChat.lastMessageAt = now;
        privateChat.lastMessage = previewText;
        await protocol.PrivateChat.db.updateRow(session, privateChat);
      }
    } else if (channelType == protocol.ChannelType.lounge) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      if (lounge != null) {
        lounge.lastMessageAt = now;
        lounge.lastMessage = previewText;
        await protocol.Lounge.db.updateRow(session, lounge);
      }
    }
  }

  /// Validates a message before it is saved.
  /// Checks safety (muted/suspended), content filtering, rate limiting, and floor rules.
  /// Throws [protocol.TalktiveException] if invalid.
  static Future<String?> validateMessage(
    Session session, {
    required protocol.Resident sender,
    required protocol.Channel channel,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
  }) async {
    final senderUuid = sender.userInfoId;
    final senderEffectiveFloor = ApartmentService.computeEffectiveFloor(sender);

    // 1. Safety Checks (Muted / Suspended)
    if (ApartmentService.isMuted(sender)) {
      throw protocol.TalktiveException(
        message: ApartmentService.getMuteReason(sender),
        code: 'USER_MUTED',
      );
    }

    // 2. Basic Input Validation (Length/Size/Duration)
    if (content != null && content.isNotEmpty) {
      InputValidationService.validateMessageContent(content).throwIfInvalid();
    }

    if (fileSize != null) {
      InputValidationService.validateFileSize(fileSize, fieldName: 'Media file')
          .throwIfInvalid();
    }

    if (mediaType == 'voice' && duration != null) {
      InputValidationService.validateVoiceDuration(duration).throwIfInvalid();
    }

    // 3. Content Validation (profanity and spam filtering)
    String? filteredContent = content;
    if (content != null && content.isNotEmpty) {
      final validation = await ContentFilterService.validateMessage(
        session,
        content,
        senderEffectiveFloor,
      );
      if (!validation.isValid) {
        throw protocol.TalktiveException(
          message: validation.reason ?? 'Invalid message content',
          code: 'CONTENT_FILTER_FAIL',
        );
      }

      // Check for repeated messages (spam detection)
      final isRepeated = await ContentFilterService.isRepeatedMessage(
        session,
        senderUuid.toString(),
        content,
      );
      if (isRepeated) {
        throw protocol.TalktiveException(
          message: 'Please don\'t send the same message repeatedly',
          code: 'SPAM_DETECTED',
        );
      }

      filteredContent = validation.filteredContent ?? content;
    }

    // 4. Check rate limiting
    final rateLimitError = await RateLimitService.checkRateLimit(
      session,
      senderUuid.toString(),
      channel.id!,
      senderEffectiveFloor,
    );
    if (rateLimitError != null) {
      throw protocol.TalktiveException(
        message: rateLimitError,
        code: 'RATE_LIMIT_EXCEEDED',
      );
    }

    // 5. Floor-based and Premium content restrictions
    final hasMedia = (imageUrl != null && imageUrl.isNotEmpty) ||
        (mediaUrl != null && mediaUrl.isNotEmpty);

    if (hasMedia) {
      // Plaza restrictions: images/media allowed only for Floor 2+
      if (channel.type == protocol.ChannelType.plaza &&
          senderEffectiveFloor < 2) {
        throw protocol.TalktiveException(
          message: 'You must reach Floor 2 to send media in the Plaza.',
          code: 'FLOOR_RESTRICTION',
        );
      }

      // Voice message premium check
      if (mediaType == 'voice' && !sender.isPremium) {
        throw protocol.TalktiveException(
          message:
              'Voice messages are a Premium feature. 🎙️ Upgrade in Settings!',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    // 6. Privacy Check: Blocked status (Private Chats)
    if (channel.type == protocol.ChannelType.private) {
      final members = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channel.id!) & t.userInfoId.notEquals(senderUuid),
      );
      if (members.isNotEmpty) {
        final otherUserUuid = members.first.userInfoId;
        // Check if the other user has blocked the sender
        final isBlocked = await ResidentService.isBlocked(
          session,
          blockerId: otherUserUuid,
          blockedId: senderUuid,
        );
        if (isBlocked) {
          throw protocol.TalktiveException(
            message:
                'Message not delivered. You are currently restricted by this resident.',
            code: 'PRIVACY_RESTRICTED',
          );
        }
      }
    }

    return filteredContent;
  }

  /// Handles all post-message-save operations: broadcasts, notifications, gamification.
  static Future<void> onMessageSaved(
    Session session, {
    required protocol.Message message,
    required protocol.Channel channel,
    required protocol.Resident sender,
  }) async {
    final senderUuid = sender.userInfoId;
    final channelId = channel.id!;

    // 1. Update sender's lastReadAt
    final senderMembership = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) & t.userInfoId.equals(senderUuid),
    );
    if (senderMembership != null) {
      senderMembership.lastReadAt = message.createdAt;
      await protocol.ChannelMember.db.updateRow(session, senderMembership);
    }

    // 2. Update denormalized last message fields
    if (channel.type != protocol.ChannelType.plaza) {
      await updateLastMessage(
        session,
        channelId,
        channelType: channel.type,
        content: message.content,
        imageUrl: message.imageUrl,
        mediaUrl: message.mediaUrl,
        mediaType: message.mediaType,
      );
    }

    // 3. Broadcast real-time message
    await session.messages.postMessage('channel_$channelId', message);

    // 4. Trigger Notifications & Gamification in background (don't block the response)
    // Note: We don't use unawaited here because we want to call them systematically.
    // The endpoint will handle the response.

    // XP & Streaks
    await GamificationService.awardXP(
      session,
      sender,
      GamificationService.XP_PER_MESSAGE,
      'Sent message',
      save: false,
    );
    sender.experienceMessageCount += 1;
    await GamificationService.updateMessageStreak(
      session,
      sender,
      save: false,
    );
    await protocol.Resident.db.updateRow(session, sender);

    // Achievement Progress
    unawaited(GamificationService.trackMultipleProgress(
      session,
      senderUuid,
      ['first_message', 'conversationalist', 'chatterbox'],
    ));

    // Time-based achievements
    await GamificationService.checkTimeBasedAchievements(session, senderUuid);
  }
  /// Lists all private chats for the given user, including profiles and metadata.
  static Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
    UuidValue userId,
  ) async {
    // Find all private chats where user is a participant
    final chats = await protocol.PrivateChat.db.find(
      session,
      where: (t) =>
          t.participant1Id.equals(userId) |
          t.participant2Id.equals(userId),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );
    
    if (chats.isEmpty) return [];

    final result = <protocol.PrivateChatWithProfile>[];
    final channelIds = chats.map((c) => c.channelId).toList();
    
    // Batch fetch related data: Members, Unread Counts, Channels
    final results = await Future.wait([
      protocol.ChannelMember.db.find(
        session,
        where: (t) => t.channelId.inSet(channelIds.toSet()),
      ),
      batchGetUnreadCounts(session, channelIds, userId),
      protocol.Channel.db.find(
        session,
        where: (t) => t.id.inSet(channelIds.toSet()),
      ),
    ]);

    final allMembers = results[0] as List<protocol.ChannelMember>;
    final unreadCounts = results[1] as Map<int, int>;
    final channels = results[2] as List<protocol.Channel>;
    
    final channelMap = {for (var c in channels) c.id: c};
    final membersByChannel = <int, List<protocol.ChannelMember>>{};
    for (var m in allMembers) {
      membersByChannel.putIfAbsent(m.channelId, () => []).add(m);
    }

    // Identify other user IDs for batch fetching residents
    final otherUserIds = <UuidValue>{};
    for (final chat in chats) {
      final otherId = chat.participant1Id.uuid == userId.uuid
          ? chat.participant2Id
          : chat.participant1Id;
      otherUserIds.add(otherId);
    }

    final residents = await ResidentService.getResidents(session, otherUserIds.toList());
    final residentsMap = {for (var r in residents) r.userInfoId: r};

    // UserInfo fallback for display names
    final userInfos = await UserInfo.db.find(
      session,
      where: (t) => t.userIdentifier.inSet(otherUserIds.map((id) => id.toString()).toSet()),
    );
    final userInfoMap = {for (var u in userInfos) u.userIdentifier: u};

    for (final chat in chats) {
      final otherId = chat.participant1Id.uuid == userId.uuid
          ? chat.participant2Id
          : chat.participant1Id;

      final members = membersByChannel[chat.channelId] ?? [];
      final currentMember = members.firstWhereOrNull((m) => m.userInfoId == userId);
      final otherMember = members.firstWhereOrNull((m) => m.userInfoId == otherId);

      // Skip left/declined chats for the listing
      if (currentMember != null &&
          (currentMember.status == protocol.ChannelMemberStatus.left ||
              currentMember.status == protocol.ChannelMemberStatus.declined)) {
        continue;
      }

      final otherResident = residentsMap[otherId];
      if (otherResident != null) {
        final userInfo = userInfoMap[otherId.toString()];

        result.add(
          protocol.PrivateChatWithProfile(
            chat: chat,
            otherResident: otherResident,
            otherUserName: otherResident.userName ?? userInfo?.userName,
            otherUserAvatar: otherResident.customAvatarUrl ?? otherResident.avatar ?? userInfo?.imageUrl,
            otherUserMood: otherResident.mood,
            currentMemberStatus: currentMember?.status,
            otherMemberStatus: otherMember?.status,
            otherUserLastReadAt: otherResident.showReadReceipts ? otherMember?.lastReadAt : null,
            unreadCount: unreadCounts[chat.channelId] ?? 0,
            channel: channelMap[chat.channelId],
          ),
        );
      }
    }

    return result;
  }

  /// Gets full details for a specific private chat.
  static Future<protocol.PrivateChatWithProfile> getPrivateChatDetails(
    Session session,
    int channelId,
    UuidValue currentUserId,
  ) async {
    final privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (privateChat == null) {
      throw protocol.TalktiveException(
        message: 'Private chat not found.',
        code: 'CHAT_NOT_FOUND',
      );
    }

    // Security check
    if (privateChat.participant1Id != currentUserId &&
        privateChat.participant2Id != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Access denied: Not a participant.',
        code: 'ACCESS_DENIED',
      );
    }

    final otherUserId = privateChat.participant1Id == currentUserId
        ? privateChat.participant2Id
        : privateChat.participant1Id;

    final otherResident = await ResidentService.getResidentProfileView(
      session,
      otherUserId,
      viewerId: currentUserId,
    );

    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    final currentMember = members.firstWhereOrNull((m) => m.userInfoId == currentUserId);
    final otherMember = members.firstWhereOrNull((m) => m.userInfoId == otherUserId);
    final channel = await protocol.Channel.db.findById(session, channelId);

    // Note: getResidentProfileView returns a different type, but we extract what we need
    final resident = await protocol.Resident.db.findFirstRow(session, where: (t) => t.userInfoId.equals(otherUserId));
    if (resident == null) {
      throw protocol.TalktiveException(
        message: 'Other resident profile not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }

    return protocol.PrivateChatWithProfile(
      chat: privateChat,
      otherResident: resident,
      otherUserName: resident?.userName,
      otherUserAvatar: resident?.customAvatarUrl ?? resident?.avatar,
      otherUserMood: resident?.mood,
      currentMemberStatus: currentMember?.status,
      otherMemberStatus: otherMember?.status,
      otherUserLastReadAt: (resident?.showReadReceipts ?? true) ? otherMember?.lastReadAt : null,
      unreadCount: await getUnreadCount(session, channelId, currentUserId),
      channel: channel,
    );
  }

  /// Responds to a private chat invitation (accept/decline).
  static Future<void> respondToChatInvite(
    Session session,
    int channelId,
    UuidValue userId,
    bool accept,
  ) async {
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) & t.userInfoId.equals(userId),
    );

    if (member == null || member.status != protocol.ChannelMemberStatus.invited) {
      return;
    }

    member.status = accept
        ? protocol.ChannelMemberStatus.joined
        : protocol.ChannelMemberStatus.declined;
    await protocol.ChannelMember.db.updateRow(session, member);

    final resident = await protocol.Resident.db.findFirstRow(session, where: (t) => t.userInfoId.equals(userId));

    if (accept && resident != null) {
      await GamificationService.awardXP(
        session,
        resident,
        15,
        'Accepted chat invite',
      );
      await GamificationService.trackProgress(session, userId, 'private_chat');
    } else if (resident != null) {
      // Send system message on decline
      final channel = await protocol.Channel.db.findById(session, channelId);
      if (channel != null) {
        await _sendSystemMessage(session, channelId, "I'm not available to chat right now.");
      }
    }
  }

  /// Leaves a private chat.
  static Future<void> leaveChat(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    final member = await protocol.ChannelMember.db.findFirstRow(
      session,
      where: (t) =>
          t.channelId.equals(channelId) & t.userInfoId.equals(userId),
    );

    if (member == null || member.status != protocol.ChannelMemberStatus.joined) {
      return;
    }

    // Send system message
    await _sendSystemMessage(session, channelId, "I've left the chat.");

    member.status = protocol.ChannelMemberStatus.left;
    await protocol.ChannelMember.db.updateRow(session, member);
  }

  /// Internal helper to send system messages.
  static Future<void> _sendSystemMessage(
    Session session,
    int channelId,
    String content,
  ) async {
    final message = protocol.Message(
      channelId: channelId,
      senderId: UuidValue.nil, // System ID
      senderName: 'System',
      senderFloor: 0,
      senderTrustScore: 100,
      content: content,
      isSystem: true,
      createdAt: DateTime.now(),
    );

    final savedMessage = await protocol.Message.db.insertRow(session, message);
    await session.messages.postMessage('channel_$channelId', savedMessage);
  }
}
