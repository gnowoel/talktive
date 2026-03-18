import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../providers/blocked_users_provider.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/user_likes_provider.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/lounge_provider.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/client_provider.dart';
import 'package:talktive/helpers/duo_trust_score_helper.dart';
import '../../providers/current_resident_provider.dart';
import '../../helpers/resident_ext.dart';

/// Simple user profile view screen
/// Shows basic user info when tapping on an avatar
class UserProfileViewScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final int? userFloor;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.userFloor,
  });

  @override
  ConsumerState<UserProfileViewScreen> createState() =>
      _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends ConsumerState<UserProfileViewScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final blockedIds = ref.watch(blockedUsersProvider).value ?? [];
    final isBlocked = blockedIds.contains(widget.userId);
    final profileAsync = ref.watch(userProfileProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.userName ?? 'Resident',
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          _buildTrailingMenu(isBlocked),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildProfileContent(isBlocked, profile),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      bottomNavigationBar:
          isBlocked || profileAsync.isLoading || profileAsync.hasError
              ? null
              : _buildBottomBar(context, ref),
    );

  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          const Text(
            'Could not load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Rubik',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => ref.invalidate(userProfileProvider(widget.userId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingMenu(bool isBlocked) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.black),
      onSelected: (value) async {
        if (value == 'block') {
          await _confirmBlock(context, isBlocked);
        } else if (value == 'report') {
          _reportUser(context, ref);
        } else if (value == 'admin_mute') {
          _confirmMute(context, ref);
        } else if (value == 'admin_suspend') {
          _confirmSuspend(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(
                isBlocked ? Icons.person_add : Icons.block,
                color: isBlocked ? AppTheme.duoGreen : AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                isBlocked ? 'Unblock resident' : 'Block resident',
                style: TextStyle(
                  color: isBlocked ? AppTheme.duoGreen : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isBlocked)
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: AppTheme.errorColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Report resident',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (ref.watch(currentResidentProvider).value?.isStaff ?? false) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'admin_mute',
            child: Row(
              children: [
                Icon(Icons.volume_off_rounded,
                    color: AppTheme.duoOrange, size: 20),
                SizedBox(width: 12),
                Text(
                  'Staff: Mute Resident',
                  style: TextStyle(
                    color: AppTheme.duoOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'admin_suspend',
            child: Row(
              children: [
                Icon(Icons.gavel_rounded, color: AppTheme.duoRed, size: 20),
                SizedBox(width: 12),
                Text(
                  'Staff: Suspend Resident',
                  style: TextStyle(
                    color: AppTheme.duoRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmBlock(BuildContext context, bool isBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBlocked ? 'Unblock resident?' : 'Block resident?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isBlocked
              ? 'You will be able to see their messages again.'
              : 'You will no longer see their messages, and they cannot start a chat with you.',
        ),
        actions: [
          DuoButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
            variant: DuoButtonVariant.ghost,
            size: DuoButtonSize.small,
          ),
          DuoButton(
            text: isBlocked ? 'Unblock' : 'Block',
            onPressed: () => Navigator.pop(ctx, true),
            color: isBlocked ? AppTheme.duoGreen : AppTheme.errorColor,
            size: DuoButtonSize.small,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(userProfileProvider(widget.userId).notifier).toggleBlock();
        if (context.mounted) {
          DuoSnackBarHelper.showSuccess(
            context,
            isBlocked ? 'Resident unblocked.' : 'Resident blocked.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e);
        }
      }
    }
  }

  Widget _buildProfileContent(bool isBlocked, UserProfileView? profile) {
    final name = profile?.userName ?? widget.userName ?? 'Neighbor';
    final avatar = profile?.userAvatar ?? widget.userAvatar;
    final floor = profile?.floor ?? widget.userFloor ?? 1;
    final bio = profile?.bio;
    final gender = profile?.gender;
    final country = profile?.country;
    final interests = profile?.interests ?? [];
    final languages = profile?.languages ?? [];
    final mutualLounges = profile?.mutualLounges ?? 0;
    final achievementCount = profile?.achievementsUnlocked ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar and basic info
          Center(
            child:
                DuoAvatar(
                      imageUrl: avatar,
                      placeholderEmoji: widget.userAvatar,
                      size: 110,
                      floorLevel: floor,
                      mood: profile?.userMood,
                      trustScore: profile?.trustScore,
                      showRing: true,
                      showFloor: true,
                      showMood: true,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
          
          // Premium Feature: Online/Offline Status
          if (ref.watch(currentResidentProvider).value?.isPremium ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: profile?.isOnline == true ? AppTheme.duoGreen : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile?.isOnline == true ? 'Online' : 'Away',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: profile?.isOnline == true ? AppTheme.duoGreen : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 180.ms),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Rubik',
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],

          const SizedBox(height: AppTheme.duoSpacingLarge),

          // Action Button (Vouch)
          _buildVouchButton(
            profile,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppTheme.duoSpacingMedium),

          // Moments Button (New style)
          _buildMomentsButton(
            profile,
          ).animate().fadeIn(delay: 270.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppTheme.duoSpacingLarge),

          // Stats Grid
          _buildStatsGrid(profile),
          const SizedBox(height: AppTheme.duoSpacingLarge),

          // Info cards
          if (gender != null || country != null)
            _buildInfoCard('About', [
              if (gender != null)
                _buildInfoRow(Icons.person, _formatGender(gender)),
              if (country != null) _buildInfoRow(Icons.flag, country),
              if (mutualLounges > 0)
                _buildInfoRow(Icons.meeting_room, '$mutualLounges mutual lounges'),
            ]),

          if (interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Interests', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests
                    .map(
                      (i) => Chip(
                        label: Text(i.toString()),
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],

          if (languages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Languages', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages
                    .map(
                      (l) => Chip(
                        label: Text(l.toString()),
                        backgroundColor: AppTheme.accentColor.withValues(
                          alpha: 0.1,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.accentColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],

          if (achievementCount > 0) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Achievements', [
              Text(
                '$achievementCount achievements unlocked',
                style: const TextStyle(fontSize: 16, fontFamily: 'Rubik'),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildMomentsButton(UserProfileView? profile) {
    final momentsCount = profile?.totalMoments ?? 0;
    return DuoButton(
      text: '📸 Sharing $momentsCount Moments',
      icon: Icons.auto_awesome,
      isSecondary: true,
      color: AppTheme.duoBlue,
      width: double.infinity,
      onPressed: () {
        final userName = profile?.userName ?? widget.userName ?? 'Resident';
        context.push(
          '/user/${widget.userId}/moments?name=${Uri.encodeComponent(userName)}',
        );
      },
    );
  }

  Widget _buildVouchButton(UserProfileView? profile) {
    if (profile == null) return const SizedBox();
    final isLiked = profile.isLiked;

    return DuoButton(
      text: isLiked ? 'Vouched' : '❤️ Vouch for Resident',
      color: isLiked ? AppTheme.duoGreen : AppTheme.secondaryColor,
      isSecondary: isLiked,
      width: double.infinity,
      onPressed: () async {
        await ref.read(userProfileProvider(widget.userId).notifier).toggleLike();
        if (mounted) {
           DuoSnackBarHelper.showSuccess(
            context,
            isLiked ? 'Vouch removed.' : 'Resident vouched! Trust Score increased.',
          );
        }
      },
    );
  }

  Widget _buildStatsGrid(UserProfileView? profile) {
    final floor = profile?.floor ?? widget.userFloor ?? 1;
    final messages = profile?.totalMessages ?? 0;
    final actualTrustScore = profile?.trustScore ?? 100;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.duoSpacingMedium,
      crossAxisSpacing: AppTheme.duoSpacingMedium,
      childAspectRatio: 1.1,
      children: [
        DuoStatCard(
          icon: Icons.shield,
          value: '$actualTrustScore',
          label: 'Trust Score',
          gradientColors: [
            _getTrustColor(actualTrustScore),
            _getTrustColor(actualTrustScore).withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
        _buildXPCard(
          profile,
        ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.8, 0.8)),
        DuoStatCard(
          icon: Icons.apartment,
          value: '$floor',
          label: 'Floor',
          gradientColors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
        DuoStatCard(
          icon: Icons.message,
          value: '$messages',
          label: 'Messages',
          gradientColors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Color _getTrustColor(int reputation) {
    return DuoTrustScoreHelper.getTrustColor(reputation);
  }

  Widget _buildXPCard(UserProfileView? profile) {
    final xp = profile?.xp ?? 0;

    var xpDisplay = '0/50';
    if (profile != null) {
      final progress = DuoFloorHelper.getXPProgressFromProfile(profile);
      final needed = DuoFloorHelper.getXPNeededFromProfile(profile);
      xpDisplay = '$progress/$needed';
    }

    return DuoStatCard(
      icon: Icons.stars,
      value: '$xp',
      label: 'XP • $xpDisplay',
      gradientColors: [AppTheme.duoYellow, AppTheme.duoOrange],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        boxShadow: AppTheme.duoCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          ...children,
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Rubik',
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'non-binary':
        return 'Non-binary';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.duoSpacingLarge,
          AppTheme.duoSpacingSmall,
          AppTheme.duoSpacingLarge,
          AppTheme.duoSpacingMedium,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DuoButton(
                text: 'Knock',
                icon: Icons.chat_bubble_outline,
                onPressed: () => _knockOnDoor(context, ref),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            Expanded(
              flex: 3,
              child: DuoButton(
                text: '🎟️ Lounge Invite',
                color: AppTheme.duoYellow,
                onPressed: () => _showInviteBottomSheet(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _knockOnDoor(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Knock on Door',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Leave an optional message to let them know why you are knocking.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Say hi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          DuoButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: DuoButtonVariant.ghost,
            size: DuoButtonSize.small,
          ),
          DuoButton(
            text: 'Knock',
            onPressed: () {
              Navigator.pop(ctx);
              _performKnock(context, ref, messageController.text.trim());
            },
            color: AppTheme.duoGreen,
            size: DuoButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _performKnock(
    BuildContext context,
    WidgetRef ref,
    String initialMessage,
  ) {
    final chatList = ref.read(privateChatListProvider.notifier);
    chatList
        .getOrCreateChat(
          widget.userId,
          initialMessage: initialMessage.isNotEmpty ? initialMessage : null,
        )
        .then((chat) {
          if (context.mounted) {
            // Unconditionally use a strict path anchor
            // This discards any deep stack we were on and firmly drops the user in the "Chats -> Thread" hierarchy.
            context.go('/chats/thread/${chat.channelId}');
          }
        })
        .catchError((error) {
          if (context.mounted) {
            DuoSnackBarHelper.showError(context, error);
          }
        });
  }

  void _showInviteBottomSheet(BuildContext context, WidgetRef ref) async {
    final loungesState = await ref
        .read(loungeListProvider.notifier)
        .fetchLounges();

    // Only show lounges where the user is actually joined
    final activeLounges = loungesState
        .where((g) => g.membershipStatus == ChannelMemberStatus.joined)
        .toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              const Text(
                'Slip a flyer under the door',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invite them to one of your lounges',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              if (activeLounges.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'You are not a member of any lounges yet!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: activeLounges.length,
                    itemBuilder: (context, index) {
                      final lounge = activeLounges[index].lounge;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.duoYellow.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(lounge.emoji ?? '👥'),
                        ),
                        title: Text(
                          lounge.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${lounge.memberCount} members'),
                        trailing: DuoButton(
                          text: 'Invite',
                          color: AppTheme.duoGreen,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context); // Close sheet immediately
                            try {
                              final client = ref.read(clientProvider);
                              await client.lounge.inviteUserToLounge(
                                lounge.id!,
                                widget.userId,
                              );
                              if (context.mounted) {
                                  DuoSnackBarHelper.showSuccess(
                                    context,
                                    'Flyer slipped under the door!',
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                DuoSnackBarHelper.showError(context, e);
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _reportUser(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Report User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please tell us what happened. Reports help keep Talktive safe.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for report',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          DuoButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: DuoButtonVariant.ghost,
            size: DuoButtonSize.small,
          ),
          DuoButton(
            text: 'Report',
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                DuoSnackBarHelper.showError(context, 'Please add a reason.');
                return;
              }
              Navigator.pop(context);
              try {
                final client = ref.read(clientProvider);
                await client.report.reportUser(
                  targetUserId: widget.userId,
                  reason: reason,
                );
                if (context.mounted) {
                  DuoSnackBarHelper.showSuccess(
                    context,
                    'Report submitted securely.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  DuoSnackBarHelper.showError(context, e);
                }
              }
            },
            color: AppTheme.errorColor,
            size: DuoButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMute(BuildContext context, WidgetRef ref) async {
    int duration = 24;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🔇 Mute Resident',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Temporarily prevent this user from sending messages or moments.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for mute',
                hintText: 'e.g. Spamming, inappropriate content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: duration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Hour')),
                DropdownMenuItem(value: 12, child: Text('12 Hours')),
                DropdownMenuItem(value: 24, child: Text('24 Hours')),
                DropdownMenuItem(value: 72, child: Text('3 Days')),
                DropdownMenuItem(value: 168, child: Text('7 Days')),
              ],
              onChanged: (val) => duration = val ?? 24,
            ),
          ],
        ),
        actions: [
          DuoButton(
            text: 'Cancel',
            variant: DuoButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          DuoButton(
            text: 'Apply Mute',
            color: AppTheme.duoOrange,
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                DuoSnackBarHelper.showError(context, 'Please provide a reason.');
                return;
              }
              Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final client = ref.read(clientProvider);
        await client.admin.muteUser(
          userId: widget.userId,
          durationHours: duration,
          reason: reasonController.text.trim(),
        );
        if (context.mounted) {
          DuoSnackBarHelper.showSuccess(
              context, 'User muted for $duration hours.');
          ref.invalidate(userProfileProvider(widget.userId));
        }
      } catch (e) {
        if (context.mounted) DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _confirmSuspend(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('⚖️ Suspend Resident?',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.duoRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will PERMANENTLY disable the user\'s account and reset their Trust Score to 0.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for suspension',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Enter "SUSPEND" to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'SUSPEND',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          DuoButton(
            text: 'Cancel',
            variant: DuoButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          DuoButton(
            text: 'Confirm Suspension',
            color: AppTheme.duoRed,
            onPressed: () {
              if (confirmController.text != 'SUSPEND') {
                DuoSnackBarHelper.showError(context, 'Please type SUSPEND to confirm.');
                return;
              }
              if (reasonController.text.trim().isEmpty) {
                DuoSnackBarHelper.showError(context, 'Please provide a reason.');
                return;
              }
              Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final client = ref.read(clientProvider);
        await client.admin.suspendUser(
          userId: widget.userId,
          reason: reasonController.text.trim(),
        );
        if (context.mounted) {
          DuoSnackBarHelper.showSuccess(context, 'User suspended permanently.');
          ref.invalidate(userProfileProvider(widget.userId));
        }
      } catch (e) {
        if (context.mounted) DuoSnackBarHelper.showError(context, e);
      }
    }
  }
}
