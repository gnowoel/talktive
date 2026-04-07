import 'package:serverpod/serverpod.dart' hide Message;
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:collection/collection.dart';
import '../utils/protocol_utils.dart';
import 'apartment_service.dart';
import 'resident_service.dart';
import 'gamification_service.dart';
import 'content_filter_service.dart';
import 'input_validation_service.dart';
import 'rate_limit_service.dart';
import 'channel_service.dart';
import 'lounge_service.dart';
import 'notification_service.dart';
import '../utils/task_utils.dart';

/// Service for handling message validation and post-save operations.
class MessagingService {
  /// Validates a message before it is saved.
  /// Checks safety (muted/suspended), content filtering, rate limiting, and floor rules.
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
      InputValidationService.validateFileSize(
        fileSize,
        fieldName: 'Media file',
      ).throwIfInvalid();
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
          message: validation.error ?? 'Invalid message content',
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
          message: "Please don't send the same message repeatedly",
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
    final hasMedia =
        (imageUrl != null && imageUrl.isNotEmpty) ||
        (mediaUrl != null && mediaUrl.isNotEmpty);

    if (hasMedia) {
      // Plaza and Lounge restrictions: images/media allowed only for Floor 2+
      if ((channel.type == protocol.ChannelType.plaza ||
              channel.type == protocol.ChannelType.lounge) &&
          senderEffectiveFloor < 2) {
        throw protocol.TalktiveException(
          message: 'You must reach Floor 2 to send media in public spaces. 🏢',
          code: 'FLOOR_RESTRICTION',
        );
      }

      // Voice message premium check
      if (mediaType == 'voice' && !ResidentService.isPlusMember(sender)) {
        throw protocol.TalktiveException(
          message:
              'Voice messages are a Premium feature. 🎙️ Upgrade in Settings!',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    // 6. Privacy Check: Blocked status (Private Chats)
    if (channel.type == protocol.ChannelType.private) {
      await ChannelService.validateMember(
        session,
        channel.id!,
        senderUuid,
      );

      await ChannelService.validateNoBlockFlow(
        session,
        channelId: channel.id!,
        senderId: senderUuid,
      );
    } else if (channel.type == protocol.ChannelType.lounge) {
      // For lounges, verify the user is a member
      await ChannelService.validateMember(
        session,
        channel.id!,
        senderUuid,
      );
    }

    return filteredContent;
  }

  /// Creates, saves, and triggers post-save processes for a new message.
  /// This is the primary entry point for sending a message from any endpoint.
  static Future<protocol.Message> sendMessage(
    Session session, {
    required protocol.Resident sender,
    required protocol.Channel channel,
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
    bool isSystem = false,
  }) async {
    // 1. Validate the content and permissions
    final filteredContent = await validateMessage(
      session,
      sender: sender,
      channel: channel,
      content: content,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      duration: duration,
      fileSize: fileSize,
    );

    final channelId = channel.id!;

    // 2. Build the message object
    final message = protocol.Message(
      channelId: channelId,
      senderId: sender.userInfoId,
      content: filteredContent,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: imageUrl != null || mediaUrl != null ? mediaType : null,
      isSystem: isSystem,
      createdAt: DateTime.now(),
      duration: duration,
      fileSize: fileSize,
      senderName: sender.userName ?? 'Resident',
      senderAvatar: sender.customAvatarUrl ?? sender.avatar,
      senderMood: sender.mood,
      senderFloor: ApartmentService.computeEffectiveFloor(sender),
      senderTrustScore: sender.trustScore,
    );

    // 3. Save to database
    final savedMessage = await protocol.Message.db.insertRow(session, message);

    // 4. MAIN PATH SENSITIVE OPERATIONS (Immediate UI reaction)
    // Update sender's lastReadAt and lastMessage fields
    await ChannelService.markAsRead(session, channelId, sender.userInfoId);
    if (channel.type != protocol.ChannelType.plaza) {
      await ChannelService.updateLastMessage(
        session,
        channelId,
        channelType: channel.type,
        content: savedMessage.content,
        imageUrl: savedMessage.imageUrl,
        mediaUrl: savedMessage.mediaUrl,
        mediaType: savedMessage.mediaType,
      );
    }

    // 5. Broadcast real-time message IMMEDIATELY (Before background tasks)
    await session.messages.postMessage('channel_$channelId', savedMessage);

    // 6. Handle heavy side effects (asynchronously in background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      // Trigger notifications (Push, mentioning, etc.)
      await NotificationService.triggerMessageNotifications(
        backgroundSession,
        channel: channel,
        message: savedMessage,
        sender: sender,
      );

      // Handle Gamification & Streaks
      await onMessagePostSave(
        backgroundSession,
        message: savedMessage,
        channel: channel,
        sender: sender,
      );
    });

    return savedMessage;
  }

