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
import '../../widgets/chat/message_bubble_modern.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_page_scaffold.dart';

/// Duolingo-style Plaza screen - public chat for all residents
class PlazaScreenModern extends ConsumerStatefulWidget {
  const PlazaScreenModern({super.key});

  @override
  ConsumerState<PlazaScreenModern> createState() => _PlazaScreenModernState();
}

class _PlazaScreenModernState extends ConsumerState<PlazaScreenModern> {
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

    return DuoPageScaffold(
      emoji: '🏛️',
      title: 'The Plaza',
      subtitle: 'Chat with everyone',
      gradient: AppTheme.primaryGradient,
      trailingHeader: currentResident != null
          ? _buildStatsChip(currentResident)
          : null,
      body: Column(
        children: [
          // Info banner
          _buildInfoBanner(),
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

  Widget _buildStatsChip(Resident currentResident) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      borderRadius: AppTheme.duoRadiusPill,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🏢 ${FloorUtils.computeFloor(currentResident)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Container(width: 1, height: 16, color: AppTheme.textLight),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Text(
            '⭐ ${currentResident.trustScore}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: currentResident.trustScore > 50
                  ? AppTheme.duoGreen
                  : currentResident.trustScore >= 20
                  ? AppTheme.duoYellow
                  : AppTheme.errorColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Expanded(
            child: Text(
              'Text only. No images allowed in Plaza.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.accentColor,
                fontFamily: 'Rubik',
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0);
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
          bottom: AppTheme.contentBottomPadding,
          top: AppTheme.duoSpacingSmall,
        ),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          return MessageBubbleModern(
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentResident != null) ...[
            DuoAvatar(
              imageUrl: currentResident.avatar,
              size: 44,
              showRing: true,
              floorLevel: FloorUtils.computeFloor(currentResident),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
          ],
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
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: canSend ? null : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
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
    );
  }
}
