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
import 'dart:typed_data' as _i5;
import 'package:talktive_client/src/protocol/message.dart' as _i6;
import 'package:talktive_client/src/protocol/moment.dart' as _i7;
import 'package:talktive_client/src/protocol/report.dart' as _i8;
import 'package:talktive_client/src/protocol/resident.dart' as _i9;
import 'package:talktive_client/src/protocol/greetings/greeting.dart' as _i10;
import 'protocol.dart' as _i11;

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
    _i5.ByteData imageData,
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
  _i3.Future<_i6.Message> sendMessage(
    int channelId,
    String content, {
    String? imageUrl,
  }) => caller.callServerEndpoint<_i6.Message>(
    'message',
    'sendMessage',
    {
      'channelId': channelId,
      'content': content,
      'imageUrl': imageUrl,
    },
  );

  /// Subscribes to a channel to receive real-time messages.
  _i3.Stream<_i6.Message> subscribe(int channelId) =>
      caller.callStreamingServerEndpoint<_i3.Stream<_i6.Message>, _i6.Message>(
        'message',
        'subscribe',
        {'channelId': channelId},
        {},
      );

  /// Fetches the history of messages for a channel.
  _i3.Future<List<_i6.Message>> listMessages(
    int channelId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i6.Message>>(
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
  _i3.Future<_i7.Moment> postMoment({
    required String imageUrl,
    required String caption,
  }) => caller.callServerEndpoint<_i7.Moment>(
    'moment',
    'postMoment',
    {
      'imageUrl': imageUrl,
      'caption': caption,
    },
  );

  /// Lists the latest moments.
  _i3.Future<List<_i7.Moment>> listMoments({
    required int limit,
    int? lastId,
  }) => caller.callServerEndpoint<List<_i7.Moment>>(
    'moment',
    'listMoments',
    {
      'limit': limit,
      'lastId': lastId,
    },
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
  _i3.Future<List<_i8.Report>> listReports({
    required int limit,
    required bool onlyUnresolved,
  }) => caller.callServerEndpoint<List<_i8.Report>>(
    'report',
    'listReports',
    {
      'limit': limit,
      'onlyUnresolved': onlyUnresolved,
    },
  );

  /// Marks a report as resolved (admin only).
  _i3.Future<void> resolveReport(int reportId) =>
      caller.callServerEndpoint<void>(
        'report',
        'resolveReport',
        {'reportId': reportId},
      );
}

/// {@category Endpoint}
class EndpointResident extends _i2.EndpointRef {
  EndpointResident(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'resident';

  /// Checks if the authenticated user has a Resident profile.
  _i3.Future<_i9.Resident?> getResident() =>
      caller.callServerEndpoint<_i9.Resident?>(
        'resident',
        'getResident',
        {},
      );

  /// Initializes a Resident profile for an authenticated user.
  /// This overwrites any existing UserProfile data (e.g. from Google) with
  /// the chosen anonymous persona.
  _i3.Future<_i9.Resident> initializeResident({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
  }) => caller.callServerEndpoint<_i9.Resident>(
    'resident',
    'initializeResident',
    {
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'country': country,
      'bio': bio,
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
  _i3.Future<_i10.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i10.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
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
         _i11.Protocol(),
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
    image = EndpointImage(this);
    message = EndpointMessage(this);
    moment = EndpointMoment(this);
    report = EndpointReport(this);
    resident = EndpointResident(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointFirebaseIdp firebaseIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointImage image;

  late final EndpointMessage message;

  late final EndpointMoment moment;

  late final EndpointReport report;

  late final EndpointResident resident;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'firebaseIdp': firebaseIdp,
    'jwtRefresh': jwtRefresh,
    'image': image,
    'message': message,
    'moment': moment,
    'report': report,
    'resident': resident,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
