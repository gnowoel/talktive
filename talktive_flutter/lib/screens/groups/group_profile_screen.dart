import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/snackbar_helper.dart';
import '../../utils/floor_utils.dart';
import 'create_group_dialog.dart';
import 'group_members_screen.dart';
import '../profile/user_profile_view_screen.dart';

class GroupProfileScreen extends ConsumerWidget {
  final int groupId;
  final Group? initialGroup; // Used for immediate display

  const GroupProfileScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupWithMembershipProvider(groupId));
    final currentResident = ref.watch(currentResidentProvider).value;

    return groupAsync.when(
      data: (membership) {
        final group = membership?.group ?? initialGroup;
        if (group == null) {
          return const DuoPageScaffold(
            emoji: '❓',
            title: 'Not Found',
            gradient: AppTheme.duoBlueGradient,
            body: DuoEmptyState(
              emoji: '🕵️',
              title: 'Group Not Found',
              subtitle: 'This clubhouse might have been disbanded.',
            ),
          );
        }

        final isCreator = currentResident?.userInfoId == group.creatorId;
        final status = membership?.membershipStatus;
        final isJoined = status == ChannelMemberStatus.joined;
        final isApplied = status == ChannelMemberStatus.applied;
        final isInvited = status == ChannelMemberStatus.invited;

        return DuoPageScaffold(
          emoji: group.emoji ?? '👥',
          title: group.name,
          subtitle: group.isPublic ? 'Public Club' : 'Private Party',
          gradient: AppTheme.duoBlueGradient,
          trailingHeader: isCreator
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    _showEditDialog(context, group);
                  },
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppTheme.contentBottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(context, group, isJoined),
                
                const SizedBox(height: 24),
                
                // Creator section
                _buildCreatorSection(context, ref, group.creatorId),

                const SizedBox(height: 24),
                
                // Description
                Text(
                  'About this Club',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DuoCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    group.description ?? 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Interests
                if (group.interests != null && group.interests!.isNotEmpty) ...[
                  Text(
                    'Interests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.interests!.map((interest) => Chip(
                      label: Text(interest, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.duoBlue)),
                      backgroundColor: AppTheme.duoBlue.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Actions
                const SizedBox(height: 16),
                _buildActionArea(context, ref, group, isJoined, isApplied, isInvited),
              ],
            ),
          ),
        );
      },
      loading: () => initialGroup != null 
          ? _buildWithInitialData(context, ref, initialGroup!, currentResident)
          : const Scaffold(body: DuoLoadingIndicator()),
      error: (err, stack) => DuoPageScaffold(
        emoji: '⚠️',
        title: 'Error',
        gradient: AppTheme.duoRedGradient,
        body: DuoEmptyState(
          emoji: '🔥',
          title: 'Clubhouse Trouble',
          subtitle: err.toString(),
          buttonText: 'Retry',
          onButtonPressed: () => ref.invalidate(groupWithMembershipProvider(groupId)),
        ),
      ),
    );
  }

  Widget _buildWithInitialData(BuildContext context, WidgetRef ref, Group group, Resident? currentResident) {
    // Partial view while loading full membership state
    return DuoPageScaffold(
      emoji: group.emoji ?? '👥',
      title: group.name,
      subtitle: group.isPublic ? 'Public Club' : 'Private Party',
      gradient: AppTheme.duoBlueGradient,
      body: const Center(child: DuoLoadingIndicator()),
    );
  }

  Widget _buildStatusCard(BuildContext context, Group group, bool isJoined) {
    return DuoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context, 
            group.memberCount.toString(), 
            'Members',
            onTap: isJoined ? () {
               HapticFeedback.lightImpact();
               context.push(
                 '/groups/members/${group.id!}',
                 extra: group,
               );
            } : null,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.maxMembers.toString(), 'Capacity'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.isPublic ? '🔓' : '🔒', 'Access'),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.duoBlue),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildCreatorSection(BuildContext context, WidgetRef ref, UuidValue creatorId) {
    final creatorAsync = ref.watch(userProfileProvider(creatorId.toString()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Club Host',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        creatorAsync.when(
          data: (profile) {
            if (profile == null) return const Text('Resident not found');
            return DuoCard(
              onTap: () {
                context.push('/user/${profile.userId}');
              },
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                child: Row(
                  children: [
                    DuoAvatar(
                      imageUrl: profile.userAvatar,
                      size: 48,
                      mood: profile.userMood,
                      showRing: true,
                      floorLevel: profile.floor,
                    ),
                    const SizedBox(width: AppTheme.duoSpacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.userName ?? 'Resident',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Floor ${profile.floor}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
          loading: () => const DuoLoadingIndicator(),
          error: (_, __) => const Text('Could not load host info'),
        ),
      ],
    );
  }

  Widget _buildActionArea(
    BuildContext context, 
    WidgetRef ref, 
    Group group, 
    bool isJoined, 
    bool isApplied, 
    bool isInvited
  ) {
    if (isJoined) {
      return Center(
        child: DuoButton(
          text: 'Enter Clubhouse',
          color: AppTheme.duoBlue,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
      );
    }

    if (isApplied) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.duoBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: AppTheme.duoBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Application pending. The host is reviewing your request.',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.duoBlue),
              ),
            ),
          ],
        ),
      );
    }

    if (isInvited) {
      return Row(
        children: [
          Expanded(
            child: DuoButton(
              text: 'Decline',
              color: AppTheme.duoRed,
              onPressed: () => ref.read(groupListProvider.notifier).respondToInvite(group.id!, false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DuoButton(
              text: 'Accept',
              color: AppTheme.duoGreen,
              onPressed: () => ref.read(groupListProvider.notifier).respondToInvite(group.id!, true),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DuoButton(
        text: group.isPublic ? 'Apply to Join' : 'Request Invite',
        onPressed: () async {
          HapticFeedback.mediumImpact();
          try {
            await ref.read(groupListProvider.notifier).applyToGroup(group.id!);
            if (context.mounted) {
              SnackBarHelper.showSuccess(context, 'Application sent!');
            }
          } catch (e) {
            if (context.mounted) {
              SnackBarHelper.showError(context, 'Failed to apply');
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(existingGroup: group),
    );
  }
}
