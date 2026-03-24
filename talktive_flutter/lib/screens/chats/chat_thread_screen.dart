import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/blocked_users_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/lounge_provider.dart';
import 'package:go_router/go_router.dart';

/// Chat thread screen for private 1-on-1 conversations
class ChatThreadScreen extends ConsumerStatefulWidget {
  final int channelId;

  const ChatThreadScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!mounted || _hasMarkedAsRead) return;
    try {
      final client = ref.read(clientProvider);
      await client.message.markChannelAsRead(widget.channelId);
      if (mounted) {
        _hasMarkedAsRead = true;
        // Invalidate both lists to update unread counts immediately
        ref.invalidate(privateChatListProvider);
        ref.invalidate(loungeListProvider);
      }
    } catch (e) {
      debugPrint('Error marking channel as read: $e');
    }
  }

  @override
  void dispose() {
    // Final mark as read when leaving - capture client synchronously
    try {
      final client = ref.read(clientProvider);
      final channelId = widget.channelId;
      client.message
          .markChannelAsRead(channelId)
          .catchError((e) => debugPrint(e));
    } catch (e) {
      debugPrint('Error in dispose mark read: $e');
    }

    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await _sendMessageInternal(content: content);
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

  Future<void> _sendMessageInternal({String? content, String? imageUrl, String? mediaUrl, String? mediaType, int? duration, int? fileSize}) async {
    try {
      await ref
          .read(realtimeChatProvider(widget.channelId).notifier)
          .sendMessage(
            content: content ?? _messageController.text.trim(),
            imageUrl: imageUrl,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            duration: duration,
            fileSize: fileSize,
          );
      _messageController.clear();
      _hasMarkedAsRead = false;
      _markAsRead();
      HapticFeedback.lightImpact();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  void _addMention(String userName) {
    final current = _messageController.text;
    if (current.isEmpty || current.endsWith(' ')) {
      _messageController.text = '$current@$userName ';
    } else {
      _messageController.text = '$current @$userName ';
    }
    // Move cursor to end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _pickAndSendImage() async {
    final mediaService = ref.read(mediaServiceProvider);
    final image = await mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final uploadResult = await mediaService.uploadFile(image, 'chats');
      if (uploadResult != null) {
        await _sendMessageInternal(imageUrl: uploadResult.url, fileSize: uploadResult.sizeInBytes);
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

    setState(() => _isSending = true);

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final uploadResult = await mediaService.uploadFile(XFile(path), 'voices');

      if (uploadResult != null) {
        await _sendMessageInternal(
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
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatDetailsAsync = ref.watch(
      privateChatDetailsProvider(widget.channelId),
    );

    // Listen for real-time updates to mark as read if user is viewing
    ref.listen(realtimeChatProvider(widget.channelId), (previous, next) {
      if (previous != null && next.hasValue && next.value != null) {
        final prevLength = previous.value?.messages.length ?? 0;
        final nextLength = next.value?.messages.length ?? 0;
        if (nextLength > prevLength) {
          _hasMarkedAsRead = false;
          _markAsRead();
        }
      }
    });

    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final chatState = ref.watch(realtimeChatProvider(widget.channelId));

    return chatDetailsAsync.when(
      data: (details) {
        if (details.currentMemberStatus == ChannelMemberStatus.invited) {
          // Instead of redirecting inside build, we can just return PeepholeScreen inline, or schedule a GoRouter push
          // But since it's a deep link, it's safe to just show the peephole view if they haven't accepted
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/chats'); // We shouldn't stay here
              context.push('/chats/peephole', extra: details);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final otherResident = details.otherResident;
        final otherName = details.otherUserName ?? 'Resident';
        final otherAvatar = details.otherUserAvatar;
        final otherFloor = DuoFloorHelper.computeFloor(otherResident);
        final otherMood = details.otherUserMood;

        final canSend =
            currentResident != null && !DuoFloorHelper.isMuted(currentResident);

        final typingUsers = chatState.value?.typingUsers ?? {};
        // Filter out ourselves if we are in the list
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                DuoAvatar(
                  imageUrl: otherAvatar,
                  size: 36,
                  mood: otherMood,
                  showRing: true,
                  floorLevel: otherFloor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                      ),
                      Text(
                        otherFloor > 0 ? 'Floor $otherFloor' : 'New Resident',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              DuoRefreshButton(
                color: Colors.black,
                onRefresh: () {
                  ref
                      .read(realtimeChatProvider(widget.channelId).notifier)
                      .refresh();
                },
              ),
              if (currentResident?.keepPrivateChats == true)
                IconButton(
                  onPressed: () async {
                    if (currentResident?.isPremium != true) {
                      DuoSnackBarHelper.showError(
                        context,
                        'Persistence is a Premium feature! 💎 Upgrade in Settings.',
                      );
                      return;
                    }

                    try {
                      final client = ref.read(clientProvider);
                      final isPersistent =
                          details.channel?.isPersistent ?? false;
                      await client.message.updateChannelPersistence(
                        widget.channelId,
                        !isPersistent,
                      );

                      if (context.mounted) {
                        HapticFeedback.mediumImpact();
                        DuoSnackBarHelper.showSuccess(
                          context,
                          !isPersistent
                              ? 'Chat will be kept permanently! 🔖'
                              : 'Chat ephemerality restored. ✨',
                        );
                        // Invalidate to refresh the Details (specifically the channel object)
                        ref.invalidate(
                            privateChatDetailsProvider(widget.channelId));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        DuoSnackBarHelper.showError(
                          context,
                          'Failed to update persistence',
                        );
                      }
                    }
                  },
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        details.channel?.isPersistent == true
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: details.channel?.isPersistent == true
                            ? AppTheme.duoPurple
                            : Colors.black54,
                        size: 28,
                      ),
                      if (currentResident?.isPremium != true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 10,
                              color: AppTheme.duoOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: details.channel?.isPersistent == true
                      ? 'Unkeep Chat'
                      : 'Keep Chat',
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (value) async {
                  if (value == 'leave') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Leave Chat?'),
                        content: const Text(
                          'Are you sure you want to leave this chat? You won\'t be able to receive messages until you\'re invited back.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Leave',
                              style: TextStyle(color: AppTheme.duoRed),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      try {
                        await ref
                            .read(privateChatListProvider.notifier)
                            .leaveChat(widget.channelId);
                        if (context.mounted) {
                          Navigator.pop(context); // Go back to chats list
                        }
                      } catch (e) {
                        if (context.mounted) {
                          DuoSnackBarHelper.showError(
                            context,
                            'Failed to leave chat',
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'leave',
                      child: Row(
                        children: [
                          const Text('🚪', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          const Text(
                            'Leave Chat',
                            style: TextStyle(
                              color: AppTheme.duoRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          controller: _messageController,
          onSend: _sendMessage,
          onVoiceSend:
              (currentResident?.isPremium ?? false) &&
                  (currentResident?.showVoiceMessages ?? true)
              ? _sendVoiceMessage
              : null,
          onVoiceStart: () async {
            if (currentResident == null) return false;

            if (!currentResident.isPremium) {
              DuoSnackBarHelper.showError(
                context,
                'Voice messages are a Premium feature! 🎙️ Upgrade in Settings.',
              );
              return false;
            }
            return true;
          },
          onTypingStatusChanged: (isTyping) {
            if (currentResident?.showTypingIndicator == true) {
              ref
                  .read(realtimeChatProvider(widget.channelId).notifier)
                  .setTyping(isTyping);
            }
          },
          onImagePick: _pickAndSendImage,
          enabled: canSend,
          isSending: _isSending,
          isLoading: currentResidentAsync.isLoading,
          focusNode: _focusNode,
          activeColor: AppTheme.duoOrange,
          hintText: canSend
              ? 'Type a message...'
              : DuoFloorHelper.getMuteInputHint(currentResident),
          content: chatState.when(
            data: (state) => state.messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(
                    state,
                    otherName,
                    currentResident,
                    details.otherResident.userInfoId.toString(),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            error: (error, stack) => _buildErrorState(error),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Loading Chat...'),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (e, stack) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Error'),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Failed to load chat: $e',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.invalidate(
                  privateChatDetailsProvider(widget.channelId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.2),
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 40)),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: AppTheme.duoSpacingLarge),
          Text(
            'Start the conversation',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            'Say hello and break the ice!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(List<String> typingUsers) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final text = typingUsers.length == 1
        ? '${typingUsers[0]} is typing...'
        : 'Multiple people are typing...';

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

  Widget _buildMessagesList(
    RealtimeChatState state,
    String otherName,
    Resident? currentResident,
    String otherUserId,
  ) {
    final messages = state.messages;
    final lastReadStatus = state.lastReadStatus;
    final otherLastReadAt = lastReadStatus[otherUserId];

    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final blockedUsers = blockedUsersAsync.value ?? [];

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(realtimeChatProvider(widget.channelId).notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          bool isRead = false;
          // Only Premium users can SEE read receipts
          if (isCurrentUser &&
              currentResident.isPremium &&
              currentResident.showOthersReadReceipts &&
              otherLastReadAt != null) {
            isRead = message.createdAt.isBefore(otherLastReadAt);
          }

          return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
                onMention: _addMention,
                otherMemberNames: [otherName],
                isRead: isRead,
              )
              .animate(delay: Duration(milliseconds: index * 30))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❌', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load messages',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
