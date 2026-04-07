import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/social_relationships_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/pinned_message_bar.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../widgets/duo/duo_typing_indicator.dart';
import '../../helpers/duo_upgrade_helper.dart';
import '../../providers/lounge_provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/client_provider.dart';
import 'package:go_router/go_router.dart';
import '../../utils/ad_navigation_utils.dart';
import '../../widgets/chat/chat_screen_mixin.dart';
import '../../helpers/resident_ext.dart';

/// Chat thread screen for private 1-on-1 conversations
class ChatThreadScreen extends ConsumerStatefulWidget {
  final int channelId;

  const ChatThreadScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen>
    with ChatScreenMixin {
  bool _isExiting = false;
  bool _hasMarkedAsRead = false;

  @override
  int get channelId => widget.channelId;

  void _showUpgradePrompt(String feature) {
    DuoUpgradeHelper.showUpgradePrompt(context, feature);
  }

  @override
  void initState() {
    super.initState();
    _threadMarkAsRead();
  }

  Future<void> _threadMarkAsRead() async {
    if (!mounted || _hasMarkedAsRead) return;
    try {
      final client = ref.read(clientProvider);
      await client.message.markChannelAsRead(channelId);
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
  Widget build(BuildContext context) {
    final chatDetailsAsync = ref.watch(privateChatDetailsProvider(channelId));

    // Listen for real-time updates to mark as read if user is viewing
    ref.listen(realtimeChatProvider(channelId), (previous, next) {
      if (previous != null && next.hasValue && next.value != null) {
        final prevLength = previous.value?.messages.length ?? 0;
        final nextLength = next.value?.messages.length ?? 0;
        if (nextLength > prevLength) {
          _hasMarkedAsRead = false;
          _threadMarkAsRead();
        }
      }
    });

    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final chatState = ref.watch(realtimeChatProvider(channelId));

    return PopScope(
      canPop: _isExiting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          setState(() => _isExiting = true);
          await context.popWithAd(ref);
        }
      },
      child: chatDetailsAsync.when(
        data: (details) {
          if (details == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                DuoSnackBarHelper.showError(context, 'Private chat not found');
                context.go('/chats');
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (details.currentMemberStatus == ChannelMemberStatus.invited) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/chats');
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
              currentResident != null &&
              !DuoFloorHelper.isMuted(currentResident);

          final typingUsers = chatState.value?.typingUsers ?? {};
          final otherTypingUsers = typingUsers
              .where((u) => u != currentResident?.userName)
              .toList();

          return DuoChatInputLayout(
            typingIndicator:
                (currentResident?.isPlus == true &&
                    currentResident?.showOthersTypingIndicators == true &&
                    otherTypingUsers.isNotEmpty)
                ? DuoTypingIndicator(
                    typingUsers: otherTypingUsers,
                    isPrivate: true,
                  )
                : null,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.popWithAd(ref);
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                if (currentResident?.keepPrivateChats == true)
                  IconButton(
                    onPressed: () async {
                      if (currentResident?.isPlus != true) {
                        _showUpgradePrompt('Chat Persistence 🔖');
                        return;
                      }

                      try {
                        final client = ref.read(clientProvider);
                        final isPersistent =
                            details.channel?.isPersistent ?? false;
                        await client.message.updateChannelPersistence(
                          channelId,
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
                          ref.invalidate(privateChatDetailsProvider(channelId));
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
                        if (currentResident?.isPlus != true)
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
                DuoRefreshButton(
                  color: Colors.black,
                  onRefresh: () {
                    ref
                        .read(realtimeChatProvider(channelId).notifier)
                        .refresh();
                  },
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
                              .leaveChat(channelId);
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
                            Text('🚪', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
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
            controller: messageController,
            onSend: sendMessage,
            onVoiceSend: sendVoiceMessage,
            onVoiceStart: () async {
              if (currentResident == null) return false;

              if (!currentResident.isPlus) {
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
            onTypingStatusChanged: handleTypingStatus,
            onImagePick: () async {
              pickAndSendImage();
            },
            mentionsWhitelist: [otherName],
            enabled: canSend,
            isSending: isSending,
            isLoading: currentResidentAsync.isLoading,
            focusNode: focusNode,
            activeColor: AppTheme.duoOrange,
            header: (chatState.value?.pinnedMessage != null)
                ? PinnedMessageBar(
                    message: chatState.value!.pinnedMessage!,
                    onUnpin: () => ref
                        .read(realtimeChatProvider(channelId).notifier)
                        .unpinMessage(chatState.value!.pinnedMessage!.id!),
                  )
                : null,
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
                  onPressed: () =>
                      ref.invalidate(privateChatDetailsProvider(channelId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
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

  Widget _buildMessagesList(
    RealtimeChatState state,
    String otherName,
    Resident? currentResident,
    String otherUserId,
  ) {
    final messages = state.messages;
    final lastReadStatus = state.lastReadStatus;
    final otherLastReadAt = lastReadStatus[otherUserId];

    final socialState = ref.watch(socialRelationshipsStateProvider).value;
    final blockedUsers = socialState?.blockedUserIds ?? [];

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(realtimeChatProvider(channelId).notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: filteredMessages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredMessages.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: state.isLoadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : state.hasMore
                    ? const Text(
                        'Scroll for more messages',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          bool isRead = false;
          // Only Plus users can SEE read receipts
          if (isCurrentUser &&
              currentResident.isPlus &&
              currentResident.showOthersReadReceipts &&
              otherLastReadAt != null) {
            isRead = message.createdAt.isBefore(otherLastReadAt);
          }

          return MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
                onMention: (name) {
                  final current = messageController.text;
                  if (current.isEmpty || current.endsWith(' ')) {
                    messageController.text = '$current@$name ';
                  } else {
                    messageController.text = '$current @$name ';
                  }
                  messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: messageController.text.length),
                  );
                  focusNode.requestFocus();
                },
                otherMemberNames: [otherName],
                isRead: isRead,
                canPin: true, // Both participants can pin in private chats
                canRecall: isCurrentUser,
              )
              .animate(delay: Duration(milliseconds: index * 10))
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
