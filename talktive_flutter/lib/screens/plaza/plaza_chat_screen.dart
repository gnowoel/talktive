import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/blocked_users_provider.dart';
import '../../config/theme.dart';
import '../../helpers/snackbar_helper.dart';
import '../../utils/floor_utils.dart';

import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_info_banner.dart';

import '../../widgets/duo/duo_page_scaffold.dart';

/// Duolingo-style Global Lounge screen - public chat
class PlazaChatScreen extends ConsumerStatefulWidget {
  const PlazaChatScreen({super.key});

  @override
  ConsumerState<PlazaChatScreen> createState() =>
      _PlazaChatScreenState();
}

class _PlazaChatScreenState extends ConsumerState<PlazaChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentResident = ref.read(currentResidentProvider).value;

    // Check reputation (mute check)
    if (currentResident != null && currentResident.trustScore <= 0) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Your reputation is too low to send messages',
        );
      }
      return;
    }

    try {
      await ref.read(realtimeChatProvider(1).notifier).sendMessage(content);
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
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(realtimeChatProvider(1));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 24)),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Lounge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Chat with everyone',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info banner
          const DuoInfoBanner(
            bannerId: 'plaza_text_only',
            text: 'Text only. No images allowed in Plaza.',
          ),
          // Messages list
          Expanded(
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const DuoEmptyState(
                    emoji: '👋',
                    title: 'Say hello!',
                    subtitle: 'Be the first to start a conversation',
                  );
                }
                return _buildMessagesList(messages, currentResident);
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
          ),
          // Input area
          _buildInputArea(currentResident),
        ],
      ),
    );
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

  Widget _buildInputArea(Resident? currentResident) {
    final canSend = currentResident == null || currentResident.trustScore > 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _messageController,
                enabled: canSend,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, fontFamily: 'Rubik'),
                decoration: InputDecoration(
                  hintText: canSend
                      ? 'Type a message...'
                      : 'Need credits to chat',
                  hintStyle: TextStyle(
                    color: AppTheme.textLight,
                    fontFamily: 'Rubik',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.duoSpacingMedium,
                    vertical: AppTheme.duoSpacingSmall,
                  ),
                  prefixIcon: canSend
                      ? null
                      : const Icon(
                          Icons.lock,
                          color: AppTheme.textLight,
                          size: 20,
                        ),
                ),
                onSubmitted: canSend ? (_) => _sendMessage() : null,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          GestureDetector(
            onTap: canSend ? _sendMessage : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: canSend
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: canSend ? null : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
