import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:go_router/go_router.dart';
import '../../providers/private_chat_provider.dart';
import '../../config/theme.dart';
import '../../utils/floor_utils.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import 'chat_thread_screen.dart';

/// Duolingo-style Chats screen - list of private conversations
class ChatsScreenModern extends ConsumerWidget {
  const ChatsScreenModern({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(privateChatListProvider);

    return DuoPageScaffold(
      emoji: '💬',
      title: 'Chats',
      subtitle: 'Private conversations',
      gradient: AppTheme.duoOrangeGradient,
      body: chatsState.when(
        data: (chats) => chats.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(privateChatListProvider.notifier).refresh();
                },
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.duoSpacingMedium,
                    AppTheme.duoSpacingMedium,
                    AppTheme.duoSpacingMedium,
                    AppTheme.contentBottomPadding,
                  ),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatWithProfile = chats[index];
                    return _buildChatCard(context, ref, chatWithProfile, index)
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1, end: 0);
                  },
                ),
              ),
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: DuoEmptyState(
        emoji: '👋',
        title: 'No chats yet',
        subtitle: 'Start a conversation with someone in the Plaza!',
        buttonText: 'Go to Plaza',
        onButtonPressed: () {
          context.go('/users');
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: DuoEmptyState(
        emoji: '😕',
        title: 'Something went wrong',
        subtitle: 'We couldn\'t load your chats. Please try again.',
        buttonText: 'Retry',
        onButtonPressed: () {
          ref.read(privateChatListProvider.notifier).refresh();
        },
      ),
    );
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

    // We don't need to resolve current resident just to show the other user anymore!
    // But we might need it for navigation (ChatThreadScreen might need my ID? No, it needs privateChat object)

    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatThreadScreen(
              privateChat: chat,
              otherUserId: chatItem.otherResident.userInfoId.uuid,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          children: [
            Stack(
              children: [
                DuoAvatar(
                  initials: otherUserName.isNotEmpty ? otherUserName[0] : '?',
                  imageUrl: otherUserAvatar,
                  size: 56,
                  showRing: true,
                  floorLevel: FloorUtils.computeFloor(chatItem.otherResident),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.duoGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
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
                          _formatTimestamp(chat.lastMessageAt!),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open chat', // Ideally this would be the last message preview, but we don't have it yet
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
