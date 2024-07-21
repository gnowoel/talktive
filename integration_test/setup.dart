import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:talktive/services/avatar.dart';
import 'package:talktive/services/firedata.dart';
import 'package:talktive/services/history.dart';

Future<void> setup() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  final host = isAndroid ? '10.0.2.2' : 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);

  await Avatar().init();
  await History().init();
  Firedata().syncTime();
}
