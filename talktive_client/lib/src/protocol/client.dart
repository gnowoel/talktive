/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:talktive_client/src/protocol/report_status.dart' as _i5;
import 'package:talktive_client/src/protocol/group.dart' as _i6;
import 'package:talktive_client/src/protocol/resident.dart' as _i7;
import 'dart:typed_data' as _i8;
import 'package:talktive_client/src/protocol/message.dart' as _i9;
import 'package:talktive_client/src/protocol/moment.dart' as _i10;
import 'package:talktive_client/src/protocol/moment_like.dart' as _i11;
import 'package:talktive_client/src/protocol/moment_comment.dart' as _i12;
import 'package:talktive_client/src/protocol/user_notification.dart' as _i13;
import 'package:talktive_client/src/protocol/private_chat.dart' as _i14;
import 'package:talktive_client/src/protocol/private_chat_with_profile.dart'
    as _i15;
import 'package:talktive_client/src/protocol/report.dart' as _i16;
import 'package:talktive_client/src/protocol/user_streak.dart' as _i17;
import 'package:talktive_client/src/protocol/daily_reward.dart' as _i18;
import 'package:talktive_client/src/protocol/greetings/greeting.dart' as _i19;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i20;
import 'protocol.dart' as _i21;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );
}

/// Exposes Firebase ID token login for the Serverpod auth core flow.
/// {@category Endpoint}
class EndpointFirebaseIdp extends _i1.EndpointFirebaseIdpBase {
  EndpointFirebaseIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'firebaseIdp';

  /// Validates a Firebase ID token and either logs in the associated user or
  /// creates a new user account if the Firebase account ID is not yet known.
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _i3.Future<_i4.AuthSuccess> login({required String idToken}) =>
      caller.callServerEndpoint<_i4.AuthSuccess>(
        'firebaseIdp',
        'login',
        {'idToken': idToken},
      );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointAchievement extends _i2.EndpointRef {
  EndpointAchievement(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'achievement';

  /// Gets all achievements with user progress.
  _i3.Future<List<Map<String, dynamic>>> getUserAchievements() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'achievement',
        'getUserAchievements',
        {},
      );

  /// Marks achievements as notified (user has seen them).
  _i3.Future<void> markAchievementsAsNotified(List<int> achievementIds) =>
      caller.callServerEndpoint<void>(
        'achievement',
        'markAchievementsAsNotified',
        {'achievementIds': achievementIds},
      );

  /// Seeds the database with predefined achievements (admin only).
  _i3.Future<void> seedAchievements() => caller.callServerEndpoint<void>(
    'achievement',
    'seedAchievements',
    {},
  );
}

/// {@category Endpoint}
class EndpointAdmin extends _i2.EndpointRef {
  EndpointAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  /// Check if the current user is an admin
  _i3.Future<bool> isAdmin() => caller.callServerEndpoint<bool>(
    'admin',
    'isAdmin',
    {},
  );

