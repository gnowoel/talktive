import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_group_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import 'create_group_dialog.dart';
import '../../widgets/duo/duo_floor_requirement_dialog.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../providers/current_resident_provider.dart';

/// Duolingo-style Groups screen - Community discussions
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupListProvider);

    return DuoPageScaffold(
      emoji: '🏘️',
      title: 'Lounges',
      subtitle: 'Join the community clubhouse',
      gradient: AppTheme.duoBlueGradient,
      trailingHeader: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DuoRefreshButton(
            color: Colors.white,
            onRefresh: () async => ref.invalidate(groupListProvider),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/groups/search');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppTheme.duoBlue,
        elevation: 6,
        child: const Icon(Icons.group_add, color: Colors.white),
      ).animate().scale(delay: 300.ms, duration: 200.ms),
      body: groupsAsync.when(
        data: (groups) => _buildGroupList(context, ref, groups),
        loading: () => const DuoLoadingIndicator(),
        error: (error, _) => DuoEmptyState(
          emoji: '🔇',
          title: 'Connection Lost',
          subtitle: 'The clubhouse door is stuck. Try again?',
          onActionPressed: () => ref.invalidate(groupListProvider),
          actionLabel: 'Retry',
        ),
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    WidgetRef ref,
    List<GroupWithMembership> groups,
  ) {
    if (groups.isEmpty) {
      return DuoEmptyState(
        emoji: '🏢',
        title: 'Empty Clubhouse',
        subtitle: 'No clubs yet. Why not create one?',
        onActionPressed: () => _showCreateDialog(context, ref),
        actionLabel: 'Start a Club',
      );
    }

    // Sort: Invites/Applications first, then Active groups
    final pending = groups
        .where(
          (g) =>
              g.membershipStatus == ChannelMemberStatus.invited ||
              g.membershipStatus == ChannelMemberStatus.applied,
        )
        .toList();

    final joined = groups
        .where((g) => g.membershipStatus == ChannelMemberStatus.joined)
        .toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupListProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader(context, '🎫 The Doorstep'),
            ...pending.asMap().entries.map(
              (entry) => _buildGroupCard(context, ref, entry.value, entry.key),
            ),
            const SizedBox(height: 32),
          ],

          if (joined.isNotEmpty) ...[
            _buildSectionHeader(context, '🛋️ My Lounges'),
            ...joined.asMap().entries.map(
              (entry) => _buildGroupCard(context, ref, entry.value, entry.key),
            ),
          ],

          const SizedBox(height: AppTheme.contentBottomPadding),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.duoBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.duoBlue,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
    final status = groupWithMembership.membershipStatus;
    final isInvite = status == ChannelMemberStatus.invited;
    final isApplied = status == ChannelMemberStatus.applied;

    return DuoGroupCard(
      group: group,
      onTap: () {
        HapticFeedback.lightImpact();
        if (isInvite) {
          DuoSnackBarHelper.showInfo(
            context,
            'Please accept the invitation to join this group.',
          );
          return;
        }
        if (isApplied) {
          DuoSnackBarHelper.showInfo(
            context,
            'Your application is pending approval.',
          );
          return;
        }
        context.push('/groups/chat/${group.id!}', extra: group);
      },
      trailing: (isInvite || isApplied)
          ? _buildStatusBadge(context, isInvite ? 'INVITED' : 'APPLIED')
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (groupWithMembership.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.duoRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      groupWithMembership.unreadCount.toString(),
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
      bottomActions: isInvite
          ? [
              Row(
                children: [
                  Expanded(
                    child: DuoButton(
                      text: 'Decline',
                      color: AppTheme.duoRed,
                      isSecondary: true,
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await ref
                              .read(groupListProvider.notifier)
                              .respondToInvite(group.id!, false);
                          if (context.mounted) {
                            DuoSnackBarHelper.showInfo(
                              context,
                              'Invitation declined.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            DuoSnackBarHelper.showError(
                              context,
                              'Failed to decline: $e',
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            DuoSnackBarHelper.showSuccess(
                              context,
                              'Invitation accepted!',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            DuoSnackBarHelper.showError(
                              context,
                              'Failed to accept: $e',
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ]
          : null,
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildStatusBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.duoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.duoBlue,
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) async {
    debugPrint('GroupsScreen: [_showCreateDialog] FAB tapped');
    HapticFeedback.lightImpact();

    Resident? currentResident = ref.read(currentResidentProvider).value;
    
    if (currentResident == null) {
      debugPrint('GroupsScreen: currentResident is null, waiting for future...');
      try {
        currentResident = await ref.read(currentResidentProvider.future);
      } catch (e) {
        debugPrint('GroupsScreen: Error waiting for resident: $e');
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, 'Failed to load profile.');
        }
        return;
      }
    }

    if (currentResident == null) {
      debugPrint('GroupsScreen: Resident still null after waiting');
      if (context.mounted) {
        DuoSnackBarHelper.showError(context, 'Resident profile not found.');
      }
      return;
    }

    if (DuoFloorHelper.isMuted(currentResident)) {
      debugPrint('GroupsScreen: Resident is muted');
      DuoSnackBarHelper.showError(
        context,
        DuoFloorHelper.getMuteReason(currentResident),
      );
      return;
    }

    final effectiveFloor = DuoFloorHelper.computeFloor(currentResident);
    debugPrint('GroupsScreen: Effective floor: $effectiveFloor');

    if (effectiveFloor < 1) {
      DuoFloorRequirementDialog.show(
        context,
        message: 'You must reach Floor 1 to create a club. Keep chatting!',
        requiredFloor: 1,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupDialog(),
    );
  }
}