  /// Handles heavy background post-save tasks like gamification and achievements.
  static Future<void> onMessagePostSave(
    Session session, {
    required protocol.Message message,
    required protocol.Channel channel,
    required protocol.Resident sender,
  }) async {
    final senderUuid = sender.userInfoId;
    final currentSender = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderUuid),
    );
    if (currentSender == null) return;
    final channelId = channel.id!;

    // 1. Award XP and update streak
    await GamificationService.awardXP(
      session,
      currentSender,
      GamificationService.xpPerMessage,
      'Sent message',
      save: false,
    );
    await GamificationService.updateMessageStreak(
      session,
      currentSender,
      save: false,
    );
    await ResidentService.updateResident(session, currentSender);

    // 2. Award Lounge XP
    if (channel.type == protocol.ChannelType.lounge) {
      await LoungeService.awardLoungeXP(
        session,
        channelId,
        1,
        'Message sent',
      );
    }

    // 3. Achievement Progress
    await GamificationService.trackMultipleProgress(
      session,
      senderUuid,
      ['first_message', 'conversationalist', 'chatterbox'],
    );
    await GamificationService.checkTimeBasedAchievements(
      session,
      senderUuid,
    );
  }

  /// Backward-compatible alias for post-save message work.
  static Future<void> onMessageSaved(
    Session session, {
    required protocol.Message message,
    required protocol.Channel channel,
    required protocol.Resident sender,
  }) async {
    await onMessagePostSave(
      session,
      message: message,
      channel: channel,
      sender: sender,
    );
  }

  /// Pins a message to the top of its channel.
  static Future<protocol.Message> pinMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    if (!await _hasManagementPermission(session, channel, resident)) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to pin messages in this channel.',
        code: 'ACCESS_DENIED',
      );
    }

    // 1. Unpin existing messages for this channel (only one pinned message at a time)

    final existingPinned = await protocol.Message.db.find(
      session,
      where: (t) =>
          t.channelId.equals(message.channelId) & t.isPinned.equals(true),
    );

    if (existingPinned.isNotEmpty) {
      await protocol.Message.db.updateWhere(
        session,
        where: (t) =>
            t.channelId.equals(message.channelId) & t.isPinned.equals(true),
        columnValues: (t) => [t.isPinned(false)],
      );

      for (final oldMessage in existingPinned) {
        oldMessage.isPinned = false;
        await session.messages.postMessage(
          'channel_${message.channelId}',
          oldMessage,
        );
      }
    }

    message.isPinned = true;
    message.pinnedAt = DateTime.now();
    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );
    return updatedMessage;
  }

  /// Unpins a message.
  static Future<protocol.Message> unpinMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    if (!await _hasManagementPermission(session, channel, resident)) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to unpin messages in this channel.',
        code: 'ACCESS_DENIED',
      );
    }

    message.isPinned = false;
    message.pinnedAt = null;
    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );
    return updatedMessage;
  }

  /// Recalls a message.
  static Future<protocol.Message> recallMessage(
    Session session, {
    required int messageId,
    required protocol.Resident resident,
  }) async {
    final message = await protocol.Message.db.findById(session, messageId);
    if (message == null) {
      throw protocol.TalktiveException(
        message: 'Message not found.',
        code: 'MESSAGE_NOT_FOUND',
      );
    }

    if (message.isRecalled) {
      return message;
    }

    final channel = await protocol.Channel.db.findById(
      session,
      message.channelId,
    );
    if (channel == null) {
      throw protocol.TalktiveException(
        message: 'Channel not found.',
        code: 'CHANNEL_NOT_FOUND',
      );
    }

    bool canRecall = (message.senderId == resident.userInfoId);
    if (!canRecall) {
      canRecall = await _hasManagementPermission(session, channel, resident);
    }

    if (!canRecall) {
      throw protocol.TalktiveException(
        message:
            'Access denied: You do not have permission to recall this message.',
        code: 'ACCESS_DENIED',
      );
    }

    // Mark as recalled
    message.isRecalled = true;
    message.recalledAt = DateTime.now();
    message.content = null;
    message.imageUrl = null;
    message.mediaUrl = null;
    message.mediaType = null;
    message.duration = null;
    message.fileSize = null;

    final updatedMessage = await protocol.Message.db.updateRow(
      session,
      message,
    );

    // Update Denormalized Info (Preview text) if it was the last message
    // Update Denormalized Preview if needed
    if (channel.type != protocol.ChannelType.plaza) {
      await ChannelService.syncLastMessageFromDb(
        session,
        channel.id!,
        channel.type,
      );
    }

    // Broadcast update
    await session.messages.postMessage(
      'channel_${message.channelId}',
      updatedMessage,
    );

    return updatedMessage;
  }

  // --- Private Chat Management ---

  /// Creates or retrieves a private 1:1 chat between two residents.
  static Future<protocol.PrivateChat> getOrCreatePrivateChat(
    Session session, {
    required protocol.Resident sender,
    required UuidValue otherUserId,
    String? initialMessage,
  }) async {
    final currentUserId = sender.userInfoId;

    if (currentUserId == otherUserId) {
      throw protocol.TalktiveException(
        message: 'Cannot create private chat with yourself.',
        code: 'SELF_CHAT_NOT_ALLOWED',
      );
    }

    final otherResident = await ResidentService.getResident(
      session,
      otherUserId,
    );
    if (otherResident == null) {
      throw protocol.TalktiveException(
        message: 'Resident not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }

    // Validation: Inviting Rules
    if (!ApartmentService.canInvite(sender: sender, receiver: otherResident)) {
      throw protocol.TalktiveException(
        message: ApartmentService.cannotInviteReason(
          sender: sender,
          receiver: otherResident,
        ),
        code: 'INVITE_RESTRICTED',
      );
    }

    // Validation: Privacy Blocks
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

    // Ordered Participants for Identity Consistency
    final participants = ProtocolUtils.orderParticipants(
      currentUserId,
      otherUserId,
    );
    final p1 = participants[0];
    final p2 = participants[1];

    var privateChat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.participant1Id.equals(p1) & t.participant2Id.equals(p2),
    );

    bool isCurrentlyInvited = false;
    bool wasJustInvited = false;

    if (privateChat != null) {
      final members = await protocol.ChannelMember.db.find(
        session,
        where: (t) => t.channelId.equals(privateChat!.channelId),
      );
      final currentMember = members.firstWhereOrNull(
        (m) => m.userInfoId == currentUserId,
      );
      final otherMember = members.firstWhereOrNull(
        (m) => m.userInfoId == otherUserId,
      );

      // Re-Activate if left/declined
      if (currentMember != null &&
          (currentMember.status == protocol.ChannelMemberStatus.left ||
              currentMember.status == protocol.ChannelMemberStatus.declined)) {
        await ChannelService.updateMemberStatus(
          session,
          channelId: privateChat.channelId,
          userId: currentUserId,
          status: protocol.ChannelMemberStatus.joined,
        );
      }

      // Re-Invite if left/declined
      if (otherMember != null) {
        if (otherMember.status == protocol.ChannelMemberStatus.invited) {
          isCurrentlyInvited = true;
        } else if (otherMember.status == protocol.ChannelMemberStatus.left ||
            otherMember.status == protocol.ChannelMemberStatus.declined) {
          await ChannelService.updateMemberStatus(
            session,
            channelId: privateChat.channelId,
            userId: otherUserId,
            status: protocol.ChannelMemberStatus.invited,
            invitedBy: currentUserId,
          );
          wasJustInvited = true;
        }
      }
    } else {
      // Create New 1:1 Identity
      final channel = await ChannelService.createChannel(
        session,
        name: 'Private Chat',
        type: protocol.ChannelType.private,
      );

      privateChat = await protocol.PrivateChat.db.insertRow(
        session,
        protocol.PrivateChat(
          channelId: channel.id!,
          participant1Id: p1,
          participant2Id: p2,
          createdAt: DateTime.now(),
          lastMessageAt: DateTime.now(),
        ),
      );

      // Creator Joins immediately
      await ChannelService.updateMemberStatus(
        session,
        channelId: channel.id!,
        userId: currentUserId,
        status: protocol.ChannelMemberStatus.joined,
        role: 'owner',
      );

      // Target is Invited
      await ChannelService.updateMemberStatus(
        session,
        channelId: channel.id!,
        userId: otherUserId,
        status: protocol.ChannelMemberStatus.invited,
        invitedBy: currentUserId,
      );

      await GamificationService.trackProgress(
        session,
        currentUserId,
        'private_chat',
      );
      wasJustInvited = true;
    }

    if (wasJustInvited) {
      TaskUtils.runBackground(session, (s) async {
        try {
          await NotificationService.sendChatInviteNotification(
            s,
            otherUserId,
            sender.userName ?? 'Someone',
            privateChat!.channelId,
          );
        } catch (_) {}
      });
    }

    // Optional Initial Message (The "Knock")
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      await _handleInitialMessage(
        session,
        sender: sender,
        channelId: privateChat.channelId,
        content: initialMessage,
        isReKnock: isCurrentlyInvited && !wasJustInvited,
      );
    }

    return privateChat;
  }

  /// Private helper for initial knock messages (handles re-knocks/updates).
  static Future<void> _handleInitialMessage(
    Session session, {
    required protocol.Resident sender,
    required int channelId,
    required String content,
    required bool isReKnock,
  }) async {
    try {
      final channel = await ChannelService.getChannel(session, channelId);
      if (channel == null) return;

      if (isReKnock) {
        // If they knock again while still pending, update the last message text
        final lastMessage = await protocol.Message.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(channelId) &
              t.senderId.equals(sender.userInfoId),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        );

        if (lastMessage != null) {
          lastMessage.content = content;
          await protocol.Message.db.updateRow(session, lastMessage);
          await session.messages.postMessage('channel_$channelId', lastMessage);
          await ChannelService.updateLastMessage(
            session,
            channelId,
            channelType: channel.type,
            content: content,
          );
          return;
        }
      }

      await sendMessage(
        session,
        sender: sender,
        channel: channel,
        content: content,
      );
    } catch (e) {
      session.log('Initial chat message error: $e', level: LogLevel.warning);
    }
  }

  /// Paginated list of private chats with profile data (Performance Optimized).
  static Future<List<protocol.PrivateChatWithProfile>> listPrivateChats(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await ResidentService.getResident(session, userId);
    final canSeeReadReceipts =
        resident != null && ResidentService.canSeeOthersReadReceipts(resident);

    // 1. Fetch Chat Records
    final chats = await protocol.PrivateChat.db.find(
      session,
      where: (t) =>
          t.participant1Id.equals(userId) | t.participant2Id.equals(userId),
      orderBy: (t) => t.lastMessageAt,
      orderDescending: true,
    );

    if (chats.isEmpty) return [];

    final channelIds = chats.map((c) => c.channelId).toSet();
    final otherIds = chats
        .map(
          (c) =>
              c.participant1Id == userId ? c.participant2Id : c.participant1Id,
        )
        .toSet();

    // 2. Batch Data Fetching (Parallel)
    final results = await Future.wait([
      protocol.ChannelMember.db.find(
        session,
        where: (t) => t.channelId.inSet(channelIds),
      ),
      ChannelService.batchGetUnreadCounts(session, channelIds.toList(), userId),
      protocol.Channel.db.find(session, where: (t) => t.id.inSet(channelIds)),
      ResidentService.getResidents(session, otherIds.toList()),
    ]);

    final membersByChannel = (results[0] as List<protocol.ChannelMember>)
        .groupListsBy((m) => m.channelId);
    final unreadCounts = results[1] as Map<int, int>;
    final channelsById = (results[2] as List<protocol.Channel>).groupListsBy(
      (c) => c.id!,
    );
    final residentsById = (results[3] as List<protocol.Resident>).groupListsBy(
      (r) => r.userInfoId,
    );

    final items = <protocol.PrivateChatWithProfile>[];

    for (final chat in chats) {
      final members = membersByChannel[chat.channelId] ?? [];
      final currentMember = members.firstWhereOrNull(
        (m) => m.userInfoId == userId,
      );

      // Visibility Gate: Don't show inactive memberships
      if (currentMember == null ||
          currentMember.status == protocol.ChannelMemberStatus.left ||
          currentMember.status == protocol.ChannelMemberStatus.declined) {
        continue;
      }

      final otherId = chat.participant1Id == userId
          ? chat.participant2Id
          : chat.participant1Id;
      final otherMember = members.firstWhereOrNull(
        (m) => m.userInfoId == otherId,
      );
      final otherResident = residentsById[otherId]?.firstOrNull;

      if (otherResident != null) {
        items.add(
          protocol.PrivateChatWithProfile(
            chat: chat,
            otherResident: ResidentService.gateResident(
              otherResident,
              viewer: resident,
            ),
            otherUserName: otherResident.userName,
            otherUserAvatar:
                otherResident.customAvatarUrl ?? otherResident.avatar,
            otherUserMood: otherResident.mood,
            currentMemberStatus: currentMember.status,
            otherMemberStatus: otherMember?.status,
            otherUserLastReadAt: canSeeReadReceipts
                ? otherMember?.lastReadAt
                : null,
            unreadCount: unreadCounts[chat.channelId] ?? 0,
            channel: channelsById[chat.channelId]?.firstOrNull,
          ),
        );
      }
    }

    return items;
  }

  /// Gets full details for a private chat.
  static Future<protocol.PrivateChatWithProfile?> getPrivateChatDetails(
    Session session,
    int channelId,
    UuidValue currentUserId,
  ) async {
    final currentResident = await ResidentService.getResident(
      session,
      currentUserId,
    );
    final canSeeReadReceipts =
        currentResident != null &&
        ResidentService.canSeeOthersReadReceipts(currentResident);

    final chat = await protocol.PrivateChat.db.findFirstRow(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
    if (chat == null) return null;

    if (chat.participant1Id != currentUserId &&
        chat.participant2Id != currentUserId) {
      throw protocol.TalktiveException(
        message: 'Access denied.',
        code: 'ACCESS_DENIED',
      );
    }

    final otherId = chat.participant1Id == currentUserId
        ? chat.participant2Id
        : chat.participant1Id;
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
    final currentMember = members.firstWhereOrNull(
      (m) => m.userInfoId == currentUserId,
    );
    final otherMember = members.firstWhereOrNull(
      (m) => m.userInfoId == otherId,
    );
    final resident = await ResidentService.getResident(session, otherId);

    if (resident == null) return null;

    return protocol.PrivateChatWithProfile(
      chat: chat,
      otherResident: ResidentService.gateResident(
        resident,
        viewer: currentResident,
      ),
      otherUserName: resident.userName,
      otherUserAvatar: resident.customAvatarUrl ?? resident.avatar,
      otherUserMood: resident.mood,
      currentMemberStatus: currentMember?.status,
      otherMemberStatus: otherMember?.status,
      otherUserLastReadAt: canSeeReadReceipts ? otherMember?.lastReadAt : null,
      unreadCount:
          (await ChannelService.batchGetUnreadCounts(session, [
            channelId,
          ], currentUserId))[channelId] ??
          0,
      channel: await ChannelService.getChannel(session, channelId),
    );
  }

  /// Responses to a chat invitation (Accept/Decline).
  static Future<void> respondToChatInvite(
    Session session,
    int channelId,
    UuidValue userId,
    bool accept,
  ) async {
    final member = await ChannelService.getMember(session, channelId, userId);
    if (member == null ||
        member.status != protocol.ChannelMemberStatus.invited) {
      return;
    }

    await ChannelService.updateMemberStatus(
      session,
      channelId: channelId,
      userId: userId,
      status: accept
          ? protocol.ChannelMemberStatus.joined
          : protocol.ChannelMemberStatus.declined,
    );
  }

  /// Leaves a private thread.
  static Future<void> leaveChat(
    Session session,
    int channelId,
    UuidValue userId,
  ) async {
    await ChannelService.updateMemberStatus(
      session,
      channelId: channelId,
      userId: userId,
      status: protocol.ChannelMemberStatus.left,
    );
  }

  /// Pinnable persistence feature management.
  static Future<void> updatePersistence(
    Session session, {
    required protocol.Resident resident,
    required int channelId,
    required bool isPersistent,
  }) async {
    // Premium Lock: Only Plus members can pin private chats to keep them forever
    if (isPersistent && !ResidentService.canKeepPrivateChats(resident)) {
      throw protocol.TalktiveException(
        message: 'Chat persistence is a Premium feature. 🏆',
        code: 'PREMIUM_REQUIRED',
      );
    }

    await ChannelService.updatePersistence(session, channelId, isPersistent);
  }

  /// Checks if a resident has administrative permission in a specific channel.
  static Future<bool> _hasManagementPermission(
    Session session,
    protocol.Channel channel,
    protocol.Resident resident,
  ) async {
    // 1. Staff (Admin/Moderator) in public spaces
    if (resident.role == protocol.ResidentRole.admin ||
        resident.role == protocol.ResidentRole.moderator) {
      if (channel.type != protocol.ChannelType.private) return true;
    }

    // 2. Fetch membership
    final member = await ChannelService.getMember(
      session,
      channel.id!,
      resident.userInfoId,
    );
    if (member == null ||
        member.status != protocol.ChannelMemberStatus.joined) {
      return false;
    }

    // 3. Admin role in the channel (Lounge Creator or explicit admin)
    if (member.role == 'admin') return true;

    // 4. Private Chat Participants (Both participants are "owners" of the thread)
    if (channel.type == protocol.ChannelType.private) return true;

    return false;
  }
}
