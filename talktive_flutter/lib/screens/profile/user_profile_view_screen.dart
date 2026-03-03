import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_badge.dart';
import '../../providers/client_provider.dart';
import '../../providers/blocked_users_provider.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/user_likes_provider.dart';
import '../../utils/floor_utils.dart';
import '../../config/languages.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  UserProfileView? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = ref.read(clientProvider);
      final profile = await client.userProfile.getUserProfile(widget.userId);

      if (context.mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedIds = ref.watch(blockedUsersProvider).value ?? [];
    final isBlocked = blockedIds.contains(widget.userId);

    return DuoPageScaffold(
      emoji: '👤',
      title: widget.userName ?? 'Profile',
      gradient: AppTheme.duoBlueGradient,
      hasBackButton: true,
      trailingHeader: _buildTrailingMenu(isBlocked),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _error != null
          ? Center(
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
                    _error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _buildProfileContent(isBlocked),
    );
  }

  Widget _buildTrailingMenu(bool isBlocked) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      onSelected: (value) async {
        if (value == 'block') {
          await _confirmBlock(context, isBlocked);
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
                isBlocked ? 'Unblock user' : 'Block user',
                style: TextStyle(
                  color: isBlocked ? AppTheme.duoGreen : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmBlock(BuildContext context, bool isBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBlocked ? 'Unblock user?' : 'Block user?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isBlocked
              ? 'You will be able to see their messages again.'
              : 'You will no longer see their messages, and they cannot start a chat with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isBlocked
                  ? AppTheme.duoGreen
                  : AppTheme.errorColor,
            ),
            child: Text(isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (isBlocked) {
          await ref.read(blockedUsersProvider.notifier).unblock(widget.userId);
        } else {
          await ref.read(blockedUsersProvider.notifier).block(widget.userId);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBlocked ? 'User unblocked.' : 'User blocked.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: isBlocked
                  ? AppTheme.duoGreen
                  : AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileContent(bool isBlocked) {
    if (_profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    final name = _profile!.userName ?? widget.userName ?? 'Unknown';
    final avatar = _profile!.userAvatar ?? widget.userAvatar;
    final floor = _profile!.floor;
    final bio = _profile!.bio;
    final gender = _profile!.gender;
    final country = _profile!.country;
    final interests = _profile!.interests;
    final languages = _profile!.languages;
    final messageCount = _profile!.totalMessages;
    final momentCount = _profile!.totalMoments;
    final achievementCount = _profile!.achievementsUnlocked;
    final streakDays = _profile!.currentStreak;
    final mutualGroups = _profile!.mutualGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar and basic info
          Center(
            child: DuoAvatar(
              imageUrl: avatar,
              size: 120,
              floorLevel: floor,
              showRing: true,
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
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
          if (bio != null) ...[
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
          _buildVouchButton().animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppTheme.duoSpacingLarge),

          // Stats Grid
          _buildStatsGrid(),
          const SizedBox(height: AppTheme.duoSpacingLarge),

          // Info cards
          if (gender != null || country != null)
            _buildInfoCard('About', [
              if (gender != null)
                _buildInfoRow(Icons.person, _formatGender(gender)),
              if (country != null) _buildInfoRow(Icons.flag, country),
              if (mutualGroups > 0)
                _buildInfoRow(Icons.group, '$mutualGroups mutual groups'),
            ]),

          if (interests != null && interests.isNotEmpty) ...[
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

          if (languages != null && languages.isNotEmpty) ...[
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

  Widget _buildVouchButton() {
    final likedIds = ref.watch(userLikesProvider).value ?? [];
    final isLiked = likedIds.contains(widget.userId);

    return DuoButton(
      text: isLiked ? 'Vouched' : '❤️ Vouch for Resident',
      color: isLiked ? AppTheme.duoGreen : AppTheme.secondaryColor,
      isSecondary: isLiked,
      width: double.infinity,
      onPressed: () async {
        try {
          if (isLiked) {
            await ref.read(userLikesProvider.notifier).unlikeUser(widget.userId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vouch removed.')),
              );
            }
          } else {
            await ref.read(userLikesProvider.notifier).likeUser(widget.userId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User vouched! Trust Score increased.'),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
    );
  }

  Widget _buildStatsGrid() {
    final floor = _profile!.floor;
    final messages = _profile!.totalMessages;
    final moments = _profile!.totalMoments;
    final actualTrustScore = _profile!.trustScore;

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
        DuoStatCard(
          icon: Icons.apartment,
          value: '$floor',
          label: 'Floor',
          gradientColors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.8, 0.8)),
        DuoStatCard(
          icon: Icons.message,
          value: '$messages',
          label: 'Messages',
          gradientColors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
        DuoStatCard(
          icon: Icons.photo_library,
          value: '$moments',
          label: 'Moments',
          gradientColors: [
            AppTheme.duoYellow,
            AppTheme.duoYellow.withValues(alpha: 0.7),
          ],
        ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Color _getTrustColor(int reputation) {
    if (reputation > 50) return AppTheme.duoGreen;
    if (reputation >= 20) return AppTheme.duoYellow;
    return AppTheme.duoRed;
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
          Text(text, style: const TextStyle(fontSize: 16, fontFamily: 'Rubik', color: AppTheme.textPrimary)),
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
}
