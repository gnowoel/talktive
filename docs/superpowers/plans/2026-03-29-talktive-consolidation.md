# Talktive Consolidation & Simplification Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thoroughly review, simplify, and consolidate the Serverpod implementation of Talktive by removing redundancy in both backend services and frontend UI logic.

**Architecture:** 
- **Backend:** Move orchestration logic (notifications) from Endpoints to Services. Standardize internal service API signatures.
- **Frontend:** Introduce a `ChatScreenMixin` to unify the logic for Plaza, Lounges, and Private Chats, reducing ~600 lines of duplicated code.

**Tech Stack:** 
- Serverpod (Backend)
- Flutter + Riverpod (Frontend)

---

### Task 1: Backend Consolidation - Notification Orchestration

**Files:**
- Modify: `talktive_server/lib/src/services/notification_service.dart`
- Modify: `talktive_server/lib/src/endpoints/message_endpoint.dart`

- [ ] **Step 1: Implement `triggerMessageNotifications` in `NotificationService`**
Move the logic from `MessageEndpoint._triggerNotifications` into `NotificationService` to centralize notification orchestration.

```dart
// talktive_server/lib/src/services/notification_service.dart

  /// Orchestrates all notifications for a new message (mentions, push, etc).
  static Future<void> triggerMessageNotifications(
    Session session, {
    required protocol.Channel channel,
    required protocol.Message message,
    required protocol.Resident sender,
  }) async {
    final content = message.content;
    if (content == null || content.isEmpty) return;

    final isPlaza = channel.type == protocol.ChannelType.plaza;
    final channelId = channel.id!;
    final senderUuid = sender.userInfoId;
    final senderName = sender.userName ?? 'Resident';

    // 1. Resolve loungeId if applicable
    int? loungeId;
    if (!isPlaza) {
      final lounge = await protocol.Lounge.db.findFirstRow(
        session,
        where: (t) => t.channelId.equals(channelId),
      );
      loungeId = lounge?.id;
    }

    // 2. Detect mentions
    final mentionedUserIds = await MentionService.getMentionedUserIds(
      session,
      channelId,
      content,
    );
    mentionedUserIds.remove(senderUuid);

    final loungeName = channel.name ?? (isPlaza ? 'Plaza' : 'Chat');

    // 3. Notify mentions (Parallel)
    final mentionFutures = mentionedUserIds.map(
      (mentionedId) => sendMentionNotification(
        session,
        mentionedId,
        senderName,
        content,
        channelId,
        loungeName,
        loungeId: loungeId,
      ),
    );

    // 4. Notify other members (Private/Lounge only)
    Future? bulkMemberFuture;
    if (!isPlaza) {
      final String channelTypeStr = channel.type == protocol.ChannelType.private
          ? 'private'
          : 'lounge';
      
      final mentionIdSet = mentionedUserIds.toSet();
      final blockedBySet = await ResidentService.getBlocksAgainstUser(session, senderUuid);

      final otherMembers = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channelId) &
            t.userInfoId.notEquals(senderUuid) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      );

      final recipientIds = <UuidValue>[];
      for (final member in otherMembers) {
        if (member.isMuted || mentionIdSet.contains(member.userInfoId)) continue;
        if (blockedBySet.contains(member.userInfoId)) continue;
        recipientIds.add(member.userInfoId);
      }

      if (recipientIds.isNotEmpty) {
        bulkMemberFuture = sendBulkMessageNotifications(
          session,
          recipientIds,
          senderName,
          content,
          channelId,
          channelTypeStr,
          loungeId: loungeId,
        );
      }
    }

    await Future.wait([...mentionFutures, if (bulkMemberFuture != null) bulkMemberFuture]);
  }
```

- [ ] **Step 2: Clean up `MessageEndpoint`**
Remove the internal `_triggerNotifications` method and call `NotificationService.triggerMessageNotifications` instead.

```dart
// talktive_server/lib/src/endpoints/message_endpoint.dart

      // 6. Handle side effects (async)
      TaskUtils.runBackground(session, (backgroundSession) async {
        final channel = await ChannelService.getChannel(backgroundSession, savedMessage.channelId);
        if (channel != null) {
          // Call the service instead of local method
          await NotificationService.triggerMessageNotifications(
            backgroundSession,
            channel: channel,
            message: savedMessage,
            sender: sender,
          );

          await MessagingService.onMessageSaved(
            backgroundSession,
            message: savedMessage,
            channel: channel,
            sender: sender,
          );
        }
      });
```

- [ ] **Step 3: Run tests to ensure notifications still work**
If integration tests exist for notifications, run them.

- [ ] **Step 4: Commit**

### Task 2: Frontend Consolidation - ChatScreenMixin

