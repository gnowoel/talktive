import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/notification_service.dart';
import '../services/input_validation_service.dart';

class NotificationEndpoint extends Endpoint {
  /// Gets user's notifications.
  Future<List<protocol.UserNotification>> getUserNotifications(
    Session session, {
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    InputValidationService.validatePagination(
      limit: limit,
      offset: offset,
    ).throwIfInvalid();
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    final currentUserId = UuidValue.fromString(currentUserIdentifier);

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
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
    }

    await NotificationService.markAsRead(session, notificationIds);
  }

  /// Gets unread notification count.
  Future<int> getUnreadCount(Session session) async {
    final authenticationInfo = session.authenticated;
    final currentUserIdentifier = authenticationInfo?.userIdentifier;

    if (currentUserIdentifier == null) {
      throw protocol.TalktiveException(message: 'Not authenticated');
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
      throw protocol.TalktiveException(message: 'Not authenticated');
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
