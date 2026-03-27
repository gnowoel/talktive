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
import 'config/auth_config.dart';

import 'serverpod_client.dart';
import 'services/edge_to_edge_manager.dart';
import 'services/background_messaging_handler.dart';
import 'version_selector.dart';

Future<void> main() async {
  debugRepaintRainbowEnabled = false;

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize SharedPreferences to ensure plugin is registered early
  // and available when needed in Initialize wrapper.
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Warning: SharedPreferences pre-initialization failed: $e');
  }

  // Initialize edge-to-edge display support
  await EdgeToEdgeManager.initialize();

  // Initialize Google Sign-In (mandatory exactly once in v7.0+)
  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb ? AuthConfig.webClientId : null,
  );


  // Initialize Serverpod Client
  await initializeServerpodClient();

  // Firebase core initialization is essential and should stay in main()
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
    // Default app already exists (native pre-init). Safe to proceed.
    Firebase.app();
  }

  // Background message handler needs to be registered early
  FirebaseMessaging.onBackgroundMessage(backgroundMessagingHandler);

  runApp(const VersionSelector());
}
