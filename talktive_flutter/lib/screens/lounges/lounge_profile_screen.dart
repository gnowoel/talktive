import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/lounge_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/resident_ext.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../providers/client_provider.dart';
import 'create_lounge_dialog.dart';

class LoungeProfileScreen extends ConsumerWidget {
  final int loungeId;
  final Lounge? initialLounge; // Used for immediate display

  const LoungeProfileScreen({
    super.key,
    required this.loungeId,
    this.initialLounge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loungeAsync = ref.watch(loungeWithMembershipProvider(loungeId));
    final currentResident = ref.watch(currentResidentProvider).value;

    return loungeAsync.when(
      data: (membership) {
        final lounge = membership?.lounge ?? initialLounge;
        if (lounge == null) {
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
                emoji: '🕵️‍♂️',
                title: 'Lounge Not Found',
                subtitle: 'This lounge might have been disbanded.',
              ),
            ),
          );
        }

        final isCreator = currentResident?.userInfoId == lounge.creatorId;
        final status = membership?.membershipStatus;
        final isJoined = status == ChannelMemberStatus.joined;
        final isApplied = status == ChannelMemberStatus.applied;
        final isInvited = status == ChannelMemberStatus.invited;

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
            actions: [
              if (currentResident?.isStaff ?? false)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.gavel,
                    size: 24,
                    color: AppTheme.textPrimary,
                  ),
                  onSelected: (value) async {
                    if (value == 'admin_private') {
                      _confirmForceAdminPrivate(context, ref, lounge);
                    } else if (value == 'admin_disband') {
                      _confirmAdminDisband(context, ref, lounge);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'admin_private',
                      enabled: lounge.isPublic && !lounge.isStaffLocked,
                      child: Text(
                        lounge.isStaffLocked
                            ? 'Lounge Locked'
                            : 'Force Private',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'admin_disband',
                      child: Text(
                        'Admin: Disband',
                        style: TextStyle(color: AppTheme.duoRed),
                      ),
                    ),
                  ],
                ),
              if (isCreator)
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 24,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () => _showEditDialog(context, lounge),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(context, lounge, isJoined),

                const SizedBox(height: 24),

                // Creator section
                _buildCreatorSection(context, ref, lounge.creatorId),

                const SizedBox(height: 24),

                // Description
                Text(
                  'About this Lounge',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DuoCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    lounge.description ?? 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 24),

                // House Rules
                if (lounge.rules != null && lounge.rules!.isNotEmpty) ...[
                  Text(
                    'House Rules',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DuoCard(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.duoOrange.withValues(alpha: 0.05),
                    borderColor: AppTheme.duoOrange.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '✋',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Please follow these guidelines:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.duoOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lounge.rules!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 24),

                // Interests
                if (lounge.interests != null &&
                    lounge.interests!.isNotEmpty) ...[
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
                    children: lounge.interests!
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
                  lounge,
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
      loading: () => initialLounge != null
          ? _buildWithInitialData(context, ref, initialLounge!, currentResident)
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
            emoji: '⚠️',
            title: 'Lounge Trouble',
            subtitle: err.toString(),
            buttonText: 'Retry',
            onButtonPressed: () =>
                ref.invalidate(loungeWithMembershipProvider(loungeId)),
          ),
        ),
      ),
    );
  }

  Widget _buildWithInitialData(
    BuildContext context,
    WidgetRef ref,
    Lounge lounge,
    Resident? currentResident,
  ) {
    // Partial view while loading full membership state
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
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Center(child: DuoLoadingIndicator()),
    );
  }

  Widget _buildStatusCard(BuildContext context, Lounge lounge, bool isJoined) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DuoStatCard(
                emoji: '📈',
                value: 'Lv. ${lounge.level}',
                label: 'Lounge Level',
                gradientColors: AppTheme.duoBlueGradient,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DuoStatCard(
                emoji: '👥',
                value: '${lounge.memberCount}',
                label: 'Members',
                gradientColors: AppTheme.duoGreenGradient,
                onTap: isJoined
                    ? () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/lounges/members/${lounge.id!}',
                          extra: lounge,
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DuoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EXPERIENCE POINTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${lounge.xp % 100}/100 XP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.duoBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (lounge.xp % 100) / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.duoBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'This lounge can hold up to ${lounge.maxMembers} members. Level up to expand! 🚀',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    dynamic value, // String or IconData
    String label, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        if (value is IconData)
          Icon(value, size: 24, color: AppTheme.duoBlue)
        else
          Text(
            value.toString(),
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
          'Lounge Host',
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
    Lounge lounge,
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
                    Text('🔕', style: TextStyle(fontSize: 24)),
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
                        .read(loungeListProvider.notifier)
                        .toggleMuteLounge(lounge.id!, val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              text: 'Enter Lounge',
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
            Text('⏳', style: TextStyle(fontSize: 24)),
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
                      .read(loungeListProvider.notifier)
                      .respondToInvite(lounge.id!, false);
                  if (context.mounted) {
                    DuoSnackBarHelper.showInfo(context, 'Invitation declined.');
                    Navigator.pop(context);
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
          const SizedBox(width: 12),
          Expanded(
            child: DuoButton(
              text: 'Accept',
              color: AppTheme.duoGreen,
              onPressed: () async {
                HapticFeedback.lightImpact();
                try {
                  await ref
                      .read(loungeListProvider.notifier)
                      .respondToInvite(lounge.id!, true);
                  if (context.mounted) {
                    DuoSnackBarHelper.showSuccess(
                      context,
                      'Invitation accepted!',
                    );
                    // Instead of popping, we just invalidate and let the view refresh
                    ref.invalidate(loungeWithMembershipProvider(lounge.id!));
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
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DuoButton(
        text: lounge.isPublic ? 'Apply to Join' : 'Request Invite',
        onPressed: () async {
          HapticFeedback.mediumImpact();
          try {
            await ref
                .read(loungeListProvider.notifier)
                .applyToLounge(lounge.id!);
            if (context.mounted) {
              DuoSnackBarHelper.showSuccess(context, 'Application sent!');
            }
          } catch (e) {
            if (context.mounted) {
              DuoSnackBarHelper.showError(context, 'Failed to apply');
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Lounge lounge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateLoungeDialog(existingLounge: lounge),
    );
  }

  void _confirmForceAdminPrivate(
    BuildContext context,
    WidgetRef ref,
    Lounge lounge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Action: Force Private?'),
        content: Text(
          'This will force "${lounge.name}" to become private and lock it permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoOrange),
            child: const Text('FORCE PRIVATE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final client = ref.read(clientProvider);
        await client.admin.makeLoungePrivate(lounge.id!);
        if (context.mounted) {
          ref.invalidate(loungeWithMembershipProvider(lounge.id!));
          ref.invalidate(loungeListProvider);
          DuoSnackBarHelper.showSuccess(context, 'Lounge visibility locked.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  void _confirmAdminDisband(
    BuildContext context,
    WidgetRef ref,
    Lounge lounge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Admin Action: Disband Lounge?',
          style: TextStyle(color: AppTheme.duoRed),
        ),
        content: Text(
          'Permanently delete "${lounge.name}" and all its content for everyone?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoRed),
            child: const Text('DISBAND PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final client = ref.read(clientProvider);
        await client.admin.disbandLounge(
          loungeId: lounge.id!,
          reason: 'Administrative action',
        );
        if (context.mounted) {
          ref.invalidate(loungeListProvider);
          Navigator.pop(context);
          DuoSnackBarHelper.showSuccess(context, 'Lounge has been disbanded.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }
}
