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
import 'package:talktive_client/src/protocol/admin_report_summary.dart' as _i5;
import 'package:talktive_client/src/protocol/report_status.dart' as _i6;
import 'package:talktive_client/src/protocol/admin_statistics.dart' as _i7;
import 'package:talktive_client/src/protocol/admin_user_summary.dart' as _i8;
import 'package:talktive_client/src/protocol/admin_user_details.dart' as _i9;
import 'package:talktive_client/src/protocol/user_achievement_view.dart'
    as _i10;
import 'package:talktive_client/src/protocol/resident.dart' as _i11;
import 'package:talktive_client/src/protocol/gamification_status.dart' as _i12;
import 'package:talktive_client/src/protocol/daily_reward.dart' as _i13;
import 'package:talktive_client/src/protocol/lounge.dart' as _i14;
import 'package:talktive_client/src/protocol/lounge_with_membership.dart'
    as _i15;
import 'package:talktive_client/src/protocol/lounge_member_with_profile.dart'
    as _i16;
import 'package:talktive_client/src/protocol/message.dart' as _i17;
import 'package:talktive_client/src/protocol/channel.dart' as _i18;
import 'package:talktive_client/src/protocol/private_chat.dart' as _i19;
import 'package:talktive_client/src/protocol/private_chat_with_profile.dart'
    as _i20;
import 'package:talktive_client/src/protocol/moment.dart' as _i21;
import 'package:talktive_client/src/protocol/moment_like.dart' as _i22;
import 'package:talktive_client/src/protocol/moment_comment.dart' as _i23;
import 'package:talktive_client/src/protocol/user_notification.dart' as _i24;
import 'package:talktive_client/src/protocol/legacy_migration_data.dart'
    as _i25;
import 'package:talktive_client/src/protocol/user_profile_view.dart' as _i26;
import 'package:talktive_client/src/protocol/user_summary.dart' as _i27;
import 'package:talktive_client/src/protocol/discovery_feed.dart' as _i28;
import 'package:talktive_client/src/protocol/search_all_results.dart' as _i29;
import 'package:talktive_client/src/protocol/greetings/greeting.dart' as _i30;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i31;
import 'protocol.dart' as _i32;

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

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
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

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'firebaseIdp',
    'hasAccount',
    {},
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

