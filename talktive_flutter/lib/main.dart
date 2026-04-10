import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;

import 'firebase_options.dart';
import 'config/app_config.dart';
import 'config/auth_config.dart';

import 'serverpod_client.dart';
import 'services/edge_to_edge_manager.dart';
import 'services/background_messaging_handler.dart';
import 'services/voice_service.dart';
import 'version_selector.dart';
import 'screens/maintenance_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugRepaintRainbowEnabled = false;

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Pre-initialize SharedPreferences to ensure plugin is registered early
  // and available when needed in Initialize wrapper.
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Warning: SharedPreferences pre-initialization failed: $e');
  }

  // Initialize Edge-to-Edge display
  try {
    await EdgeToEdgeManager.initialize();
  } catch (e) {
    debugPrint('Main: EdgeToEdge initialization failed: $e');
  }

  // Initialize VoiceService for audio focus and proximity events
  try {
    await VoiceService.init();
  } catch (e) {
    debugPrint('Main: VoiceService initialization failed: $e');
  }

  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb ? AuthConfig.webClientId : null,
    serverClientId: kIsWeb ? null : AuthConfig.webClientId,
  );

  try {
    await AppConfig.initialize();
  } catch (e) {
    debugPrint('Main: AppConfig initialization failed: $e');
    runApp(const _MaintenanceApp());
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
    // Android can arrive here if the default app was initialized natively.
    Firebase.app();
  }

  // Initialize Firebase Emulators if configured
  if (kDebugMode && AppConfig.instance.useFirebaseEmulators) {
    final host = AppConfig.instance.firebaseEmulatorHost;
    debugPrint('Main: Using Firebase Emulators at $host');
    try {
      FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8088);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      debugPrint('Main: Firebase Emulators initialized successfully');
    } catch (e) {
      debugPrint('Main: Error initializing emulators: $e');
    }
  }

  // Initialize Serverpod Client
  await initializeServerpodClient();

  // Background message handler needs to be registered early
  FirebaseMessaging.onBackgroundMessage(backgroundMessagingHandler);

  runApp(const VersionSelector());
}

class _MaintenanceApp extends StatelessWidget {
  const _MaintenanceApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MaintenanceScreen(),
    );
  }
}
