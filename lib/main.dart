import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/avatar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final host = isAndroid ? '10.0.2.2' : 'localhost';

    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  if (!kDebugMode && !kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }

  Avatar().init();
  debugRepaintRainbowEnabled = false;
  runApp(const App());
}
