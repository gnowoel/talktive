import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../config/languages.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import 'blocked_users_screen.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/media_service.dart';
import '../../providers/client_provider.dart';
import '../../helpers/duo_snackbar_helper.dart';
import 'package:flutter/services.dart';

/// Duolingo-style Profile screen - Achievement Hub
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentAsync = ref.watch(currentResidentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
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
      ),
      body: residentAsync.when(
        data: (resident) => _buildProfileContent(context, ref, resident),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, stack) => Center(
          child: DuoCard(
            margin: const EdgeInsets.all(AppTheme.duoSpacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.duoSpacingMedium),
                const Text(
                  'Error loading profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  error.toString(),
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, resident) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.duoSpacingLarge),
          // Avatar (Moved from header to body)
          Center(
            child: Stack(
              children: [
                DuoAvatar(
                  imageUrl: resident?.customAvatarUrl ?? resident?.avatar,
                  placeholderEmoji: resident?.avatar,
                  size: 110,
                  floorLevel: resident != null
                      ? DuoFloorHelper.computeFloor(resident!)
                      : null,
                  mood: resident?.mood,
                  trustScore: resident?.trustScore,
                  showRing: true,
                  showFloor: true,
                  showMood: true,
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                if (resident?.isPremium ?? false)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadAvatar(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ).animate(delay: 400.ms).fadeIn().scale(),
              ],
            ),
          ),

          if (resident?.userName != null && resident!.userName!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              resident.userName!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ).animate().fadeIn(delay: 110.ms).slideY(begin: 0.1, end: 0),
          ],

          if (resident?.bio != null && resident!.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                resident.bio!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  fontFamily: 'Rubik',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1, end: 0),
          ],

          if (resident?.mood != null && resident!.mood!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(resident.mood!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Current Mood',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
          ],

          // Moments Button (Prominent placement)
          _buildMomentsButton(
            context,
            ref,
            resident,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          // Stats grid
          _buildStatsGrid(context, ref, resident),
          // Languages section
          _buildLanguagesSection(resident),
          // Interests section
          _buildInterestsSection(resident),
          // Edit Profile button
          _buildEditProfileButton(context, ref, resident),
          // Blocked users menu
          _buildBlockedUsersButton(context),
          // Sign out button
          _buildSignOutButton(context, ref),
          const SizedBox(height: AppTheme.contentBottomPadding),
        ],
      ),
    );
  }

  String _displayName(Resident? resident) {
    final name = resident?.userName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Your Profile';
  }


  Widget _buildMomentsButton(
    BuildContext context,
    WidgetRef ref,
    Resident? resident,
  ) {
    final profileView = resident != null
        ? ref.watch(userProfileProvider(resident.userInfoId.toString())).value
        : null;
    final momentsCount = profileView?.totalMoments ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.duoSpacingLarge),
      child: DuoButton(
        text: '📸 Sharing $momentsCount Moments',
        icon: Icons.auto_awesome,
        isSecondary: true,
        color: AppTheme.duoBlue,
        width: double.infinity,
        onPressed: () {
          if (resident != null) {
            final userName = resident.userName ?? 'Me';
            context.push(
              '/user/${resident.userInfoId}/moments?name=${Uri.encodeComponent(userName)}',
            );
          }
        },
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    WidgetRef ref,
    Resident? resident,
  ) {
    if (resident == null) return const SizedBox();

    final profileAsync = ref.watch(userProfileProvider(resident.userInfoId.toString()));
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.duoSpacingLarge,
        AppTheme.duoSpacingMedium,
        AppTheme.duoSpacingLarge,
        AppTheme.duoSpacingLarge,
      ),
      child: profileAsync.when(
        data: (profile) {
          final trustScore = profile?.trustScore ?? 100;
          final floor = profile?.floor ?? 1;
          final messages = profile?.totalMessages ?? 0;
          final xp = profile?.xp ?? 0;

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.duoSpacingMedium,
            crossAxisSpacing: AppTheme.duoSpacingMedium,
            childAspectRatio: 1.1,
            children: [
              // Trust Score
              DuoStatCard(
                icon: Icons.shield,
                value: '$trustScore',
                label: 'Trust Score',
                gradientColors: [
                  DuoFloorHelper.getTrustColor(trustScore),
                  DuoFloorHelper.getTrustColor(trustScore).withValues(alpha: 0.7),
                ],
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
              
              // XP (Experience Points)
              _buildXPCard(context, profile)
                  .animate()
                  .fadeIn(delay: 350.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              
              // Floor (Computed from XP and Trust)
              DuoStatCard(
                icon: Icons.apartment,
                value: '$floor',
                label: 'Floor',
                gradientColors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.7),
                ],
              ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              
              // Messages
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Error loading stats'),
      ),
    );
  }

  /// Build XP card with progress indicator
  Widget _buildXPCard(BuildContext context, UserProfileView? profile) {
    final xp = profile?.xp ?? 0;

    // Default placeholder
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

  Widget _buildLanguagesSection(Resident? resident) {
    final languages = resident?.languages;

    if (languages == null || languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingMedium,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((code) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.duoGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.duoGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLanguages.getFlag(code),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLanguages.getName(code),
                        style: const TextStyle(
                          color: AppTheme.duoGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInterestsSection(Resident? resident) {
    final interests = resident?.interests;

    if (interests == null || interests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingMedium,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0);
  }



  Widget _buildBlockedUsersButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingSmall,
      ),
      child: DuoButton(
        text: 'Blocked Users',
        icon: Icons.block,
        color: AppTheme.textSecondary,
        isSecondary: true,
        width: double.infinity,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BlockedUsersScreen()),
          );
        },
      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildEditProfileButton(
    BuildContext context,
    WidgetRef ref,
    resident,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingSmall,
      ),
      child: DuoButton(
        text: 'Edit Profile',
        icon: Icons.edit,
        color: AppTheme.primaryColor,
        isSecondary: true,
        width: double.infinity,
        onPressed: () {
          if (resident != null) {
            context.push('/profile-setup', extra: {'resident': resident});
          }
        },
      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      child: DuoButton(
        text: 'Sign Out',
        icon: Icons.logout,
        color: AppTheme.duoRed,
        width: double.infinity,
        onPressed: () async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: DuoCard(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign Out?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    const Text(
                      'Are you sure you want to sign out?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),
                    Row(
                      children: [
                        Expanded(
                          child: DuoButton(
                            text: 'Cancel',
                            isSecondary: true,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        const SizedBox(width: AppTheme.duoSpacingSmall),
                        Expanded(
                          child: DuoButton(
                            text: 'Sign Out',
                            color: AppTheme.duoRed,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
            ),
          );

          if (confirmed == true) {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/welcome');
            }
          }
        },
      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final picker = ref.read(mediaServiceProvider);

    final image = await picker.pickImage();
    if (image == null) return;

    try {
      // Show loading snackbar or dialog if needed, but let's just do it
      DuoSnackBarHelper.showSuccess(context, 'Uploading avatar... ⏳');

      final imageUrl = await picker.uploadFile(image, 'avatars');
      if (imageUrl != null) {
        await ref.read(clientProvider).resident.updateCustomAvatar(imageUrl);
        ref.invalidate(currentResidentProvider);
        if (context.mounted) {
          DuoSnackBarHelper.showSuccess(context, 'Avatar updated! 🌟');
        }
      }
    } catch (e) {
      if (context.mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to upload avatar: $e');
      }
    }
  }
}
