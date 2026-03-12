import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import '../serverpod_client.dart';

part 'user_notifications_provider.g.dart';

@riverpod
class UserNotifications extends _$UserNotifications {
  @override
  Future<List<UserNotification>> build() async {
    return _fetchNotifications();
  }

  Future<List<UserNotification>> _fetchNotifications() async {
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  Future<void> markAsRead(List<int> ids) async {
    try {
      await client.notification.markAsRead(ids);
      // Refresh to update state
      await refresh();
    } catch (e) {
      // Ignore error for marking as read
    }
  }
}
