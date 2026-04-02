import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/client_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../services/media_service.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../helpers/duo_floor_helper.dart';
import '../../helpers/duo_upgrade_helper.dart';
import '../../helpers/resident_ext.dart';

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
      client.message.markChannelAsRead(channelId).catchError((_) => null);
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
          autoFocus: false,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to upload image: $e');
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> sendVoiceMessage(String path, int durationSeconds) async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    if (!currentResident.isPlus) {
      DuoUpgradeHelper.showUpgradePrompt(context, 'Voice Messages');
      return;
    }

    setState(() => isSending = true);
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final uploadResult = await mediaService.uploadFile(
        XFile(path),
        'voices',
        fileExtension: kIsWeb ? 'wav' : 'm4a',
        contentTypeOverride: kIsWeb ? 'audio/wav' : 'audio/mp4',
      );

      if (uploadResult != null) {
        await sendMessage(
          mediaUrl: uploadResult.url,
          mediaType: 'voice',
          duration: durationSeconds,
          fileSize: uploadResult.sizeInBytes,
          autoFocus: false,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to send voice: $e');
      }
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
    bool autoFocus = true,
  }) async {
    final finalContent = content ?? messageController.text.trim();
    if (finalContent.isEmpty && imageUrl == null && mediaUrl == null) return;

    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident != null && DuoFloorHelper.isMuted(currentResident)) {
      DuoSnackBarHelper.showError(
        context,
        'Your reputation is too low to send messages',
      );
      return;
    }

    setState(() => isSending = true);
    try {
      await ref
          .read(realtimeChatProvider(channelId).notifier)
          .sendMessage(
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
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
        if (autoFocus) {
          Future.delayed(Duration.zero, () {
            if (mounted) focusNode.requestFocus();
          });
        }
      }
    }
  }

  void handleTypingStatus(bool isTyping) {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident != null) {
      ref.read(realtimeChatProvider(channelId).notifier).setTyping(isTyping);
    }
  }
}
