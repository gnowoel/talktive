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
import '../endpoints/message_endpoint.dart' as _i9;
import '../endpoints/moment_endpoint.dart' as _i10;
import '../endpoints/notification_endpoint.dart' as _i11;
import '../endpoints/private_chat_endpoint.dart' as _i12;
import '../endpoints/report_endpoint.dart' as _i13;
import '../endpoints/resident_endpoint.dart' as _i14;
import '../endpoints/search_endpoint.dart' as _i15;
import '../greetings/greeting_endpoint.dart' as _i16;
import 'package:talktive_server/src/generated/report_status.dart' as _i17;
import 'package:talktive_server/src/generated/protocol.dart' as _i18;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i19;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i20;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i21;

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
      'message': _i9.MessageEndpoint()
        ..initialize(
          server,
          'message',
          null,
        ),
      'moment': _i10.MomentEndpoint()
        ..initialize(
          server,
          'moment',
          null,
        ),
      'notification': _i11.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'privateChat': _i12.PrivateChatEndpoint()
        ..initialize(
          server,
          'privateChat',
          null,
        ),
      'report': _i13.ReportEndpoint()
        ..initialize(
          server,
          'report',
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
      'greeting': _i16.GreetingEndpoint()
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
        'isAdmin': _i1.MethodConnector(
          name: 'isAdmin',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).isAdmin(session),
        ),
        'isModerator': _i1.MethodConnector(
          name: 'isModerator',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).isModerator(
                session,
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
        'getAllReports': _i1.MethodConnector(
          name: 'getAllReports',
          params: {
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<_i17.ReportStatus?>(),
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
              type: _i1.getType<_i17.ReportStatus>(),
              nullable: false,
            ),
            'adminNotes': _i1.ParameterDescription(
              name: 'adminNotes',
              type: _i1.getType<String?>(),
              nullable: true,
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
                    adminNotes: params['adminNotes'],
                  ),
        ),
        'suspendUser': _i1.MethodConnector(
          name: 'suspendUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
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
              type: _i1.getType<String>(),
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
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'durationHours': _i1.ParameterDescription(
              name: 'durationHours',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).muteUser(
                session,
                userId: params['userId'],
                durationHours: params['durationHours'],
                reason: params['reason'],
              ),
        ),
        'unmuteUser': _i1.MethodConnector(
          name: 'unmuteUser',
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
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).unmuteUser(
                session,
                params['userId'],
              ),
        ),
        'resetReputation': _i1.MethodConnector(
          name: 'resetReputation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
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
        'deleteMessage': _i1.MethodConnector(
          name: 'deleteMessage',
          params: {
            'messageId': _i1.ParameterDescription(
              name: 'messageId',
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
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteMessage(
                    session,
                    messageId: params['messageId'],
                    reason: params['reason'],
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
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).deleteMoment(
                session,
                momentId: params['momentId'],
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
              type: _i1.getType<String>(),
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
        'promoteToModerator': _i1.MethodConnector(
          name: 'promoteToModerator',
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
              type: _i1.getType<String>(),
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
        'demoteFromAdmin': _i1.MethodConnector(
          name: 'demoteFromAdmin',
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
                  (endpoints['admin'] as _i5.AdminEndpoint).demoteFromAdmin(
                    session,
                    userId: params['userId'],
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
              type: _i1.getType<String>(),
              nullable: false,
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
        'getUserDetails': _i1.MethodConnector(
          name: 'getUserDetails',
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
                  (endpoints['admin'] as _i5.AdminEndpoint).getUserDetails(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'runArchival': _i1.MethodConnector(
          name: 'runArchival',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).runArchival(
                session,
              ),
        ),
        'getArchivalStats': _i1.MethodConnector(
          name: 'getArchivalStats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getArchivalStats(session),
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
        'kickMember': _i1.MethodConnector(
          name: 'kickMember',
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
              ) async => (endpoints['lounge'] as _i8.LoungeEndpoint).kickMember(
                session,
                params['loungeId'],
                params['targetUserIdString'],
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
        'getLoungeMembersWithProfiles': _i1.MethodConnector(
          name: 'getLoungeMembersWithProfiles',
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
                  .getLoungeMembersWithProfiles(
                    session,
                    params['loungeId'],
                  ),
        ),
        'getPendingApplicationsWithProfiles': _i1.MethodConnector(
          name: 'getPendingApplicationsWithProfiles',
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
                  .getPendingApplicationsWithProfiles(
                    session,
                    params['loungeId'],
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
                  (endpoints['message'] as _i9.MessageEndpoint).sendMessage(
                    session,
                    params['channelId'],
                    content: params['content'],
                    imageUrl: params['imageUrl'],
                    mediaUrl: params['mediaUrl'],
                    mediaType: params['mediaType'],
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
                  (endpoints['message'] as _i9.MessageEndpoint).listMessages(
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
              ) async => (endpoints['message'] as _i9.MessageEndpoint)
                  .markChannelAsRead(
                    session,
                    params['channelId'],
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
              ) => (endpoints['message'] as _i9.MessageEndpoint).subscribe(
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
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moment'] as _i10.MomentEndpoint).postMoment(
                    session,
                    imageUrl: params['imageUrl'],
                    caption: params['caption'],
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
                  (endpoints['moment'] as _i10.MomentEndpoint).listMoments(
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
                  (endpoints['moment'] as _i10.MomentEndpoint).listUserMoments(
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
                  (endpoints['moment'] as _i10.MomentEndpoint).likeMoment(
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
                  (endpoints['moment'] as _i10.MomentEndpoint).unlikeMoment(
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
                  (endpoints['moment'] as _i10.MomentEndpoint).getMomentLikes(
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
                  (endpoints['moment'] as _i10.MomentEndpoint).hasLikedMoment(
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
              ) async => (endpoints['moment'] as _i10.MomentEndpoint)
                  .hasLikedMoments(
                    session,
                    params['momentIds'],
                  )
                  .then(
                    (container) =>
                        _i18.Protocol().mapContainerToJson(container),
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
                  (endpoints['moment'] as _i10.MomentEndpoint).addComment(
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
              ) async => (endpoints['moment'] as _i10.MomentEndpoint)
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
                  (endpoints['moment'] as _i10.MomentEndpoint).deleteComment(
                    session,
                    params['commentId'],
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
                  (endpoints['notification'] as _i11.NotificationEndpoint)
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
                  (endpoints['notification'] as _i11.NotificationEndpoint)
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
                  (endpoints['notification'] as _i11.NotificationEndpoint)
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
                  (endpoints['notification'] as _i11.NotificationEndpoint)
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
                  (endpoints['notification'] as _i11.NotificationEndpoint)
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
              ) async => (endpoints['privateChat'] as _i12.PrivateChatEndpoint)
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
              ) async => (endpoints['privateChat'] as _i12.PrivateChatEndpoint)
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
              ) async => (endpoints['privateChat'] as _i12.PrivateChatEndpoint)
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
              ) async => (endpoints['privateChat'] as _i12.PrivateChatEndpoint)
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
              ) async => (endpoints['privateChat'] as _i12.PrivateChatEndpoint)
                  .leaveChat(
                    session,
                    params['channelId'],
                  ),
        ),
      },
    );
    connectors['report'] = _i1.EndpointConnector(
      name: 'report',
      endpoint: endpoints['report']!,
      methodConnectors: {
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
                  (endpoints['report'] as _i13.ReportEndpoint).reportUser(
                    session,
                    targetUserId: params['targetUserId'],
                    reason: params['reason'],
                    channelId: params['channelId'],
                    messageId: params['messageId'],
                  ),
        ),
        'getReportCount': _i1.MethodConnector(
          name: 'getReportCount',
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
                  (endpoints['report'] as _i13.ReportEndpoint).getReportCount(
                    session,
                    params['userId'],
                  ),
        ),
        'listReports': _i1.MethodConnector(
          name: 'listReports',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'onlyUnresolved': _i1.ParameterDescription(
              name: 'onlyUnresolved',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['report'] as _i13.ReportEndpoint).listReports(
                    session,
                    limit: params['limit'],
                    onlyUnresolved: params['onlyUnresolved'],
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
            'approved': _i1.ParameterDescription(
              name: 'approved',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['report'] as _i13.ReportEndpoint).resolveReport(
                    session,
                    params['reportId'],
                    params['approved'],
                  ),
        ),
        'getReportDetails': _i1.MethodConnector(
          name: 'getReportDetails',
          params: {
            'reportId': _i1.ParameterDescription(
              name: 'reportId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['report'] as _i13.ReportEndpoint).getReportDetails(
                    session,
                    params['reportId'],
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
              type: _i1.getType<String>(),
              nullable: false,
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
                    interests: params['interests'],
                    languages: params['languages'],
                    mood: params['mood'],
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
                    interests: params['interests'],
                    languages: params['languages'],
                    mood: params['mood'],
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
              ) async =>
                  (endpoints['resident'] as _i14.ResidentEndpoint).likeUser(
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
                  (endpoints['resident'] as _i14.ResidentEndpoint).unlikeUser(
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
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
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
              ) async =>
                  (endpoints['resident'] as _i14.ResidentEndpoint).blockUser(
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
                  (endpoints['resident'] as _i14.ResidentEndpoint).unblockUser(
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
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .isUserBlocked(
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
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .getBlockedUserIds(session),
        ),
        'updateOnlineSettings': _i1.MethodConnector(
          name: 'updateOnlineSettings',
          params: {
            'showOnlineStatus': _i1.ParameterDescription(
              name: 'showOnlineStatus',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .updateOnlineSettings(
                    session,
                    showOnlineStatus: params['showOnlineStatus'],
                  ),
        ),
        'purchasePremium': _i1.MethodConnector(
          name: 'purchasePremium',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i14.ResidentEndpoint)
                  .purchasePremium(session),
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
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).searchUsers(
                    session,
                    params['query'],
                    limit: params['limit'],
                  ),
        ),
        'searchLounges': _i1.MethodConnector(
          name: 'searchLounges',
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
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).searchLounges(
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
                    limit: params['limit'],
                  ),
        ),
        'getActiveUsers': _i1.MethodConnector(
          name: 'getActiveUsers',
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
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).getActiveUsers(
                    session,
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
        'discoverUsersByInterests': _i1.MethodConnector(
          name: 'discoverUsersByInterests',
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
                  .discoverUsersByInterests(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'discoverUsersByLanguages': _i1.MethodConnector(
          name: 'discoverUsersByLanguages',
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
                  .discoverUsersByLanguages(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'getDiscoveryFeed': _i1.MethodConnector(
          name: 'getDiscoveryFeed',
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
              ) async =>
                  (endpoints['search'] as _i15.SearchEndpoint).getDiscoveryFeed(
                    session,
                    limit: params['limit'],
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
              ) async => (endpoints['greeting'] as _i16.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i19.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i20.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth'] = _i21.Endpoints()..initializeEndpoints(server);
  }
}
