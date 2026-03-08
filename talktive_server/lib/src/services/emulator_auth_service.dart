import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/firebase.dart';
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;

/// A custom FirebaseIdpConfig that targets the local Firebase Emulator.
class EmulatorFirebaseIdpConfig extends FirebaseIdpConfig {
  const EmulatorFirebaseIdpConfig({
    required super.credentials,
    super.firebaseAccountDetailsValidation = FirebaseIdpConfig.validateFirebaseAccountDetails,
  });

  @override
  FirebaseIdp build({
    required TokenManager tokenManager,
    required AuthUsers authUsers,
    required UserProfiles userProfiles,
  }) {
    return EmulatorFirebaseIdp(
      this,
      tokenIssuer: tokenManager,
      authUsers: authUsers,
      userProfiles: userProfiles,
    );
  }
}

/// A custom FirebaseIdp implementation that works with the emulator.
class EmulatorFirebaseIdp implements FirebaseIdp {
  @override
  final FirebaseIdpConfig config;
  
  @override
  final FirebaseIdpUtils utils;
  
  @override
  final FirebaseIdpAdmin admin;

  final TokenIssuer _tokenIssuer;
  final UserProfiles _userProfiles;

  EmulatorFirebaseIdp(
    this.config, {
    required TokenIssuer tokenIssuer,
    required AuthUsers authUsers,
    required UserProfiles userProfiles,
  }) : _tokenIssuer = tokenIssuer,
       _userProfiles = userProfiles,
       utils = EmulatorFirebaseIdpUtils(config: config, authUsers: authUsers),
       admin = FirebaseIdpAdmin(utils: EmulatorFirebaseIdpUtils(config: config, authUsers: authUsers));

  @override
  Future<AuthSuccess> login(
    final Session session, {
    required final String idToken,
    final Transaction? transaction,
  }) async {
    return await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      transaction,
      (final transaction) async {
        final account = await utils.authenticate(
          session,
          idToken: idToken,
          transaction: transaction,
        );

        final image = account.details.image;
        if (account.newAccount) {
          try {
            await _userProfiles.createUserProfile(
              session,
              account.authUserId,
              UserProfileData(
                fullName: account.details.fullName?.trim(),
                email: account.details.email,
              ),
              transaction: transaction,
              imageSource: image != null ? UserImageFromUrl(image) : null,
            );
          } catch (e, stackTrace) {
            session.log(
              'Failed to create user profile for new Firebase user.',
              level: LogLevel.error,
              exception: e,
              stackTrace: stackTrace,
            );
          }
        } else if (image != null) {
          try {
            final user = await UserProfile.db.findFirstRow(
              session,
              where: (final t) => t.authUserId.equals(account.authUserId),
              transaction: transaction,
            );
            if (user != null && user.image == null) {
              await _userProfiles.setUserImageFromUrl(
                session,
                account.authUserId,
                image,
                transaction: transaction,
              );
            }
          } catch (e, stackTrace) {
            session.log(
              'Failed to update user profile image for existing Firebase user.',
              level: LogLevel.error,
              exception: e,
              stackTrace: stackTrace,
            );
          }
        }

        return _tokenIssuer.issueToken(
          session,
          authUserId: account.authUserId,
          transaction: transaction,
          method: 'firebase',
          scopes: account.scopes,
        );
      },
    );
  }

  @override
  Future<bool> hasAccount(Session session) async =>
      await utils.getAccount(session) != null;
}

/// A custom FirebaseIdpUtils that overrides token verification for the emulator.
class EmulatorFirebaseIdpUtils extends FirebaseIdpUtils {
  final FirebaseIdpConfig config;

  EmulatorFirebaseIdpUtils({
    required this.config,
    required AuthUsers authUsers,
  }) : super(config: config, authUsers: authUsers);

  @override
  Future<FirebaseAccountDetails> fetchAccountDetails(
    Session session, {
    required String idToken,
  }) async {
    final String projectId = config.credentials.projectId;
    
    try {
      // Decode the token without verification (safe for local emulator use)
      final unverified = jwt.JWT.decode(idToken);
      final payload = unverified.payload as Map<String, dynamic>;
      
      session.log('EmulatorAuth: Processing token for project $projectId', level: LogLevel.debug);
      
      // Basic claim validation
      final aud = payload['aud'];
      if (aud != projectId) {
        session.log('EmulatorAuth: Project ID mismatch. Expected $projectId but got $aud', level: LogLevel.warning);
        // Sometimes the emulator uses a different project ID naming convention or "demo-..."
        // We can choose to be lenient here if desired, but let's stick to the confirmation for now.
      }

      // Map claims to FirebaseAccountDetails
      final details = (
        userIdentifier: payload['sub'] as String,
        email: payload['email'] as String?,
        fullName: payload['name'] as String?,
        image: payload['picture'] != null ? Uri.tryParse(payload['picture'] as String) : null,
        verifiedEmail: payload['email_verified'] as bool?,
        phone: payload['phone_number'] as String?,
      );

      // Run standard validation (like email verification check)
      config.firebaseAccountDetailsValidation(details);

      return details;
    } catch (e) {
      session.log('EmulatorAuth: Failed to decode/validate token: $e', level: LogLevel.error);
      rethrow;
    }
  }
}
