import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/lounge_provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_resident_card.dart';
import '../../widgets/duo/duo_button.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';

class LoungeMembersScreen extends ConsumerWidget {
  final int loungeId;
  final Lounge? initialLounge;

  const LoungeMembersScreen({
    super.key,
    required this.loungeId,
    this.initialLounge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loungeAsync = ref.watch(loungeWithMembershipProvider(loungeId));
    final membersAsync = ref.watch(loungeMembersWithProfilesProvider(loungeId));
    final currentResidentAsync = ref.watch(currentResidentProvider);

    return loungeAsync.when(
      data: (membership) {
        final lounge = membership?.lounge ?? initialLounge;
        if (lounge == null) {
          return const Scaffold(body: Center(child: Text('Lounge not found')));
        }

        final isCreator =
            currentResidentAsync.value?.userInfoId == lounge.creatorId;

        // Only fetch pending applications if user is creator
        final pendingAsync = isCreator
            ? ref.watch(pendingApplicationsProvider(loungeId))
            : const AsyncValue.data(<LoungeMemberWithProfile>[]);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              lounge.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppTheme.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: membersAsync.when(
            data: (members) => pendingAsync.when(
              data: (pending) =>
                  _buildBody(context, ref, members, pending, isCreator, lounge),
              loading: () => const DuoLoadingIndicator(),
              error: (error, stack) => _buildErrorState(context, error),
            ),
            loading: () => const DuoLoadingIndicator(),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        );
      },

      loading: () => const Scaffold(body: Center(child: DuoLoadingIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<LoungeMemberWithProfile> members,
    List<LoungeMemberWithProfile> pending,
    bool isCreator,
    Lounge lounge,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(loungeMembersWithProfilesProvider(loungeId));
        if (isCreator) ref.invalidate(pendingApplicationsProvider(loungeId));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        children: [
          if (isCreator && pending.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              '🎫 Pending Applications (${pending.length})',
            ),
            ...pending.map(
              (m) => _buildMemberCard(
                context,
                ref,
                m,
                isCreator,
                lounge,
                isPending: true,
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
          ],
          _buildSectionHeader(context, '👥 Residents (${members.length})'),
          ...members.map(
            (m) => _buildMemberCard(context, ref, m, isCreator, lounge),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
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
    LoungeMemberWithProfile memberProfile,
    bool isCreator,
    Lounge lounge, {
    bool isPending = false,
  }) {
    final resident = memberProfile.resident;
    final isTargetCreator = resident.userInfoId == lounge.creatorId;

    return DuoResidentCard(
      resident: resident,
      isHost: isTargetCreator,
      showBadge: isPending,
      badgeText: 'APPLYING',
      badgeColor: AppTheme.duoBlue,
      onTap: () {
        context.push(
          '/user/${resident.userInfoId.toString()}',
          extra: {
            'userName': resident.userName,
            'userAvatar': resident.customAvatarUrl ?? resident.avatar,
            'userFloor': DuoFloorHelper.computeFloor(resident),
          },
        );
      },
      actions: isCreator && !isTargetCreator
          ? [
              if (isPending) ...[
                DuoButton(
                  text: 'Ignore',
                  variant: DuoButtonVariant.secondary,
                  size: DuoButtonSize.small,
                  onPressed: () => _handleApplication(
                    context,
                    ref,
                    resident.userInfoId.toString(),
                    false,
                  ),
                ),
                const SizedBox(width: 8),
                DuoButton(
                  text: 'Accept',
                  size: DuoButtonSize.small,
                  onPressed: () => _handleApplication(
                    context,
                    ref,
                    resident.userInfoId.toString(),
                    true,
                  ),
                ),
              ] else ...[
                DuoButton(
                  text: 'Kick',
                  variant: DuoButtonVariant.secondary,
                  size: DuoButtonSize.small,
                  color: AppTheme.duoRed,
                  onPressed: () => _confirmKick(context, ref, resident, lounge),
                ),
              ],
            ]
          : null,
    );
  }

  Future<void> _handleApplication(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool approved,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      final client = ref.read(clientProvider);
      await client.lounge.approveLoungeApplication(loungeId, userId, approved);

      ref.invalidate(loungeMembersWithProfilesProvider(loungeId));
      ref.invalidate(pendingApplicationsProvider(loungeId));
      ref.invalidate(loungeListProvider);

      if (context.mounted) {
        DuoSnackBarHelper.showSuccess(
          context,
          approved ? 'Member accepted!' : 'Application ignored.',
        );
      }
    } catch (e) {
      if (context.mounted) DuoSnackBarHelper.showError(context, e.toString());
    }
  }

  void _confirmKick(
    BuildContext context,
    WidgetRef ref,
    Resident resident,
    Lounge lounge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kick resident?'),
        content: Text(
          'Are you sure you want to remove ${resident.userName} from this lounge?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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

  Future<void> _kickMember(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    HapticFeedback.heavyImpact();
    try {
      final client = ref.read(clientProvider);
      await client.lounge.kickMember(loungeId, userId);

      ref.invalidate(loungeMembersWithProfilesProvider(loungeId));
      ref.invalidate(loungeListProvider);

      if (context.mounted) {
        DuoSnackBarHelper.showSuccess(context, 'Resident removed from clubhouse.');
      }
    } catch (e) {
      if (context.mounted) DuoSnackBarHelper.showError(context, e.toString());
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
