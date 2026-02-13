import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/streak_provider.dart';
import '../../config/theme.dart';
import '../../config/languages.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_badge.dart';
import '../../widgets/duo/duo_streak_card.dart';
import '../achievements/achievements_screen.dart';

/// Duolingo-style Profile screen - Achievement Hub
class ProfileScreenModern extends ConsumerWidget {
  const ProfileScreenModern({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentAsync = ref.watch(currentResidentProvider);
    final resident = residentAsync.value;

    return DuoPageScaffold(
      emoji: '👤',
      title: 'Profile',
      subtitle: _displayName(resident),
      gradient: AppTheme.duoGreenGradient,
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
                  style: const TextStyle(color: Colors.red),
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
            child:
                DuoAvatar(
                      imageUrl: resident?.avatar,
                      initials: _displayName(resident).isNotEmpty
                          ? _displayName(resident)[0]
                          : '?',
                      size: 100,
                      floorLevel: resident?.floor,
                      showRing: true,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
          ),

          // Streak card
          _buildStreakCard(context, ref),
          // Stats grid
          _buildStatsGrid(resident),
          // Languages section
          _buildLanguagesSection(resident),
          // Interests section
          _buildInterestsSection(resident),
          // Achievements section
          _buildAchievementsSection(context, ref),
          // Info card
          _buildInfoCard(),
          // Sign out button
          _buildSignOutButton(context, ref),
          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }

  String _displayName(Resident? resident) {
    final id = resident?.userInfoId.uuid;
    if (id == null || id.isEmpty) {
      return 'Anonymous';
    }
    return 'Resident ${id.substring(0, 6)}';
  }

  Widget _buildStreakCard(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(userStreakProvider);

    return streakAsync.when(
      data: (streakData) {
        if (streakData == null || streakData.streak == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.duoSpacingLarge,
            AppTheme.duoSpacingMedium,
            AppTheme.duoSpacingLarge,
            0,
          ),
          child: DuoStreakCard(
            currentStreak: streakData.streak!.currentStreak,
            longestStreak: streakData.streak!.longestStreak,
            canClaimReward: streakData.canClaimReward,
            onClaimReward: () async {
              try {
                final reward = await ref
                    .read(userStreakProvider.notifier)
                    .claimReward();

                if (context.mounted && reward != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎉 Claimed ${reward.rewardAmount} credits!',
                      ),
                      backgroundColor: AppTheme.duoGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusMedium,
                        ),
                      ),
                    ),
                  );

                  // Refresh resident data to show updated credits
                  ref.invalidate(currentResidentProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to claim reward: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsGrid(resident) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppTheme.duoSpacingMedium,
        crossAxisSpacing: AppTheme.duoSpacingMedium,
        childAspectRatio: 1.1,
        children: [
          DuoStatCard(
                icon: Icons.apartment,
                value: '${resident?.floor ?? 0}',
                label: 'Floor Level',
                gradientColors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
              )
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          DuoStatCard(
                icon: Icons.star,
                value: '${resident?.experienceMessageCount ?? 0}',
                label: 'Experience',
                gradientColors: [AppTheme.duoYellow, Colors.orange],
              )
              .animate()
              .fadeIn(delay: 350.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          DuoStatCard(
                icon: Icons.credit_score,
                value: '${resident?.creditScore ?? 0}',
                label: 'Credits',
                gradientColors: [
                  AppTheme.duoGreen,
                  AppTheme.duoGreen.withOpacity(0.7),
                ],
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          DuoStatCard(
                icon: Icons.message,
                value: '${resident?.experienceMessageCount ?? 0}',
                label: 'Messages',
                gradientColors: [
                  AppTheme.accentColor,
                  AppTheme.accentColor.withOpacity(0.7),
                ],
              )
              .animate()
              .fadeIn(delay: 450.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
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
                  color: AppTheme.duoGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.duoGreen.withOpacity(0.3)),
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
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
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
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAchievementsSection(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        final unlocked = achievements
            .where((a) => a['unlocked'] == true)
            .toList();
        final totalPoints = unlocked.fold<int>(
          0,
          (sum, a) => sum + (a['achievement'].points as int),
        );

        // Show first 6 achievements
        final preview = achievements.take(6).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.duoSpacingLarge,
            vertical: AppTheme.duoSpacingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '${unlocked.length}/${achievements.length} • $totalPoints pts',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              // Achievement badges
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length + 1, // +1 for "View All" button
                  itemBuilder: (context, index) {
                    if (index == preview.length) {
                      // "View All" button
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(
                            left: AppTheme.duoSpacingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.duoRadiusSmall,
                            ),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                  fontFamily: 'Rubik',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final achievement = preview[index];
                    final achievementData = achievement['achievement'];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : AppTheme.duoSpacingSmall,
                      ),
                      child: DuoBadge(
                        emoji: achievementData.emoji,
                        name: achievementData.name,
                        isUnlocked: achievement['unlocked'] == true,
                        isNew: achievement['isNew'] == true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.duoSpacingLarge),
      child: DuoCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.duoSpacingSmall),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.secondaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusSmall),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            const Expanded(
              child: Text(
                'Your floor level determines your privileges in the apartment building',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Rubik',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
                ),
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
}
