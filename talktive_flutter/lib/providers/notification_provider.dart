import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'notification_provider.g.dart';

/// Provider for user notifications.
@riverpod
class UserNotifications extends _$UserNotifications {
  @override
  FutureOr<List<UserNotification>> build() async {
    return fetchNotifications();
  }

  Future<List<UserNotification>> fetchNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final client = ref.read(clientProvider);
    try {
      return await client.notification.getUserNotifications(
        limit: limit,
        offset: 0,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      return [];
    }
  }

  /// Marks notifications as read.
  Future<void> markAsRead(List<int> notificationIds) async {
    final client = ref.read(clientProvider);
    try {
      await client.notification.markAsRead(notificationIds);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes the notifications list.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for unread notification count.
@riverpod
class UnreadNotificationCount extends _$UnreadNotificationCount {
  @override
  FutureOr<int> build() async {
    return fetchUnreadCount();
  }

  Future<int> fetchUnreadCount() async {
    final client = ref.read(clientProvider);
    try {
      return await client.notification.getUnreadCount();
    } catch (e) {
      return 0;
    }
  }

  /// Refreshes the unread count.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
