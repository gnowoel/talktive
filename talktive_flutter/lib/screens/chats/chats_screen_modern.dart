import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import 'chat_thread_screen.dart';
import '../groups/group_chat_screen.dart';
import '../groups/create_group_dialog.dart';

/// Duolingo-style Chats screen - Unified Private & Group conversations
class ChatsScreenModern extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ChatsScreenModern({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ChatsScreenModern> createState() => _ChatsScreenModernState();
}

class _ChatsScreenModernState extends ConsumerState<ChatsScreenModern> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(ChatsScreenModern oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const DuoHeader(
              emoji: '💬',
              title: 'Chats',
              subtitle: 'Conversations & Communities',
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

            // Custom Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.duoSpacingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                boxShadow: [AppTheme.duoCardShadow.first],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Private'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.duoSpacingMedium),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PrivateChatsList(),
                  _GroupChatsList(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Only show FAB on Groups tab
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 1 ? child! : const SizedBox.shrink();
        },
        child: FloatingActionButton(
          heroTag: 'groups_fab',
          onPressed: () {
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              builder: (context) => const CreateGroupDialog(),
            );
          },
          backgroundColor: AppTheme.duoOrange,
          child: const Icon(Icons.add, size: 28),
        ).animate().scale(delay: 300.ms, duration: 300.ms),
      ),
    );
  }
}

class _PrivateChatsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(privateChatListProvider);

    return chatsState.when(
      data: (chats) => chats.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(privateChatListProvider.notifier).refresh();
              },
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _buildChatCard(context, ref, chat, index)
                      .animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0);
                },
              ),
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => _buildErrorState(context, ref, error, isGroup: false),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: DuoEmptyState(
        emoji: '🤝',
        title: 'No chats yet',
        subtitle: 'Start a conversation with someone from the Plaza',
        buttonText: 'Go to Plaza',
        onButtonPressed: () {
          // Navigate to Plaza tab (index 0)
          // Using GoRouter to navigate to the root route which is Plaza in the new layout
          // Or find the ancestor DefaultTabController if HomeScreen uses one (it uses IndexedStack)
          // Best is to use the callback or router.
          // Since we are inside HomeScreen, we can't easily switch the parent IndexedStack index
          // without a provider or callback.
          // However, for now, let's just use GoRouter to force navigation
           context.go('/plaza');
        },
      ),
    );
  }

  Widget _buildChatCard(
    BuildContext context,
    WidgetRef ref,
    PrivateChat chat,
    int index,
  ) {
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;

    if (currentResident == null) {
      return const SizedBox.shrink();
    }

    final otherUserId = chat.participant1Id == currentResident.userInfoId
        ? chat.participant2Id
        : chat.participant1Id;

    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatThreadScreen(
              privateChat: chat,
              otherUserId: otherUserId.uuid,
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
                const DuoAvatar(initials: 'U', size: 56, showRing: true),
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
                          'Resident',
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
                    'Tap to open chat',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
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
}

class _GroupChatsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupListProvider);

    return groupsState.when(
      data: (groups) => groups.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(groupListProvider.notifier).refresh();
              },
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupCard(context, ref, group, index)
                      .animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0);
                },
              ),
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => _buildErrorState(context, ref, error, isGroup: true),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: DuoEmptyState(
        emoji: '🎉',
        title: 'No groups yet',
        subtitle: 'Create or join a community',
        buttonText: 'Create Group',
        onButtonPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateGroupDialog(),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref,
    Group group,
    int index,
  ) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(group: group),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.duoOrange.withValues(alpha: 0.2),
                    AppTheme.duoYellow.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
              ),
              child: Center(
                child: Text(
                  group.emoji ?? '👥',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
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
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.isPublic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.duoGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Public',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.duoGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (group.description != null && group.description!.isNotEmpty)
                    Text(
                      group.description!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount} members',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
}

Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error, {required bool isGroup}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
        const SizedBox(height: AppTheme.duoSpacingMedium),
        Text(
          'Failed to load ${isGroup ? 'groups' : 'chats'}',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.duoSpacingSmall),
        Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.duoSpacingLarge),
        ElevatedButton(
          onPressed: () {
            if (isGroup) {
               ref.read(groupListProvider.notifier).refresh();
            } else {
               ref.read(privateChatListProvider.notifier).refresh();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.duoBorderRadius),
            ),
          ),
          child: const Text('Retry'),
        ),
      ],
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
