import 'package:flutter/material.dart';
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
import 'group_chat_screen.dart';
import 'create_group_dialog.dart';
import 'group_search_screen.dart';
import '../../helpers/snackbar_helper.dart';
import '../../utils/floor_utils.dart';
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
      gradient: AppTheme.duoYellowGradient,
      trailingHeader: IconButton(
        icon: const Icon(Icons.search, color: Colors.white, size: 28),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupSearchScreen()),
          );
        },
      ),
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

  Widget _buildGroupList(BuildContext context, WidgetRef ref, List<GroupWithMembership> groups) {
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
    final pending = groups.where((g) => 
      g.membershipStatus == ChannelMemberStatus.invited || 
      g.membershipStatus == ChannelMemberStatus.applied
    ).toList();
    
    final joined = groups.where((g) => 
      g.membershipStatus == ChannelMemberStatus.joined
    ).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupListProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader(context, '🎫 The Doorstep'),
            ...pending.asMap().entries.map((entry) => _buildGroupCard(context, ref, entry.value, entry.key)),
            const SizedBox(height: 32),
          ],
          
          if (joined.isNotEmpty) ...[
            _buildSectionHeader(context, '🛋️ My Lounges'),
            ...joined.asMap().entries.map((entry) => _buildGroupCard(context, ref, entry.value, entry.key)),
          ],
          
          const SizedBox(height: 32),
          Center(
            child: DuoButton(
              onPressed: () => _showCreateDialog(context, ref),
              icon: Icons.add,
              text: 'Create New Club',
              variant: DuoButtonVariant.ghost,
              color: AppTheme.duoYellow,
            ),
          ),
          const SizedBox(height: AppTheme.contentBottomPadding),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, WidgetRef ref, GroupWithMembership groupWithMembership, int index) {
    final group = groupWithMembership.group;
    final status = groupWithMembership.membershipStatus;
    final isInvite = status == ChannelMemberStatus.invited;
    final isApplied = status == ChannelMemberStatus.applied;

    return DuoGroupCard(
      group: group,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupChatScreen(group: group)),
        );
      },
      trailing: (isInvite || isApplied) 
          ? _buildStatusBadge(context, isInvite ? 'INVITED' : 'APPLIED')
          : const Icon(Icons.chevron_right, color: Colors.grey),
      bottomActions: isInvite ? [
        Row(
          children: [
            Expanded(
              child: DuoButton(
                text: 'Decline',
                color: AppTheme.duoRed,
                isSecondary: true,
                onPressed: () => ref.read(groupListProvider.notifier).respondToInvite(group.id!, false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DuoButton(
                text: 'Accept',
                color: AppTheme.duoGreen,
                onPressed: () => ref.read(groupListProvider.notifier).respondToInvite(group.id!, true),
              ),
            ),
          ],
        ),
      ] : null,
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
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.duoBlue),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    if (FloorUtils.isMuted(currentResident!)) {
      SnackBarHelper.showError(context, FloorUtils.getMuteReason(currentResident!));
      return;
    }

    if (FloorUtils.computeFloor(currentResident!) < 1) {
      SnackBarHelper.showError(context, 'You must reach Floor 1 to create a club. Keep chatting!');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }
}
