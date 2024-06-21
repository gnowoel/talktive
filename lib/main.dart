import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firedata.dart';
import 'services/history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';

    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  await History().loadRecords();
  Firedata().syncTime();
  runApp(const App());
}
