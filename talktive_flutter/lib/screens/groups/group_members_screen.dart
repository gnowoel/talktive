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
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../helpers/snackbar_helper.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          group.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
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

    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          children: [
            Row(
              children: [
                DuoAvatar(
                  imageUrl: resident.avatar,
                  size: 48,
                  mood: resident.mood,
                  showRing: true,
                  floorLevel: FloorUtils.computeFloor(resident),
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            resident.userName ?? 'Resident',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isTargetCreator) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.duoYellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('HOST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Floor ${FloorUtils.computeFloor(resident)} • ⭐ ${resident.trustScore}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isCreator && !isTargetCreator) ...[
              const SizedBox(height: 12),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: DuoButton(
                        text: 'Decline',
                        color: AppTheme.duoRed,
                        onPressed: () => _respondToApplication(context, ref, resident.userInfoId.toString(), false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DuoButton(
                        text: 'Approve',
                        color: AppTheme.duoGreen,
                        onPressed: () => _respondToApplication(context, ref, resident.userInfoId.toString(), true),
                      ),
                    ),
                  ],
                )
              else
                DuoButton(
                  text: 'Kick from Club',
                  color: AppTheme.duoRed,
                  isSecondary: true,
                  width: double.infinity,
                  onPressed: () => _confirmKick(context, ref, resident),
                ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  void _respondToApplication(BuildContext context, WidgetRef ref, String userId, bool approve) async {
    HapticFeedback.mediumImpact();
    try {
      final client = ref.read(clientProvider);
      await client.group.approveGroupApplication(group.id!, userId, approve);
      
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, approve ? 'Member approved!' : 'Application declined.');
        ref.invalidate(pendingApplicationsProvider(group.id!));
        ref.invalidate(groupMembersWithProfilesProvider(group.id!));
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  void _confirmKick(BuildContext context, WidgetRef ref, Resident member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kick Member?'),
        content: Text('Are you sure you want to remove ${member.userName} from the club?'),
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
      HapticFeedback.heavyImpact();
      try {
        final client = ref.read(clientProvider);
        await client.group.kickMember(group.id!, member.userInfoId.toString());
        if (context.mounted) {
          SnackBarHelper.showSuccess(context, '${member.userName} has been removed.');
          ref.invalidate(groupMembersWithProfilesProvider(group.id!));
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load members',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
