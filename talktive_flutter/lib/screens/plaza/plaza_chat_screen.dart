import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/blocked_users_provider.dart';
import '../../config/theme.dart';
import '../../helpers/duo_upgrade_helper.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';

import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_info_banner.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import 'package:image_picker/image_picker.dart';

/// Duolingo-style Global Lounge screen - public chat
class PlazaChatScreen extends ConsumerStatefulWidget {
  const PlazaChatScreen({super.key});

  @override
  ConsumerState<PlazaChatScreen> createState() => _PlazaChatScreenState();
}

class _PlazaChatScreenState extends ConsumerState<PlazaChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    final floor = DuoFloorHelper.computeFloor(currentResident);
    if (floor < 2) {
      DuoSnackBarHelper.showError(
        context,
        'You need to be Floor 2+ to send images in Plaza! 🏢',
      );
      return;
    }

    final mediaService = ref.read(mediaServiceProvider);
    final image = await mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final uploadResult = await mediaService.uploadFile(image, 'chats');
      if (uploadResult != null) {
        await _sendMessage(
          imageUrl: uploadResult.url,
          fileSize: uploadResult.sizeInBytes,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to upload image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendMessage({
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
  }) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && imageUrl == null) return;

    final currentResident = ref.read(currentResidentProvider).value;

    // Check reputation (mute check)
    if (currentResident != null && currentResident.trustScore <= 0) {
      if (mounted) {
        DuoSnackBarHelper.showError(
          context,
          'Your reputation is too low to send messages',
        );
      }
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(realtimeChatProvider(1).notifier)
          .sendMessage(
            content: content.isEmpty ? null : content,
            imageUrl: imageUrl,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            duration: duration,
            fileSize: fileSize,
          );

      _messageController.clear();
      HapticFeedback.lightImpact();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: AppTheme.duoAnimationNormal,
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        // On Web, requesting focus needs to happen after the next frame to work reliably
        Future.delayed(Duration.zero, () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
  }

  Future<void> _sendVoiceMessage(String path, int durationSeconds) async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    if (!currentResident.isPremium) {
      DuoSnackBarHelper.showError(
        context,
        'Voice messages are a Premium feature! 🎙️ Upgrade in Settings.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final uploadResult = await mediaService.uploadFile(XFile(path), 'voices');

      if (uploadResult != null) {
        await _sendMessage(
          mediaUrl: uploadResult.url,
          mediaType: 'voice',
          duration: durationSeconds,
          fileSize: uploadResult.sizeInBytes,
        );
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to send voice: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showUpgradePrompt(String featureName) {
    if (mounted) {
      DuoUpgradeHelper.showUpgradePrompt(context, featureName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(realtimeChatProvider(1));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final canSend =
        currentResident != null && !DuoFloorHelper.isMuted(currentResident);

    final typingUsers = chatState.value?.typingUsers ?? {};
    final otherTypingUsers = typingUsers
        .where((u) => u != currentResident?.userName)
        .toList();

    return DuoChatInputLayout(
      typingIndicator:
          (currentResident?.isPremium == true &&
              currentResident?.showOthersTypingIndicators == true &&
              otherTypingUsers.isNotEmpty)
          ? _buildTypingIndicator(otherTypingUsers)
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.public, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Lounge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Chat with everyone',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          DuoRefreshButton(
            color: Colors.black,
            onRefresh: () {
              ref.read(realtimeChatProvider(1).notifier).refresh();
            },
          ),
        ],
      ),
      header: DuoInfoBanner(
        bannerId: 'plaza_image_rules',
        text:
            currentResident != null &&
                DuoFloorHelper.computeFloor(currentResident) >= 2
            ? '📸 You can now share images in the Global Lounge!'
            : 'Text only. Floor 2+ residents can share images.',
      ),
      controller: _messageController,
      onSend: _sendMessage,
      onVoiceSend: _sendVoiceMessage,
      onVoiceStart: () async {
        final currentResident = ref.read(currentResidentProvider).value;
        if (currentResident == null) return false;

        if (!currentResident.isPremium) {
          _showUpgradePrompt('Voice Messages');
          return false;
        }

        if (!currentResident.showVoiceMessages) {
          DuoSnackBarHelper.showWarning(
            context,
            'Enable voice messages in Settings! 🎙️',
          );
          return false;
        }
        return true;
      },
      onTypingStatusChanged: (isTyping) {
        if (currentResident?.isPremium == true &&
            currentResident?.showTypingIndicator == true) {
          ref.read(realtimeChatProvider(1).notifier).setTyping(isTyping);
        }
      },
      onImagePick: () async {
        if (currentResident?.isPremium != true) {
          _showUpgradePrompt('Image Sharing');
          return;
        }

        if (currentResident?.showImagesInPlaza != true) {
          DuoSnackBarHelper.showWarning(
            context,
            'Enable image sharing in Settings! 📸',
          );
          return;
        }

        _pickAndSendImage();
      },
      enabled: canSend,
      isLoading: currentResidentAsync.isLoading,
      isSending: _isSending,
      focusNode: _focusNode,
      hintText: canSend
          ? 'Type a message...'
          : DuoFloorHelper.getMuteInputHint(currentResident),
      content: chatState.when(
        data: (state) {
          if (state.messages.isEmpty) {
            return const DuoEmptyState(
              emoji: '👋',
              title: 'Say hello!',
              subtitle: 'Be the first to start a conversation',
            );
          }
          return _buildMessagesList(state.messages, currentResident);
        },
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => DuoEmptyState(
          emoji: '😕',
          title: 'Connection Error',
          subtitle: error.toString(),
          buttonText: 'Retry',
          onButtonPressed: () {
            ref.read(realtimeChatProvider(1).notifier).refresh();
          },
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(List<String> typingUsers) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final text = typingUsers.length == 1
        ? '${typingUsers[0]} is typing...'
        : '${typingUsers[0]} and ${typingUsers.length - 1} others typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: 4,
      ),
      child: Row(
        children: [
          SizedBox(
                width: 24,
                child: const Text('✍️', style: TextStyle(fontSize: 14)),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 600.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.1, 1.1),
              ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildMessagesList(List<Message> messages, Resident? currentResident) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final blockedUsers = blockedUsersAsync.value ?? [];

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(realtimeChatProvider(1).notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.only(
          left: AppTheme.duoSpacingMedium,
          right: AppTheme.duoSpacingMedium,
          bottom: AppTheme.duoSpacingMedium,
          top: AppTheme.duoSpacingSmall,
        ),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 30))
              .slideX(begin: isCurrentUser ? 0.1 : -0.1, end: 0);
        },
      ),
    );
  }
}
