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
import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/firebase_idp_endpoint.dart' as _i3;
import '../auth/jwt_refresh_endpoint.dart' as _i4;
import '../endpoints/admin_endpoint.dart' as _i5;
import '../endpoints/gamification_endpoint.dart' as _i6;
import '../endpoints/health_endpoint.dart' as _i7;
import '../endpoints/lounge_endpoint.dart' as _i8;
import '../endpoints/media_endpoint.dart' as _i9;
import '../endpoints/message_endpoint.dart' as _i10;
import '../endpoints/moment_endpoint.dart' as _i11;
import '../endpoints/notification_endpoint.dart' as _i12;
import '../endpoints/private_chat_endpoint.dart' as _i13;
import '../endpoints/resident_endpoint.dart' as _i14;
import '../endpoints/search_endpoint.dart' as _i15;
import '../endpoints/social_endpoint.dart' as _i16;
import '../greetings/greeting_endpoint.dart' as _i17;
import 'package:talktive_server/src/generated/report_status.dart' as _i18;
import 'package:talktive_server/src/generated/protocol.dart' as _i19;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i20;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i21;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i22;
import 'package:talktive_server/src/generated/future_calls.dart' as _i23;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'firebaseIdp': _i3.FirebaseIdpEndpoint()
        ..initialize(
          server,
          'firebaseIdp',
          null,
        ),
      'jwtRefresh': _i4.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'admin': _i5.AdminEndpoint()
        ..initialize(
          server,
          'admin',
          null,
        ),
      'gamification': _i6.GamificationEndpoint()
        ..initialize(
          server,
          'gamification',
          null,
        ),
      'health': _i7.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
      'lounge': _i8.LoungeEndpoint()
        ..initialize(
          server,
          'lounge',
          null,
        ),
      'media': _i9.MediaEndpoint()
        ..initialize(
          server,
          'media',
          null,
        ),
      'message': _i10.MessageEndpoint()
        ..initialize(
          server,
          'message',
          null,
        ),
      'moment': _i11.MomentEndpoint()
        ..initialize(
          server,
          'moment',
          null,
        ),
      'notification': _i12.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'privateChat': _i13.PrivateChatEndpoint()
        ..initialize(
          server,
          'privateChat',
          null,
        ),
      'resident': _i14.ResidentEndpoint()
        ..initialize(
          server,
          'resident',
          null,
        ),
      'search': _i15.SearchEndpoint()
        ..initialize(
          server,
          'search',
          null,
        ),
      'social': _i16.SocialEndpoint()
        ..initialize(
          server,
          'social',
          null,
        ),
      'greeting': _i17.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['firebaseIdp'] = _i1.EndpointConnector(
      name: 'firebaseIdp',
      endpoint: endpoints['firebaseIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['firebaseIdp'] as _i3.FirebaseIdpEndpoint).login(
                    session,
                    idToken: params['idToken'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['firebaseIdp'] as _i3.FirebaseIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i4.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['admin'] = _i1.EndpointConnector(
      name: 'admin',
      endpoint: endpoints['admin']!,
      methodConnectors: {
        'getPendingReports': _i1.MethodConnector(
          name: 'getPendingReports',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getPendingReports(
                    session,
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'listReports': _i1.MethodConnector(
          name: 'listReports',
          params: {
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<_i18.ReportStatus?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).listReports(
                session,
                status: params['status'],
                limit: params['limit'],
                offset: params['offset'],
              ),
        ),
        'getAllReports': _i1.MethodConnector(
          name: 'getAllReports',
          params: {
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<_i18.ReportStatus?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getAllReports(
                    session,
                    status: params['status'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'resolveReport': _i1.MethodConnector(
          name: 'resolveReport',
          params: {
            'reportId': _i1.ParameterDescription(
              name: 'reportId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<_i18.ReportStatus>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).resolveReport(
                    session,
                    reportId: params['reportId'],
                    status: params['status'],
                  ),
        ),
        'suspendUser': _i1.MethodConnector(
          name: 'suspendUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).suspendUser(
                session,
                userId: params['userId'],
                reason: params['reason'],
              ),
        ),
        'unsuspendUser': _i1.MethodConnector(
          name: 'unsuspendUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).unsuspendUser(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'muteUser': _i1.MethodConnector(
          name: 'muteUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'minutes': _i1.ParameterDescription(
              name: 'minutes',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'durationHours': _i1.ParameterDescription(
              name: 'durationHours',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).muteUser(
                session,
                userId: params['userId'],
                minutes: params['minutes'],
                durationHours: params['durationHours'],
                reason: params['reason'],
              ),
        ),
        'unmuteUser': _i1.MethodConnector(
          name: 'unmuteUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).unmuteUser(
                session,
                userId: params['userId'],
              ),
        ),
        'deleteMessage': _i1.MethodConnector(
          name: 'deleteMessage',
          params: {
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteMessage(
                    session,
                    messageId: params['messageId'],
                  ),
        ),
        'resetReputation': _i1.MethodConnector(
          name: 'resetReputation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).resetReputation(
                    session,
                    userId: params['userId'],
                    reason: params['reason'],
                  ),
        ),
        'getStatistics': _i1.MethodConnector(
          name: 'getStatistics',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getStatistics(session),
        ),
        'searchUsers': _i1.MethodConnector(
          name: 'searchUsers',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).searchUsers(
                session,
                query: params['query'],
                limit: params['limit'],
                offset: params['offset'],
              ),
        ),
        'promoteToAdmin': _i1.MethodConnector(
          name: 'promoteToAdmin',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).promoteToAdmin(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'demoteFromAdmin': _i1.MethodConnector(
          name: 'demoteFromAdmin',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).demoteFromAdmin(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'promoteToModerator': _i1.MethodConnector(
          name: 'promoteToModerator',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).promoteToModerator(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'demoteFromModerator': _i1.MethodConnector(
          name: 'demoteFromModerator',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).demoteFromModerator(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'makeLoungePrivate': _i1.MethodConnector(
          name: 'makeLoungePrivate',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).makeLoungePrivate(
                    session,
                    params['loungeId'],
                  ),
        ),
        'disbandLounge': _i1.MethodConnector(
          name: 'disbandLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).disbandLounge(
                    session,
                    loungeId: params['loungeId'],
                    reason: params['reason'],
                  ),
        ),
        'isStaff': _i1.MethodConnector(
          name: 'isStaff',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).isStaff(session),
        ),
        'getUserDetails': _i1.MethodConnector(
          name: 'getUserDetails',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getUserDetails(
                    session,
                    userId: params['userId'],
                  ),
        ),
      },
    );
    connectors['gamification'] = _i1.EndpointConnector(
      name: 'gamification',
      endpoint: endpoints['gamification']!,
      methodConnectors: {
        'getUserAchievements': _i1.MethodConnector(
          name: 'getUserAchievements',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .getUserAchievements(session),
        ),
        'markAchievementsAsNotified': _i1.MethodConnector(
          name: 'markAchievementsAsNotified',
          params: {
            'achievementIds': _i1.ParameterDescription(
              name: 'achievementIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .markAchievementsAsNotified(
                    session,
                    params['achievementIds'],
                  ),
        ),
        'getGamificationData': _i1.MethodConnector(
          name: 'getGamificationData',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .getGamificationData(session),
        ),
        'getGamificationStatus': _i1.MethodConnector(
          name: 'getGamificationStatus',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .getGamificationStatus(session),
        ),
        'canClaimDailyReward': _i1.MethodConnector(
          name: 'canClaimDailyReward',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .canClaimDailyReward(session),
        ),
        'claimDailyReward': _i1.MethodConnector(
          name: 'claimDailyReward',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .claimDailyReward(session),
        ),
        'getRewardHistory': _i1.MethodConnector(
          name: 'getRewardHistory',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .getRewardHistory(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'seedAchievements': _i1.MethodConnector(
          name: 'seedAchievements',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['gamification'] as _i6.GamificationEndpoint)
                  .seedAchievements(session),
        ),
      },
    );
    connectors['health'] = _i1.EndpointConnector(
      name: 'health',
      endpoint: endpoints['health']!,
      methodConnectors: {
        'check': _i1.MethodConnector(
          name: 'check',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i7.HealthEndpoint).check(session),
        ),
        'detailed': _i1.MethodConnector(
          name: 'detailed',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i7.HealthEndpoint).detailed(session),
        ),
        'ready': _i1.MethodConnector(
          name: 'ready',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i7.HealthEndpoint).ready(session),
        ),
        'live': _i1.MethodConnector(
          name: 'live',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i7.HealthEndpoint).live(session),
        ),
        'metrics': _i1.MethodConnector(
          name: 'metrics',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i7.HealthEndpoint).metrics(session),
        ),
      },
    );
    connectors['lounge'] = _i1.EndpointConnector(
      name: 'lounge',
      endpoint: endpoints['lounge']!,
      methodConnectors: {
        'createLounge': _i1.MethodConnector(
          name: 'createLounge',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'emoji': _i1.ParameterDescription(
              name: 'emoji',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isPublic': _i1.ParameterDescription(
              name: 'isPublic',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'maxMembers': _i1.ParameterDescription(
              name: 'maxMembers',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'interests': _i1.ParameterDescription(
              name: 'interests',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'languages': _i1.ParameterDescription(
              name: 'languages',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'rules': _i1.ParameterDescription(
              name: 'rules',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).createLounge(
                    session,
                    params['name'],
                    description: params['description'],
                    emoji: params['emoji'],
                    isPublic: params['isPublic'],
                    maxMembers: params['maxMembers'],
                    interests: params['interests'],
                    languages: params['languages'],
                    country: params['country'],
                    rules: params['rules'],
                  ),
        ),
        'listMyLounges': _i1.MethodConnector(
          name: 'listMyLounges',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).listMyLounges(
                    session,
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'getLounge': _i1.MethodConnector(
          name: 'getLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint).getLounge(
                session,
                params['loungeId'],
              ),
        ),
        'searchPublicLounges': _i1.MethodConnector(
          name: 'searchPublicLounges',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint)
                  .searchPublicLounges(
                    session,
                    params['query'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'applyToLounge': _i1.MethodConnector(
          name: 'applyToLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).applyToLounge(
                    session,
                    params['loungeId'],
                  ),
        ),
        'inviteUserToLounge': _i1.MethodConnector(
          name: 'inviteUserToLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserIdString': _i1.ParameterDescription(
              name: 'targetUserIdString',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint)
                  .inviteUserToLounge(
                    session,
                    params['loungeId'],
                    params['targetUserIdString'],
                  ),
        ),
        'respondToLoungeInvite': _i1.MethodConnector(
          name: 'respondToLoungeInvite',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'accept': _i1.ParameterDescription(
              name: 'accept',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint)
                  .respondToLoungeInvite(
                    session,
                    params['loungeId'],
                    params['accept'],
                  ),
        ),
        'approveLoungeApplication': _i1.MethodConnector(
          name: 'approveLoungeApplication',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserIdString': _i1.ParameterDescription(
              name: 'targetUserIdString',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'approve': _i1.ParameterDescription(
              name: 'approve',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint)
                  .approveLoungeApplication(
                    session,
                    params['loungeId'],
                    params['targetUserIdString'],
                    params['approve'],
                  ),
        ),
        'leaveLounge': _i1.MethodConnector(
          name: 'leaveLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).leaveLounge(
                    session,
                    params['loungeId'],
                  ),
        ),
        'toggleMuteLounge': _i1.MethodConnector(
          name: 'toggleMuteLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isMuted': _i1.ParameterDescription(
              name: 'isMuted',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).toggleMuteLounge(
                    session,
                    params['loungeId'],
                    params['isMuted'],
                  ),
        ),
        'getLoungeMembers': _i1.MethodConnector(
          name: 'getLoungeMembers',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).getLoungeMembers(
                    session,
                    params['loungeId'],
                  ),
        ),
        'getPendingApplications': _i1.MethodConnector(
          name: 'getPendingApplications',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint)
                  .getPendingApplications(
                    session,
                    params['loungeId'],
                  ),
        ),
        'updateLounge': _i1.MethodConnector(
          name: 'updateLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'emoji': _i1.ParameterDescription(
              name: 'emoji',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isPublic': _i1.ParameterDescription(
              name: 'isPublic',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'maxMembers': _i1.ParameterDescription(
              name: 'maxMembers',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'interests': _i1.ParameterDescription(
              name: 'interests',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'languages': _i1.ParameterDescription(
              name: 'languages',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'rules': _i1.ParameterDescription(
              name: 'rules',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).updateLounge(
                    session,
                    params['loungeId'],
                    name: params['name'],
                    description: params['description'],
                    emoji: params['emoji'],
                    isPublic: params['isPublic'],
                    maxMembers: params['maxMembers'],
                    interests: params['interests'],
                    languages: params['languages'],
                    country: params['country'],
                    rules: params['rules'],
                  ),
        ),
        'deleteLounge': _i1.MethodConnector(
          name: 'deleteLounge',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lounge'] as _i8.LoungeEndpoint).deleteLounge(
                    session,
                    params['loungeId'],
                  ),
        ),
        'kickMember': _i1.MethodConnector(
          name: 'kickMember',
          params: {
            'loungeId': _i1.ParameterDescription(
              name: 'loungeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint).kickMember(
                session,
                loungeId: params['loungeId'],
                targetUserId: params['targetUserId'],
              ),
        ),
      },
    );
    connectors['media'] = _i1.EndpointConnector(
      name: 'media',
      endpoint: endpoints['media']!,
      methodConnectors: {
        'getUploadDescription': _i1.MethodConnector(
          name: 'getUploadDescription',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileSize': _i1.ParameterDescription(
              name: 'fileSize',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['media'] as _i9.MediaEndpoint)
                  .getUploadDescription(
                    session,
                    params['path'],
                    params['fileSize'],
                  ),
        ),
        'verifyUpload': _i1.MethodConnector(
          name: 'verifyUpload',
          params: {
            'path': _i1.ParameterDescription(
              name: 'path',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['media'] as _i9.MediaEndpoint).verifyUpload(
                session,
                params['path'],
              ),
        ),
      },
    );
    connectors['message'] = _i1.EndpointConnector(
      name: 'message',
      endpoint: endpoints['message']!,
      methodConnectors: {
        'sendMessage': _i1.MethodConnector(
          name: 'sendMessage',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'content': _i1.ParameterDescription(
              name: 'content',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'imageUrl': _i1.ParameterDescription(
              name: 'imageUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'mediaUrl': _i1.ParameterDescription(
              name: 'mediaUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'mediaType': _i1.ParameterDescription(
              name: 'mediaType',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'duration': _i1.ParameterDescription(
              name: 'duration',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'fileSize': _i1.ParameterDescription(
              name: 'fileSize',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'isSystem': _i1.ParameterDescription(
              name: 'isSystem',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i10.MessageEndpoint).sendMessage(
                    session,
                    params['channelId'],
                    content: params['content'],
                    imageUrl: params['imageUrl'],
                    mediaUrl: params['mediaUrl'],
                    mediaType: params['mediaType'],
                    duration: params['duration'],
                    fileSize: params['fileSize'],
                    isSystem: params['isSystem'],
                  ),
        ),
        'listMessages': _i1.MethodConnector(
          name: 'listMessages',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i10.MessageEndpoint).listMessages(
                    session,
                    params['channelId'],
                    limit: params['limit'],
                    offset: params['offset'],
                  ),
        ),
        'markChannelAsRead': _i1.MethodConnector(
          name: 'markChannelAsRead',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['message'] as _i10.MessageEndpoint)
                  .markChannelAsRead(
                    session,
                    params['channelId'],
                  ),
        ),
        'sendTypingIndicator': _i1.MethodConnector(
          name: 'sendTypingIndicator',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isTyping': _i1.ParameterDescription(
              name: 'isTyping',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['message'] as _i10.MessageEndpoint)
                  .sendTypingIndicator(
                    session,
                    params['channelId'],
                    params['isTyping'],
                  ),
        ),
        'updateChannelPersistence': _i1.MethodConnector(
          name: 'updateChannelPersistence',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isPersistent': _i1.ParameterDescription(
              name: 'isPersistent',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['message'] as _i10.MessageEndpoint)
                  .updateChannelPersistence(
                    session,
                    params['channelId'],
                    params['isPersistent'],
                  ),
        ),
        'getPinnedMessage': _i1.MethodConnector(
          name: 'getPinnedMessage',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['message'] as _i10.MessageEndpoint)
                  .getPinnedMessage(
                    session,
                    params['channelId'],
                  ),
        ),
        'pinMessage': _i1.MethodConnector(
          name: 'pinMessage',
          params: {
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i10.MessageEndpoint).pinMessage(
                    session,
                    params['messageId'],
                  ),
        ),
        'unpinMessage': _i1.MethodConnector(
          name: 'unpinMessage',
          params: {
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i10.MessageEndpoint).unpinMessage(
                    session,
                    params['messageId'],
                  ),
        ),
        'recallMessage': _i1.MethodConnector(
          name: 'recallMessage',
          params: {
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i10.MessageEndpoint).recallMessage(
                    session,
                    params['messageId'],
                  ),
        ),
        'subscribe': _i1.MethodStreamConnector(
          name: 'subscribe',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['message'] as _i10.MessageEndpoint).subscribe(
                session,
                params['channelId'],
              ),
        ),
      },
    );
    connectors['moment'] = _i1.EndpointConnector(
      name: 'moment',
      endpoint: endpoints['moment']!,
      methodConnectors: {
        'postMoment': _i1.MethodConnector(
          name: 'postMoment',
          params: {
            'imageUrl': _i1.ParameterDescription(
              name: 'imageUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'caption': _i1.ParameterDescription(
              name: 'caption',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'fileSize': _i1.ParameterDescription(
              name: 'fileSize',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).postMoment(
                    session,
                    imageUrl: params['imageUrl'],
                    caption: params['caption'],
                    fileSize: params['fileSize'],
                  ),
        ),
        'listMoments': _i1.MethodConnector(
          name: 'listMoments',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'lastId': _i1.ParameterDescription(
              name: 'lastId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).listMoments(
                    session,
                    limit: params['limit'],
                    lastId: params['lastId'],
                  ),
        ),
        'listUserMoments': _i1.MethodConnector(
          name: 'listUserMoments',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'lastId': _i1.ParameterDescription(
              name: 'lastId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).listUserMoments(
                    session,
                    userId: params['userId'],
                    limit: params['limit'],
                    lastId: params['lastId'],
                  ),
        ),
        'likeMoment': _i1.MethodConnector(
          name: 'likeMoment',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).likeMoment(
                    session,
                    params['momentId'],
                  ),
        ),
        'unlikeMoment': _i1.MethodConnector(
          name: 'unlikeMoment',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).unlikeMoment(
                    session,
                    params['momentId'],
                  ),
        ),
        'getMomentLikes': _i1.MethodConnector(
          name: 'getMomentLikes',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).getMomentLikes(
                    session,
                    params['momentId'],
                  ),
        ),
        'hasLikedMoment': _i1.MethodConnector(
          name: 'hasLikedMoment',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).hasLikedMoment(
                    session,
                    params['momentId'],
                  ),
        ),
        'hasLikedMoments': _i1.MethodConnector(
          name: 'hasLikedMoments',
          params: {
            'momentIds': _i1.ParameterDescription(
              name: 'momentIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['moment'] as _i11.MomentEndpoint)
                  .hasLikedMoments(
                    session,
                    params['momentIds'],
                  )
                  .then(
                    (container) =>
                        _i19.Protocol().mapContainerToJson(container),
                  ),
        ),
        'addComment': _i1.MethodConnector(
          name: 'addComment',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'text': _i1.ParameterDescription(
              name: 'text',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).addComment(
                    session,
                    params['momentId'],
                    params['text'],
                  ),
        ),
        'getMomentComments': _i1.MethodConnector(
          name: 'getMomentComments',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['moment'] as _i11.MomentEndpoint)
                  .getMomentComments(
                    session,
                    params['momentId'],
                    limit: params['limit'],
                  ),
        ),
        'deleteComment': _i1.MethodConnector(
          name: 'deleteComment',
          params: {
            'commentId': _i1.ParameterDescription(
              name: 'commentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).deleteComment(
                    session,
                    params['commentId'],
                  ),
        ),
        'deleteMoment': _i1.MethodConnector(
          name: 'deleteMoment',
          params: {
            'momentId': _i1.ParameterDescription(
              name: 'momentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i11.MomentEndpoint).deleteMoment(
                    session,
                    params['momentId'],
                  ),
        ),
      },
    );
    connectors['notification'] = _i1.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'getUserNotifications': _i1.MethodConnector(
          name: 'getUserNotifications',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'unreadOnly': _i1.ParameterDescription(
              name: 'unreadOnly',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _i12.NotificationEndpoint)
                      .getUserNotifications(
                        session,
                        limit: params['limit'],
                        offset: params['offset'],
                        unreadOnly: params['unreadOnly'],
                      ),
        ),
        'markAsRead': _i1.MethodConnector(
          name: 'markAsRead',
          params: {
            'notificationIds': _i1.ParameterDescription(
              name: 'notificationIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _i12.NotificationEndpoint)
                      .markAsRead(
                        session,
                        params['notificationIds'],
                      ),
        ),
        'getUnreadCount': _i1.MethodConnector(
          name: 'getUnreadCount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _i12.NotificationEndpoint)
                      .getUnreadCount(session),
        ),
        'registerDeviceToken': _i1.MethodConnector(
          name: 'registerDeviceToken',
          params: {
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'platform': _i1.ParameterDescription(
              name: 'platform',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _i12.NotificationEndpoint)
                      .registerDeviceToken(
                        session,
                        params['token'],
                        params['platform'],
                      ),
        ),
        'unregisterDeviceToken': _i1.MethodConnector(
          name: 'unregisterDeviceToken',
          params: {
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _i12.NotificationEndpoint)
                      .unregisterDeviceToken(
                        session,
                        params['token'],
                      ),
        ),
      },
    );
    connectors['privateChat'] = _i1.EndpointConnector(
      name: 'privateChat',
      endpoint: endpoints['privateChat']!,
      methodConnectors: {
        'getOrCreatePrivateChat': _i1.MethodConnector(
          name: 'getOrCreatePrivateChat',
          params: {
            'otherUserId': _i1.ParameterDescription(
              name: 'otherUserId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'initialMessage': _i1.ParameterDescription(
              name: 'initialMessage',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['privateChat'] as _i13.PrivateChatEndpoint)
                  .getOrCreatePrivateChat(
                    session,
                    params['otherUserId'],
                    initialMessage: params['initialMessage'],
                  ),
        ),
        'listPrivateChats': _i1.MethodConnector(
          name: 'listPrivateChats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['privateChat'] as _i13.PrivateChatEndpoint)
                  .listPrivateChats(session),
        ),
        'getPrivateChatDetails': _i1.MethodConnector(
          name: 'getPrivateChatDetails',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['privateChat'] as _i13.PrivateChatEndpoint)
                  .getPrivateChatDetails(
                    session,
                    params['channelId'],
                  ),
        ),
        'respondToChatInvite': _i1.MethodConnector(
          name: 'respondToChatInvite',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'accept': _i1.ParameterDescription(
              name: 'accept',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['privateChat'] as _i13.PrivateChatEndpoint)
                  .respondToChatInvite(
                    session,
                    params['channelId'],
                    params['accept'],
                  ),
        ),
        'leaveChat': _i1.MethodConnector(
          name: 'leaveChat',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['privateChat'] as _i13.PrivateChatEndpoint)
                  .leaveChat(
                    session,
                    params['channelId'],
                  ),
        ),
      },
    );
    connectors['resident'] = _i1.EndpointConnector(
      name: 'resident',
      endpoint: endpoints['resident']!,
      methodConnectors: {
        'getResident': _i1.MethodConnector(
          name: 'getResident',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .getResident(session),
        ),
        'getResidentById': _i1.MethodConnector(
          name: 'getResidentById',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .getResidentById(
                    session,
                    params['userId'],
                  ),
        ),
        'initializeResident': _i1.MethodConnector(
          name: 'initializeResident',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'avatar': _i1.ParameterDescription(
              name: 'avatar',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bio': _i1.ParameterDescription(
              name: 'bio',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'ageRange': _i1.ParameterDescription(
              name: 'ageRange',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'interests': _i1.ParameterDescription(
              name: 'interests',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'languages': _i1.ParameterDescription(
              name: 'languages',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'mood': _i1.ParameterDescription(
              name: 'mood',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'customAvatarUrl': _i1.ParameterDescription(
              name: 'customAvatarUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .initializeResident(
                    session,
                    name: params['name'],
                    avatar: params['avatar'],
                    gender: params['gender'],
                    country: params['country'],
                    bio: params['bio'],
                    ageRange: params['ageRange'],
                    interests: params['interests'],
                    languages: params['languages'],
                    mood: params['mood'],
                    customAvatarUrl: params['customAvatarUrl'],
                  ),
        ),
        'updateResident': _i1.MethodConnector(
          name: 'updateResident',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'avatar': _i1.ParameterDescription(
              name: 'avatar',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bio': _i1.ParameterDescription(
              name: 'bio',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'ageRange': _i1.ParameterDescription(
              name: 'ageRange',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'interests': _i1.ParameterDescription(
              name: 'interests',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'languages': _i1.ParameterDescription(
              name: 'languages',
              type: _i1.getType<List<String>?>(),
              nullable: true,
            ),
            'mood': _i1.ParameterDescription(
              name: 'mood',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'customAvatarUrl': _i1.ParameterDescription(
              name: 'customAvatarUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .updateResident(
                    session,
                    name: params['name'],
                    avatar: params['avatar'],
                    gender: params['gender'],
                    country: params['country'],
                    bio: params['bio'],
                    ageRange: params['ageRange'],
                    interests: params['interests'],
                    languages: params['languages'],
                    mood: params['mood'],
                    customAvatarUrl: params['customAvatarUrl'],
                  ),
        ),
        'updateCustomAvatar': _i1.MethodConnector(
          name: 'updateCustomAvatar',
          params: {
            'customAvatarUrl': _i1.ParameterDescription(
              name: 'customAvatarUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'avatarSize': _i1.ParameterDescription(
              name: 'avatarSize',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .updateCustomAvatar(
                    session,
                    params['customAvatarUrl'],
                    avatarSize: params['avatarSize'],
                  ),
        ),
        'getUserProfile': _i1.MethodConnector(
          name: 'getUserProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .getUserProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updatePrivacy': _i1.MethodConnector(
          name: 'updatePrivacy',
          params: {
            'hideAds': _i1.ParameterDescription(
              name: 'hideAds',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showVoiceMessages': _i1.ParameterDescription(
              name: 'showVoiceMessages',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showAdvancedDiscovery': _i1.ParameterDescription(
              name: 'showAdvancedDiscovery',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showCustomAvatar': _i1.ParameterDescription(
              name: 'showCustomAvatar',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showOthersOnlineStatus': _i1.ParameterDescription(
              name: 'showOthersOnlineStatus',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showOthersReadReceipts': _i1.ParameterDescription(
              name: 'showOthersReadReceipts',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'showOthersTypingIndicators': _i1.ParameterDescription(
              name: 'showOthersTypingIndicators',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'keepPrivateChats': _i1.ParameterDescription(
              name: 'keepPrivateChats',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .updatePrivacy(
                    session,
                    hideAds: params['hideAds'],
                    showVoiceMessages: params['showVoiceMessages'],
                    showAdvancedDiscovery: params['showAdvancedDiscovery'],
                    showCustomAvatar: params['showCustomAvatar'],
                    showOthersOnlineStatus: params['showOthersOnlineStatus'],
                    showOthersReadReceipts: params['showOthersReadReceipts'],
                    showOthersTypingIndicators:
                        params['showOthersTypingIndicators'],
                    keepPrivateChats: params['keepPrivateChats'],
                  ),
        ),
        'setPremiumStatus': _i1.MethodConnector(
          name: 'setPremiumStatus',
          params: {
            'isPremium': _i1.ParameterDescription(
              name: 'isPremium',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .setPremiumStatus(
                    session,
                    isPremium: params['isPremium'],
                  ),
        ),
        'startPremiumTrial': _i1.MethodConnector(
          name: 'startPremiumTrial',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .startPremiumTrial(session),
        ),
      },
    );
    connectors['search'] = _i1.EndpointConnector(
      name: 'search',
      endpoint: endpoints['search']!,
      methodConnectors: {
        'searchUsers': _i1.MethodConnector(
          name: 'searchUsers',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'interest': _i1.ParameterDescription(
              name: 'interest',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'ageRange': _i1.ParameterDescription(
              name: 'ageRange',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isPremium': _i1.ParameterDescription(
              name: 'isPremium',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).searchUsers(
                    session,
                    params['query'],
                    gender: params['gender'],
                    country: params['country'],
                    language: params['language'],
                    interest: params['interest'],
                    ageRange: params['ageRange'],
                    isPremium: params['isPremium'],
                    limit: params['limit'],
                  ),
        ),
        'searchLounges': _i1.MethodConnector(
          name: 'searchLounges',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'interest': _i1.ParameterDescription(
              name: 'interest',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).searchLounges(
                    session,
                    params['query'],
                    interest: params['interest'],
                    language: params['language'],
                    country: params['country'],
                    limit: params['limit'],
                  ),
        ),
        'getDiscoveryFeed': _i1.MethodConnector(
          name: 'getDiscoveryFeed',
          params: {
            'interest': _i1.ParameterDescription(
              name: 'interest',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).getDiscoveryFeed(
                    session,
                    interest: params['interest'],
                    language: params['language'],
                    country: params['country'],
                    limit: params['limit'],
                  ),
        ),
        'searchAll': _i1.MethodConnector(
          name: 'searchAll',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['search'] as _i15.SearchEndpoint).searchAll(
                session,
                params['query'],
                limit: params['limit'],
              ),
        ),
        'getTrendingMoments': _i1.MethodConnector(
          name: 'getTrendingMoments',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['search'] as _i15.SearchEndpoint)
                  .getTrendingMoments(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'getPopularLounges': _i1.MethodConnector(
          name: 'getPopularLounges',
          params: {
            'interest': _i1.ParameterDescription(
              name: 'interest',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['search'] as _i15.SearchEndpoint)
                  .getPopularLounges(
                    session,
                    interest: params['interest'],
                    language: params['language'],
                    country: params['country'],
                    limit: params['limit'],
                  ),
        ),
        'getActiveUsers': _i1.MethodConnector(
          name: 'getActiveUsers',
          params: {
            'gender': _i1.ParameterDescription(
              name: 'gender',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'country': _i1.ParameterDescription(
              name: 'country',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'interest': _i1.ParameterDescription(
              name: 'interest',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'ageRange': _i1.ParameterDescription(
              name: 'ageRange',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isPremium': _i1.ParameterDescription(
              name: 'isPremium',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).getActiveUsers(
                    session,
                    gender: params['gender'],
                    country: params['country'],
                    language: params['language'],
                    interest: params['interest'],
                    ageRange: params['ageRange'],
                    isPremium: params['isPremium'],
                    limit: params['limit'],
                  ),
        ),
      },
    );
    connectors['social'] = _i1.EndpointConnector(
      name: 'social',
      endpoint: endpoints['social']!,
      methodConnectors: {
        'likeUser': _i1.MethodConnector(
          name: 'likeUser',
          params: {
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['social'] as _i16.SocialEndpoint).likeUser(
                session,
                params['targetUserId'],
              ),
        ),
        'unlikeUser': _i1.MethodConnector(
          name: 'unlikeUser',
          params: {
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['social'] as _i16.SocialEndpoint).unlikeUser(
                    session,
                    params['targetUserId'],
                  ),
        ),
        'getMyLikedUserIds': _i1.MethodConnector(
          name: 'getMyLikedUserIds',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['social'] as _i16.SocialEndpoint)
                  .getMyLikedUserIds(session),
        ),
        'blockUser': _i1.MethodConnector(
          name: 'blockUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['social'] as _i16.SocialEndpoint).blockUser(
                session,
                params['userId'],
              ),
        ),
        'unblockUser': _i1.MethodConnector(
          name: 'unblockUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['social'] as _i16.SocialEndpoint).unblockUser(
                    session,
                    params['userId'],
                  ),
        ),
        'isUserBlocked': _i1.MethodConnector(
          name: 'isUserBlocked',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['social'] as _i16.SocialEndpoint).isUserBlocked(
                    session,
                    params['userId'],
                  ),
        ),
        'getBlockedUserIds': _i1.MethodConnector(
          name: 'getBlockedUserIds',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['social'] as _i16.SocialEndpoint)
                  .getBlockedUserIds(session),
        ),
        'reportUser': _i1.MethodConnector(
          name: 'reportUser',
          params: {
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['social'] as _i16.SocialEndpoint).reportUser(
                    session,
                    targetUserId: params['targetUserId'],
                    reason: params['reason'],
                    channelId: params['channelId'],
                    messageId: params['messageId'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i17.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i20.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i21.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth'] = _i22.Endpoints()..initializeEndpoints(server);
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i23.FutureCalls();
  }
}