**Files:**
- Create: `talktive_flutter/lib/widgets/chat/chat_screen_mixin.dart`
- Modify: `talktive_flutter/lib/screens/plaza/plaza_chat_screen.dart`
- Modify: `talktive_flutter/lib/screens/lounges/lounge_chat_screen.dart`
- Modify: `talktive_flutter/lib/screens/chats/chat_thread_screen.dart`

- [ ] **Step 1: Create `ChatScreenMixin`**
Extract all common chat screen logic into a reusable mixin.

```dart
// talktive_flutter/lib/widgets/chat/chat_screen_mixin.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/client_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../services/media_service.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../helpers/duo_floor_helper.dart';
import '../../helpers/duo_upgrade_helper.dart';

mixin ChatScreenMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isSending = false;

  int get channelId;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _markAsRead();
  }

  @override
  void dispose() {
    // Final mark as read when leaving
    try {
      final client = ref.read(clientProvider);
      client.message.markChannelAsRead(channelId).catchError((_) {});
    } catch (_) {}

    scrollController.dispose();
    messageController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.hasClients) {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        ref.read(realtimeChatProvider(channelId).notifier).loadMore();
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      final client = ref.read(clientProvider);
      await client.message.markChannelAsRead(channelId);
    } catch (_) {}
  }

  Future<void> pickAndSendImage({int floorRestriction = 0}) async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    if (floorRestriction > 0) {
      final floor = DuoFloorHelper.computeFloor(currentResident);
      if (floor < floorRestriction) {
        DuoSnackBarHelper.showError(
          context,
          'You need to be Floor $floorRestriction+ to send images here! 🏢',
        );
        return;
      }
    }

    final mediaService = ref.read(mediaServiceProvider);
    final image = await mediaService.pickImage();
    if (image == null) return;

    setState(() => isSending = true);
    try {
      final uploadResult = await mediaService.uploadFile(image, 'chats');
      if (uploadResult != null) {
        await sendMessage(
          imageUrl: uploadResult.url,
          fileSize: uploadResult.sizeInBytes,
        );
      }
    } catch (e) {
      DuoSnackBarHelper.showError(context, 'Failed to upload image: $e');
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> sendVoiceMessage(String path, int durationSeconds) async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null || !currentResident.isPremium) return;

    setState(() => isSending = true);
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final uploadResult = await mediaService.uploadFile(XFile(path), 'voices');

      if (uploadResult != null) {
        await sendMessage(
          mediaUrl: uploadResult.url,
          mediaType: 'voice',
          duration: durationSeconds,
          fileSize: uploadResult.sizeInBytes,
        );
      }
    } catch (e) {
      DuoSnackBarHelper.showError(context, 'Failed to send voice: $e');
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> sendMessage({
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
  }) async {
    final finalContent = content ?? messageController.text.trim();
    if (finalContent.isEmpty && imageUrl == null && mediaUrl == null) return;

    setState(() => isSending = true);
    try {
      await ref.read(realtimeChatProvider(channelId).notifier).sendMessage(
            content: finalContent.isEmpty ? null : finalContent,
            imageUrl: imageUrl,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            duration: duration,
            fileSize: fileSize,
          );

      messageController.clear();
      HapticFeedback.lightImpact();

      if (scrollController.hasClients) {
        scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      DuoSnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => isSending = false);
        Future.delayed(Duration.zero, () {
          if (mounted) focusNode.requestFocus();
        });
      }
    }
  }

  void handleTypingStatus(bool isTyping) {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident?.isPremium == true && currentResident?.showTypingIndicator == true) {
      ref.read(realtimeChatProvider(channelId).notifier).setTyping(isTyping);
    }
  }
}
```

- [ ] **Step 2: Update `PlazaChatScreen` to use `ChatScreenMixin`**
Refactor `plaza_chat_screen.dart` to use the mixin and remove duplicated code.

- [ ] **Step 3: Update `LoungeChatScreen` to use `ChatScreenMixin`**
Refactor `lounge_chat_screen.dart`.

- [ ] **Step 4: Update `ChatThreadScreen` to use `ChatScreenMixin`**
Refactor `chat_thread_screen.dart`.

- [ ] **Step 5: Verify all chat screens still work correctly**

- [ ] **Step 6: Commit**

### Task 3: Final Review and Minor Simplifications

- [ ] **Step 1: Check `ResidentService` for minor simplifications**
Ensure `isResidentOnline` is used consistently.

- [ ] **Step 2: Check `ChannelService` for minor simplifications**
Ensure `updateLastMessage` is correctly used by all relevant services.

- [ ] **Step 3: Final full-stack verification**
Run the server and the app to ensure everything is working as expected.

- [ ] **Step 4: Commit**
