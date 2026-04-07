import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/social_relationships_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../helpers/resident_ext.dart';

import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/pinned_message_bar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_info_banner.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../widgets/duo/duo_typing_indicator.dart';
import '../../utils/ad_navigation_utils.dart';
import '../../widgets/chat/chat_screen_mixin.dart';

/// Duolingo-style Global Lounge screen - public chat
class PlazaChatScreen extends ConsumerStatefulWidget {
  const PlazaChatScreen({super.key});

  @override
  ConsumerState<PlazaChatScreen> createState() => _PlazaChatScreenState();
}

class _PlazaChatScreenState extends ConsumerState<PlazaChatScreen>
    with ChatScreenMixin {
  bool _isExiting = false;

  @override
  int get channelId => 1;

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(realtimeChatProvider(channelId));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final canSend =
        currentResident != null && !DuoFloorHelper.isMuted(currentResident);

    final typingUsers = chatState.value?.typingUsers ?? {};
    final otherTypingUsers = typingUsers
        .where((u) => u != currentResident?.userName)
        .toList();

    return PopScope(
      canPop: _isExiting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          setState(() => _isExiting = true);
          await context.popWithAd(ref);
        }
      },
      child: DuoChatInputLayout(
        typingIndicator:
            (currentResident?.isPlus == true &&
                currentResident?.showOthersTypingIndicators == true &&
                otherTypingUsers.isNotEmpty)
            ? DuoTypingIndicator(typingUsers: otherTypingUsers)
            : null,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.popWithAd(ref);
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
                ref.read(realtimeChatProvider(channelId).notifier).refresh();
              },
            ),
          ],
        ),
        header: Column(
          children: [
            DuoInfoBanner(
              bannerId: 'plaza_image_rules',
              text:
                  currentResident != null &&
                      DuoFloorHelper.computeFloor(currentResident) >= 2
                  ? '📸 You can now share images in the Global Lounge!'
                  : 'Text only. Floor 2+ residents can share images.',
            ),
            if (chatState.value?.pinnedMessage != null)
              PinnedMessageBar(
                message: chatState.value!.pinnedMessage!,
                onUnpin: (currentResident?.isStaff ?? false)
                    ? () => ref
                          .read(realtimeChatProvider(channelId).notifier)
                          .unpinMessage(chatState.value!.pinnedMessage!.id!)
                    : null,
              ),
          ],
        ),
        controller: messageController,
        onSend: sendMessage,
        onVoiceSend: sendVoiceMessage,
        onVoiceStart: () async {
          final currentResident = ref.read(currentResidentProvider).value;
          if (currentResident == null) return false;

          if (!currentResident.isPlus) {
            if (mounted) {
              ref
                  .read(realtimeChatProvider(channelId).notifier)
                  .setTyping(false); // Cancel typing
              // Mixin handles upgrade prompt if we want, but here we keep it custom if needed
            }
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
          pickAndSendImage(floorRestriction: 2);
        },
        enabled: canSend,
        isLoading: currentResidentAsync.isLoading,
        isSending: isSending,
        focusNode: focusNode,
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
            return _buildMessagesList(state, currentResident);
          },
          loading: () => const DuoLoadingIndicator(),
          error: (error, stack) => DuoEmptyState(
            emoji: '😕',
            title: 'Connection Error',
            subtitle: error.toString(),
            buttonText: 'Retry',
            onButtonPressed: () {
              ref.read(realtimeChatProvider(channelId).notifier).refresh();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    RealtimeChatState state,
    Resident? currentResident,
  ) {
    final messages = state.messages;
    final socialState = ref.watch(socialRelationshipsStateProvider).value;
    final blockedUsers = socialState?.blockedUserIds ?? [];

    // For Plaza, we don't have a static member list, so we use the names
    // of people currently visible in the message list for highlighting.
    final visibleMemberNames =
        messages
            .map((m) => m.senderName)
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();

    final filteredMessages =
        messages.where((msg) {
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
        padding: const EdgeInsets.only(
          left: AppTheme.duoSpacingMedium,
          right: AppTheme.duoSpacingMedium,
          bottom: AppTheme.duoSpacingMedium,
          top: AppTheme.duoSpacingSmall,
        ),
        itemCount: filteredMessages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredMessages.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child:
                    state.isLoadingMore
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

          return MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
                onMention: (name) {
                  final current = messageController.text;
                  // Requirement: "inserts @Some User Name " (with trailing space)
                  // We also ensure leading space if not at start.
                  if (current.isEmpty || current.endsWith(' ')) {
                    messageController.text = '$current@$name ';
                  } else {
                    messageController.text = '$current @$name ';
                  }
                  messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: messageController.text.length),
                  );
                  // Focus the input
                  focusNode.requestFocus();
                },
                otherMemberNames: visibleMemberNames,
                canPin: currentResident?.isStaff ?? false,
                canRecall: isCurrentUser || (currentResident?.isStaff ?? false),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 10))
              .slideX(begin: isCurrentUser ? 0.1 : -0.1, end: 0);
        },
      ),
    );
  }
}