/// Endpoint for administrative and moderation tasks.
/// {@category Endpoint}
class EndpointAdmin extends _i2.EndpointRef {
  EndpointAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  /// Fetches pending reports with detailed user summaries.
  _i3.Future<List<_i5.AdminReportSummary>> getPendingReports({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i5.AdminReportSummary>>(
    'admin',
    'getPendingReports',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Fetches all reports with optional status filtering.
  _i3.Future<List<_i5.AdminReportSummary>> listReports({
    _i6.ReportStatus? status,
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i5.AdminReportSummary>>(
    'admin',
    'listReports',
    {
      'status': status,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Legacy helper for getAllReports
  _i3.Future<List<_i5.AdminReportSummary>> getAllReports({
    _i6.ReportStatus? status,
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i5.AdminReportSummary>>(
    'admin',
    'getAllReports',
    {
      'status': status,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Resolves a report, optionally taking action against the target.
  _i3.Future<void> resolveReport({
    required int reportId,
    required _i6.ReportStatus status,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'resolveReport',
    {
      'reportId': reportId,
      'status': status,
    },
  );

  /// Suspends a user account.
  _i3.Future<void> suspendUser({
    required _i2.UuidValue userId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'suspendUser',
    {
      'userId': userId,
      'reason': reason,
    },
  );

  /// Unsuspends a user account.
  _i3.Future<void> unsuspendUser({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'unsuspendUser',
        {'userId': userId},
      );

  /// Mutes a user for a specified duration.
  _i3.Future<void> muteUser({
    required _i2.UuidValue userId,
    int? minutes,
    int? durationHours,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'muteUser',
    {
      'userId': userId,
      'minutes': minutes,
      'durationHours': durationHours,
      'reason': reason,
    },
  );

  /// Unmutes a user immediately.
  _i3.Future<void> unmuteUser({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'unmuteUser',
        {'userId': userId},
      );

  /// Deletes a message.
  _i3.Future<void> deleteMessage({required int messageId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'deleteMessage',
        {'messageId': messageId},
      );

  /// Resets a user's reputation to default.
  _i3.Future<void> resetReputation({
    required _i2.UuidValue userId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'resetReputation',
    {
      'userId': userId,
      'reason': reason,
    },
  );

  /// Computes platform-wide statistics.
  _i3.Future<_i7.AdminStatistics> getStatistics() =>
      caller.callServerEndpoint<_i7.AdminStatistics>(
        'admin',
        'getStatistics',
        {},
      );

  /// Searches for users by name or specific ID.
  _i3.Future<List<_i8.AdminUserSummary>> searchUsers({
    String? query,
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i8.AdminUserSummary>>(
    'admin',
    'searchUsers',
    {
      'query': query,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Promotes a user to Admin role.
  _i3.Future<void> promoteToAdmin({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'promoteToAdmin',
        {'userId': userId},
      );

  /// Demotes an Admin to Moderator or regular user.
  _i3.Future<void> demoteFromAdmin({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'demoteFromAdmin',
        {'userId': userId},
      );

  /// Promotes a user to Moderator role.
  _i3.Future<void> promoteToModerator({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'promoteToModerator',
        {'userId': userId},
      );

  /// Demotes a moderator back to a regular user.
  _i3.Future<void> demoteFromModerator({required _i2.UuidValue userId}) =>
      caller.callServerEndpoint<void>(
        'admin',
        'demoteFromModerator',
        {'userId': userId},
      );

  /// Makes a lounge private/locked by staff.
  _i3.Future<void> makeLoungePrivate(int loungeId) =>
      caller.callServerEndpoint<void>(
        'admin',
        'makeLoungePrivate',
        {'loungeId': loungeId},
      );

  /// Disbands a lounge.
  _i3.Future<void> disbandLounge({
    required int loungeId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'admin',
    'disbandLounge',
    {
      'loungeId': loungeId,
      'reason': reason,
    },
  );

  /// Checks if the current user is a staff member.
  _i3.Future<bool> isStaff() => caller.callServerEndpoint<bool>(
    'admin',
    'isStaff',
    {},
  );

  /// Fetches detailed user information and history for administrative review.
  _i3.Future<_i9.AdminUserDetails> getUserDetails({
    required _i2.UuidValue userId,
  }) => caller.callServerEndpoint<_i9.AdminUserDetails>(
    'admin',
    'getUserDetails',
    {'userId': userId},
  );
}

/// {@category Endpoint}
class EndpointGamification extends _i2.EndpointRef {
  EndpointGamification(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'gamification';

  /// Gets all achievements with user progress.
  _i3.Future<List<_i10.UserAchievementView>> getUserAchievements() =>
      caller.callServerEndpoint<List<_i10.UserAchievementView>>(
        'gamification',
        'getUserAchievements',
        {},
      );

  /// Marks achievements as notified (user has seen them).
  _i3.Future<void> markAchievementsAsNotified(List<int> achievementIds) =>
      caller.callServerEndpoint<void>(
        'gamification',
        'markAchievementsAsNotified',
        {'achievementIds': achievementIds},
      );

  /// Gets the current user's resident data (containing streaks).
  _i3.Future<_i11.Resident> getGamificationData() =>
      caller.callServerEndpoint<_i11.Resident>(
        'gamification',
        'getGamificationData',
        {},
      );

  /// Gets the combined gamification status for a resident.
  _i3.Future<_i12.GamificationStatus> getGamificationStatus() =>
      caller.callServerEndpoint<_i12.GamificationStatus>(
        'gamification',
        'getGamificationStatus',
        {},
      );

  /// Checks if the user can claim today's daily reward.
  _i3.Future<bool> canClaimDailyReward() => caller.callServerEndpoint<bool>(
    'gamification',
    'canClaimDailyReward',
    {},
  );

  /// Claims the daily reward.
  _i3.Future<_i13.DailyReward> claimDailyReward() =>
      caller.callServerEndpoint<_i13.DailyReward>(
        'gamification',
        'claimDailyReward',
        {},
      );

  /// Gets the user's reward history.
  _i3.Future<List<_i13.DailyReward>> getRewardHistory({required int limit}) =>
      caller.callServerEndpoint<List<_i13.DailyReward>>(
        'gamification',
        'getRewardHistory',
        {'limit': limit},
      );

  /// Seeds the database with predefined achievements (admin only).
  _i3.Future<void> seedAchievements() => caller.callServerEndpoint<void>(
    'gamification',
    'seedAchievements',
    {},
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

/// Endpoint for managing interest-based lounges (Clubhouse).
/// {@category Endpoint}
class EndpointLounge extends _i2.EndpointRef {
  EndpointLounge(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'lounge';

  /// Creates a new lounge.
  _i3.Future<_i14.Lounge> createLounge(
    String name, {
    String? description,
    String? emoji,
    required bool isPublic,
    required int maxMembers,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) => caller.callServerEndpoint<_i14.Lounge>(
    'lounge',
    'createLounge',
    {
      'name': name,
      'description': description,
      'emoji': emoji,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      'interests': interests,
      'languages': languages,
      'country': country,
      'rules': rules,
    },
  );

  /// Lists all lounges the user considers 'theirs' (joined, invited, applied).
  _i3.Future<List<_i15.LoungeWithMembership>> listMyLounges({
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i15.LoungeWithMembership>>(
    'lounge',
    'listMyLounges',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Gets details about a specific lounge.
  _i3.Future<_i14.Lounge> getLounge(int loungeId) =>
      caller.callServerEndpoint<_i14.Lounge>(
        'lounge',
        'getLounge',
        {'loungeId': loungeId},
      );

  /// Searches for public lounges based on a query.
  _i3.Future<List<_i14.Lounge>> searchPublicLounges(
    String query, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i14.Lounge>>(
    'lounge',
    'searchPublicLounges',
    {
      'query': query,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Applies to join a public lounge.
  _i3.Future<void> applyToLounge(int loungeId) =>
      caller.callServerEndpoint<void>(
        'lounge',
        'applyToLounge',
        {'loungeId': loungeId},
      );

  /// Invites a user to a lounge.
  _i3.Future<void> inviteUserToLounge(
    int loungeId,
    String targetUserIdString,
  ) => caller.callServerEndpoint<void>(
    'lounge',
    'inviteUserToLounge',
    {
      'loungeId': loungeId,
      'targetUserIdString': targetUserIdString,
    },
  );

  /// Responds to a lounge invite.
  _i3.Future<void> respondToLoungeInvite(
    int loungeId,
    bool accept,
  ) => caller.callServerEndpoint<void>(
    'lounge',
    'respondToLoungeInvite',
    {
      'loungeId': loungeId,
      'accept': accept,
    },
  );

  /// Approves or rejects a pending lounge application (creator only).
  _i3.Future<void> approveLoungeApplication(
    int loungeId,
    String targetUserIdString,
    bool approve,
  ) => caller.callServerEndpoint<void>(
    'lounge',
    'approveLoungeApplication',
    {
      'loungeId': loungeId,
      'targetUserIdString': targetUserIdString,
      'approve': approve,
    },
  );

  /// Leaves a lounge.
  _i3.Future<void> leaveLounge(int loungeId) => caller.callServerEndpoint<void>(
    'lounge',
    'leaveLounge',
    {'loungeId': loungeId},
  );

  /// Toggles mute status for lounge notifications.
  _i3.Future<void> toggleMuteLounge(
    int loungeId,
    bool isMuted,
  ) => caller.callServerEndpoint<void>(
    'lounge',
    'toggleMuteLounge',
    {
      'loungeId': loungeId,
      'isMuted': isMuted,
    },
  );

  /// Gets all active members of a lounge.
  _i3.Future<List<_i16.LoungeMemberWithProfile>> getLoungeMembers(
    int loungeId,
  ) => caller.callServerEndpoint<List<_i16.LoungeMemberWithProfile>>(
    'lounge',
    'getLoungeMembers',
    {'loungeId': loungeId},
  );

  /// Gets all pending applications for a lounge (creator only).
  _i3.Future<List<_i16.LoungeMemberWithProfile>> getPendingApplications(
    int loungeId,
  ) => caller.callServerEndpoint<List<_i16.LoungeMemberWithProfile>>(
    'lounge',
    'getPendingApplications',
    {'loungeId': loungeId},
  );

  /// Updates lounge metadata (admin only).
  _i3.Future<_i14.Lounge> updateLounge(
    int loungeId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) => caller.callServerEndpoint<_i14.Lounge>(
    'lounge',
    'updateLounge',
    {
      'loungeId': loungeId,
      'name': name,
      'description': description,
      'emoji': emoji,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      'interests': interests,
      'languages': languages,
      'country': country,
      'rules': rules,
    },
  );

  /// Deletes a lounge (creator only).
  _i3.Future<void> deleteLounge(int loungeId) =>
      caller.callServerEndpoint<void>(
        'lounge',
        'deleteLounge',
        {'loungeId': loungeId},
      );

  /// Kicks a member from a lounge (creator only).
  _i3.Future<void> kickMember({
    required int loungeId,
    required _i2.UuidValue targetUserId,
  }) => caller.callServerEndpoint<void>(
    'lounge',
    'kickMember',
    {
      'loungeId': loungeId,
      'targetUserId': targetUserId,
    },
  );
}

/// {@category Endpoint}
class EndpointMedia extends _i2.EndpointRef {
  EndpointMedia(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'media';

  /// Generates an upload description for a file.
  /// Validates permissions (floor level, premium status) based on the destination path.
  _i3.Future<String?> getUploadDescription(
    String path,
    int fileSize,
    String? fileExtension,
  ) => caller.callServerEndpoint<String?>(
    'media',
    'getUploadDescription',
    {
      'path': path,
      'fileSize': fileSize,
      'fileExtension': fileExtension,
    },
  );

  /// Verifies if a file exists in storage.
  _i3.Future<bool> verifyUpload(String path) => caller.callServerEndpoint<bool>(
    'media',
    'verifyUpload',
    {'path': path},
  );
}

/// Unified endpoint for all Resident communication (Plaza, Lounges, Private).
/// {@category Endpoint}
class EndpointMessage extends _i2.EndpointRef {
  EndpointMessage(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'message';

  _i3.Future<String> ping() => caller.callServerEndpoint<String>(
    'message',
    'ping',
    {},
  );

  /// Sends a message to a specific channel.
  _i3.Future<_i17.Message> sendMessage(
    int channelId, {
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
    required bool isSystem,
  }) => caller.callServerEndpoint<_i17.Message>(
    'message',
    'sendMessage',
    {
      'channelId': channelId,
      'content': content,
      'imageUrl': imageUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'duration': duration,
      'fileSize': fileSize,
      'isSystem': isSystem,
    },
  );

  /// Subscribes to a channel to receive live updates.
  _i3.Stream<_i2.SerializableModel> subscribe(int channelId) =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i2.SerializableModel>,
        _i2.SerializableModel
      >(
        'message',
        'subscribe',
        {'channelId': channelId},
        {},
      );

  /// Lists message history for a channel.
  _i3.Future<List<_i17.Message>> listMessages(
    int channelId, {
    required int limit,
    required int offset,
    int? beforeId,
  }) => caller.callServerEndpoint<List<_i17.Message>>(
    'message',
    'listMessages',
    {
      'channelId': channelId,
      'limit': limit,
      'offset': offset,
      'beforeId': beforeId,
    },
  );

  /// Marks all messages in a channel as read for the current resident.
  _i3.Future<void> markChannelAsRead(int channelId) =>
      caller.callServerEndpoint<void>(
        'message',
        'markChannelAsRead',
        {'channelId': channelId},
      );

  /// Sends a typing indicator to a channel.
  _i3.Future<void> sendTypingIndicator(
    int channelId,
    bool isTyping,
  ) => caller.callServerEndpoint<void>(
    'message',
    'sendTypingIndicator',
    {
      'channelId': channelId,
      'isTyping': isTyping,
    },
  );

  /// Updates channel-specific settings like persistence.
  _i3.Future<_i18.Channel> updateChannelPersistence(
    int channelId,
    bool isPersistent,
  ) => caller.callServerEndpoint<_i18.Channel>(
    'message',
    'updateChannelPersistence',
    {
      'channelId': channelId,
      'isPersistent': isPersistent,
    },
  );

  /// Gets the currently pinned message for a channel.
  _i3.Future<_i17.Message?> getPinnedMessage(int channelId) =>
      caller.callServerEndpoint<_i17.Message?>(
        'message',
        'getPinnedMessage',
        {'channelId': channelId},
      );

  /// Pins a message in a channel.
  _i3.Future<_i17.Message> pinMessage(int messageId) =>
      caller.callServerEndpoint<_i17.Message>(
        'message',
        'pinMessage',
        {'messageId': messageId},
      );

  /// Unpins a message.
  _i3.Future<_i17.Message> unpinMessage(int messageId) =>
      caller.callServerEndpoint<_i17.Message>(
        'message',
        'unpinMessage',
        {'messageId': messageId},
      );

  /// Recalls (deletes) a message.
  _i3.Future<_i17.Message> recallMessage(int messageId) =>
      caller.callServerEndpoint<_i17.Message>(
        'message',
        'recallMessage',
        {'messageId': messageId},
      );

  /// Starts or resumes a 1:1 chat session.
  _i3.Future<_i19.PrivateChat> getOrCreatePrivateChat(
    String otherUserId, {
    String? initialMessage,
  }) => caller.callServerEndpoint<_i19.PrivateChat>(
    'message',
    'getOrCreatePrivateChat',
    {
      'otherUserId': otherUserId,
      'initialMessage': initialMessage,
    },
  );

  /// Lists all private chats (Peep-hole preview mode enabled).
  _i3.Future<List<_i20.PrivateChatWithProfile>> listPrivateChats() =>
      caller.callServerEndpoint<List<_i20.PrivateChatWithProfile>>(
        'message',
        'listPrivateChats',
        {},
      );

  /// Gets details about a private chat including the other participant.
  _i3.Future<_i20.PrivateChatWithProfile?> getPrivateChatDetails(
    int channelId,
  ) => caller.callServerEndpoint<_i20.PrivateChatWithProfile?>(
    'message',
    'getPrivateChatDetails',
    {'channelId': channelId},
  );

  /// Responds to a knock/invite.
  _i3.Future<void> respondToChatInvite(
    int channelId,
    bool accept,
  ) => caller.callServerEndpoint<void>(
    'message',
    'respondToChatInvite',
    {
      'channelId': channelId,
      'accept': accept,
    },
  );

  /// Leaves a private thread.
  _i3.Future<void> leaveChat(int channelId) => caller.callServerEndpoint<void>(
    'message',
    'leaveChat',
    {'channelId': channelId},
  );
}

/// {@category Endpoint}
class EndpointMoment extends _i2.EndpointRef {
  EndpointMoment(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moment';

  /// Posts a new moment to the feed.
  /// Only residents on Floor 2+ can post moments (to prevent spam).
  _i3.Future<_i21.Moment> postMoment({
    required String imageUrl,
    required String caption,
    int? fileSize,
  }) => caller.callServerEndpoint<_i21.Moment>(
    'moment',
    'postMoment',
    {
      'imageUrl': imageUrl,
      'caption': caption,
      'fileSize': fileSize,
    },
  );

  /// Lists the latest moments.
  _i3.Future<List<_i21.Moment>> listMoments({
    required int limit,
    int? lastId,
  }) => caller.callServerEndpoint<List<_i21.Moment>>(
    'moment',
    'listMoments',
    {
      'limit': limit,
      'lastId': lastId,
    },
  );

  /// Lists the moments for a specific user.
  _i3.Future<List<_i21.Moment>> listUserMoments({
    required _i2.UuidValue userId,
    required int limit,
    int? lastId,
  }) => caller.callServerEndpoint<List<_i21.Moment>>(
    'moment',
    'listUserMoments',
    {
      'userId': userId,
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
  _i3.Future<List<_i22.MomentLike>> getMomentLikes(int momentId) =>
      caller.callServerEndpoint<List<_i22.MomentLike>>(
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
  _i3.Future<_i23.MomentComment> addComment(
    int momentId,
    String text,
  ) => caller.callServerEndpoint<_i23.MomentComment>(
    'moment',
    'addComment',
    {
      'momentId': momentId,
      'text': text,
    },
  );

  /// Gets comments for a moment.
  _i3.Future<List<_i23.MomentComment>> getMomentComments(
    int momentId, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i23.MomentComment>>(
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

  /// Deletes a moment (only by author or admin).
  _i3.Future<void> deleteMoment(int momentId) =>
      caller.callServerEndpoint<void>(
        'moment',
        'deleteMoment',
        {'momentId': momentId},
      );
}

/// {@category Endpoint}
class EndpointNotification extends _i2.EndpointRef {
  EndpointNotification(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Gets user's notifications.
  _i3.Future<List<_i24.UserNotification>> getUserNotifications({
    required int limit,
    required int offset,
    required bool unreadOnly,
  }) => caller.callServerEndpoint<List<_i24.UserNotification>>(
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

  /// Creates or retrieves a private chat between two residents.
  _i3.Future<_i19.PrivateChat> getOrCreatePrivateChat(
    String otherUserId, {
    String? initialMessage,
  }) => caller.callServerEndpoint<_i19.PrivateChat>(
    'privateChat',
    'getOrCreatePrivateChat',
    {
      'otherUserId': otherUserId,
      'initialMessage': initialMessage,
    },
  );

  /// Lists all private chats for the current resident.
  _i3.Future<List<_i20.PrivateChatWithProfile>> listPrivateChats() =>
      caller.callServerEndpoint<List<_i20.PrivateChatWithProfile>>(
        'privateChat',
        'listPrivateChats',
        {},
      );

  /// Gets details about a private chat including the other participant.
  _i3.Future<_i20.PrivateChatWithProfile?> getPrivateChatDetails(
    int channelId,
  ) => caller.callServerEndpoint<_i20.PrivateChatWithProfile?>(
    'privateChat',
    'getPrivateChatDetails',
    {'channelId': channelId},
  );

  /// Accepts or declines a private chat invitation.
  _i3.Future<void> respondToChatInvite(
    int channelId,
    bool accept,
  ) => caller.callServerEndpoint<void>(
    'privateChat',
    'respondToChatInvite',
    {
      'channelId': channelId,
      'accept': accept,
    },
  );

  /// Leaves a private chat.
  _i3.Future<void> leaveChat(int channelId) => caller.callServerEndpoint<void>(
    'privateChat',
    'leaveChat',
    {'channelId': channelId},
  );
}

/// {@category Endpoint}
class EndpointResident extends _i2.EndpointRef {
  EndpointResident(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'resident';

  /// Checks if the authenticated user has a Resident profile and
  /// performs standard background tasks (daily login bonus, etc.).
  _i3.Future<_i11.Resident?> getResident() =>
      caller.callServerEndpoint<_i11.Resident?>(
        'resident',
        'getResident',
        {},
      );

  /// Returns sanitized legacy profile data for the authenticated user, if any.
  _i3.Future<_i25.LegacyMigrationData?> getLegacyMigrationData() =>
      caller.callServerEndpoint<_i25.LegacyMigrationData?>(
        'resident',
        'getLegacyMigrationData',
        {},
      );

  /// Fetches a Resident profile by their user ID.
  _i3.Future<_i11.Resident?> getResidentById(String userId) =>
      caller.callServerEndpoint<_i11.Resident?>(
        'resident',
        'getResidentById',
        {'userId': userId},
      );

  /// Initializes a Resident profile for an authenticated user.
  _i3.Future<_i11.Resident> initializeResident({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
  }) => caller.callServerEndpoint<_i11.Resident>(
    'resident',
    'initializeResident',
    {
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'country': country,
      'bio': bio,
      'ageRange': ageRange,
      'interests': interests,
      'languages': languages,
      'mood': mood,
      'customAvatarUrl': customAvatarUrl,
    },
  );

  /// Updates an existing Resident's profile details.
  _i3.Future<_i11.Resident> updateResident({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
  }) => caller.callServerEndpoint<_i11.Resident>(
    'resident',
    'updateResident',
    {
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'country': country,
      'bio': bio,
      'ageRange': ageRange,
      'interests': interests,
      'languages': languages,
      'mood': mood,
      'customAvatarUrl': customAvatarUrl,
    },
  );

  /// Updates only the custom avatar URL (standalone method for overlay button).
  _i3.Future<_i11.Resident> updateCustomAvatar(
    String? customAvatarUrl, {
    int? avatarSize,
  }) => caller.callServerEndpoint<_i11.Resident>(
    'resident',
    'updateCustomAvatar',
    {
      'customAvatarUrl': customAvatarUrl,
      'avatarSize': avatarSize,
    },
  );

  /// Get a user's profile view (with stats)
  _i3.Future<_i26.UserProfileView?> getUserProfile(String userId) =>
      caller.callServerEndpoint<_i26.UserProfileView?>(
        'resident',
        'getUserProfile',
        {'userId': userId},
      );

  /// Updates privacy settings (Others, Voice, Search, etc).
  _i3.Future<_i11.Resident> updatePrivacy({
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
  }) => caller.callServerEndpoint<_i11.Resident>(
    'resident',
    'updatePrivacy',
    {
      'hideAds': hideAds,
      'showVoiceMessages': showVoiceMessages,
      'showAdvancedDiscovery': showAdvancedDiscovery,
      'showCustomAvatar': showCustomAvatar,
      'showOthersOnlineStatus': showOthersOnlineStatus,
      'showOthersReadReceipts': showOthersReadReceipts,
      'showOthersTypingIndicators': showOthersTypingIndicators,
      'keepPrivateChats': keepPrivateChats,
    },
  );

  /// Updates premium status (Mock for testing).
  _i3.Future<_i11.Resident> setPremiumStatus({required bool isPremium}) =>
      caller.callServerEndpoint<_i11.Resident>(
        'resident',
        'setPremiumStatus',
        {'isPremium': isPremium},
      );

  /// Starts a 24-hour premium trial.
  _i3.Future<_i11.Resident> startPremiumTrial() =>
      caller.callServerEndpoint<_i11.Resident>(
        'resident',
        'startPremiumTrial',
        {},
      );

  /// Vouches for another resident.
  _i3.Future<void> vouchForResident(_i2.UuidValue targetUserId) =>
      caller.callServerEndpoint<void>(
        'resident',
        'vouchForResident',
        {'targetUserId': targetUserId},
      );

  /// Removes a vouch for another resident.
  _i3.Future<void> removeResidentVouch(_i2.UuidValue targetUserId) =>
      caller.callServerEndpoint<void>(
        'resident',
        'removeResidentVouch',
        {'targetUserId': targetUserId},
      );

  /// Get list of resident IDs liked by current resident.
  _i3.Future<List<String>> getMyLikedResidentIds() =>
      caller.callServerEndpoint<List<String>>(
        'resident',
        'getMyLikedResidentIds',
        {},
      );

  /// Blocks a resident.
  _i3.Future<bool> blockResident(String userId) =>
      caller.callServerEndpoint<bool>(
        'resident',
        'blockResident',
        {'userId': userId},
      );

  /// Unblocks a resident.
  _i3.Future<bool> unblockResident(String userId) =>
      caller.callServerEndpoint<bool>(
        'resident',
        'unblockResident',
        {'userId': userId},
      );

  /// Checks if a resident is blocked.
  _i3.Future<bool> isResidentBlocked(String userId) =>
      caller.callServerEndpoint<bool>(
        'resident',
        'isResidentBlocked',
        {'userId': userId},
      );

  /// Gets list of resident IDs blocked by current resident.
  _i3.Future<List<String>> getBlockedResidentIds() =>
      caller.callServerEndpoint<List<String>>(
        'resident',
        'getBlockedResidentIds',
        {},
      );

  /// Reports a resident for inappropriate behavior.
  _i3.Future<void> reportResident({
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) => caller.callServerEndpoint<void>(
    'resident',
    'reportResident',
    {
      'targetUserId': targetUserId,
      'reason': reason,
      'channelId': channelId,
      'messageId': messageId,
    },
  );
}

/// {@category Endpoint}
class EndpointSearch extends _i2.EndpointRef {
  EndpointSearch(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Search for users with advanced filtering
  _i3.Future<List<_i27.UserSummary>> searchUsers(
    String? query, {
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    required int limit,
  }) => caller.callServerEndpoint<List<_i27.UserSummary>>(
    'search',
    'searchUsers',
    {
      'query': query,
      'gender': gender,
      'country': country,
      'language': language,
      'interest': interest,
      'ageRange': ageRange,
      'isPremium': isPremium,
      'limit': limit,
    },
  );

  /// Search for lounges with advanced filtering
  _i3.Future<List<_i14.Lounge>> searchLounges(
    String? query, {
    String? interest,
    String? language,
    String? country,
    required int limit,
  }) => caller.callServerEndpoint<List<_i14.Lounge>>(
    'search',
    'searchLounges',
    {
      'query': query,
      'interest': interest,
      'language': language,
      'country': country,
      'limit': limit,
    },
  );

  /// Get personalized discovery feed
  _i3.Future<_i28.DiscoveryFeed> getDiscoveryFeed({
    String? interest,
    String? language,
    String? country,
    required int limit,
  }) => caller.callServerEndpoint<_i28.DiscoveryFeed>(
    'search',
    'getDiscoveryFeed',
    {
      'interest': interest,
      'language': language,
      'country': country,
      'limit': limit,
    },
  );

  /// Search all content (users, lounges, moments)
  _i3.Future<_i29.SearchAllResults> searchAll(
    String query, {
    required int limit,
  }) => caller.callServerEndpoint<_i29.SearchAllResults>(
    'search',
    'searchAll',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Get trending moments (most liked in last 7 days) - CACHED
  _i3.Future<List<_i21.Moment>> getTrendingMoments({required int limit}) =>
      caller.callServerEndpoint<List<_i21.Moment>>(
        'search',
        'getTrendingMoments',
        {'limit': limit},
      );

  /// Get popular lounges (most members) - CACHED
  _i3.Future<List<_i14.Lounge>> getPopularLounges({
    String? interest,
    String? language,
    String? country,
    required int limit,
  }) => caller.callServerEndpoint<List<_i14.Lounge>>(
    'search',
    'getPopularLounges',
    {
      'interest': interest,
      'language': language,
      'country': country,
      'limit': limit,
    },
  );

  /// Get active users (most messages in last 7 days) - OPTIMIZED
  _i3.Future<List<_i27.UserSummary>> getActiveUsers({
    String? gender,
    String? country,
    String? language,
    String? interest,
    String? ageRange,
    bool? isPremium,
    required int limit,
  }) => caller.callServerEndpoint<List<_i27.UserSummary>>(
    'search',
    'getActiveUsers',
    {
      'gender': gender,
      'country': country,
      'language': language,
      'interest': interest,
      'ageRange': ageRange,
      'isPremium': isPremium,
      'limit': limit,
    },
  );
}

/// Backward-compatible endpoint for resident social actions.
/// {@category Endpoint}
class EndpointSocial extends _i2.EndpointRef {
  EndpointSocial(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'social';

  _i3.Future<void> likeUser(String targetUserId) =>
      caller.callServerEndpoint<void>(
        'social',
        'likeUser',
        {'targetUserId': targetUserId},
      );

  _i3.Future<void> unlikeUser(String targetUserId) =>
      caller.callServerEndpoint<void>(
        'social',
        'unlikeUser',
        {'targetUserId': targetUserId},
      );

  _i3.Future<List<String>> getMyLikedUserIds() =>
      caller.callServerEndpoint<List<String>>(
        'social',
        'getMyLikedUserIds',
        {},
      );

  _i3.Future<bool> blockUser(String userId) => caller.callServerEndpoint<bool>(
    'social',
    'blockUser',
    {'userId': userId},
  );

  _i3.Future<bool> unblockUser(String userId) =>
      caller.callServerEndpoint<bool>(
        'social',
        'unblockUser',
        {'userId': userId},
      );

  _i3.Future<bool> isUserBlocked(String userId) =>
      caller.callServerEndpoint<bool>(
        'social',
        'isUserBlocked',
        {'userId': userId},
      );

  _i3.Future<List<String>> getBlockedUserIds() =>
      caller.callServerEndpoint<List<String>>(
        'social',
        'getBlockedUserIds',
        {},
      );

  _i3.Future<void> reportUser({
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) => caller.callServerEndpoint<void>(
    'social',
    'reportUser',
    {
      'targetUserId': targetUserId,
      'reason': reason,
      'channelId': channelId,
      'messageId': messageId,
    },
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
  _i3.Future<_i30.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i30.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
    auth = _i31.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;

  late final _i31.Caller auth;
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
         _i32.Protocol(),
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
    admin = EndpointAdmin(this);
    gamification = EndpointGamification(this);
    health = EndpointHealth(this);
    lounge = EndpointLounge(this);
    media = EndpointMedia(this);
    message = EndpointMessage(this);
    moment = EndpointMoment(this);
    notification = EndpointNotification(this);
    privateChat = EndpointPrivateChat(this);
    resident = EndpointResident(this);
    search = EndpointSearch(this);
    social = EndpointSocial(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointFirebaseIdp firebaseIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAdmin admin;

  late final EndpointGamification gamification;

  late final EndpointHealth health;

  late final EndpointLounge lounge;

  late final EndpointMedia media;

  late final EndpointMessage message;

  late final EndpointMoment moment;

  late final EndpointNotification notification;

  late final EndpointPrivateChat privateChat;

  late final EndpointResident resident;

  late final EndpointSearch search;

  late final EndpointSocial social;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'firebaseIdp': firebaseIdp,
    'jwtRefresh': jwtRefresh,
    'admin': admin,
    'gamification': gamification,
    'health': health,
    'lounge': lounge,
    'media': media,
    'message': message,
    'moment': moment,
    'notification': notification,
    'privateChat': privateChat,
    'resident': resident,
    'search': search,
    'social': social,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
    'auth': modules.auth,
  };
}
