import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/notification_service.dart';
import '../services/input_validation_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class NotificationEndpoint extends Endpoint with EndpointAuthMixin {
  /// Gets user's notifications.
  Future<List<protocol.UserNotification>> getUserNotifications(
    Session session, {
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final currentUserId = await getUserId(session);

    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();

    return await NotificationService.getUserNotifications(
      session,
      currentUserId,
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
  }

  /// Marks notifications as read.
  Future<void> markAsRead(
    Session session,
    List<int> notificationIds,
  ) async {
    for (final id in notificationIds) {
      InputValidationService.validateId(id, 'Notification ID').throwIfInvalid();
    }
    await getUserId(session); // Ensure authenticated

    await NotificationService.markAsRead(session, notificationIds);
  }

  /// Gets unread notification count.
  Future<int> getUnreadCount(Session session) async {
    final currentUserId = await getUserId(session);

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

    // Gracefully handle unauthenticated calls during login/startup transitions
    if (currentUserIdentifier == null) {
      session.log('FCM token registration skipped: Not authenticated');
      return;
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
