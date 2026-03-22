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
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
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
          subtitle: 'Progress & Updates',
          emoji: '🏆',
          gradient: AppTheme.duoGreenGradient,
          trailingHeader: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(
                context,
                emoji: '👤',
                onTap: () => context.push('/my-profile'),
              ),
              const SizedBox(width: AppTheme.duoSpacingSmall),
              _buildHeaderIcon(
                context,
                emoji: '⚙️',
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

  Widget _buildHeaderIcon(BuildContext context, {required String emoji, required VoidCallback onTap}) {
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
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
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
                        onPressed: () => _showMarkAllAsReadConfirmation(context, ref, notifications),
                        icon: const Text('🧹', style: TextStyle(fontSize: 20)),
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.duoSpacingMedium),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(context, ref, notification)
                        .animate(delay: Duration(milliseconds: 50 * index))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                  childCount: notifications.length,
                ),
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
                  child: _buildMiniStat(
                    context,
                    label: 'Floor',
                    value: '${DuoFloorHelper.computeFloor(resident)}',
                    emoji: '🏢',
                    color: AppTheme.duoPurple,
                  ),
                ),
                const SizedBox(width: AppTheme.duoSpacingSmall),
                Expanded(
                  child: _buildMiniStat(
                    context,
                    label: 'Experience',
                    value: '${resident.xp}',
                    emoji: '🌟',
                    color: AppTheme.duoYellow,
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
        if (data == null || data.achievements.isEmpty) return const SizedBox.shrink();

        final achievements = data.achievements;
        final unlocked = achievements.where((a) => a.unlocked).toList();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppTheme.duoSpacingMedium,
            0,
            AppTheme.duoSpacingMedium,
            AppTheme.duoSpacingMedium,
          ),
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
            border: Border.all(color: Colors.grey[200]!, width: 2),
            boxShadow: AppTheme.duoCardShadow,
          ),
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
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final achievementData = achievement.achievement;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == achievements.length - 1 ? 0 : AppTheme.duoSpacingSmall,
                      ),
                      child: DuoBadge(
                        emoji: achievementData.emoji,
                        name: achievementData.name,
                        isUnlocked: achievement.unlocked,
                        isNew: achievement.isNew,
                        onTap: () {
                          // Show detail maybe? For now just stay here
                          HapticFeedback.selectionClick();
                        },
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

    required String label,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      borderWidth: 2,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
    final emoji = _getEmojiForType(notification.type);

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
              
              // Skip redundant navigation if we're already on the activity screen
              if (route != null && route != '/activity') {
                context.push(route);
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
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            timeago.format(notification.createdAt, locale: 'en_short'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      color: AppTheme.duoRed, // Changed from Green to Red for unread indicator
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(duration: 1000.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getEmojiForType(String type) {
    switch (type) {
      case 'message':
        return '💬';
      case 'moment_like':
        return '❤️';
      case 'moment_comment':
        return '💬';
      case 'achievement':
        return '🏆';
      case 'streak':
        return '🔥';
      case 'lounge_invite':
        return '🎫';
      case 'mention':
        return '🏷️';
      case 'chat_invite':
        return '🚪';
      case 'level_up':
        return '🆙';
      default:
        return '🔔';
    }
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 64)),
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
            onRefresh: () async => ref.read(activityHistoryProvider.notifier).refresh(),
          ),
        ],
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
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              final unreadIds = notifications
                  .where((n) => !n.read && n.id != null)
                  .map((n) => n.id!)
                  .toList();
              if (unreadIds.isNotEmpty) {
                ref.read(activityHistoryProvider.notifier).markAsRead(unreadIds);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppTheme.duoGreen, fontWeight: FontWeight.bold),
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
