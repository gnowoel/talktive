import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../utils/floor_utils.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_resident_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../helpers/snackbar_helper.dart';
import '../profile/user_profile_view_screen.dart';

class GroupMembersScreen extends ConsumerWidget {
  final Group group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersWithProfilesProvider(group.id!));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    
    final isCreator = currentResidentAsync.value?.userInfoId == group.creatorId;
    
    // Only fetch pending applications if user is creator
    final pendingAsync = isCreator 
        ? ref.watch(pendingApplicationsProvider(group.id!))
        : const AsyncValue.data(<GroupMemberWithProfile>[]);

    return DuoPageScaffold(
      emoji: '👥',
      title: group.name,
      subtitle: '${group.memberCount} members',
      gradient: AppTheme.duoBlueGradient,
      body: membersAsync.when(
        data: (members) => pendingAsync.when(
          data: (pending) => _buildBody(context, ref, members, pending, isCreator),
          loading: () => const DuoLoadingIndicator(),
          error: (error, stack) => _buildErrorState(context, error),
        ),
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, 
    WidgetRef ref, 
    List<GroupMemberWithProfile> members, 
    List<GroupMemberWithProfile> pending,
    bool isCreator
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupMembersWithProfilesProvider(group.id!));
        if (isCreator) ref.invalidate(pendingApplicationsProvider(group.id!));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        children: [
          if (isCreator && pending.isNotEmpty) ...[
            _buildSectionHeader(context, '🎫 Pending Applications (${pending.length})'),
            ...pending.map((m) => _buildMemberCard(context, ref, m, isCreator, isPending: true)),
            const SizedBox(height: AppTheme.duoSpacingLarge),
          ],
          _buildSectionHeader(context, '👥 Residents (${members.length})'),
          ...members.map((m) => _buildMemberCard(context, ref, m, isCreator)),
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

  Widget _buildMemberCard(
    BuildContext context, 
    WidgetRef ref, 
    GroupMemberWithProfile memberProfile, 
    bool isCreator, 
    {bool isPending = false}
  ) {
    final resident = memberProfile.resident;
    final isTargetCreator = resident.userInfoId == group.creatorId;

    return DuoResidentCard(
      resident: resident,
      isHost: isTargetCreator,
      showBadge: isPending,
      badgeText: 'APPLYING',
      badgeColor: AppTheme.duoBlue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              userId: resident.userInfoId.toString(),
              userName: resident.userName,
              userAvatar: resident.avatar,
              userFloor: FloorUtils.computeFloor(resident),
            ),
          ),
        );
      },
      actions: isCreator && !isTargetCreator
          ? [
              if (isPending) ...[
                DuoButton(
                  text: 'Ignore',
                  variant: DuoButtonVariant.secondary,
                  size: DuoButtonSize.small,
                  onPressed: () => _handleApplication(context, ref, resident.userInfoId.toString(), false),
                ),
                const SizedBox(width: 8),
                DuoButton(
                  text: 'Accept',
                  size: DuoButtonSize.small,
                  onPressed: () => _handleApplication(context, ref, resident.userInfoId.toString(), true),
                ),
              ] else ...[
                DuoButton(
                  text: 'Kick',
                  variant: DuoButtonVariant.secondary,
                  size: DuoButtonSize.small,
                  color: AppTheme.duoRed,
                  onPressed: () => _confirmKick(context, ref, resident),
                ),
              ]
            ]
          : null,
    );
  }

  Future<void> _handleApplication(BuildContext context, WidgetRef ref, String userId, bool approved) async {
    HapticFeedback.mediumImpact();
    try {
      final client = ref.read(clientProvider);
      await client.group.respondToGroupApplication(group.id!, userId, approved);
      
      ref.invalidate(groupMembersWithProfilesProvider(group.id!));
      ref.invalidate(pendingApplicationsProvider(group.id!));
      ref.invalidate(groupListProvider);
      
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, approved ? 'Member accepted!' : 'Application ignored.');
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showError(context, e.toString());
    }
  }

  void _confirmKick(BuildContext context, WidgetRef ref, Resident resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kick resident?'),
        content: Text('Are you sure you want to remove ${resident.userName} from this club?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoRed),
            child: const Text('Kick'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _kickMember(context, ref, resident.userInfoId.toString());
    }
  }

  Future<void> _kickMember(BuildContext context, WidgetRef ref, String userId) async {
    HapticFeedback.heavyImpact();
    try {
      final client = ref.read(clientProvider);
      await client.group.kickMember(group.id!, userId);
      
      ref.invalidate(groupMembersWithProfilesProvider(group.id!));
      ref.invalidate(groupListProvider);
      
      if (context.mounted) SnackBarHelper.showSuccess(context, 'Resident removed from club.');
    } catch (e) {
      if (context.mounted) SnackBarHelper.showError(context, e.toString());
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.duoRed, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
