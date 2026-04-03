import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    hide Endpoints, Protocol;
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/firebase.dart';
import 'package:serverpod_cloud_storage_r2/serverpod_cloud_storage_r2.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';
import 'src/future_calls/daily_cleanup.dart';
import 'src/future_calls/credit_restoration.dart';
import 'src/services/fcm_service.dart';
import 'src/services/emulator_auth_service.dart';
import 'src/utils/seed_data.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Register Cloud Storage
  // Only register Cloudflare R2 in production/staging environments
  if (pod.runMode != 'development') {
    final accountId = Platform.environment['CLOUDFLARE_ACCOUNT_ID'] ?? '<ACCOUNT_ID>';
    final publicHost = Platform.environment['CLOUDFLARE_PUBLIC_HOST'] ?? 'media.talktive.app';
    
    pod.addCloudStorage(R2CloudStorage(
      serverpod: pod,
      storageId: 'public',
      public: true,
      bucket: 'talktive-media',
      accountId: accountId,
      publicHost: publicHost,
    ));
  }

  // Register Future Calls
  pod.registerFutureCall(DailyCleanupCall(), 'dailyCleanup');
  pod.registerFutureCall(CreditRestorationCall(), 'creditRestoration');

  // Initialize authentication services for the server.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      ServerSideSessionsConfigFromPasswords(),
      JwtConfigFromPasswords(
        issuer: 'talktive',
      ),
    ],
    identityProviderBuilders: [
      pod.runMode == 'development'
          ? EmulatorFirebaseIdpConfig(
              credentials: FirebaseServiceAccountCredentials.fromJson(
                jsonDecode(
                  File(
                    'config/firebase_service_account_key.json',
                  ).readAsStringSync(),
                ),
              ),
            )
          : FirebaseIdpConfig(
              credentials: FirebaseServiceAccountCredentials.fromJson(
                jsonDecode(
                  File(
                    'config/firebase_service_account_key.json',
                  ).readAsStringSync(),
                ),
              ),
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
    // Seed Achievements
    await SeedData.seedAchievements(session);

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

  // Initialize FCM for push notifications
  await FCMService.initialize();

  // Schedule first cleanup call for 3 AM Eastern (07:00 UTC).
  // The DailyCleanupCall will reschedule itself every 24 hours at the target time.
  // We use try/catch to ensure server starts even if scheduling fails.
  // Start the server.
  await pod.start();

  // Schedule first cleanup call for 5 AM Eastern (09:00 UTC).
  // The DailyCleanupCall will reschedule itself every 24 hours at the target time.
  // We use try/catch to ensure server continues even if scheduling fails.
  try {
    await pod.futureCalls
        .callAtTime(DailyCleanupCall.getNextCleanupTime())
        .dailyCleanupCall
        .invoke(null);
  } catch (e) {
    stdout.writeln(
      'Notification: Daily cleanup already scheduled or failed to schedule: $e',
    );
  }
}
