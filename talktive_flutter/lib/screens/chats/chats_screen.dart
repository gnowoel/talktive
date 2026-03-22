import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:go_router/go_router.dart';
import '../../providers/private_chat_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../helpers/date_formatter.dart';
import '../../providers/current_resident_provider.dart';

/// Duolingo-style Chats screen - list of private conversations
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(privateChatListProvider);

    return DuoPageScaffold(
      icon: Icons.chat,
      title: 'Chats',
      subtitle: 'Private conversations',
      trailingHeader: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ref.watch(currentResidentProvider).value?.isPremium == true && 
              (ref.watch(currentResidentProvider).value?.showNeighborsDiscovery ?? true))
            IconButton(
              icon: const Icon(Icons.search, size: 28, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/discovery/people');
              },
            ),
          DuoRefreshButton(
            onRefresh: () async {
              await ref.read(privateChatListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      gradient: AppTheme.duoOrangeGradient,
      body: chatsState.when(
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEmptyState(context);
          }

          final pendingChats = chats
              .where(
                (c) => c.currentMemberStatus == ChannelMemberStatus.invited,
              )
              .toList();
          final activeChats = chats
              .where(
                (c) => c.currentMemberStatus != ChannelMemberStatus.invited,
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(privateChatListProvider.notifier).refresh();
            },
            color: AppTheme.primaryColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.duoSpacingMedium,
                AppTheme.duoSpacingMedium,
                AppTheme.duoSpacingMedium,
                AppTheme.contentBottomPadding,
              ),
              children: [
                if (pendingChats.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    '${pendingChats.length} ${pendingChats.length == 1 ? 'Person is' : 'People are'} Knocking...',
                    AppTheme.duoOrange,
                    Icons.door_front_door,
                  ),
                  ...pendingChats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chat = entry.value;
                    return _buildPendingCard(context, ref, chat, index)
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1, end: 0);
                  }),
                  const SizedBox(height: AppTheme.duoSpacingLarge),
                  if (activeChats.isNotEmpty)
                    _buildSectionHeader(
                      context,
                      'Active Chats',
                      AppTheme.textSecondary,
                      Icons.all_inbox,
                    ),
                  const SizedBox(height: AppTheme.duoSpacingSmall),
                ],

                if (activeChats.isEmpty && pendingChats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No active chats.\nReview the door!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ...activeChats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chat = entry.value;
                    return _buildChatCard(context, ref, chat, index)
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1, end: 0);
                  }),
              ],
            ),
          );
        },
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: DuoEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No chats yet',
        subtitle: 'Start a conversation with someone in the Plaza!',
        buttonText: 'Go to Plaza',
        onButtonPressed: () {
          context.go('/plaza');
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: DuoEmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: 'We couldn\'t load your chats. Please try again.',
        buttonText: 'Retry',
        onButtonPressed: () {
          ref.read(privateChatListProvider.notifier).refresh();
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String _getLastMessagePreview(PrivateChatWithProfile chatItem) {
    final lastMsg = chatItem.chat.lastMessage;
    if (lastMsg != null && lastMsg.isNotEmpty) {
      return lastMsg;
    }
    
    final lastAt = chatItem.chat.lastMessageAt;
    if (lastAt != null) {
      return 'Activity: ${formatTimestamp(lastAt)}';
    }
    return 'Start chatting!';
  }

  Widget _buildChatCard(
    BuildContext context,
    WidgetRef ref,
    PrivateChatWithProfile chatItem,
    int index,
  ) {
    final chat = chatItem.chat;
    final otherUserName = chatItem.otherUserName ?? 'Resident';
    final otherUserAvatar = chatItem.otherUserAvatar;

    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      onTap: () {
        HapticFeedback.lightImpact();
        if (chatItem.currentMemberStatus == ChannelMemberStatus.invited) {
          context.push('/chats/peephole', extra: chatItem);
          return;
        }
        context.push('/chats/thread/${chat.channelId}');
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          children: [
            DuoAvatar(
              imageUrl: otherUserAvatar,
              placeholderEmoji: chatItem.otherResident.avatar,
              size: 56,
              mood: chatItem.otherUserMood,
              showRing: true,
              floorLevel: DuoFloorHelper.computeFloor(chatItem.otherResident),
              isOnline: (ref.watch(currentResidentProvider).value?.isPremium ?? false) &&
                  (ref.watch(currentResidentProvider).value?.showOthersOnlineStatus ?? true) &&
                  chatItem.otherResident.showOnlineStatus &&
                  chatItem.otherResident.lastSeen != null &&
                  DateTime.now().difference(chatItem.otherResident.lastSeen!).inMinutes < 5,
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          formatTimestamp(chat.lastMessageAt!),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLastMessagePreview(chatItem),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      color: chatItem.unreadCount > 0
                          ? AppTheme.textPrimary
                          : Colors.grey[500],
                      fontWeight: chatItem.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            if (chatItem.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.duoRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chatItem.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(
    BuildContext context,
    WidgetRef ref,
    PrivateChatWithProfile chatItem,
    int index,
  ) {
    final otherUserName = chatItem.otherUserName ?? 'Stranger';
    final otherUserAvatar = chatItem.otherUserAvatar;

    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      color: Colors.white,
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/chats/peephole', extra: chatItem);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
          border: Border.all(color: AppTheme.duoOrange, width: 2),
        ),
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${chatItem.chat.id}',
              child: DuoAvatar(
                imageUrl: otherUserAvatar,
                placeholderEmoji: chatItem.otherResident.avatar,
                size: 56,
                mood: chatItem.otherUserMood,
                showRing: false,
                floorLevel: DuoFloorHelper.computeFloor(chatItem.otherResident),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.duoOrange, // Highlighted text
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to look through the peephole',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.duoOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.visibility, size: 20, color: AppTheme.duoOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
