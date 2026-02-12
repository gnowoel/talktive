import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import 'group_chat_screen.dart';
import 'create_group_dialog.dart';

/// Duolingo-style Groups screen - list of group chats
class GroupsScreenModern extends ConsumerWidget {
  const GroupsScreenModern({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const DuoHeader(
              emoji: '👥',
              title: 'Groups',
              subtitle: 'Join communities',
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
            Expanded(
              child: groupsState.when(
                data: (groups) => groups.isEmpty
                    ? _buildEmptyState(context, ref)
                    : _buildGroupList(context, ref, groups),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
                error: (error, stack) => _buildErrorState(context, ref, error),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: () {
          HapticFeedback.lightImpact();
          _showCreateGroupDialog(context, ref);
        },
        backgroundColor: AppTheme.duoOrange,
        child: const Icon(Icons.add, size: 28),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: DuoEmptyState(
        emoji: '🎉',
        title: 'No groups yet',
        subtitle: 'Create or join a community',
        buttonText: 'Create Group',
        onButtonPressed: () {
          _showCreateGroupDialog(context, ref);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load groups',
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
          const SizedBox(height: AppTheme.duoSpacingLarge),
          ElevatedButton(
            onPressed: () {
              ref.read(groupListProvider.notifier).refresh();
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

  Widget _buildGroupList(
    BuildContext context,
    WidgetRef ref,
    List<Group> groups,
  ) {
    return RefreshIndicator(
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
            // Group icon/emoji
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
            // Group info
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
                      const SizedBox(width: 12),
                      Icon(Icons.person_add, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Max ${group.maxMembers}',
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

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }
}
