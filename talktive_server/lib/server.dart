import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart'
    hide Protocol, Endpoints, GoogleClientSecret;
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:serverpod_auth_idp_server/providers/apple.dart';
import 'src/services/auth_hooks.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';
import 'src/future_calls/message_cleanup.dart';
import 'src/future_calls/credit_restoration.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Register Future Calls
  pod.registerFutureCall(MessageCleanupCall(), 'messageCleanup');
  pod.registerFutureCall(CreditRestorationCall(), 'creditRestoration');

  // Configure Auth Hooks
  AuthConfig.set(
    AuthConfig(
      onUserCreated: AuthHooks.onUserCreated,
    ),
  );

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
      ),
      // Google Sign In
      // Google Sign In
      GoogleIdpConfig(
        clientSecret: GoogleClientSecret.fromJson(
          jsonDecode(
            File('config/google_client_secret.json').readAsStringSync(),
          ),
        ),
      ),
      // Apple Sign In
      AppleIdpConfig(
        serviceIdentifier: 'TODO_APPLE_SERVICE_ID',
        bundleIdentifier: 'com.talktive.app', // Replace with valid bundle ID
        redirectUri:
            'https://example.com/signin-apple', // Replace with valid URI
        keyId: 'TODO_APPLE_KEY_ID',
        teamId:
            'TODO_APPLE_TEAM_ID', // Reused for key? AppleIdp usually takes teamId separately if needed, check params
        // AppleIdpConfig in 3.2.3 usually takes:
        // bundleIdentifier, serviceIdentifier, redirectUri, keyId, teamId, privateKeyPath, specific args?
        // Let's rely on error message: "key is required", "redirectUri required", "serviceIdentifier required", "bundleIdentifier required".
        // privateKeyPath is likely 'key' param name? Or content?
        // Let's guess 'key' is the private key string or path?
        // Error said "key is required".
        // I will use `key` instead of `privateKeyPath`.
        key: 'TODO_APPLE_PRIVATE_KEY_CONTENT_OR_PATH',
      ),
    ],
  );

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Seed Data
  final session = await pod.createSession(enableLogging: true);
  try {
    final plaza = await Channel.db.findById(session, 1);
    if (plaza == null) {
      session.log('Seeding: Creating Plaza Channel (ID 1)');
      // Insert with explicit ID if possible, or just insert and hope it gets ID 1.
      // Postgres serials usually start at 1. If empty, it will be 1.
      // To be safe, we can try to force it if the framework allows, or just insert.
      await Channel.db.insertRow(
        session,
        Channel(
          type: ChannelType.plaza,
          createdAt: DateTime.now(),
        ),
      );
    }
  } catch (e) {
    session.log('Seeding Error: $e', level: LogLevel.error);
  } finally {
    await session.close();
  }

  // Start the server.
  await pod.start();
}

void _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // NOTE: Here you call your mail service to send the verification code to
  // the user. For testing, we will just log the verification code.
  session.log('[EmailIdp] Registration code ($email): $verificationCode');
}

void _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // NOTE: Here you call your mail service to send the verification code to
  // the user. For testing, we will just log the verification code.
  session.log('[EmailIdp] Password reset code ($email): $verificationCode');
}