  /// Get all pending reports with pagination
  _i3.Future<List<Map<String, dynamic>>> getPendingReports({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'admin',
    'getPendingReports',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Get all reports (with status filter)
  _i3.Future<List<Map<String, dynamic>>> getAllReports({
    _i5.ReportStatus? status,
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'admin',
    'getAllReports',
    {
      'status': status,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Resolve a report (approve or reject)
  _i3.Future<void> resolveReport({
    required int reportId,
    required _i5.ReportStatus status,
    String? adminNotes,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'resolveReport',
    {
      'reportId': reportId,
      'status': status,
      'adminNotes': adminNotes,
    },
  );

  /// Suspend a user (disable account)
  _i3.Future<void> suspendUser({
    required String userId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'suspendUser',
    {
      'userId': userId,
      'reason': reason,
    },
  );

  /// Unsuspend a user (re-enable account)
  _i3.Future<void> unsuspendUser({required String userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'unsuspendUser',
        {'userId': userId},
      );

  /// Reset user trustScore to 100 (for appeals)
  _i3.Future<void> resetReputation({
    required String userId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'resetReputation',
    {
      'userId': userId,
      'reason': reason,
    },
  );

  /// Delete a message
  _i3.Future<void> deleteMessage({
    required int messageId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'deleteMessage',
    {
      'messageId': messageId,
      'reason': reason,
    },
  );

  /// Delete a moment
  _i3.Future<void> deleteMoment({
    required int momentId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'deleteMoment',
    {
      'momentId': momentId,
      'reason': reason,
    },
  );

  /// Get platform statistics - OPTIMIZED with caching
  _i3.Future<Map<String, dynamic>> getStatistics() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'admin',
        'getStatistics',
        {},
      );

  /// Search users by name or ID
  _i3.Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required int limit,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'admin',
    'searchUsers',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Promote user to admin
  _i3.Future<void> promoteToAdmin({required String userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'promoteToAdmin',
        {'userId': userId},
      );

  /// Demote admin to regular user
  _i3.Future<void> demoteFromAdmin({required String userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'demoteFromAdmin',
        {'userId': userId},
      );

  /// Get user details for admin view
  _i3.Future<Map<String, dynamic>> getUserDetails({required String userId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'admin',
        'getUserDetails',
        {'userId': userId},
      );

  /// Run data archival tasks (admin only).
  _i3.Future<Map<String, int>> runArchival() =>
      caller.callServerEndpoint<Map<String, int>>(
        'admin',
        'runArchival',
        {},
      );

  /// Get archival statistics (admin only).
  _i3.Future<Map<String, int>> getArchivalStats() =>
      caller.callServerEndpoint<Map<String, int>>(
        'admin',
        'getArchivalStats',
        {},
      );
}

/// {@category Endpoint}
class EndpointGroup extends _i2.EndpointRef {
  EndpointGroup(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'group';

  /// Creates a new group.
  _i3.Future<_i6.Group> createGroup(
    String name, {
    String? description,
    String? emoji,
    required bool isPublic,
    required int maxMembers,
  }) => caller.callServerEndpoint<_i6.Group>(
    'group',
    'createGroup',
    {
      'name': name,
      'description': description,
      'emoji': emoji,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
    },
  );

  /// Lists all groups (public groups + groups user is a member of).
  _i3.Future<List<_i6.Group>> listGroups({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i6.Group>>(
    'group',
    'listGroups',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Gets details about a specific group.
  _i3.Future<_i6.Group> getGroup(int groupId) =>
      caller.callServerEndpoint<_i6.Group>(
        'group',
        'getGroup',
        {'groupId': groupId},
      );

  /// Joins a group.
  _i3.Future<void> joinGroup(int groupId) => caller.callServerEndpoint<void>(
    'group',
    'joinGroup',
    {'groupId': groupId},
  );

  /// Leaves a group.
  _i3.Future<void> leaveGroup(int groupId) => caller.callServerEndpoint<void>(
    'group',
    'leaveGroup',
    {'groupId': groupId},
  );

  /// Gets all members of a group.
  _i3.Future<List<_i7.Resident>> getGroupMembers(int groupId) =>
      caller.callServerEndpoint<List<_i7.Resident>>(
        'group',
        'getGroupMembers',
        {'groupId': groupId},
      );

  /// Updates group details (admin only).
  _i3.Future<_i6.Group> updateGroup(
    int groupId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
  }) => caller.callServerEndpoint<_i6.Group>(
    'group',
    'updateGroup',
    {
      'groupId': groupId,
      'name': name,
      'description': description,
      'emoji': emoji,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
    },
  );

  /// Deletes a group (creator only).
  _i3.Future<void> deleteGroup(int groupId) => caller.callServerEndpoint<void>(
    'group',
    'deleteGroup',
    {'groupId': groupId},
  );
}

/// Health check endpoint for monitoring and load balancers
/// {@category Endpoint}
class EndpointHealth extends _i2.EndpointRef {
  EndpointHealth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  /// Basic health check - returns 200 OK if server is running
  _i3.Future<Map<String, dynamic>> check() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'check',
        {},
      );

  /// Detailed health check - includes database and Redis status
  _i3.Future<Map<String, dynamic>> detailed() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'detailed',
        {},
      );

  /// Readiness check - returns 200 when server is ready to accept traffic
  _i3.Future<Map<String, dynamic>> ready() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'ready',
        {},
      );

  /// Liveness check - returns 200 if server process is alive
  _i3.Future<Map<String, dynamic>> live() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'live',
        {},
      );

  /// Metrics endpoint - returns basic server metrics
  _i3.Future<Map<String, dynamic>> metrics() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'metrics',
        {},
      );
}

/// {@category Endpoint}
class EndpointImage extends _i2.EndpointRef {
  EndpointImage(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'image';

  /// Uploads an image file to the server's local storage.
  /// Returns the URL path to access the uploaded image.
  ///
  /// Images are stored in: /var/talktive/uploads/
  /// Accessible via: /uploads/{filename}
  ///
  /// Restrictions:
  /// - Max file size: 5MB
  /// - Allowed formats: JPEG, PNG, WebP
  /// - Only authenticated users can upload
  _i3.Future<String> uploadImage(
    _i8.ByteData imageData,
    String fileName,
  ) => caller.callServerEndpoint<String>(
    'image',
    'uploadImage',
    {
      'imageData': imageData,
      'fileName': fileName,
    },
  );

  /// Deletes an image from the server (user can only delete their own images).
  _i3.Future<void> deleteImage(String imageUrl) =>
      caller.callServerEndpoint<void>(
        'image',
        'deleteImage',
        {'imageUrl': imageUrl},
      );
}

/// {@category Endpoint}
class EndpointMessage extends _i2.EndpointRef {
  EndpointMessage(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'message';

  /// Sends a message to a channel (Plaza, Group, or Private).
  _i3.Future<_i9.Message> sendMessage(
    int channelId,
    String content, {
    String? imageUrl,
  }) => caller.callServerEndpoint<_i9.Message>(
    'message',
    'sendMessage',
    {
      'channelId': channelId,
      'content': content,
      'imageUrl': imageUrl,
    },
  );

  /// Subscribes to a channel to receive real-time messages.
  _i3.Stream<_i9.Message> subscribe(int channelId) =>
      caller.callStreamingServerEndpoint<_i3.Stream<_i9.Message>, _i9.Message>(
        'message',
        'subscribe',
        {'channelId': channelId},
        {},
      );

  /// Fetches the history of messages for a channel.
  _i3.Future<List<_i9.Message>> listMessages(
    int channelId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i9.Message>>(
    'message',
    'listMessages',
    {
      'channelId': channelId,
      'limit': limit,
      'offset': offset,
    },
  );
}

/// {@category Endpoint}
class EndpointMoment extends _i2.EndpointRef {
  EndpointMoment(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moment';

  /// Posts a new moment to the feed.
  /// Only residents on Floor 2+ can post moments (to prevent spam).
  _i3.Future<_i10.Moment> postMoment({
    required String imageUrl,
    required String caption,
  }) => caller.callServerEndpoint<_i10.Moment>(
    'moment',
    'postMoment',
    {
      'imageUrl': imageUrl,
      'caption': caption,
    },
  );

  /// Lists the latest moments.
  _i3.Future<List<_i10.Moment>> listMoments({
    required int limit,
    int? lastId,
  }) => caller.callServerEndpoint<List<_i10.Moment>>(
    'moment',
    'listMoments',
    {
      'limit': limit,
      'lastId': lastId,
    },
  );

  /// Likes a moment.
  _i3.Future<void> likeMoment(int momentId) => caller.callServerEndpoint<void>(
    'moment',
    'likeMoment',
    {'momentId': momentId},
  );

  /// Unlikes a moment.
  _i3.Future<void> unlikeMoment(int momentId) =>
      caller.callServerEndpoint<void>(
        'moment',
        'unlikeMoment',
        {'momentId': momentId},
      );

  /// Gets likes for a moment.
  _i3.Future<List<_i11.MomentLike>> getMomentLikes(int momentId) =>
      caller.callServerEndpoint<List<_i11.MomentLike>>(
        'moment',
        'getMomentLikes',
        {'momentId': momentId},
      );

  /// Checks if the current user has liked a moment.
  _i3.Future<bool> hasLikedMoment(int momentId) =>
      caller.callServerEndpoint<bool>(
        'moment',
        'hasLikedMoment',
        {'momentId': momentId},
      );

  /// Batch checks if the current user has liked multiple moments.
  /// This solves the N+1 query problem when loading a feed of moments.
  /// Returns a Map of momentId -> isLiked.
  _i3.Future<Map<int, bool>> hasLikedMoments(List<int> momentIds) =>
      caller.callServerEndpoint<Map<int, bool>>(
        'moment',
        'hasLikedMoments',
        {'momentIds': momentIds},
      );

  /// Adds a comment to a moment.
  _i3.Future<_i12.MomentComment> addComment(
    int momentId,
    String text,
  ) => caller.callServerEndpoint<_i12.MomentComment>(
    'moment',
    'addComment',
    {
      'momentId': momentId,
      'text': text,
    },
  );

  /// Gets comments for a moment.
  _i3.Future<List<_i12.MomentComment>> getMomentComments(
    int momentId, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i12.MomentComment>>(
    'moment',
    'getMomentComments',
    {
      'momentId': momentId,
      'limit': limit,
    },
  );

  /// Deletes a comment (only by author).
  _i3.Future<void> deleteComment(int commentId) =>
      caller.callServerEndpoint<void>(
        'moment',
        'deleteComment',
        {'commentId': commentId},
      );
}

/// {@category Endpoint}
class EndpointNotification extends _i2.EndpointRef {
  EndpointNotification(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Gets user's notifications.
  _i3.Future<List<_i13.UserNotification>> getUserNotifications({
    required int limit,
    required int offset,
    required bool unreadOnly,
  }) => caller.callServerEndpoint<List<_i13.UserNotification>>(
    'notification',
    'getUserNotifications',
    {
      'limit': limit,
      'offset': offset,
      'unreadOnly': unreadOnly,
    },
  );

  /// Marks notifications as read.
  _i3.Future<void> markAsRead(List<int> notificationIds) =>
      caller.callServerEndpoint<void>(
        'notification',
        'markAsRead',
        {'notificationIds': notificationIds},
      );

  /// Gets unread notification count.
  _i3.Future<int> getUnreadCount() => caller.callServerEndpoint<int>(
    'notification',
    'getUnreadCount',
    {},
  );

  /// Registers a device token for push notifications.
  _i3.Future<void> registerDeviceToken(
    String token,
    String platform,
  ) => caller.callServerEndpoint<void>(
    'notification',
    'registerDeviceToken',
    {
      'token': token,
      'platform': platform,
    },
  );

  /// Unregisters a device token.
  _i3.Future<void> unregisterDeviceToken(String token) =>
      caller.callServerEndpoint<void>(
        'notification',
        'unregisterDeviceToken',
        {'token': token},
      );
}

/// {@category Endpoint}
class EndpointPrivateChat extends _i2.EndpointRef {
  EndpointPrivateChat(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'privateChat';

  /// Creates or retrieves a private chat between two users.
  /// Returns the channel ID for the private chat.
  _i3.Future<_i14.PrivateChat> getOrCreatePrivateChat(String otherUserId) =>
      caller.callServerEndpoint<_i14.PrivateChat>(
        'privateChat',
        'getOrCreatePrivateChat',
        {'otherUserId': otherUserId},
      );

  /// Lists all private chats for the current user.
  _i3.Future<List<_i15.PrivateChatWithProfile>> listPrivateChats() =>
      caller.callServerEndpoint<List<_i15.PrivateChatWithProfile>>(
        'privateChat',
        'listPrivateChats',
        {},
      );

  /// Gets details about a private chat including the other participant's info.
  _i3.Future<Map<String, dynamic>> getPrivateChatDetails(int channelId) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'privateChat',
        'getPrivateChatDetails',
        {'channelId': channelId},
      );

  /// Updates the lastMessageAt timestamp for a private chat.
  _i3.Future<void> updateLastMessageTime(int privateChatId) =>
      caller.callServerEndpoint<void>(
        'privateChat',
        'updateLastMessageTime',
        {'privateChatId': privateChatId},
      );
}

/// {@category Endpoint}
class EndpointReport extends _i2.EndpointRef {
  EndpointReport(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'report';

  /// Reports a user for inappropriate behavior.
  /// Implements abuse prevention:
  /// - Floor 0 users cannot report
  /// - Max 5 reports per day per user
  /// - 30-minute cooldown between reports
  /// - Cannot report the same user more than once per day
  _i3.Future<void> reportUser({
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) => caller.callServerEndpoint<void>(
    'report',
    'reportUser',
    {
      'targetUserId': targetUserId,
      'reason': reason,
      'channelId': channelId,
      'messageId': messageId,
    },
  );

  /// Gets the number of reports a user has received (for moderation).
  _i3.Future<int> getReportCount(String userId) =>
      caller.callServerEndpoint<int>(
        'report',
        'getReportCount',
        {'userId': userId},
      );

  /// Lists recent reports for moderation (admin only).
  _i3.Future<List<_i16.Report>> listReports({
    required int limit,
    required bool onlyUnresolved,
  }) => caller.callServerEndpoint<List<_i16.Report>>(
    'report',
    'listReports',
    {
      'limit': limit,
      'onlyUnresolved': onlyUnresolved,
    },
  );

  /// Marks a report as resolved (admin only).
  _i3.Future<void> resolveReport(
    int reportId,
    bool approved,
  ) => caller.callServerEndpoint<void>(
    'report',
    'resolveReport',
    {
      'reportId': reportId,
      'approved': approved,
    },
  );

  /// Gets detailed report information with user context (admin only).
  _i3.Future<Map<String, dynamic>> getReportDetails(int reportId) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'report',
        'getReportDetails',
        {'reportId': reportId},
      );
}

/// {@category Endpoint}
class EndpointResident extends _i2.EndpointRef {
  EndpointResident(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'resident';

  /// Checks if the authenticated user has a Resident profile.
  _i3.Future<_i7.Resident?> getResident() =>
      caller.callServerEndpoint<_i7.Resident?>(
        'resident',
        'getResident',
        {},
      );

  /// Fetches a Resident profile by their user ID.
  _i3.Future<_i7.Resident?> getResidentById(String userId) =>
      caller.callServerEndpoint<_i7.Resident?>(
        'resident',
        'getResidentById',
        {'userId': userId},
      );

  /// Initializes a Resident profile for an authenticated user.
  /// This overwrites any existing UserProfile data (e.g. from Google) with
  /// the chosen anonymous persona.
  _i3.Future<_i7.Resident> initializeResident({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String>? interests,
    List<String>? languages,
  }) => caller.callServerEndpoint<_i7.Resident>(
    'resident',
    'initializeResident',
    {
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'country': country,
      'bio': bio,
      'interests': interests,
      'languages': languages,
    },
  );
}

/// {@category Endpoint}
class EndpointSearch extends _i2.EndpointRef {
  EndpointSearch(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Search for users by name (optimized with early limit)
  _i3.Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    required int limit,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'search',
    'searchUsers',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Search for groups by name or description
  _i3.Future<List<_i6.Group>> searchGroups(
    String query, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i6.Group>>(
    'search',
    'searchGroups',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Get trending moments (most liked in last 7 days) - CACHED
  _i3.Future<List<_i10.Moment>> getTrendingMoments({required int limit}) =>
      caller.callServerEndpoint<List<_i10.Moment>>(
        'search',
        'getTrendingMoments',
        {'limit': limit},
      );

  /// Get popular groups (most members) - CACHED
  _i3.Future<List<_i6.Group>> getPopularGroups({required int limit}) =>
      caller.callServerEndpoint<List<_i6.Group>>(
        'search',
        'getPopularGroups',
        {'limit': limit},
      );

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  _i3.Future<List<Map<String, dynamic>>> getActiveUsers({required int limit}) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'search',
        'getActiveUsers',
        {'limit': limit},
      );

  /// Get recent moments (for discovery feed)
  _i3.Future<List<_i10.Moment>> getRecentMoments({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i10.Moment>>(
    'search',
    'getRecentMoments',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Search all content (users, groups, moments)
  _i3.Future<Map<String, dynamic>> searchAll(
    String query, {
    required int limit,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'search',
    'searchAll',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Discover users by shared interests
  _i3.Future<List<Map<String, dynamic>>> discoverUsersByInterests({
    required int limit,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'search',
    'discoverUsersByInterests',
    {'limit': limit},
  );

  /// Discover users by shared languages
  _i3.Future<List<Map<String, dynamic>>> discoverUsersByLanguages({
    required int limit,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'search',
    'discoverUsersByLanguages',
    {'limit': limit},
  );

  /// Get personalized discovery feed (combines interests, languages, and activity)
  _i3.Future<Map<String, dynamic>> getDiscoveryFeed({required int limit}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'search',
        'getDiscoveryFeed',
        {'limit': limit},
      );
}

/// {@category Endpoint}
class EndpointStreak extends _i2.EndpointRef {
  EndpointStreak(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'streak';

  /// Gets the current user's streak data.
  _i3.Future<_i17.UserStreak?> getUserStreak() =>
      caller.callServerEndpoint<_i17.UserStreak?>(
        'streak',
        'getUserStreak',
        {},
      );

  /// Checks if the user can claim today's daily reward.
  _i3.Future<bool> canClaimDailyReward() => caller.callServerEndpoint<bool>(
    'streak',
    'canClaimDailyReward',
    {},
  );

  /// Claims the daily reward.
  _i3.Future<_i18.DailyReward> claimDailyReward() =>
      caller.callServerEndpoint<_i18.DailyReward>(
        'streak',
        'claimDailyReward',
        {},
      );

  /// Gets the user's reward history.
  _i3.Future<List<_i18.DailyReward>> getRewardHistory({required int limit}) =>
      caller.callServerEndpoint<List<_i18.DailyReward>>(
        'streak',
        'getRewardHistory',
        {'limit': limit},
      );
}

/// {@category Endpoint}
class EndpointUserLike extends _i2.EndpointRef {
  EndpointUserLike(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'userLike';

  /// Vouch/Like a user.
  /// Implements One-Vote Rule and adds +10 to target's Trust Score.
  _i3.Future<void> likeUser(String targetUserId) =>
      caller.callServerEndpoint<void>(
        'userLike',
        'likeUser',
        {'targetUserId': targetUserId},
      );

  /// Remove a Vouch/Like from a user.
  /// Removes -10 from target's Trust Score.
  _i3.Future<void> unlikeUser(String targetUserId) =>
      caller.callServerEndpoint<void>(
        'userLike',
        'unlikeUser',
        {'targetUserId': targetUserId},
      );

  /// Get the list of UUIDs that the current user has liked.
  _i3.Future<List<String>> getMyLikedUserIds() =>
      caller.callServerEndpoint<List<String>>(
        'userLike',
        'getMyLikedUserIds',
        {},
      );
}

/// {@category Endpoint}
class EndpointUserProfile extends _i2.EndpointRef {
  EndpointUserProfile(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'userProfile';

  /// Get a user's profile by their user ID
  _i3.Future<Map<String, dynamic>?> getUserProfile(String userId) =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'userProfile',
        'getUserProfile',
        {'userId': userId},
      );

  /// Block a user
  _i3.Future<bool> blockUser(String userId) => caller.callServerEndpoint<bool>(
    'userProfile',
    'blockUser',
    {'userId': userId},
  );

  /// Unblock a user
  _i3.Future<bool> unblockUser(String userId) =>
      caller.callServerEndpoint<bool>(
        'userProfile',
        'unblockUser',
        {'userId': userId},
      );

  /// Check if a user is blocked
  _i3.Future<bool> isUserBlocked(String userId) =>
      caller.callServerEndpoint<bool>(
        'userProfile',
        'isUserBlocked',
        {'userId': userId},
      );

  /// Get list of user IDs blocked by the current user
  _i3.Future<List<String>> getBlockedUserIds() =>
      caller.callServerEndpoint<List<String>>(
        'userProfile',
        'getBlockedUserIds',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i19.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i19.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
    auth = _i20.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;

  late final _i20.Caller auth;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i21.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    firebaseIdp = EndpointFirebaseIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    achievement = EndpointAchievement(this);
    admin = EndpointAdmin(this);
    group = EndpointGroup(this);
    health = EndpointHealth(this);
    image = EndpointImage(this);
    message = EndpointMessage(this);
    moment = EndpointMoment(this);
    notification = EndpointNotification(this);
    privateChat = EndpointPrivateChat(this);
    report = EndpointReport(this);
    resident = EndpointResident(this);
    search = EndpointSearch(this);
    streak = EndpointStreak(this);
    userLike = EndpointUserLike(this);
    userProfile = EndpointUserProfile(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointFirebaseIdp firebaseIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAchievement achievement;

  late final EndpointAdmin admin;

  late final EndpointGroup group;

  late final EndpointHealth health;

  late final EndpointImage image;

  late final EndpointMessage message;

  late final EndpointMoment moment;

  late final EndpointNotification notification;

  late final EndpointPrivateChat privateChat;

  late final EndpointReport report;

  late final EndpointResident resident;

  late final EndpointSearch search;

  late final EndpointStreak streak;

  late final EndpointUserLike userLike;

  late final EndpointUserProfile userProfile;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'firebaseIdp': firebaseIdp,
    'jwtRefresh': jwtRefresh,
    'achievement': achievement,
    'admin': admin,
    'group': group,
    'health': health,
    'image': image,
    'message': message,
    'moment': moment,
    'notification': notification,
    'privateChat': privateChat,
    'report': report,
    'resident': resident,
    'search': search,
    'streak': streak,
    'userLike': userLike,
    'userProfile': userProfile,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
    'auth': modules.auth,
  };
}
