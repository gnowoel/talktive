import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/snackbar_helper.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import 'create_group_dialog.dart';

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
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Not Found',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
            ),
            body: const Center(
              child: DuoEmptyState(
                emoji: '🕵️',
                title: 'Group Not Found',
                subtitle: 'This lounge might have been disbanded.',
              ),
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
          subtitle: group.isPublic ? 'Public lounge' : 'Private lounge',
          gradient: group.isPublic
              ? AppTheme.duoBlueGradient
              : AppTheme.duoOrangeGradient,
          hasBackButton: true,
          trailingHeader: isCreator
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditDialog(context, group),
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.interests!
                        .map(
                          (interest) => Chip(
                            label: Text(
                              interest,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.duoBlue,
                              ),
                            ),
                            backgroundColor: AppTheme.duoBlue.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                const SizedBox(height: 16),
                _buildActionArea(
                  context,
                  ref,
                  membership?.isMuted ?? false,
                  group,
                  isJoined,
                  isApplied,
                  isInvited,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => initialGroup != null
          ? _buildWithInitialData(context, ref, initialGroup!, currentResident)
          : const Scaffold(body: Center(child: DuoLoadingIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: DuoEmptyState(
            emoji: '🔥',
            title: 'Clubhouse Trouble',
            subtitle: err.toString(),
            buttonText: 'Retry',
            onButtonPressed: () =>
                ref.invalidate(groupWithMembershipProvider(groupId)),
          ),
        ),
      ),
    );
  }

  Widget _buildWithInitialData(
    BuildContext context,
    WidgetRef ref,
    Group group,
    Resident? currentResident,
  ) {
    // Partial view while loading full membership state
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
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
            onTap: isJoined
                ? () {
                    HapticFeedback.lightImpact();
                    context.push('/groups/members/${group.id!}', extra: group);
                  }
                : null,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.maxMembers.toString(), 'Capacity'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.isPublic ? '🔓' : '🔒', 'Access'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.duoBlue,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  Widget _buildCreatorSection(
    BuildContext context,
    WidgetRef ref,
    UuidValue creatorId,
  ) {
    final creatorAsync = ref.watch(userProfileProvider(creatorId.toString()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Club Host',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Floor ${profile.floor}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
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
          error: (_, _) => const Text('Could not load host info'),
        ),
      ],
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    WidgetRef ref,
    bool isMuted,
    Group group,
    bool isJoined,
    bool isApplied,
    bool isInvited,
  ) {
    if (isJoined) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      'Mute Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isMuted,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref
                        .read(groupListProvider.notifier)
                        .toggleMuteGroup(group.id!, val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              text: 'Enter Clubhouse',
              color: AppTheme.duoBlue,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
            ),
          ),
        ],
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.duoBlue,
                ),
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
              onPressed: () async {
                HapticFeedback.lightImpact();
                try {
                  await ref
                      .read(groupListProvider.notifier)
                      .respondToInvite(group.id!, false);
                  if (context.mounted) {
                    SnackBarHelper.showInfo(context, 'Invitation declined.');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    SnackBarHelper.showError(context, 'Failed to decline: $e');
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DuoButton(
              text: 'Accept',
              color: AppTheme.duoGreen,
              onPressed: () async {
                HapticFeedback.lightImpact();
                try {
                  await ref
                      .read(groupListProvider.notifier)
                      .respondToInvite(group.id!, true);
                  if (context.mounted) {
                    SnackBarHelper.showSuccess(context, 'Invitation accepted!');
                    // Instead of popping, we just invalidate and let the view refresh
                    ref.invalidate(groupWithMembershipProvider(group.id!));
                  }
                } catch (e) {
                  if (context.mounted) {
                    SnackBarHelper.showError(context, 'Failed to accept: $e');
                  }
                }
              },
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupDialog(existingGroup: group),
    );
  }
}
