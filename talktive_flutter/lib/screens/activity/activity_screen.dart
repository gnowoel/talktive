import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'package:talktive_client/talktive_client.dart';

import '../../providers/user_notifications_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_refresh_button.dart';

/// Activity screen showing significant notification history
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(userNotificationsProvider);

    return DuoPageScaffold(
      title: 'Activity',
      subtitle: 'Notifications & history',
      emoji: '🔔',
      gradient: AppTheme.duoBlueGradient,
      trailingHeader: DuoRefreshButton(
        color: Colors.white,
        onRefresh: () async => ref.refresh(userNotificationsProvider),
      ),
      hasBackButton: true,
      body: activityAsync.when(
        data: (notifications) =>
            _buildActivityList(context, ref, notifications),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.duoBlue),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    WidgetRef ref,
    List<UserNotification> notifications,
  ) {
    if (notifications.isEmpty) {
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.2),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(userNotificationsProvider),
      color: AppTheme.duoBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(context, ref, notification)
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.1, end: 0);
        },
      ),
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
          if (notification.id != null && !notification.read) {
            ref.read(userNotificationsProvider.notifier).markAsRead([
              notification.id!,
            ]);
          }

          if (notification.data != null) {
            try {
              final data =
                  jsonDecode(notification.data!) as Map<String, dynamic>;
              final route = data['route'] as String?;
              if (route != null) {
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
              : AppTheme.duoBlue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        : FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeago.format(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
      case 'group_invite':
        return '🎫';
      case 'mention':
        return '🏷️';
      default:
        return '🔔';
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
            color: AppTheme.duoBlue,
            onRefresh: () async => ref.refresh(userNotificationsProvider),
          ),
        ],
      ),
    );
  }
}
