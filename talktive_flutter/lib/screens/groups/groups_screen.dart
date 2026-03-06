import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import 'group_chat_screen.dart';
import 'create_group_dialog.dart';
import 'group_search_screen.dart';

/// Duolingo-style Groups screen - Community discussions
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupListProvider);

    return DuoPageScaffold(
      emoji: '👥',
      title: 'Groups',
      subtitle: 'Join communities',
      gradient: AppTheme.duoBlueGradient,
      trailingHeader: IconButton(
        icon: const Icon(Icons.search, color: Colors.white, size: 28),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GroupSearchScreen(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (context) => const CreateGroupDialog(),
          );
        },
        backgroundColor: AppTheme.duoBlue,
        child: const Icon(Icons.add, size: 28),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
      body: groupsState.when(
        data: (groups) {
          if (groups.isEmpty) return _buildEmptyState(context);

          final pendingGroups = groups.where((g) => g.membershipStatus == ChannelMemberStatus.invited || g.membershipStatus == ChannelMemberStatus.applied).toList();
          final activeGroups = groups.where((g) => g.membershipStatus == ChannelMemberStatus.joined).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(groupListProvider.notifier).refresh();
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
                if (pendingGroups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '🎫 The Doorstep',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  ...pendingGroups.asMap().entries.map((entry) => _buildPendingCard(context, ref, entry.value, entry.key)),
                  const SizedBox(height: AppTheme.duoSpacingMedium),
                ],
                if (activeGroups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '🛋️ My Lounges',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  ...activeGroups.asMap().entries.map((entry) => _buildGroupCard(context, ref, entry.value, entry.key)),
                ],
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: DuoEmptyState(
        emoji: '😕',
        title: 'Something went wrong',
        subtitle: 'We couldn\'t load groups. Please try again.',
        buttonText: 'Retry',
        onButtonPressed: () {
          ref.read(groupListProvider.notifier).refresh();
        },
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref,
    GroupWithMembership groupWithMembership,
    int index,
  ) {
    final group = groupWithMembership.group;
    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
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
                    AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
                    AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
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
                  if (group.description != null &&
                      group.description!.isNotEmpty)
                    Text(
                      group.description!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildPendingCard(
    BuildContext context,
    WidgetRef ref,
    GroupWithMembership groupWithMembership,
    int index,
  ) {
    final group = groupWithMembership.group;
    final isInvite = groupWithMembership.membershipStatus == ChannelMemberStatus.invited;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      decoration: BoxDecoration(
        color: isInvite ? AppTheme.duoYellow.withValues(alpha: 0.15) : AppTheme.duoBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        border: Border.all(
          color: isInvite ? AppTheme.duoYellow : AppTheme.duoBlue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.emoji ?? '👥', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isInvite ? 'invited you to join' : 'Pending host approval',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isInvite) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(groupListProvider.notifier).respondToInvite(group.channelId, false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.duoRed,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(groupListProvider.notifier).respondToInvite(group.channelId, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.duoGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}
