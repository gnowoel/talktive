import 'package:firebase_core/firebase_core.dart';
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
import 'version_selector.dart';

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

  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb ? AuthConfig.webClientId : null,
    serverClientId: kIsWeb ? null : AuthConfig.webClientId,
  );

  await AppConfig.initialize();

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

  // Initialize Serverpod Client
  await initializeServerpodClient();

  // Background message handler needs to be registered early
  FirebaseMessaging.onBackgroundMessage(backgroundMessagingHandler);

  runApp(const VersionSelector());
}
