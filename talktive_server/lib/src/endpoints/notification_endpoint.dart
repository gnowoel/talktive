import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/notification_service.dart';

class NotificationEndpoint extends Endpoint {
  /// Gets user's notifications.
  Future<List<protocol.UserNotification>> getUserNotifications(
    Session session, {
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await NotificationService.getUserNotifications(
      session,
      currentUserId,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  /// Marks notifications as read.
  Future<void> markAsRead(
    Session session,
    List<int> notificationIds,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    await NotificationService.markAsRead(session, notificationIds);
  }

  /// Gets unread notification count.
  Future<int> getUnreadCount(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    return await NotificationService.getUnreadCount(session, currentUserId);
  }

  /// Registers a device token for push notifications.
  Future<void> registerDeviceToken(
    Session session,
    String token,
    String platform,
  ) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

    await NotificationService.registerDeviceToken(
      session,
      currentUserId,
      token,
      platform,
    );
  }

  /// Unregisters a device token.
  Future<void> unregisterDeviceToken(
    Session session,
    String token,
  ) async {
    await NotificationService.unregisterDeviceToken(session, token);
  }
}
