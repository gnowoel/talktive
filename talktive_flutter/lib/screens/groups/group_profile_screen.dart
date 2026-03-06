import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../helpers/snackbar_helper.dart';
import 'create_group_dialog.dart';

class GroupProfileScreen extends ConsumerWidget {
  final Group group;
  final bool isFromSearch;

  const GroupProfileScreen({
    super.key,
    required this.group,
    this.isFromSearch = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentResident = ref.watch(currentResidentProvider).value;
    final isCreator = currentResident?.userInfoId == group.creatorId;
    
    // Check if user is already a member
    final myGroups = ref.watch(groupListProvider).value ?? [];
    final membership = myGroups.where((g) => g.group.id == group.id).firstOrNull;
    final isJoined = membership?.membershipStatus == ChannelMemberStatus.joined;
    final isApplied = membership?.membershipStatus == ChannelMemberStatus.applied;
    final isInvited = membership?.membershipStatus == ChannelMemberStatus.invited;

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
            _buildStatusCard(context, group),
            
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
  }

  Widget _buildStatusCard(BuildContext context, Group group) {
    return DuoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, group.memberCount.toString(), 'Members'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.maxMembers.toString(), 'Capacity'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(context, group.isPublic ? '🔓' : '🔒', 'Access'),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
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
            // In a real app we'd navigate to chat. Since we're in profile, 
            // if we came from chat we might want to just pop.
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
