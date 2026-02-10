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
import '../endpoints/image_endpoint.dart' as _i5;
import '../endpoints/message_endpoint.dart' as _i6;
import '../endpoints/moment_endpoint.dart' as _i7;
import '../endpoints/report_endpoint.dart' as _i8;
import '../endpoints/resident_endpoint.dart' as _i9;
import '../greetings/greeting_endpoint.dart' as _i10;
import 'dart:typed_data' as _i11;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i12;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i13;

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
      'image': _i5.ImageEndpoint()
        ..initialize(
          server,
          'image',
          null,
        ),
      'message': _i6.MessageEndpoint()
        ..initialize(
          server,
          'message',
          null,
        ),
      'moment': _i7.MomentEndpoint()
        ..initialize(
          server,
          'moment',
          null,
        ),
      'report': _i8.ReportEndpoint()
        ..initialize(
          server,
          'report',
          null,
        ),
      'resident': _i9.ResidentEndpoint()
        ..initialize(
          server,
          'resident',
          null,
        ),
      'greeting': _i10.GreetingEndpoint()
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
    connectors['image'] = _i1.EndpointConnector(
      name: 'image',
      endpoint: endpoints['image']!,
      methodConnectors: {
        'uploadImage': _i1.MethodConnector(
          name: 'uploadImage',
          params: {
            'imageData': _i1.ParameterDescription(
              name: 'imageData',
              type: _i1.getType<_i11.ByteData>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['image'] as _i5.ImageEndpoint).uploadImage(
                session,
                params['imageData'],
                params['fileName'],
              ),
        ),
        'deleteImage': _i1.MethodConnector(
          name: 'deleteImage',
          params: {
            'imageUrl': _i1.ParameterDescription(
              name: 'imageUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['image'] as _i5.ImageEndpoint).deleteImage(
                session,
                params['imageUrl'],
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
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'imageUrl': _i1.ParameterDescription(
              name: 'imageUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['message'] as _i6.MessageEndpoint).sendMessage(
                    session,
                    params['channelId'],
                    params['content'],
                    imageUrl: params['imageUrl'],
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
                  (endpoints['message'] as _i6.MessageEndpoint).listMessages(
                    session,
                    params['channelId'],
                    limit: params['limit'],
                    offset: params['offset'],
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
              ) => (endpoints['message'] as _i6.MessageEndpoint).subscribe(
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
              ) async => (endpoints['moment'] as _i7.MomentEndpoint).postMoment(
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
                  (endpoints['moment'] as _i7.MomentEndpoint).listMoments(
                    session,
                    limit: params['limit'],
                    lastId: params['lastId'],
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
              ) async => (endpoints['report'] as _i8.ReportEndpoint).reportUser(
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
                  (endpoints['report'] as _i8.ReportEndpoint).getReportCount(
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
                  (endpoints['report'] as _i8.ReportEndpoint).listReports(
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
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['report'] as _i8.ReportEndpoint).resolveReport(
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
              ) async => (endpoints['resident'] as _i9.ResidentEndpoint)
                  .getResident(session),
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
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['resident'] as _i9.ResidentEndpoint)
                  .initializeResident(
                    session,
                    name: params['name'],
                    avatar: params['avatar'],
                    gender: params['gender'],
                    country: params['country'],
                    bio: params['bio'],
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
              ) async => (endpoints['greeting'] as _i10.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i12.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i13.Endpoints()
      ..initializeEndpoints(server);
  }
}
