import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Messaging.handleMessage(message);
}

Future<void> main() async {
  debugRepaintRainbowEnabled = false;
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase core initialization is essential and should stay in main()
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background message handler needs to be registered early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const App());
}
