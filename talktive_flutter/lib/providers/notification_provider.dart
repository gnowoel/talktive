import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'auth_provider.dart';

part 'notification_provider.g.dart';

/// Represents an in-app popup notification.
class DuoNotification {
  final String title;
  final String message;
  final String emoji;
  final VoidCallback? onTap;
  final Duration duration;

  DuoNotification({
    required this.title,
    required this.message,
    this.emoji = '🔔',
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });
}

/// Provider for the single current in-app popup notification.
@riverpod
class InAppNotification extends _$InAppNotification {
  @override
  DuoNotification? build() => null;

  void show(DuoNotification notification) {
    state = notification;
    // Auto-dismiss
    Future.delayed(notification.duration, () {
      if (state == notification) {
        state = null;
      }
    });
  }

  void dismiss() {
    state = null;
  }
}

/// Provider for fetching and managing the persistent activity history (notifications).
@riverpod
class ActivityHistory extends _$ActivityHistory {
  @override
  Future<List<UserNotification>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.hasValue || authState.value is! Authenticated) {
      return const <UserNotification>[];
    }
    return _fetchNotifications();
  }

  Future<List<UserNotification>> _fetchNotifications() async {
    final client = ref.read(clientProvider);
    try {
      final notifications = await client.notification.getUserNotifications(
        limit: 50,
        offset: 0,
        unreadOnly: false,
      );
      return notifications;
    } catch (e) {
      throw Exception('Failed to load activity: $e');
    }
  }

  Future<void> refresh() async {
    bool isMounted = true;
    ref.onDispose(() => isMounted = false);

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _fetchNotifications());
    if (isMounted) {
      state = result;
    }
  }

  Future<void> markAsRead(List<int> ids) async {
    final client = ref.read(clientProvider);
    try {
      await client.notification.markAsRead(ids);
      // Refresh local state to reflect read status
      final currentData = state.value;
      if (currentData != null) {
        state = AsyncValue.data(
          currentData.map((n) {
            if (ids.contains(n.id)) {
              return n.copyWith(read: true);
            }
            return n;
          }).toList(),
        );
      }
    } catch (e) {
      // Ignore error for marking as read
    }
  }
}
