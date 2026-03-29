import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'package:talktive_client/talktive_client.dart';

import '../../providers/notification_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../widgets/duo/duo_streak_card.dart';
import '../../widgets/duo/duo_badge.dart';
import '../../widgets/duo/duo_stat_card.dart';
import '../../helpers/duo_snackbar_helper.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';

/// Activity screen showing significant notification history and gamification progress
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityHistoryProvider);
    final gamificationAsync = ref.watch(gamificationProvider);

    return Stack(
      children: [
        DuoPageScaffold(
          title: 'Activity',
          subtitle: 'Your building journey',
          emoji: '🏆',
          gradient: AppTheme.duoGreenGradient,
          trailingHeader: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(
                context,
                icon: Icons.person,
                onTap: () => context.push('/my-profile'),
              ),
              const SizedBox(width: AppTheme.duoSpacingSmall),
              _buildHeaderIcon(
                context,
                icon: Icons.settings,
                onTap: () => context.push('/activity/settings'),
              ),
              const SizedBox(width: AppTheme.duoSpacingSmall),
              DuoRefreshButton(
                color: Colors.white,
                onRefresh: () async {
                  await ref.read(activityHistoryProvider.notifier).refresh();
                  await ref.read(gamificationProvider.notifier).refresh();
                },
              ),
            ],
          ),
          hasBackButton: context.canPop(),
          body: activityAsync.when(
            data: (notifications) => _buildActivityContent(
              context,
              ref,
              notifications,
              gamificationAsync,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.duoGreen),
            ),
            error: (error, stack) => _buildErrorState(context, ref, error),
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
            gravity: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildActivityContent(
    BuildContext context,
    WidgetRef ref,
    List<UserNotification> notifications,
    AsyncValue<GamificationData?> gamificationAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(activityHistoryProvider.notifier).refresh();
        await ref.read(gamificationProvider.notifier).refresh();
      },
      color: AppTheme.duoGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Gamification / Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
              child: _buildGamificationSection(context, ref, gamificationAsync),
            ),
          ),

          // Achievements Section
          SliverToBoxAdapter(
            child: _buildAchievementsSection(context, ref, gamificationAsync),
          ),

          // Activity Header
          if (notifications.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.duoSpacingLarge,
                  vertical: AppTheme.duoSpacingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Updates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (notifications.any((n) => !n.read))
                      IconButton(
                        onPressed: () => _showMarkAllAsReadConfirmation(
                          context,
                          ref,
                          notifications,
                        ),
                        icon: const Icon(
                          Icons.done_all,
                          size: 24,
                          color: AppTheme.duoGreen,
                        ),
                        tooltip: 'Mark all as read',
                      ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.1),
              ),
            ),

          // List or Empty State
          if (notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.duoSpacingMedium,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(context, ref, notification)
                      .animate(delay: Duration(milliseconds: 50 * index))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1, end: 0);
                }, childCount: notifications.length),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.contentBottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<GamificationData?> gamificationAsync,
  ) {
    return gamificationAsync.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final resident = data.resident;

        return Column(
          children: [
            DuoStreakCard(
              currentStreak: resident.currentStreak,
              longestStreak: resident.longestStreak,
              canClaimReward: data.canClaimReward,
              onClaimReward: () async {
                try {
                  final reward = await ref
                      .read(gamificationProvider.notifier)
                      .claimDailyReward();
                  if (context.mounted && reward != null) {
                    DuoSnackBarHelper.showSuccess(
                      context,
                      '🎉 Claimed ${reward.rewardAmount} credits!',
                    );
                    ref.invalidate(currentResidentProvider);
                  }
                } catch (e) {
                  if (context.mounted) DuoSnackBarHelper.showError(context, e);
                }
              },
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            Row(
              children: [
                Expanded(
                  child: DuoStatCard(
                    label: 'Floor',
                    value: '${DuoFloorHelper.computeFloor(resident)}',
                    emoji: '🏢',
                    gradientColors: [
                      AppTheme.duoPurple,
                      AppTheme.duoPurple.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.duoSpacingSmall),
                Expanded(
                  child: DuoStatCard(
                    label: 'Experience',
                    value: '${resident.xp}',
                    emoji: '🌟',
                    gradientColors: [AppTheme.duoYellow, AppTheme.duoOrange],
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<GamificationData?> gamificationAsync,
  ) {
    return gamificationAsync.when(
      data: (data) {
        if (data == null || data.achievements.isEmpty) {
          return const SizedBox.shrink();
        }

        final achievements = data.achievements;
        final unlocked = achievements.where((a) => a.unlocked).toList();
        return DuoCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.duoSpacingMedium,
            0,
            AppTheme.duoSpacingMedium,
            AppTheme.duoSpacingMedium,
          ),
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Badges',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '${unlocked.length}/${achievements.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.duoGreen,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.duoSpacingSmall),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final achievementData = achievement.achievement;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == achievements.length - 1
                            ? 0
                            : AppTheme.duoSpacingMedium,
                      ),
                      child: DuoBadge(
                        emoji: achievementData.emoji,
                        name: achievementData.name,
                        isUnlocked: achievement.unlocked,
                        isNew: achievement.isNew,
                        onTap: () =>
                            _showAchievementDetail(context, achievement),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📬', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            'Meaningful events will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    UserNotification notification,
  ) {
    final iconWidget = _getIconWidgetForType(
      notification.type,
      notification.read,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          // Always play confetti for celebratory types on tap, even if already read
          if (notification.type == 'level_up' ||
              notification.type == 'achievement' ||
              notification.type == 'streak') {
            _confettiController.play();
          }

          if (notification.id != null && !notification.read) {
            ref.read(activityHistoryProvider.notifier).markAsRead([
              notification.id!,
            ]);

            // Refresh stats to ensure UI reflects new level/floor immediately on first read
            if (notification.type == 'level_up' ||
                notification.type == 'achievement' ||
                notification.type == 'streak') {
              ref.read(gamificationProvider.notifier).refresh();
            }
          }

          if (notification.data != null) {
            try {
              final data =
                  jsonDecode(notification.data!) as Map<String, dynamic>;
              final route = data['route'] as String?;

              // Improved navigation for shell-aware routes
              if (route != null && route != '/activity') {
                final isMainTab =
                    route == '/plaza' ||
                    route == '/moments' ||
                    route == '/chats' ||
                    route == '/lounges';

                if (isMainTab) {
                  context.go(route);
                } else {
                  context.push(route);
                }
              }
            } catch (e) {
              debugPrint('Error parsing notification data: $e');
            }
          }
        },
        child: DuoCard(
          color: notification.read
              ? Colors.white
              : Colors.grey[50], // Very subtle highlight
          borderWidth: 2,
          borderColor: notification.read
              ? Colors.grey[200]!
              : Colors.grey[300]!, // Subtler border
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: notification.read ? Colors.grey[50] : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: notification.read
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: Colors.grey[800],
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeago.format(
                              notification.createdAt,
                              locale: 'en_short',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notification.read)
                  Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppTheme
                              .duoRed, // Changed from Green to Red for unread indicator
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getIconWidgetForType(String type, bool isRead) {
    final color = isRead ? Colors.grey : AppTheme.primaryColor;
    const double size = 26;

    switch (type) {
      case 'message':
        return Icon(Icons.chat_bubble_outline, size: size, color: color);
      case 'moment_like':
        return const Text('❤️', style: TextStyle(fontSize: size));
      case 'moment_comment':
        return Icon(Icons.comment_outlined, size: size, color: color);
      case 'achievement':
        return const Text('🎖️', style: TextStyle(fontSize: size));
      case 'streak':
        return const Text('🔥', style: TextStyle(fontSize: size));
      case 'lounge_invite':
        return const Text('✉️', style: TextStyle(fontSize: size));
      case 'mention':
        return Icon(Icons.alternate_email, size: size, color: color);
      case 'chat_invite':
        return const Text('👋', style: TextStyle(fontSize: size));
      case 'level_up':
        return const Text('🏆', style: TextStyle(fontSize: size));
      default:
        return Icon(Icons.notifications_none, size: size, color: color);
    }
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load activity',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          DuoRefreshButton(
            color: AppTheme.duoGreen,
            onRefresh: () async =>
                ref.read(activityHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(
    BuildContext context,
    UserAchievementView userAchievement,
  ) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.unlocked;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.duoRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.duoSpacingSmall),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? Colors.white : Colors.grey[100],
                border: Border.all(
                  color: isUnlocked ? AppTheme.duoPurple : Colors.grey[300]!,
                  width: 4,
                ),
                boxShadow: isUnlocked ? AppTheme.duoCardShadow : null,
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppTheme.duoPurple.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                achievement.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppTheme.duoPurple : Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontFamily: 'Rubik',
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
            if (!isUnlocked && achievement.targetValue > 1) ...[
              Text(
                'PROGRESS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor:
                        (userAchievement.progress / achievement.targetValue)
                            .clamp(0.0, 1.0),
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.duoPurpleGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${userAchievement.progress} / ${achievement.targetValue}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rubik',
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💎 ', style: TextStyle(fontSize: 18)),
                Text(
                  '${achievement.points} Points',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.duoOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.duoSpacingXLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.duoPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusMedium,
                        ),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.duoPurple.withValues(alpha: 0.5),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith((states) => 4),
                    ),
                child: const Text(
                  'GOT IT!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
          ],
        ),
      ),
    );
  }

  void _showMarkAllAsReadConfirmation(
    BuildContext context,
    WidgetRef ref,
    List<UserNotification> notifications,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Mark all as read?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will mark all your recent updates as read.',
          style: TextStyle(fontFamily: 'Rubik'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final unreadIds = notifications
                  .where((n) => !n.read && n.id != null)
                  .map((n) => n.id!)
                  .toList();
              if (unreadIds.isNotEmpty) {
                ref
                    .read(activityHistoryProvider.notifier)
                    .markAsRead(unreadIds);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: AppTheme.duoGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        ),
      ),
    );
  }
}
